import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/alarm_model.dart';
import '../../services/alarm_service.dart';
import '../../widgets/sound_picker_sheet.dart';
import '../../widgets/time_picker_wheel.dart';

class AlarmsTab extends StatefulWidget {
  const AlarmsTab({super.key});

  @override
  State<AlarmsTab> createState() => _AlarmsTabState();
}

class _AlarmsTabState extends State<AlarmsTab> {
  // Temporary editing state for bottom sheet
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  String _selectedSound = 'default';
  List<int> _selectedRepeatDays = [];
  String _selectedLabel = '';
  String? _editingAlarmId;

  void _editAlarm(AlarmModel alarm) {
    setState(() {
      _editingAlarmId = alarm.id;
      _selectedTime = TimeOfDay(hour: alarm.hour, minute: alarm.minute);
      _selectedSound = alarm.sound;
      _selectedRepeatDays = List.from(alarm.repeatDays);
      _selectedLabel = alarm.label;
    });
    _showAlarmEditorSheet(context);
  }

  void _createNewAlarm() {
    final now = TimeOfDay.now();
    setState(() {
      _editingAlarmId = null;
      _selectedTime = TimeOfDay(
        hour: now.hour,
        minute: now.minute + 1 >= 60 ? 0 : now.minute + 1,
      );
      _selectedSound = 'default';
      _selectedRepeatDays = [];
      _selectedLabel = '';
    });
    _showAlarmEditorSheet(context);
  }

  Future<void> _saveAlarm() async {
    HapticFeedback.mediumImpact();
    final service = context.read<AlarmService>();
    if (_editingAlarmId != null) {
      await service.updateAlarm(
        id: _editingAlarmId!,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        sound: _selectedSound,
        repeatDays: _selectedRepeatDays,
        label: _selectedLabel,
      );
    } else {
      await service.addAlarm(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        sound: _selectedSound,
        repeatDays: _selectedRepeatDays,
        label: _selectedLabel,
      );
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingAlarmId != null ? 'Alarm updated' : 'Alarm created',
            style: AppTextStyles.body(context).copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.accentOf(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAlarmEditorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTextOf(context).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _editingAlarmId != null ? 'EDIT ALARM' : 'NEW ALARM',
                    style: AppTextStyles.buttonLabel(context).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TimePickerWheel(
                    initialHour: _selectedTime.hour,
                    initialMinute: _selectedTime.minute,
                    onChanged: (time) {
                      setModalState(() => _selectedTime = time);
                    },
                  ),
                  const SizedBox(height: 24),
                  // Alarm Label Input
                  TextField(
                    onChanged: (val) => _selectedLabel = val,
                    controller: TextEditingController(text: _selectedLabel)
                      ..selection = TextSelection.collapsed(offset: _selectedLabel.length),
                    style: AppTextStyles.body(context),
                    decoration: InputDecoration(
                      hintText: 'Add alarm label...',
                      hintStyle: AppTextStyles.subheading(context),
                      filled: true,
                      fillColor: AppColors.surfaceCardOf(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weekday selection
                  Text('REPEAT ON', style: AppTextStyles.buttonLabel(context)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final selected = _selectedRepeatDays.contains(dayNum);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            if (selected) {
                              _selectedRepeatDays.remove(dayNum);
                            } else {
                              _selectedRepeatDays.add(dayNum);
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? AppColors.accentOf(context) : AppColors.surfaceCardOf(context),
                            border: selected ? null : Border.all(color: AppColors.borderOf(context)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            days[i][0],
                            style: AppTextStyles.buttonLabel(context).copyWith(
                              color: selected ? Colors.white : AppColors.primaryTextOf(context),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Alarm Sound Selector
                  InkWell(
                    onTap: () {
                      SoundPickerSheet.show(
                        context,
                        selectedSound: _selectedSound,
                        onSoundSelected: (sound) {
                          setModalState(() => _selectedSound = sound);
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCardOf(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.music_note_outlined, color: AppColors.accentOf(context)),
                              const SizedBox(width: 12),
                              Text('SOUND', style: AppTextStyles.body(context)),
                            ],
                          ),
                          Text(
                            _selectedSound.toUpperCase(),
                            style: AppTextStyles.subheading(context).copyWith(
                              color: AppColors.accentOf(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Save Button
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'CANCEL',
                            style: AppTextStyles.buttonLabel(context).copyWith(
                              color: AppColors.secondaryTextOf(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOf(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('SAVE', style: AppTextStyles.buttonLabel(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getAlarmStatus(List<AlarmModel> alarms) {
    final active = alarms.where((a) => a.enabled).toList();
    if (active.isEmpty) return 'NO ALARMS SET';
    final next = active.first;
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final alarmMinutes = next.hour * 60 + next.minute;
    final diff = alarmMinutes > currentMinutes
        ? alarmMinutes - currentMinutes
        : alarmMinutes - currentMinutes + 1440;
    final hours = diff ~/ 60;
    final mins = diff % 60;
    if (hours > 0) {
      return 'ALARM IN ${hours}H ${mins}MIN';
    }
    return 'ALARM IN ${mins}MIN';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AlarmService>();
    final alarms = service.alarms;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alarms',
                style: AppTextStyles.heading(context),
              ),
              const SizedBox(height: 4),
              Text(
                _getAlarmStatus(alarms),
                style: AppTextStyles.subheading(context),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: alarms.isEmpty
                    ? _buildEmptyState()
                    : _buildAlarmList(alarms),
              ),
            ],
          ),
        ),
        // Premium squircle orange "+" button
        Positioned(
          right: 24,
          bottom: 24,
          child: GestureDetector(
            onTap: _createNewAlarm,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentOf(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOf(context).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondaryTextOf(context).withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(
              Icons.alarm,
              color: AppColors.secondaryTextOf(context).withValues(alpha: 0.5),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NO ACTIVE ALARMS',
            style: AppTextStyles.buttonLabel(context).copyWith(
              color: AppColors.secondaryTextOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "+" button to set one.',
            style: AppTextStyles.subheading(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(List<AlarmModel> alarms) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: alarms.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        final timeStr = '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final repeatText = alarm.isRepeating
            ? alarm.repeatDays.map((d) => days[d - 1]).join(' ')
            : 'Once';

        return Dismissible(
          key: ValueKey(alarm.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context.read<AlarmService>().removeAlarm(alarm.id);
          },
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          child: GestureDetector(
            onTap: () => _editAlarm(alarm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: alarm.enabled ? AppColors.accentOf(context) : AppColors.surfaceCardOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: alarm.enabled ? Colors.transparent : AppColors.borderOf(context),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeStr,
                          style: AppTextStyles.alarmTime(context).copyWith(
                            color: alarm.enabled ? Colors.white : AppColors.primaryTextOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (alarm.label.isNotEmpty) ...[
                              Text(
                                '${alarm.label.toUpperCase()}  •  ',
                                style: AppTextStyles.alarmLabel(context).copyWith(
                                  color: alarm.enabled ? Colors.white.withValues(alpha: 0.8) : AppColors.secondaryTextOf(context),
                                ),
                              ),
                            ],
                            Text(
                              repeatText.toUpperCase(),
                              style: AppTextStyles.alarmLabel(context).copyWith(
                                color: alarm.enabled ? Colors.white.withValues(alpha: 0.8) : AppColors.secondaryTextOf(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Custom Checkmark Selector Switch
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<AlarmService>().toggleAlarm(alarm.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: alarm.enabled ? Colors.white : Colors.transparent,
                        border: Border.all(
                          color: alarm.enabled ? Colors.white : AppColors.borderOf(context),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: alarm.enabled
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.accentOf(context),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
