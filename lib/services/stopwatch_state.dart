import 'package:flutter/foundation.dart';

class StopwatchState extends ChangeNotifier {
  int _elapsedMs = 0;
  bool _isRunning = false;

  int get elapsedMs => _elapsedMs;
  bool get isRunning => _isRunning;

  void start() {
    _isRunning = true;
    notifyListeners();
  }

  void stop() {
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _elapsedMs = 0;
    _isRunning = false;
    notifyListeners();
  }

  void tick() {
    _elapsedMs += 10;
    notifyListeners();
  }

  void setElapsed(int ms) {
    _elapsedMs = ms;
    notifyListeners();
  }
}
