import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmSettings extends ChangeNotifier {
  static const _prefix = 'alarm_settings';
  static const _autoDismissKey = '${_prefix}_auto_dismiss';
  static const _vibrateKey = '${_prefix}_vibrate';
  static const _volumeKey = '${_prefix}_volume';

  int _autoDismissMinutes = 0;
  bool _vibrateOnAlarm = true;
  double _volume = 1.0;

  int get autoDismissMinutes => _autoDismissMinutes;
  bool get vibrateOnAlarm => _vibrateOnAlarm;
  bool get autoDismissEnabled => _autoDismissMinutes > 0;
  double get volume => _volume;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoDismissMinutes = prefs.getInt(_autoDismissKey) ?? 0;
    _vibrateOnAlarm = prefs.getBool(_vibrateKey) ?? true;
    _volume = prefs.getDouble(_volumeKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setAutoDismissMinutes(int minutes) async {
    _autoDismissMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoDismissKey, minutes);
  }

  Future<void> setVibrateOnAlarm(bool value) async {
    _vibrateOnAlarm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrateKey, value);
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
  }
}
