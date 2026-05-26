import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/time_picker_wheel.dart';
import 'settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late TimeOfDay _selectedTime;
  String _selectedSound = 'default';
  List<int> _selectedRepeatDays = [];

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _selectedTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute + 1 >= 60 ? 0 : now.minute + 1,
    );
  }

  void _onTimeChanged(TimeOfDay time) {
    setState(() {
      _selectedTime = time;
    });
  }

  Future<void> _onConfirmAlarm() async {
    final service = context.read<AlarmService>();
    await service.addAlarm(
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      sound: _selectedSound,
      repeatDays: _selectedRepeatDays,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarm set for ${_selectedTime.format(context)}',
            style: AppTextStyles.body,
          ),
          backgroundColor: AppColors.surfaceCard,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleAlarm(String id) async {
    await context.read<AlarmService>().toggleAlarm(id);
  }

  Future<void> _deleteAlarm(String id) async {
    await context.read<AlarmService>().removeAlarm(id);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AlarmService>();
    final alarms = service.alarms;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Align(
                        child: Text(
                          _selectedTime.format(context),
                          style: AppTextStyles.displayTime,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 22),
                          color: AppColors.secondaryText,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getAlarmStatus(alarms),
                    style: AppTextStyles.subheading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Divider(
              color: AppColors.border,
              height: 1,
              thickness: 0.5,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: alarms.isEmpty
                  ? _buildEmptyState()
                  : _buildAlarmList(alarms),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomSheet(),
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
      return 'ALARM IN ${hours}h ${mins}min';
    }
    return 'ALARM IN ${mins}min';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.dimWhite, width: 1),
            ),
            child: const Icon(
              Icons.alarm_outlined,
              color: AppColors.dimWhite,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NO ALARMS',
            style: AppTextStyles.subheading,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new alarm',
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(List<AlarmModel> alarms) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: alarms.length,
      separatorBuilder: (_, __) => Divider(
        color: AppColors.border,
        height: 1,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return _AlarmTile(
          alarm: alarm,
          onToggle: () => _toggleAlarm(alarm.id),
          onDelete: () => _deleteAlarm(alarm.id),
        );
      },
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TimePickerWheel(
            initialHour: _selectedTime.hour,
            initialMinute: _selectedTime.minute,
            onChanged: _onTimeChanged,
            onConfirmed: _onConfirmAlarm,
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomControl(
                  icon: Icons.music_note_outlined,
                  label: 'SOUND',
                  onTap: () {},
                ),
                _BottomControl(
                  icon: Icons.repeat_outlined,
                  label: 'REPEAT',
                  onTap: () => _showRepeatPicker(),
                ),
                _BottomControl(
                  icon: Icons.short_text_outlined,
                  label: 'LABEL',
                  onTap: () => _showLabelDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showRepeatPicker() {
    final days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('REPEAT', style: AppTextStyles.buttonLabel),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (i) {
                      final selected = _selectedRepeatDays.contains(i + 1);
                      return ChoiceChip(
                        label: Text(days[i]),
                        selected: selected,
                        onSelected: (v) {
                          setModalState(() {
                            if (v) {
                              _selectedRepeatDays.add(i + 1);
                            } else {
                              _selectedRepeatDays.remove(i + 1);
                            }
                          });
                        },
                        selectedColor: AppColors.primaryText,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.background : AppColors.primaryText,
                          letterSpacing: 1,
                        ),
                        side: BorderSide(
                          color: AppColors.border,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('DONE', style: AppTextStyles.buttonLabel),
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

  void _showLabelDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Alarm label',
            hintStyle: AppTextStyles.subheading,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text('DONE', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final repeatText = alarm.isRepeating
        ? alarm.repeatDays.map((d) => days[d - 1]).join(' ')
        : 'Once';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: AppTextStyles.alarmTime.copyWith(
                    color: alarm.enabled
                        ? AppColors.primaryText
                        : AppColors.mediumWhite,
                  ),
                ),
                if (alarm.label.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    alarm.label.toUpperCase(),
                    style: AppTextStyles.alarmLabel.copyWith(
                      color: alarm.enabled
                          ? AppColors.secondaryText
                          : AppColors.dimWhite,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  repeatText.toUpperCase(),
                  style: AppTextStyles.alarmLabel.copyWith(
                    color: alarm.enabled
                        ? AppColors.secondaryText
                        : AppColors.dimWhite,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: alarm.enabled
                      ? AppColors.primaryText
                      : AppColors.dimWhite,
                  width: 1.5,
                ),
                color: alarm.enabled
                    ? AppColors.primaryText
                    : Colors.transparent,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: alarm.enabled ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: alarm.enabled
                            ? AppColors.background
                            : AppColors.mediumWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              color: AppColors.mediumWhite,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryText, size: 20),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.buttonLabel),
          ],
        ),
      ),
    );
  }
}
