import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/sound_picker_sheet.dart';
import '../widgets/time_picker_wheel.dart';
import 'settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TimeOfDay _selectedTime;
  String _selectedSound = 'default';
  List<int> _selectedRepeatDays = [];
  String _selectedLabel = '';
  String? _editingAlarmId;
  bool _isPickerVisible = false;
  late AnimationController _pickerAnimController;
  late Animation<double> _pickerAnimation;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _selectedTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute + 1 >= 60 ? 0 : now.minute + 1,
    );
    _pickerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pickerAnimation = CurvedAnimation(
      parent: _pickerAnimController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic.flipped,
    );
  }

  @override
  void dispose() {
    _pickerAnimController.dispose();
    super.dispose();
  }

  void _togglePicker() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPickerVisible = !_isPickerVisible;
      if (_isPickerVisible) {
        _pickerAnimController.forward();
      } else {
        _pickerAnimController.reverse();
      }
    });
  }

  void _hidePicker() {
    if (!_isPickerVisible) return;
    setState(() => _isPickerVisible = false);
    _pickerAnimController.reverse();
  }

  void _onTimeChanged(TimeOfDay time) {
    setState(() => _selectedTime = time);
  }

  Future<void> _onConfirmAlarm() async {
    HapticFeedback.mediumImpact();
    final service = context.read<AlarmService>();
    final id = _editingAlarmId;
    if (id != null) {
      await service.updateAlarm(
        id: id,
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
    _editingAlarmId = null;
    _hidePicker();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            id != null
                ? 'Alarm updated'
                : 'Alarm set for ${_selectedTime.format(context)}',
            style: AppTextStyles.body(context),
          ),
          backgroundColor: AppColors.surfaceCardOf(context),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleAlarm(String id) async {
    HapticFeedback.selectionClick();
    await context.read<AlarmService>().toggleAlarm(id);
  }

  void _editAlarm(AlarmModel alarm) {
    setState(() {
      _editingAlarmId = alarm.id;
      _selectedTime = TimeOfDay(hour: alarm.hour, minute: alarm.minute);
      _selectedSound = alarm.sound;
      _selectedRepeatDays = List.from(alarm.repeatDays);
      _selectedLabel = alarm.label;
      _isPickerVisible = true;
      _pickerAnimController.forward();
    });
  }

  Future<void> _deleteAlarm(String id) async {
    await context.read<AlarmService>().removeAlarm(id);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AlarmService>();
    final alarms = service.alarms;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
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
                          style: AppTextStyles.displayTime(context),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 22),
                          color: AppColors.secondaryTextOf(context),
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
                    style: AppTextStyles.subheading(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Divider(
              color: AppColors.borderOf(context),
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
      bottomNavigationBar: AnimatedBuilder(
        animation: _pickerAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surfaceCardOf(context),
              border: Border(
                top: BorderSide(
                    color: AppColors.borderOf(context), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isPickerVisible) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: AppColors.primaryTextOf(context)),
                        onPressed: _hidePicker,
                      ),
                    ],
                  ),
                  TimePickerWheel(
                    initialHour: _selectedTime.hour,
                    initialMinute: _selectedTime.minute,
                    onChanged: _onTimeChanged,
                    onConfirmed: _onConfirmAlarm,
                  ),
                  const SizedBox(height: 16),
                  Divider(
                      color: AppColors.borderOf(context),
                      height: 1,
                      thickness: 0.5),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomControl(
                          icon: Icons.music_note_outlined,
                          label: 'SOUND',
                          onTap: () => SoundPickerSheet.show(
                            context,
                            selectedSound: _selectedSound,
                            onSoundSelected: (sound) {
                              setState(() => _selectedSound = sound);
                            },
                          ),
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
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          alarms.isEmpty
                              ? 'TAP + TO SET ALARM'
                              : '${alarms.length} ALARM${alarms.length == 1 ? '' : 'S'}',
                          style: AppTextStyles.buttonLabel(context),
                        ),
                        FloatingActionButton(
                          heroTag: 'add_alarm',
                          mini: true,
                          onPressed: _togglePicker,
                          backgroundColor: AppColors.primaryTextOf(context),
                          foregroundColor: AppColors.backgroundOf(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.add, size: 24),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
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
              border:
                  Border.all(color: AppColors.dimWhiteOf(context), width: 1),
            ),
            child: Icon(
              Icons.alarm_outlined,
              color: AppColors.dimWhiteOf(context),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NO ALARMS',
            style: AppTextStyles.subheading(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new alarm',
            style: AppTextStyles.body(context)
                .copyWith(color: AppColors.secondaryTextOf(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(List<AlarmModel> alarms) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return Dismissible(
          key: ValueKey(alarm.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            HapticFeedback.mediumImpact();
            return true;
          },
          onDismissed: (_) => _deleteAlarm(alarm.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: AppColors.primaryTextOf(context).withValues(alpha: 0.1),
            child: Icon(Icons.delete_outline,
                color: AppColors.primaryTextOf(context)),
          ),
          child: Column(
            children: [
              _AlarmTile(
                alarm: alarm,
                onTap: () => _editAlarm(alarm),
                onToggle: () => _toggleAlarm(alarm.id),
              ),
              Divider(
                color: AppColors.borderOf(context),
                height: 1,
                thickness: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRepeatPicker() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardOf(context),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('REPEAT', style: AppTextStyles.buttonLabel(context)),
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
                        selectedColor: AppColors.primaryTextOf(context),
                        backgroundColor: AppColors.backgroundOf(context),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.backgroundOf(context)
                              : AppColors.primaryTextOf(context),
                          letterSpacing: 1,
                        ),
                        side: BorderSide(color: AppColors.borderOf(context)),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child:
                          Text('DONE', style: AppTextStyles.buttonLabel(context)),
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
    final controller = TextEditingController(text: _selectedLabel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCardOf(context),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.body(context),
          decoration: InputDecoration(
            hintText: 'Alarm label',
            hintStyle: AppTextStyles.subheading(context),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.borderOf(context)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedLabel = controller.text);
              Navigator.pop(ctx);
            },
            child:
                Text('DONE', style: AppTextStyles.buttonLabel(context)),
          ),
        ],
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _AlarmTile({
    required this.alarm,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final repeatText = alarm.isRepeating
        ? alarm.repeatDays.map((d) => days[d - 1]).join(' ')
        : 'Once';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: AppTextStyles.alarmTime(context).copyWith(
                      color: alarm.enabled
                          ? AppColors.primaryTextOf(context)
                          : AppColors.mediumWhiteOf(context),
                    ),
                  ),
                  if (alarm.label.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      alarm.label.toUpperCase(),
                      style: AppTextStyles.alarmLabel(context).copyWith(
                        color: alarm.enabled
                            ? AppColors.secondaryTextOf(context)
                            : AppColors.dimWhiteOf(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    repeatText.toUpperCase(),
                    style: AppTextStyles.alarmLabel(context).copyWith(
                      color: alarm.enabled
                          ? AppColors.secondaryTextOf(context)
                          : AppColors.dimWhiteOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: alarm.enabled
                      ? AppColors.primaryTextOf(context)
                      : AppColors.dimWhiteOf(context),
                  width: 1.5,
                ),
                color: alarm.enabled
                    ? AppColors.primaryTextOf(context)
                    : Colors.transparent,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    left: alarm.enabled ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: alarm.enabled
                            ? AppColors.backgroundOf(context)
                            : AppColors.mediumWhiteOf(context),
                      ),
                    ),
                  ),
                ],
              ),
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
            Icon(icon, color: AppColors.primaryTextOf(context), size: 20),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.buttonLabel(context)),
          ],
        ),
      ),
    );
  }
}
