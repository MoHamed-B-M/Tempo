import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/hive_helper.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';

final alarmServiceProvider = Provider<AlarmService>((ref) {
  throw UnimplementedError('AlarmService must be provided via overrides');
});

final alarmListProvider =
    NotifierProvider<AlarmListNotifier, List<AlarmModel>>(
  AlarmListNotifier.new,
);

class AlarmListNotifier extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() {
    final stored = HiveHelper.alarms.values.toList();
    stored.sort((a, b) {
      final aMin = a.hour * 60 + a.minute;
      final bMin = b.hour * 60 + b.minute;
      return aMin.compareTo(bMin);
    });
    return stored;
  }

  AlarmService get _service => ref.read(alarmServiceProvider);

  Future<void> addAlarm({
    required int hour,
    required int minute,
    String sound = 'default',
    List<int> repeatDays = const [],
    String label = '',
  }) async {
    final alarm = AlarmModel(
      hour: hour,
      minute: minute,
      sound: sound,
      repeatDays: repeatDays,
      label: label,
    );
    await HiveHelper.alarms.put(alarm.id, alarm);
    sortAndUpdate();
    if (alarm.enabled) await _service.scheduleAlarm(alarm);
  }

  Future<void> updateAlarm(String id, AlarmModel updated) async {
    await HiveHelper.alarms.put(id, updated);
    sortAndUpdate();
    await _service.cancelAlarm(updated);
    if (updated.enabled) await _service.scheduleAlarm(updated);
  }

  Future<void> removeAlarm(String id) async {
    final existing = HiveHelper.alarms.get(id);
    if (existing != null) await _service.cancelAlarm(existing);
    await HiveHelper.alarms.delete(id);
    sortAndUpdate();
  }

  Future<void> toggleAlarm(String id) async {
    final alarm = HiveHelper.alarms.get(id);
    if (alarm == null) return;
    final updated = alarm.copyWith(enabled: !alarm.enabled);
    await HiveHelper.alarms.put(id, updated);
    sortAndUpdate();
    await _service.cancelAlarm(alarm);
    if (updated.enabled) await _service.scheduleAlarm(updated);
  }

  Future<void> updateAlarmLabel(String id, String label) async {
    final alarm = HiveHelper.alarms.get(id);
    if (alarm == null) return;
    await HiveHelper.alarms.put(id, alarm.copyWith(label: label));
    sortAndUpdate();
  }

  Future<void> updateAlarmRepeatDays(String id, List<int> days) async {
    final alarm = HiveHelper.alarms.get(id);
    if (alarm == null) return;
    final updated = alarm.copyWith(repeatDays: days);
    await HiveHelper.alarms.put(id, updated);
    sortAndUpdate();
    await _service.cancelAlarm(updated);
    if (updated.enabled) await _service.scheduleAlarm(updated);
  }

  Future<void> updateAlarmSound(String id, String sound) async {
    final alarm = HiveHelper.alarms.get(id);
    if (alarm == null) return;
    final updated = alarm.copyWith(sound: sound);
    await HiveHelper.alarms.put(id, updated);
    sortAndUpdate();
    await _service.cancelAlarm(updated);
    if (updated.enabled) await _service.scheduleAlarm(updated);
  }

  Future<void> clearAll() async {
    for (final alarm in state) {
      await _service.cancelAlarm(alarm);
    }
    await HiveHelper.alarms.clear();
    state = [];
  }

  Future<void> disableAlarm(String id) async {
    final alarm = HiveHelper.alarms.get(id);
    if (alarm == null || !alarm.enabled) return;
    await HiveHelper.alarms.put(id, alarm.copyWith(enabled: false));
    sortAndUpdate();
  }

  void sortAndUpdate() {
    final list = HiveHelper.alarms.values.toList();
    list.sort((a, b) {
      final aMin = a.hour * 60 + a.minute;
      final bMin = b.hour * 60 + b.minute;
      return aMin.compareTo(bMin);
    });
    state = list;
  }
}
