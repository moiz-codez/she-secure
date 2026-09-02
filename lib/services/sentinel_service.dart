import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:screen_state_v2/screen_state.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app.dart';
import '../firebase_options.dart';
import '../providers/fake_call_provider.dart';
import '../utils/listen_heuristic.dart';
import '../utils/sentinel_heuristic.dart';
import 'audio_detection_service.dart';
import 'location_service.dart';
import 'sms_service.dart';

/// YAMNet's fixed input window: 0.975s of mono audio at 16kHz.
const _yamnetSampleRate = 16000;
const _yamnetWindowSamples = 15600;
const _screamLabels = ['Screaming', 'Crying, sobbing'];

const sentinelServiceChannelId = 'sentinel_service';
const sentinelServiceNotificationId = 8801;
const sentinelCheckinChannelId = 'sentinel_checkin';
const sentinelCheckinNotificationId = 8802;
const fakeCallChannelId = 'fake_call';
const fakeCallNotificationId = 8803;

/// Sets up the always-on notification channels and registers the
/// background-service config. Call once from `main()`, before `runApp`.
Future<void> initializeSentinelService() async {
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        sentinelServiceChannelId,
        'Smart Sentinel',
        description: 'Shows while Smart Sentinel is watching in the background.',
        importance: Importance.low,
      ));
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        sentinelCheckinChannelId,
        'Are-you-safe check',
        description: 'A silent, vibrate-only prompt when Smart Sentinel notices something unusual.',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ));
  // Silent — FakeCallProvider plays the actual ringtone once the ringing
  // screen is up (via flutter_ringtone_player, which can bypass silent
  // mode); this notification only exists to full-screen-launch the app
  // over a locked screen when the scheduled delay elapses.
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        fakeCallChannelId,
        'Fake call',
        description: 'Launches the fake-call screen when a scheduled call is due.',
        importance: Importance.max,
        playSound: false,
      ));

  await FlutterBackgroundService().configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false,
      autoStartOnBoot: false,
      isForegroundMode: true,
      notificationChannelId: sentinelServiceChannelId,
      foregroundServiceNotificationId: sentinelServiceNotificationId,
      initialNotificationTitle: 'Smart Sentinel',
      initialNotificationContent: 'Watching · learning your routine',
      foregroundServiceTypes: [AndroidForegroundType.location, AndroidForegroundType.microphone],
    ),
  );
}

/// Wires up the main isolate's own notification plugin instance so tapping
/// the "Are you safe?" ping (shown by the background isolate) opens the
/// check-in screen — the actual 30s countdown/escalation already runs
/// regardless of whether this is ever tapped; this is just the way in.
/// Call once from `main()`, before `runApp`.
Future<void> initializeMainIsolateNotifications() async {
  final notifications = FlutterLocalNotificationsPlugin();
  void handleTap(String? payload) {
    if (payload == 'checkin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed(Routes.checkin);
      });
    } else if (payload == 'fakecall') {
      const MethodChannel('she_secure/lockscreen').invokeMethod('showOverLockScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) context.read<FakeCallProvider>().ringNow();
        navigatorKey.currentState?.pushNamed(Routes.fakeCall);
      });
    }
  }

  await notifications.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    onDidReceiveNotificationResponse: (response) => handleTap(response.payload),
  );

  final launchDetails = await notifications.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true) {
    handleTap(launchDetails?.notificationResponse?.payload);
  }
}

/// Starts the background service if it isn't already running and [needed]
/// is true, then forwards [fields] as a 'configure' message. Used by both
/// SentinelProvider and ListenProvider — the background isolate above only
/// updates whichever fields are present in [fields], so either can call
/// this independently without clobbering the other's config.
Future<void> pushBackgroundConfig(Map<String, dynamic> fields, {required bool needed}) async {
  final service = FlutterBackgroundService();
  if (needed && !await service.isRunning()) {
    await service.startService();
  }
  service.invoke('configure', fields);
}

// ---- Background isolate state — plain top-level vars, this isolate lives
// as long as the foreground service does. ----
String? _uid;
bool _sentinelOn = false;
String _sensitivity = 'Balanced';
Timer? _sampleTimer;
Timer? _checkInTimer;
int _checkInSecondsLeft = 0;
bool _checkInActive = false;
int _anomalyStreak = 0;

bool _listenOn = false;
String _earSensitivity = 'Balanced';
AudioRecorder? _recorder;
StreamSubscription<Uint8List>? _micSub;
final List<int> _micBuffer = []; // raw little-endian PCM16 bytes
int _screamStreak = 0;

Timer? _fakeCallTimer;

bool _shakeOn = false;
StreamSubscription<UserAccelerometerEvent>? _shakeSub;
final List<DateTime> _shakePeaks = [];

bool _powerButtonOn = false;
StreamSubscription<ScreenStateEvent>? _screenSub;
final List<DateTime> _screenToggles = [];

/// A shake hard enough to matter, not just walking/pocket jostle.
const _shakeThreshold = 22.0; // m/s², well above normal handling
const _shakePeaksNeeded = 3;
const _shakeWindow = Duration(seconds: 2);

/// Real physical power-button KeyEvents aren't delivered to regular apps
/// at all — this approximates "press power 3x quickly" via the same
/// screen-on/off toggles a power button press causes, which is the
/// standard technique non-privileged apps use for this gesture. Not a
/// perfect proxy (anything else that toggles the screen counts too), but
/// it needs no special permission and works with the screen locked.
const _powerTogglesNeeded = 4; // ~2 presses' worth of on/off transitions
const _powerWindow = Duration(seconds: 3);

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // `startService()` on the main-isolate side only confirms Android
  // started this isolate — not that the awaits below have finished. If a
  // message arrives before its listener is registered, it's silently
  // dropped (no queueing, no error). Sentinel/Listen's config gets
  // resent on every Firestore change so a dropped first message was easy
  // to miss, but a one-shot action like scheduling a fake call has no
  // retry — that's why it could go missing entirely. Fix: register every
  // listener synchronously, right now, before any `await`; each handler
  // waits on `_ready` itself before touching Firebase/notifications.
  final ready = Completer<void>();
  FlutterLocalNotificationsPlugin? notificationsOrNull;

  service.on('configure').listen((event) async {
    await ready.future;
    final notifications = notificationsOrNull!;
    if (event == null) return;
    if (event.containsKey('uid')) _uid = event['uid'] as String?;

    if (event.containsKey('sentinelOn')) {
      final wasOn = _sentinelOn;
      _sentinelOn = event['sentinelOn'] as bool? ?? false;
      _sensitivity = event['sensitivity'] as String? ?? _sensitivity;
      if (_sentinelOn && !wasOn) {
        _sample(notifications, service); // sample right away, then every 5 min
        _sampleTimer?.cancel();
        _sampleTimer = Timer.periodic(const Duration(minutes: 5), (_) => _sample(notifications, service));
      } else if (!_sentinelOn && wasOn) {
        _sampleTimer?.cancel();
      }
    }

    if (event.containsKey('listenOn')) {
      final wasOn = _listenOn;
      _listenOn = event['listenOn'] as bool? ?? false;
      _earSensitivity = event['earSensitivity'] as String? ?? _earSensitivity;
      if (_listenOn && !wasOn) {
        _startMicStream(service);
      } else if (!_listenOn && wasOn) {
        _stopMicStream();
      }
    }

    if (event.containsKey('shakeOn')) {
      final wasOn = _shakeOn;
      _shakeOn = event['shakeOn'] as bool? ?? false;
      if (_shakeOn && !wasOn) {
        _startShakeDetection(service);
      } else if (!_shakeOn && wasOn) {
        _stopShakeDetection();
      }
    }

    if (event.containsKey('powerButtonOn')) {
      final wasOn = _powerButtonOn;
      _powerButtonOn = event['powerButtonOn'] as bool? ?? false;
      if (_powerButtonOn && !wasOn) {
        _startPowerButtonDetection(service);
      } else if (!_powerButtonOn && wasOn) {
        _stopPowerButtonDetection();
      }
    }

    // A caller that just needs the service *running* (Fake Call's
    // scheduleCall, Distress Listening's simulate button) sends an empty
    // `configure` purely to trigger pushBackgroundConfig's startService()
    // — it carries none of the toggle keys above. Without this guard, that
    // empty ping fell straight through to the check below with every
    // toggle still at its old value and _fakeCallTimer not yet set (the
    // real 'scheduleFakeCall' message hadn't been processed yet), so the
    // service stopped itself milliseconds after starting — the schedule
    // (or the scream simulation) that was about to follow never landed,
    // and shake/power-button detection got killed as collateral damage
    // any time this happened while they were the only things running.
    // Only re-evaluate "is anything still needed" when this message
    // actually changed one of the toggles.
    final touchedToggle = event.containsKey('sentinelOn') ||
        event.containsKey('listenOn') ||
        event.containsKey('shakeOn') ||
        event.containsKey('powerButtonOn');
    if (touchedToggle && !_sentinelOn && !_listenOn && !_shakeOn && !_powerButtonOn && _fakeCallTimer == null) {
      _sampleTimer?.cancel();
      _checkInTimer?.cancel();
      _stopMicStream();
      _stopShakeDetection();
      _stopPowerButtonDetection();
      service.stopSelf();
    }
  });

  service.on('simulateCheckIn').listen((_) async {
    await ready.future;
    _startCheckIn(
      'You are 2.4 km off your usual route home and moving at running pace.',
      notificationsOrNull!,
      service,
    );
  });

  service.on('confirm').listen((_) async {
    await ready.future;
    await _endCheckIn(escalated: false, notifications: notificationsOrNull!, service: service);
  });
  service.on('escalateNow').listen((_) async {
    await ready.future;
    await _endCheckIn(escalated: true, notifications: notificationsOrNull!, service: service);
  });

  service.on('simulateScream').listen((_) async {
    await ready.future;
    await _fireScream(service);
  });

  service.on('scheduleFakeCall').listen((event) async {
    await ready.future;
    final seconds = event?['seconds'] as int? ?? 0;
    final callerName = event?['callerName'] as String? ?? '';
    _scheduleFakeCall(seconds, callerName, notificationsOrNull!, service);
  });
  service.on('cancelFakeCall').listen((_) {
    _fakeCallTimer?.cancel();
    _fakeCallTimer = null;
  });

  service.on('stop').listen((_) {
    _sampleTimer?.cancel();
    _checkInTimer?.cancel();
    _fakeCallTimer?.cancel();
    _fakeCallTimer = null;
    _stopMicStream();
    _stopShakeDetection();
    _stopPowerButtonDetection();
    service.stopSelf();
  });

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  notificationsOrNull = notifications;
  ready.complete();
}

void _scheduleFakeCall(
  int seconds,
  String callerName,
  FlutterLocalNotificationsPlugin notifications,
  ServiceInstance service,
) {
  _fakeCallTimer?.cancel();
  var secondsLeft = seconds;
  _fakeCallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    secondsLeft -= 1;
    if (secondsLeft <= 0) {
      timer.cancel();
      _fakeCallTimer = null;
      _fireFakeCall(callerName, notifications, service);
    } else {
      service.invoke('fakeCallTick', {'secondsLeft': secondsLeft});
    }
  });
}

Future<void> _fireFakeCall(
  String callerName,
  FlutterLocalNotificationsPlugin notifications,
  ServiceInstance service,
) async {
  // Full-screen intent: if the phone is locked, Android launches the app
  // over the lock screen automatically, same as a real incoming call —
  // MainActivity's showOverLockScreen() (triggered by the 'fake_call'
  // intent extra flutter_local_notifications attaches) keeps it from
  // requiring the phone to be unlocked first.
  await notifications.show(
    id: fakeCallNotificationId,
    title: 'Incoming call',
    body: callerName,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        fakeCallChannelId,
        'Fake call',
        category: AndroidNotificationCategory.call,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: false,
        ongoing: true,
        autoCancel: true,
      ),
    ),
    payload: 'fakecall',
  );
  service.invoke('fakeCallFired', {'callerName': callerName});
}

void _startMicStream(ServiceInstance service) async {
  final recorder = AudioRecorder();
  if (!await recorder.hasPermission()) {
    recorder.dispose();
    return;
  }
  final stream = await recorder.startStream(
    const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: _yamnetSampleRate, numChannels: 1),
  );
  _recorder = recorder;
  _micBuffer.clear();
  _screamStreak = 0;
  _micSub = stream.listen((chunk) => _onAudioChunk(chunk, service));
}

void _stopMicStream() {
  _micSub?.cancel();
  _micSub = null;
  _recorder?.dispose();
  _recorder = null;
  _micBuffer.clear();
}

void _startShakeDetection(ServiceInstance service) {
  _shakePeaks.clear();
  _shakeSub?.cancel();
  _shakeSub = userAccelerometerEventStream().listen((event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (magnitude < _shakeThreshold) return;
    final now = DateTime.now();
    _shakePeaks.add(now);
    _shakePeaks.removeWhere((t) => now.difference(t) > _shakeWindow);
    if (_shakePeaks.length >= _shakePeaksNeeded) {
      _shakePeaks.clear();
      unawaited(_fireAlert(source: 'Shake to alert').then((_) => service.invoke('shortcutFired')));
    }
  });
}

void _stopShakeDetection() {
  _shakeSub?.cancel();
  _shakeSub = null;
  _shakePeaks.clear();
}

void _startPowerButtonDetection(ServiceInstance service) {
  _screenToggles.clear();
  _screenSub?.cancel();
  _screenSub = Screen().screenStateStream.listen((event) {
    if (event == ScreenStateEvent.SCREEN_UNLOCKED) return;
    final now = DateTime.now();
    _screenToggles.add(now);
    _screenToggles.removeWhere((t) => now.difference(t) > _powerWindow);
    if (_screenToggles.length >= _powerTogglesNeeded) {
      _screenToggles.clear();
      unawaited(_fireAlert(source: 'Power button ×3').then((_) => service.invoke('shortcutFired')));
    }
  });
}

void _stopPowerButtonDetection() {
  _screenSub?.cancel();
  _screenSub = null;
  _screenToggles.clear();
}

const _bytesPerWindow = _yamnetWindowSamples * 2; // PCM16 = 2 bytes/sample

void _onAudioChunk(Uint8List chunk, ServiceInstance service) {
  _micBuffer.addAll(chunk);
  while (_micBuffer.length >= _bytesPerWindow) {
    final windowBytes = Uint8List.fromList(_micBuffer.sublist(0, _bytesPerWindow));
    _micBuffer.removeRange(0, _bytesPerWindow);
    unawaited(_classifyWindow(windowBytes, service));
  }
}

Future<void> _classifyWindow(Uint8List bytes, ServiceInstance service) async {
  final byteData = ByteData.sublistView(bytes);
  final window = List<double>.generate(
    _yamnetWindowSamples,
    (i) => byteData.getInt16(i * 2, Endian.little) / 32768.0,
  );

  final confidence = await AudioDetectionService.classify(window, _screamLabels);
  final decision = checkScreamConfidence(
    confidence: confidence,
    sensitivity: _earSensitivity,
    consecutiveHits: _screamStreak,
  );
  _screamStreak = decision.isHit ? _screamStreak + 1 : 0;
  if (decision.shouldFire) {
    _screamStreak = 0;
    await _fireScream(service);
  }
}

Future<void> _fireScream(ServiceInstance service) async {
  await _fireAlert(source: 'Distress Listening');
  service.invoke('screamDetected');
}

Future<void> _sample(FlutterLocalNotificationsPlugin notifications, ServiceInstance service) async {
  final uid = _uid;
  if (uid == null || !_sentinelOn || _checkInActive) return;

  final position = await LocationService.getCurrentPosition();
  if (position == null) return;

  final now = DateTime.now();
  final sample = SentinelSample(
    weekday: now.weekday,
    minuteOfDay: now.hour * 60 + now.minute,
    lat: position.latitude,
    lng: position.longitude,
    speed: max(position.speed, 0),
  );

  final samples = FirebaseFirestore.instance.collection('users').doc(uid).collection('sentinelSamples');
  unawaited(samples.add({
    'timestamp': FieldValue.serverTimestamp(),
    'lat': sample.lat,
    'lng': sample.lng,
    'speed': sample.speed,
    'weekday': sample.weekday,
    'minuteOfDay': sample.minuteOfDay,
  }));
  // ponytail: client-side pruning on the same write path, bounded to one
  // small query — move to a scheduled Cloud Function if sample volume ever
  // makes this worth doing server-side instead.
  final cutoff = now.subtract(const Duration(days: 28));
  final stale = await samples.where('timestamp', isLessThan: Timestamp.fromDate(cutoff)).limit(20).get();
  for (final doc in stale.docs) {
    unawaited(doc.reference.delete());
  }

  final recent = await samples
      .where('weekday', isEqualTo: sample.weekday)
      .orderBy('timestamp', descending: true)
      .limit(60)
      .get();
  final baseline = recent.docs
      .map((d) => SentinelSample(
            weekday: d['weekday'] as int,
            minuteOfDay: d['minuteOfDay'] as int,
            lat: (d['lat'] as num).toDouble(),
            lng: (d['lng'] as num).toDouble(),
            speed: (d['speed'] as num).toDouble(),
          ))
      .where((s) => (s.minuteOfDay - sample.minuteOfDay).abs() <= 90)
      .toList();

  final result = checkAnomaly(
    current: sample,
    baseline: baseline,
    sensitivity: _sensitivity,
    recentAnomalyStreak: _anomalyStreak,
  );
  _anomalyStreak = result.signalPresent ? _anomalyStreak + 1 : 0;

  if (result.isAnomaly) {
    _anomalyStreak = 0;
    _startCheckIn(result.reason, notifications, service);
  }
}

void _startCheckIn(String reason, FlutterLocalNotificationsPlugin notifications, ServiceInstance service) {
  if (_checkInActive) return;
  _checkInActive = true;
  _checkInSecondsLeft = 30;

  notifications.show(
    id: sentinelCheckinNotificationId,
    title: 'Are you safe?',
    body: 'Tap to check in — an alert goes out on its own in 30 seconds.',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        sentinelCheckinChannelId,
        'Are-you-safe check',
        playSound: false,
        enableVibration: true,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
      ),
    ),
    payload: 'checkin',
  );

  service.invoke('checkinStarted', {'reason': reason, 'secondsLeft': _checkInSecondsLeft});

  _checkInTimer?.cancel();
  _checkInTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    _checkInSecondsLeft -= 1;
    if (_checkInSecondsLeft <= 0) {
      timer.cancel();
      _endCheckIn(escalated: true, notifications: notifications, service: service);
    } else {
      service.invoke('checkinTick', {'secondsLeft': _checkInSecondsLeft});
    }
  });
}

Future<void> _endCheckIn({
  required bool escalated,
  required FlutterLocalNotificationsPlugin notifications,
  required ServiceInstance service,
}) async {
  _checkInTimer?.cancel();
  _checkInActive = false;
  await notifications.cancel(id: sentinelCheckinNotificationId);

  if (escalated) {
    await _fireAlert(source: 'Smart Sentinel');
  }
  service.invoke('checkinEnded', {'escalated': escalated});
}

/// The actual "send help" side effects — a real location fix, a real SMS
/// to every trusted contact, a real history record. Runs here (rather than
/// through `SosProvider.arm()`) because this background isolate has no
/// access to that main-isolate instance; `SosProvider.markArmedExternally`
/// just mirrors the resulting armed state if the app happens to be open.
Future<void> _fireAlert({required String source}) async {
  final uid = _uid;
  if (uid == null) return;

  final position = await LocationService.getCurrentPosition();
  final where = position == null
      ? 'Location unavailable'
      : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

  final usersDoc = FirebaseFirestore.instance.collection('users').doc(uid);
  unawaited(usersDoc.collection('sosHistory').add({
    'where': where,
    'when': FieldValue.serverTimestamp(),
    'detail': 'Alert sent ($source)',
  }));

  final contactsSnapshot = await usersDoc.collection('contacts').get();
  final numbers = contactsSnapshot.docs.map((d) => d['phone'] as String? ?? '').where((p) => p.isNotEmpty).toList();
  final link = position == null ? '' : ' https://maps.google.com/?q=${position.latitude},${position.longitude}';
  await SmsService.sendToAll(numbers, 'I need help, this is my location.$link');
}
