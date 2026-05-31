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
  TimeOfDay _selectedTime = TimeOfDay.now();
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

  Future<void> _saveAlarm(BuildContext sheetContext) async {
    HapticFeedback.mediumImpact();
    final service = context.read<AlarmService>();
    try {
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
      if (!mounted) return;
      if (sheetContext.mounted) {
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
        Navigator.pop(sheetContext);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save alarm',
            style: AppTextStyles.body(context).copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom +
                    80,
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
                        color: AppColors.secondaryTextOf(ctx)
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _editingAlarmId != null ? 'EDIT ALARM' : 'NEW ALARM',
                    style: AppTextStyles.buttonLabel(ctx).copyWith(fontSize: 16),
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
                  Card(
                    elevation: 0,
                    color: AppColors.surfaceCardOf(ctx),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: TextField(
                        onChanged: (val) => _selectedLabel = val,
                        controller: TextEditingController(text: _selectedLabel)
                          ..selection = TextSelection.collapsed(
                              offset: _selectedLabel.length),
                        style: AppTextStyles.body(ctx),
                        decoration: InputDecoration(
                          hintText: 'Add alarm label...',
                          hintStyle: AppTextStyles.subheading(ctx),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('REPEAT ON', style: AppTextStyles.buttonLabel(ctx)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      final selected = _selectedRepeatDays.contains(dayNum);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutCubic,
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.accentOf(ctx)
                                : AppColors.surfaceCardOf(ctx),
                            border: selected
                                ? null
                                : Border.all(
                                    color: AppColors.borderOf(ctx)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            days[i][0],
                            style: AppTextStyles.buttonLabel(ctx).copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.primaryTextOf(ctx),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
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
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 0,
                      color: AppColors.surfaceCardOf(ctx),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.music_note_outlined,
                                    color: AppColors.accentOf(ctx)),
                                const SizedBox(width: 12),
                                Text('SOUND',
                                    style: AppTextStyles.body(ctx)),
                              ],
                            ),
                            Text(
                              _selectedSound.toUpperCase(),
                              style: AppTextStyles.subheading(ctx).copyWith(
                                color: AppColors.accentOf(ctx),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(ctx).size.height * 0.04),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'CANCEL',
                              style:
                                  AppTextStyles.buttonLabel(ctx).copyWith(
                                color: AppColors.secondaryTextOf(ctx),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _saveAlarm(ctx),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentOf(ctx),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text('SAVE',
                                style: AppTextStyles.buttonLabel(ctx)),
                          ),
                        ),
                      ],
                    ),
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
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: _createNewAlarm,
            backgroundColor: AppColors.accentOf(context),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 4,
            child: const Icon(Icons.add, size: 28),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentOf(context).withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.alarm_add_rounded,
              color: AppColors.accentOf(context).withValues(alpha: 0.6),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NO ALARMS YET',
            style: AppTextStyles.buttonLabel(context).copyWith(
              color: AppColors.secondaryTextOf(context),
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first alarm',
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
        final timeStr =
            '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
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
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: alarm.enabled ? 2 : 0,
            color: alarm.enabled
                ? AppColors.accentOf(context)
                : AppColors.surfaceCardOf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: alarm.enabled
                  ? BorderSide.none
                  : BorderSide(
                      color: AppColors.borderOf(context), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _editAlarm(alarm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeStr,
                                style:
                                    AppTextStyles.alarmTime(context).copyWith(
                                  color: alarm.enabled
                                      ? Colors.white
                                      : AppColors.primaryTextOf(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (alarm.enabled)
                                Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (alarm.label.isNotEmpty) ...[
                                Text(
                                  '${alarm.label.toUpperCase()}  •  ',
                                  style: AppTextStyles.alarmLabel(context)
                                      .copyWith(
                                    color: alarm.enabled
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : AppColors.secondaryTextOf(context),
                                  ),
                                ),
                              ],
                              Text(
                                repeatText.toUpperCase(),
                                style: AppTextStyles.alarmLabel(context)
                                    .copyWith(
                                  color: alarm.enabled
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppColors.secondaryTextOf(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context
                            .read<AlarmService>()
                            .toggleAlarm(alarm.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: alarm.enabled
                              ? Colors.white
                              : Colors.transparent,
                          border: Border.all(
                            color: alarm.enabled
                                ? Colors.white
                                : AppColors.borderOf(context),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: alarm.enabled
                            ? Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: AppColors.accentOf(context),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
