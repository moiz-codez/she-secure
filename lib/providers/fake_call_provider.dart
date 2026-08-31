import 'dart:async';

import 'package:flutter/foundation.dart';

enum FakeCallPhase { setup, waiting, ringing, inCall }

class FakeCallProvider extends ChangeNotifier {
  static const names = ['Abbu', 'Ammi', 'Boss', 'Bhai'];
  static const delaysSeconds = [5, 10, 30, 60];

  FakeCallPhase phase = FakeCallPhase.setup;
  String callerName = 'Abbu';
  int delaySeconds = 10;
  int secondsLeft = 10;
  int callSeconds = 0;

  Timer? _timer;

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
  }

  void scheduleCall() {
    _timer?.cancel();
    phase = FakeCallPhase.waiting;
    secondsLeft = delaySeconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft -= 1;
      if (secondsLeft <= 0) {
        timer.cancel();
        phase = FakeCallPhase.ringing;
        callSeconds = 0;
      }
      notifyListeners();
    });
  }

  void answer() {
    _timer?.cancel();
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
    phase = FakeCallPhase.setup;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
