import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import '../../providers/alarm_provider.dart';
import '../../widgets/sound_picker_sheet.dart';

class SleepTimerTab extends ConsumerStatefulWidget {
  const SleepTimerTab({super.key});

  @override
  ConsumerState<SleepTimerTab> createState() => _SleepTimerTabState();
}

class _SleepTimerTabState extends ConsumerState<SleepTimerTab> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  List<int> _selectedDays = [4];

  bool _sunriseAlarm = false;
  bool _vibrate = true;
  String _selectedSound = 'default';

  final List<String> _days = ['S', 'S', 'M', 'T', 'W', 'T', 'F'];

  void _incrementTime(int minutes) {
    HapticFeedback.selectionClick();
    setState(() {
      int totalMinutes =
          _selectedTime.hour * 60 + _selectedTime.minute + minutes;
      if (totalMinutes >= 1440) totalMinutes -= 1440;
      if (totalMinutes < 0) totalMinutes += 1440;
      _selectedTime =
          TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
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
    final cs = Theme.of(context).colorScheme;

    await ref.read(alarmListProvider.notifier).addAlarm(
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
            style: TextStyle(
              fontFamily: 'GoogleFonts.plusJakartaSans',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: cs.primary,
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep Timer',
            style: TextStyle(
              fontFamily: 'GoogleFonts.plusJakartaSans',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set a regular wake-up alarm'.toUpperCase(),
            style: TextStyle(
              fontFamily: 'GoogleFonts.plusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _incrementTime(-15),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.surfaceContainerHigh,
                      border:
                          Border.all(color: cs.outlineVariant, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.remove,
                      color: cs.onSurface,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _selectedTime
                          .format(context)
                          .replaceAll(RegExp(r'[a-zA-Z\s]'), ''),
                      style: TextStyle(
                        fontFamily: 'GoogleFonts.plusJakartaSans',
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      _selectedTime
                          .format(context)
                          .replaceAll(RegExp(r'[0-9:]'), '')
                          .trim()
                          .toLowerCase(),
                      style: TextStyle(
                        fontFamily: 'GoogleFonts.plusJakartaSans',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => _incrementTime(15),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.2),
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
                    color: isSelected ? cs.primary : cs.surfaceContainerHigh,
                    border: isSelected
                        ? null
                        : Border.all(color: cs.outlineVariant, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _days[index],
                    style: TextStyle(
                      fontFamily: 'GoogleFonts.plusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          Column(
            children: [
              _buildSettingCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Sunrise alarm',
                subtitle: 'Slowly brighten screen before alarm',
                enabled: _sunriseAlarm,
                cs: cs,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sunriseAlarm = !_sunriseAlarm);
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.vibration_outlined,
                title: 'Vibrate',
                subtitle: null,
                enabled: _vibrate,
                cs: cs,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _vibrate = !_vibrate);
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.music_note_outlined,
                title: 'Sound',
                subtitle:
                    'Default (${_selectedSound == 'default' ? 'miui_week_ringtone.ogg' : _selectedSound})',
                enabled: false,
                cs: cs,
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
          Row(
            children: [
              Expanded(
                child: M3EOutlinedButton(
                  onPressed: _resetFields,
                  size: M3EButtonSize.md,
                  decoration: M3EButtonDecoration(
                    side: WidgetStatePropertyAll(
                        BorderSide(color: cs.outlineVariant)),
                    borderRadius: 16,
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: M3EFilledButton(
                  onPressed: _saveSleepSchedule,
                  size: M3EButtonSize.md,
                  decoration: M3EButtonDecoration(
                    borderRadius: 16,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? Colors.transparent : cs.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? cs.onPrimary : cs.onSurface,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts.plusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'GoogleFonts.plusJakartaSans',
                        fontSize: 12,
                        color: enabled
                            ? cs.onPrimary.withValues(alpha: 0.7)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? cs.onPrimary : Colors.transparent,
                border: Border.all(
                  color: enabled
                      ? cs.onPrimary
                      : cs.onSurfaceVariant.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: enabled
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: cs.primary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
