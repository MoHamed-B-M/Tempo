import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../../widgets/time_picker_wheel.dart';

class AlarmsTab extends ConsumerStatefulWidget {
  const AlarmsTab({super.key});

  @override
  ConsumerState<AlarmsTab> createState() => _AlarmsTabState();
}

class _AlarmsTabState extends ConsumerState<AlarmsTab> {
  void _showCreateSheet() {
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
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            var hour = TimeOfDay.now().hour;
            var minute = (TimeOfDay.now().minute + 1) % 60;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom +
                    24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'SET ALARM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: sheetCs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TimePickerWheel(
                    initialHour: hour,
                    initialMinute: minute,
                    onChanged: (t) {
                      setSheetState(() {
                        hour = t.hour;
                        minute = t.minute;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: M3EFilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(alarmListProvider.notifier).addAlarm(
                              hour: hour,
                              minute: minute,
                            );
                        Navigator.pop(ctx);
                      },
                      size: M3EButtonSize.md,
                      child: const Text('ADD ALARM'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSheet(AlarmModel alarm) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _ExpandedAlarmPanel(
          alarm: alarm,
          cs: Theme.of(ctx).colorScheme,
          onDelete: () {
            ref.read(alarmListProvider.notifier).removeAlarm(alarm.id);
            Navigator.pop(ctx);
          },
          onUpdateLabel: (label) =>
              ref.read(alarmListProvider.notifier).updateAlarmLabel(alarm.id, label),
          onUpdateRepeatDays: (days) =>
              ref.read(alarmListProvider.notifier).updateAlarmRepeatDays(alarm.id, days),
          onUpdateSound: (sound) =>
              ref.read(alarmListProvider.notifier).updateAlarmSound(alarm.id, sound),
        ),
      ),
    );
  }

  String _getStatus(List<AlarmModel> alarms) {
    final active = alarms.where((a) => a.enabled).toList();
    if (active.isEmpty) return 'No alarms';
    final now = TimeOfDay.now();
    final cur = now.hour * 60 + now.minute;
    int bestMin = 1440;
    AlarmModel? best;
    for (final a in active) {
      final alarmMin = a.hour * 60 + a.minute;
      final diff = alarmMin > cur ? alarmMin - cur : alarmMin - cur + 1440;
      if (diff < bestMin) {
        bestMin = diff;
        best = a;
      }
    }
    if (best == null) return 'No upcoming alarms';
    final h = bestMin ~/ 60;
    final m = bestMin % 60;
    final parts = <String>[];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}min');
    return 'Next alarm in ${parts.join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmListProvider);
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: Colors.transparent,
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
                        'Alarm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatus(alarms),
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _AlarmGridCard(
                      alarm: alarms[index],
                      onToggle: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(alarmListProvider.notifier)
                            .toggleAlarm(alarms[index].id);
                      },
                      onTap: () => _showEditSheet(alarms[index]),
                      onDelete: () => ref
                          .read(alarmListProvider.notifier)
                          .removeAlarm(alarms[index].id),
                    ),
                    childCount: alarms.length,
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 96,
          child: Center(
            child: GestureDetector(
              onTap: _showCreateSheet,
              child: M3EContainer.gem(
                color: cs.primary,
                width: 64,
                height: 64,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                child: Icon(Icons.add, color: cs.onPrimary, size: 28),
              ),
            ),
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
          M3EContainer.circle(
            color: cs.primary.withValues(alpha: 0.1),
            width: 80,
            height: 80,
            child: Icon(
              Icons.alarm_add_rounded,
              color: cs.primary.withValues(alpha: 0.6),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No alarms',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
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
}

class _AlarmGridCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color? cardBackgroundColor;

  const _AlarmGridCard({
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    this.cardBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = alarm.enabled;
    final cardColor = cardBackgroundColor ?? cs.primaryContainer;
    final textColor =
        enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4);
    final mutedColor =
        cs.onSurfaceVariant.withValues(alpha: enabled ? 0.9 : 0.4);
    final timeStr =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String subtitle;
    if (alarm.label.isNotEmpty) {
      subtitle = alarm.label;
    } else if (alarm.isRepeating) {
      subtitle = alarm.repeatDays.map((d) => days[d - 1]).join(' ');
    } else {
      subtitle = 'Once';
    }

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            color: enabled ? cardColor : cardColor.withValues(alpha: 0.45),
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: enabled,
                        onChanged: (_) => onToggle(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedAlarmPanel extends StatefulWidget {
  final AlarmModel alarm;
  final ColorScheme cs;
  final VoidCallback onDelete;
  final ValueChanged<String> onUpdateLabel;
  final ValueChanged<List<int>> onUpdateRepeatDays;
  final ValueChanged<String> onUpdateSound;

  const _ExpandedAlarmPanel({
    required this.alarm,
    required this.cs,
    required this.onDelete,
    required this.onUpdateLabel,
    required this.onUpdateRepeatDays,
    required this.onUpdateSound,
  });

  @override
  State<_ExpandedAlarmPanel> createState() => _ExpandedAlarmPanelState();
}

class _ExpandedAlarmPanelState extends State<_ExpandedAlarmPanel> {
  late String _label;
  late List<int> _repeatDays;
  late String _sound;
  late final M3EDropdownController<String> _soundController;
  Timer? _labelDebounce;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _sounds = [
    ('default', 'Default'),
    ('radar', 'Radar'),
    ('crystal', 'Crystal'),
    ('pulse', 'Pulse'),
    ('echo', 'Echo'),
    ('ripple', 'Ripple'),
  ];

  @override
  void initState() {
    super.initState();
    _label = widget.alarm.label;
    _repeatDays = List.from(widget.alarm.repeatDays);
    _sound = widget.alarm.sound;
    _soundController = M3EDropdownController<String>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final match = _sounds.firstWhere((s) => s.$1 == _sound,
          orElse: () => _sounds.first);
      _soundController.toggleOnly(
          M3EDropdownItem<String>(label: match.$2, value: match.$1));
    });
  }

  @override
  void dispose() {
    _labelDebounce?.cancel();
    _soundController.dispose();
    super.dispose();
  }

  void _saveLabel(String val) {
    _label = val;
    _labelDebounce?.cancel();
    _labelDebounce = Timer(const Duration(milliseconds: 400), () {
      widget.onUpdateLabel(_label);
    });
  }

  void _saveRepeatDays() {
    widget.onUpdateRepeatDays(_repeatDays);
  }

  void _saveSound(String value) {
    _sound = value;
    widget.onUpdateSound(value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: TextEditingController(text: _label)
              ..selection = TextSelection.collapsed(offset: _label.length),
            onChanged: _saveLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Alarm label',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
              prefixIcon: Icon(Icons.label_outline,
                  color: cs.onSurfaceVariant, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'REPEAT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayNum = i + 1;
              final selected = _repeatDays.contains(dayNum);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _repeatDays.remove(dayNum);
                    } else {
                      _repeatDays.add(dayNum);
                    }
                  });
                  _saveRepeatDays();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? cs.primary : cs.surfaceContainerHigh,
                    border:
                        selected ? null : Border.all(color: cs.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _dayNames[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          M3EDropdownMenu<String>(
            controller: _soundController,
            singleSelect: true,
            items: _sounds
                .map((s) => M3EDropdownItem(label: s.$2, value: s.$1))
                .toList(),
            onSelectionChanged: (items) {
              if (items.isNotEmpty && items.first.value != _sound) {
                setState(() {
                  _sound = items.first.value;
                });
                _saveSound(_sound);
              }
            },
            fieldStyle: M3EDropdownFieldStyle(
              hintText: 'Sound',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: cs.surfaceContainerHigh,
              border: BorderSide(color: cs.outlineVariant),
            ),
            dropdownStyle: const M3EDropdownStyle(
              containerRadius: 12,
              maxHeight: 300,
            ),
            itemStyle: M3EDropdownItemStyle(
              outerRadius: 8,
              innerRadius: 4,
            ),
            haptic: M3EHapticFeedback.light,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: M3EOutlinedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onDelete();
              },
              icon:
                  Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
              label: Text(
                'Delete alarm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
              size: M3EButtonSize.md,
              decoration: M3EButtonDecoration(
                side: WidgetStatePropertyAll(
                    BorderSide(color: cs.error.withValues(alpha: 0.3))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
