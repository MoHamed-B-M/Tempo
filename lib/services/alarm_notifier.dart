import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import 'alarm_service.dart';

class AlarmStateNotifier extends ChangeNotifier {
  static const _storageKey = 'alarms';

  final AlarmService _service;
  List<AlarmModel> _state = [];

  List<AlarmModel> get state => _state;
  List<AlarmModel> get alarms => _state;

  set state(List<AlarmModel> value) {
    _state = value;
    notifyListeners();
  }

  AlarmStateNotifier(this._service);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      state = list
          .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((a) => a.toJson()).toList());
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
    state = [...state, alarm];
    await _persist();
    if (alarm.enabled) {
      await _service.scheduleAlarm(alarm);
    }
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
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = state[index].copyWith(
      hour: hour,
      minute: minute,
      sound: sound,
      repeatDays: repeatDays,
      label: label,
    );
    final newList = [...state];
    newList[index] = updated;
    state = newList;
    await _persist();
    await _service.cancelAlarm(state[index]);
    if (updated.enabled) {
      await _service.scheduleAlarm(updated);
    }
  }

  Future<void> removeAlarm(String id) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    await _service.cancelAlarm(state[index]);
    state = [...state.take(index), ...state.skip(index + 1)];
    await _persist();
  }

  Future<void> toggleAlarm(String id) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = state[index].copyWith(enabled: !state[index].enabled);
    final newList = [...state];
    newList[index] = updated;
    state = newList;
    await _persist();
    await _service.cancelAlarm(state[index]);
    if (updated.enabled) {
      await _service.scheduleAlarm(updated);
    }
  }

  Future<void> disableAlarm(String id) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1 || !state[index].enabled) return;
    final newList = [...state];
    newList[index] = state[index].copyWith(enabled: false);
    state = newList;
    await _persist();
  }

  Future<void> updateAlarmLabel(String id, String label) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final newList = [...state];
    newList[index] = state[index].copyWith(label: label);
    state = newList;
    await _persist();
  }

  Future<void> updateAlarmRepeatDays(String id, List<int> days) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = state[index].copyWith(repeatDays: days);
    final newList = [...state];
    newList[index] = updated;
    state = newList;
    await _persist();
    await _service.cancelAlarm(updated);
    if (updated.enabled) {
      await _service.scheduleAlarm(updated);
    }
  }

  Future<void> updateAlarmSound(String id, String sound) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = state[index].copyWith(sound: sound);
    final newList = [...state];
    newList[index] = updated;
    state = newList;
    await _persist();
    await _service.cancelAlarm(updated);
    if (updated.enabled) {
      await _service.scheduleAlarm(updated);
    }
  }

  Future<void> clearAllAlarms() async {
    for (final alarm in state) {
      await _service.cancelAlarm(alarm);
    }
    state = [];
    await _persist();
  }

  Future<void> scheduleAll() async {
    await _service.scheduleAll(state);
  }

  void checkMissedAlarms() {
    _service.checkMissedAlarms(state);
  }

  Future<List<String>> fetchAndClearStoppedAlarms() {
    return _service.fetchAndClearStoppedAlarms();
  }
}
