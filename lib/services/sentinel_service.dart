import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app.dart';
import '../firebase_options.dart';
import '../utils/sentinel_heuristic.dart';
import 'location_service.dart';
import 'sms_service.dart';

const sentinelServiceChannelId = 'sentinel_service';
const sentinelServiceNotificationId = 8801;
const sentinelCheckinChannelId = 'sentinel_checkin';
const sentinelCheckinNotificationId = 8802;

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
      foregroundServiceTypes: [AndroidForegroundType.location],
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

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );

  service.on('configure').listen((event) {
    if (event == null) return;
    _uid = event['uid'] as String?;
    final wasOn = _sentinelOn;
    _sentinelOn = event['sentinelOn'] as bool? ?? false;
    _sensitivity = event['sensitivity'] as String? ?? 'Balanced';
    if (_sentinelOn && !wasOn) {
      _sample(notifications, service); // sample right away, then every 5 min
      _sampleTimer?.cancel();
      _sampleTimer = Timer.periodic(const Duration(minutes: 5), (_) => _sample(notifications, service));
    } else if (!_sentinelOn && wasOn) {
      _sampleTimer?.cancel();
    }
  });

  service.on('simulateCheckIn').listen((_) {
    _startCheckIn(
      'You are 2.4 km off your usual route home and moving at running pace.',
      notifications,
      service,
    );
  });

  service.on('confirm').listen((_) => _endCheckIn(escalated: false, notifications: notifications, service: service));
  service.on('escalateNow').listen((_) => _endCheckIn(escalated: true, notifications: notifications, service: service));

  service.on('stop').listen((_) {
    _sampleTimer?.cancel();
    _checkInTimer?.cancel();
    service.stopSelf();
  });
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
    await _fireAlert();
  }
  service.invoke('checkinEnded', {'escalated': escalated});
}

/// The actual "send help" side effects — a real location fix, a real SMS
/// to every trusted contact, a real history record. Runs here (rather than
/// through `SosProvider.arm()`) because this background isolate has no
/// access to that main-isolate instance; `SosProvider.markArmedExternally`
/// just mirrors the resulting armed state if the app happens to be open.
Future<void> _fireAlert() async {
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
    'detail': 'Alert sent (Smart Sentinel)',
  }));

  final contactsSnapshot = await usersDoc.collection('contacts').get();
  final numbers = contactsSnapshot.docs.map((d) => d['phone'] as String? ?? '').where((p) => p.isNotEmpty).toList();
  final link = position == null ? '' : ' https://maps.google.com/?q=${position.latitude},${position.longitude}';
  await SmsService.sendToAll(numbers, 'I need help, this is my location.$link');
}
