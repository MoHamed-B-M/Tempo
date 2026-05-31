import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
            ),
          ),
        );
        Navigator.pop(sheetContext);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save alarm'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showAlarmEditorSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final sheetCs = Theme.of(ctx).colorScheme;
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
                        color: sheetCs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _editingAlarmId != null ? 'EDIT ALARM' : 'NEW ALARM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: sheetCs.onSurface,
                      letterSpacing: 0.5,
                    ),
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
                    color: sheetCs.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: TextField(
                        onChanged: (val) => _selectedLabel = val,
                        controller: TextEditingController(text: _selectedLabel)
                          ..selection = TextSelection.collapsed(
                              offset: _selectedLabel.length),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: sheetCs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add alarm label...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: sheetCs.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'REPEAT ON',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sheetCs.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
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
                                ? sheetCs.primary
                                : sheetCs.surfaceContainerHigh,
                            border: selected
                                ? null
                                : Border.all(
                                    color: sheetCs.outlineVariant),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            days[i][0],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? sheetCs.onPrimary
                                  : sheetCs.onSurface,
                              letterSpacing: 0.5,
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
                      color: sheetCs.surfaceContainerHigh,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.music_note_outlined,
                                    color: sheetCs.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'SOUND',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: sheetCs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _selectedSound.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: sheetCs.primary,
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sheetCs.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _saveAlarm(ctx),
                            child: Text(
                              'SAVE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
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
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: cs.surface,
              foregroundColor: cs.onSurface,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                title: Padding(
                  padding:
                      const EdgeInsets.only(left: 24, bottom: 16, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Alarms',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getAlarmStatus(alarms),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (alarms.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(cs),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildAlarmItem(alarms[index], cs),
                  childCount: alarms.length,
                ),
              ),
          ],
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: _createNewAlarm,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
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

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.alarm_add_rounded,
              color: cs.primary.withValues(alpha: 0.6),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NO ALARMS YET',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first alarm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmItem(AlarmModel alarm, ColorScheme cs) {
    final timeStr =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final repeatText = alarm.isRepeating
        ? alarm.repeatDays.map((d) => days[d - 1]).join(' ')
        : 'Once';

    return TweenAnimationBuilder<double>(
      key: ValueKey('anim_${alarm.id}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: ValueKey(alarm.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<AlarmService>().removeAlarm(alarm.id),
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: cs.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(Icons.delete_outline_rounded, color: cs.error),
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: alarm.enabled ? cs.primaryContainer : cs.surfaceContainerHigh,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _editAlarm(alarm),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: alarm.enabled
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (alarm.enabled)
                              Icon(
                                Icons.notifications_active_rounded,
                                color: cs.onPrimaryContainer
                                    .withValues(alpha: 0.7),
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: alarm.enabled
                                      ? cs.onPrimaryContainer
                                          .withValues(alpha: 0.8)
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                            Text(
                              repeatText.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: alarm.enabled
                                    ? cs.onPrimaryContainer
                                        .withValues(alpha: 0.8)
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: alarm.enabled,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      context.read<AlarmService>().toggleAlarm(alarm.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
