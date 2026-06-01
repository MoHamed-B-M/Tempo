import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/hive_helper.dart';

final alarmSettingsProvider =
    NotifierProvider<AlarmSettingsNotifier, AlarmSettingsState>(
  AlarmSettingsNotifier.new,
);

class AlarmSettingsState {
  final int autoDismissMinutes;
  final bool vibrateOnAlarm;
  final double volume;

  const AlarmSettingsState({
    this.autoDismissMinutes = 0,
    this.vibrateOnAlarm = true,
    this.volume = 1.0,
  });

  bool get autoDismissEnabled => autoDismissMinutes > 0;

  AlarmSettingsState copyWith({
    int? autoDismissMinutes,
    bool? vibrateOnAlarm,
    double? volume,
  }) {
    return AlarmSettingsState(
      autoDismissMinutes: autoDismissMinutes ?? this.autoDismissMinutes,
      vibrateOnAlarm: vibrateOnAlarm ?? this.vibrateOnAlarm,
      volume: volume ?? this.volume,
    );
  }
}

class AlarmSettingsNotifier extends Notifier<AlarmSettingsState> {
  @override
  AlarmSettingsState build() {
    final autoDismiss =
        HiveHelper.settings.get('auto_dismiss_minutes') as int? ?? 0;
    final vibrate = HiveHelper.settings.get('vibrate_on_alarm') as bool? ?? true;
    final volume = HiveHelper.settings.get('alarm_volume') as double? ?? 1.0;
    return AlarmSettingsState(
      autoDismissMinutes: autoDismiss,
      vibrateOnAlarm: vibrate,
      volume: volume,
    );
  }

  Future<void> setAutoDismissMinutes(int minutes) async {
    state = state.copyWith(autoDismissMinutes: minutes);
    await HiveHelper.settings.put('auto_dismiss_minutes', minutes);
  }

  Future<void> setVibrateOnAlarm(bool value) async {
    state = state.copyWith(vibrateOnAlarm: value);
    await HiveHelper.settings.put('vibrate_on_alarm', value);
  }

  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    await HiveHelper.settings.put('alarm_volume', clamped);
  }
}
