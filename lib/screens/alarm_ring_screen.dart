import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/lock_screen.dart';

class AlarmRingScreen extends ConsumerWidget {
  final AlarmModel alarm;

  const AlarmRingScreen({super.key, required this.alarm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = TimeOfDay.now();
    final timeStr = now.format(context);
    final settings = ref.watch(alarmSettingsProvider);
    final alarmService = ref.read(alarmServiceProvider);

    void snooze() {
      alarmService.snoozeAlarm(alarm);
      Navigator.of(context).pop();
    }

    void dismiss() {
      alarmService.stopAlarm(alarm);
      if (!alarm.isRepeating) {
        ref.read(alarmListProvider.notifier).disableAlarm(alarm.id);
      }
      Navigator.of(context).pop();
    }

    return LockScreen(
      mode: LockScreenMode.alarm,
      title: alarm.label.isNotEmpty ? alarm.label : 'Alarm',
      timeDisplay: timeStr,
      showSnooze: true,
      autoDismissMinutes: settings.autoDismissMinutes,
      vibrateEnabled: settings.vibrateOnAlarm,
      volume: settings.volume,
      onStop: dismiss,
      onSnooze: snooze,
    );
  }
}
