import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import 'alarm_service.dart';

class AlarmNotifier extends ChangeNotifier {
  static const _storageKey = 'alarms';

  final AlarmService _service;
  List<AlarmModel> _alarms = [];

  List<AlarmModel> get alarms => _alarms;

  AlarmNotifier(this._service);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      _alarms = list
          .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<AlarmModel> addAlarm({
    required int hour,
    required int minute,
    String sound = 'default',
    List<int> repeatDays = const [],
    String label = '',
  }) async {
    final alarm = AlarmModel(
      id: const Uuid().v4(),
      hour: hour,
      minute: minute,
      sound: sound,
      repeatDays: repeatDays,
      label: label,
    );
    _alarms.add(alarm);
    await _persist();
    if (alarm.enabled) {
      await _service.scheduleAlarm(alarm);
    }
    notifyListeners();
    return alarm;
  }

  Future<void> updateAlarm({
    required String id,
    required int hour,
    required int minute,
    String sound = 'default',
    List<int> repeatDays = const [],
    String label = '',
  }) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(
      hour: hour,
      minute: minute,
      sound: sound,
      repeatDays: repeatDays,
      label: label,
    );
    _alarms[index] = updated;
    await _persist();
    await _service.cancelAlarm(_alarms[index]);
    if (updated.enabled) {
      await _service.scheduleAlarm(updated);
    }
    notifyListeners();
  }

  Future<void> removeAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    await _service.cancelAlarm(_alarms[index]);
    _alarms.removeAt(index);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(enabled: !_alarms[index].enabled);
    _alarms[index] = updated;
    await _persist();
    await _service.cancelAlarm(_alarms[index]);
    if (updated.enabled) {
      await _service.scheduleAlarm(updated);
    }
    notifyListeners();
  }

  Future<void> disableAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1 || !_alarms[index].enabled) return;
    _alarms[index] = _alarms[index].copyWith(enabled: false);
    await _persist();
    notifyListeners();
  }

  Future<void> updateAlarmLabel(String id, String label) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _alarms[index] = _alarms[index].copyWith(label: label);
    await _persist();
    notifyListeners();
  }

  Future<void> updateAlarmRepeatDays(String id, List<int> days) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _alarms[index] = _alarms[index].copyWith(repeatDays: days);
    await _persist();
    await _service.cancelAlarm(_alarms[index]);
    if (_alarms[index].enabled) {
      await _service.scheduleAlarm(_alarms[index]);
    }
    notifyListeners();
  }

  Future<void> updateAlarmSound(String id, String sound) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _alarms[index] = _alarms[index].copyWith(sound: sound);
    await _persist();
    await _service.cancelAlarm(_alarms[index]);
    if (_alarms[index].enabled) {
      await _service.scheduleAlarm(_alarms[index]);
    }
    notifyListeners();
  }

  Future<void> clearAllAlarms() async {
    for (final alarm in _alarms) {
      await _service.cancelAlarm(alarm);
    }
    _alarms.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> scheduleAll() async {
    await _service.scheduleAll(_alarms);
  }

  void checkMissedAlarms() {
    _service.checkMissedAlarms(_alarms);
  }

  Future<List<String>> fetchAndClearStoppedAlarms() {
    return _service.fetchAndClearStoppedAlarms();
  }
}
