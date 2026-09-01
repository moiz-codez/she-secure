import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import '../services/sentinel_service.dart';

enum FakeCallPhase { setup, waiting, ringing, inCall }

/// The setup/ringing/in-call UI and its timers are all local — the one
/// exception is the *scheduled* delay: that countdown runs in the same
/// background service Smart Sentinel/Distress Listening use
/// (`sentinel_service.dart`), so it still fires even if the screen turns
/// off or the app is backgrounded while waiting. This provider mirrors
/// that isolate's tick/fire events, the same pattern `SentinelProvider`
/// uses for its check-in countdown.
class FakeCallProvider extends ChangeNotifier {
  FakeCallProvider() {
    _tickSub = _service.on('fakeCallTick').listen((event) {
      secondsLeft = event?['secondsLeft'] as int? ?? secondsLeft;
      notifyListeners();
    });
    _firedSub = _service.on('fakeCallFired').listen((event) {
      callerName = event?['callerName'] as String? ?? callerName;
      phase = FakeCallPhase.ringing;
      callSeconds = 0;
      notifyListeners();
      _startRinging();
    });
  }

  static const names = ['Abbu', 'Ammi', 'Boss', 'Bhai'];
  static const delaysSeconds = [5, 10, 30, 60];

  FakeCallPhase phase = FakeCallPhase.setup;
  String callerName = 'Abbu';
  int delaySeconds = 10;
  int secondsLeft = 10;
  int callSeconds = 0;

  Timer? _timer;
  final _service = FlutterBackgroundService();
  StreamSubscription<Map<String, dynamic>?>? _tickSub;
  StreamSubscription<Map<String, dynamic>?>? _firedSub;
  final _ringtonePlayer = FlutterRingtonePlayer();

  void _startRinging() {
    _ringtonePlayer.play(android: AndroidSounds.ringtone, looping: true, volume: 1, asAlarm: true);
  }

  void _stopRinging() => _ringtonePlayer.stop();

  void setCallerName(String name) {
    callerName = name;
    notifyListeners();
  }

  void setDelay(int seconds) {
    delaySeconds = seconds;
    secondsLeft = seconds;
    notifyListeners();
  }

  void ringNow() {
    _timer?.cancel();
    phase = FakeCallPhase.ringing;
    callSeconds = 0;
    notifyListeners();
    _startRinging();
  }

  Future<void> scheduleCall() async {
    phase = FakeCallPhase.waiting;
    secondsLeft = delaySeconds;
    notifyListeners();
    await pushBackgroundConfig({}, needed: true);
    _service.invoke('scheduleFakeCall', {'seconds': delaySeconds, 'callerName': callerName});
  }

  void answer() {
    _timer?.cancel();
    _stopRinging();
    phase = FakeCallPhase.inCall;
    callSeconds = 0;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      callSeconds += 1;
      notifyListeners();
    });
  }

  void endCall() {
    _timer?.cancel();
    _stopRinging();
    _service.invoke('cancelFakeCall');
    phase = FakeCallPhase.setup;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickSub?.cancel();
    _firedSub?.cancel();
    _stopRinging();
    super.dispose();
  }
}
