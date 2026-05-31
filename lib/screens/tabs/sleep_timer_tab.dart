import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/alarm_service.dart';
import '../../widgets/sound_picker_sheet.dart';

class SleepTimerTab extends StatefulWidget {
  const SleepTimerTab({super.key});

  @override
  State<SleepTimerTab> createState() => _SleepTimerTabState();
}

class _SleepTimerTabState extends State<SleepTimerTab> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  List<int> _selectedDays = [4]; // Pre-select Thursday (T) to match mockup Screen 3
  
  // Settings card states
  bool _sunriseAlarm = false;
  bool _vibrate = true; // Pre-enable Vibrate to match mockup Screen 3 (orange card)
  String _selectedSound = 'default';

  final List<String> _days = ['S', 'S', 'M', 'T', 'W', 'T', 'F'];

  void _incrementTime(int minutes) {
    HapticFeedback.selectionClick();
    setState(() {
      int totalMinutes = _selectedTime.hour * 60 + _selectedTime.minute + minutes;
      if (totalMinutes >= 1440) totalMinutes -= 1440;
      if (totalMinutes < 0) totalMinutes += 1440;
      _selectedTime = TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
    });
  }

  void _toggleDay(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      final dayNumber = index + 1;
      if (_selectedDays.contains(dayNumber)) {
        _selectedDays.remove(dayNumber);
      } else {
        _selectedDays.add(dayNumber);
      }
    });
  }

  Future<void> _saveSleepSchedule() async {
    HapticFeedback.mediumImpact();
    final service = context.read<AlarmService>();
    
    // Add sleep alarm to AlarmService
    await service.addAlarm(
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      sound: _selectedSound,
      repeatDays: _selectedDays,
      label: 'Wake-up Alarm',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sleep alarm scheduled for ${_selectedTime.format(context)}',
            style: AppTextStyles.body(context).copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.accentOf(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetFields() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedTime = const TimeOfDay(hour: 7, minute: 0);
      _selectedDays = [4];
      _sunriseAlarm = false;
      _vibrate = true;
      _selectedSound = 'default';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep Timer',
            style: AppTextStyles.heading(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Set a regular wake-up alarm'.toUpperCase(),
            style: AppTextStyles.subheading(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Large Time Display with Plus / Minus buttons
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus Button
                GestureDetector(
                  onTap: () => _incrementTime(-15),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceCardOf(context),
                      border: Border.all(color: AppColors.borderOf(context), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.remove,
                      color: AppColors.primaryTextOf(context),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Time Text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _selectedTime.format(context).replaceAll(RegExp(r'[a-zA-Z\s]'), ''),
                      style: AppTextStyles.displayTime(context).copyWith(fontSize: 64),
                    ),
                    Text(
                      _selectedTime.format(context).replaceAll(RegExp(r'[0-9:]'), '').trim().toLowerCase(),
                      style: AppTextStyles.displayTime(context).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Plus Button
                GestureDetector(
                  onTap: () => _incrementTime(15),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentOf(context),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentOf(context).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Weekdays selector row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index + 1);
              return GestureDetector(
                onTap: () => _toggleDay(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accentOf(context) : AppColors.surfaceCardOf(context),
                    border: isSelected ? null : Border.all(color: AppColors.borderOf(context), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _days[index],
                    style: AppTextStyles.buttonLabel(context).copyWith(
                      color: isSelected ? Colors.white : AppColors.primaryTextOf(context),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          // Toggle Settings Cards
          Column(
            children: [
              // Sunrise Alarm Card
              _buildSettingCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Sunrise alarm',
                subtitle: 'Slowly brighten screen before alarm',
                enabled: _sunriseAlarm,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sunriseAlarm = !_sunriseAlarm);
                },
              ),
              const SizedBox(height: 12),
              // Vibrate Card (Pre-enabled, matches mockup 3)
              _buildSettingCard(
                icon: Icons.vibration_outlined,
                title: 'Vibrate',
                subtitle: null,
                enabled: _vibrate,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _vibrate = !_vibrate);
                },
              ),
              const SizedBox(height: 12),
              // Sound Card
              _buildSettingCard(
                icon: Icons.music_note_outlined,
                title: 'Sound',
                subtitle: 'Default (${_selectedSound == 'default' ? 'miui_week_ringtone.ogg' : _selectedSound})',
                enabled: false, // Solid sound card stays white
                onTap: () {
                  SoundPickerSheet.show(
                    context,
                    selectedSound: _selectedSound,
                    onSoundSelected: (sound) {
                      setState(() => _selectedSound = sound);
                    },
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          // Bottom Navigation / Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _resetFields,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderOf(context), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.buttonLabel(context).copyWith(
                        color: AppColors.secondaryTextOf(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _saveSleepSchedule,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accentOf(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentOf(context).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Next',
                      style: AppTextStyles.buttonLabel(context).copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String? subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? AppColors.accentOf(context) : AppColors.surfaceCardOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? Colors.transparent : AppColors.borderOf(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? Colors.white : AppColors.primaryTextOf(context),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      color: enabled ? Colors.white : AppColors.primaryTextOf(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.alarmLabel(context).copyWith(
                        color: enabled ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryTextOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Custom Radio/Check Circle on the Right
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: enabled ? Colors.white : AppColors.secondaryTextOf(context).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: enabled
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.accentOf(context),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
