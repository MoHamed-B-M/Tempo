import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../services/alarm_notifier.dart';
import '../services/alarm_service.dart';
import '../services/alarm_settings.dart';
import '../widgets/lock_screen.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  void _snooze() {
    context.read<AlarmService>().snoozeAlarm(widget.alarm);
    Navigator.of(context).pop();
  }

  void _dismiss() {
    final service = context.read<AlarmService>();
    service.stopAlarm(widget.alarm);
    if (!widget.alarm.isRepeating) {
      context.read<AlarmStateNotifier>().disableAlarm(widget.alarm.id);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final timeStr = now.format(context);
    final settings = context.watch<AlarmSettings>();

    return LockScreen(
      mode: LockScreenMode.alarm,
      title: widget.alarm.label.isNotEmpty ? widget.alarm.label : 'Alarm',
      timeDisplay: timeStr,
      showSnooze: true,
      autoDismissMinutes: settings.autoDismissMinutes,
      vibrateEnabled: settings.vibrateOnAlarm,
      volume: settings.volume,
      onStop: _dismiss,
      onSnooze: _snooze,
    );
  }
}
