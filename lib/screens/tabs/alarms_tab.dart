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
  final Set<String> _expandedIds = {};

  bool _isExpanded(int index, List<AlarmModel> alarms) {
    if (index >= alarms.length) return false;
    return _expandedIds.contains(alarms[index].id);
  }

  void _toggleExpand(int index, List<AlarmModel> alarms) {
    HapticFeedback.mediumImpact();
    final id = alarms[index].id;
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.clear();
        _expandedIds.add(id);
      }
    });
  }

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
              SliverM3EDismissibleCardList(
                itemCount: alarms.length,
                itemBuilder: (context, index) =>
                    _buildAlarmCard(alarms, index, cs),
                onDismiss: (index, direction) async {
                  ref.read(alarmListProvider.notifier).removeAlarm(alarms[index].id);
                  return true;
                },
                style: M3EDismissibleCardStyle(
                  outerRadius: 20,
                  innerRadius: 6,
                  gap: 0,
                  color: cs.surfaceContainerHigh,
                  border: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: EdgeInsets.zero,
                  neighbourPull: 8,
                  neighbourReach: 3,
                  neighbourMotion:
                      const M3EMotion.custom(stiffness: 800, damping: 0.7),
                  snapBackMotion:
                      const M3EMotion.custom(stiffness: 380, damping: 0.6),
                  flyMotion:
                      const M3EMotion.custom(stiffness: 400, damping: 0.8),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 26),
                  ),
                  backgroundBorderRadius: 20,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
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
                child: const Icon(Icons.add, color: Colors.white, size: 28),
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

  Widget _buildAlarmCard(List<AlarmModel> alarms, int index, ColorScheme cs) {
    final alarm = alarms[index];
    final timeStr =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String subtitle;
    if (alarm.label.isNotEmpty && alarm.isRepeating) {
      final d = alarm.repeatDays.map((d) => days[d - 1]).join(' ');
      subtitle = '${alarm.label}  •  $d';
    } else if (alarm.label.isNotEmpty) {
      subtitle = alarm.label;
    } else if (alarm.isRepeating) {
      subtitle = alarm.repeatDays.map((d) => days[d - 1]).join(' ');
    } else {
      subtitle = 'Once';
    }

    final enabled = alarm.enabled;
    final textColor =
        enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4);
    final subtitleColor = enabled
        ? cs.onSurfaceVariant
        : cs.onSurfaceVariant.withValues(alpha: 0.4);

    return buildM3EExpandableItem(
      index: index,
      totalCount: alarms.length,
      isExpanded: _isExpanded(index, alarms),
      decoration: M3EExpandableStyle(
        outerRadius: 20,
        innerRadius: 6,
        gap: 0,
        expandedRadius: 20,
        color: Colors.transparent,
        border: BorderSide.none,
        elevation: 0,
        margin: EdgeInsets.zero,
        headerPadding: EdgeInsets.zero,
        bodyPadding: EdgeInsets.zero,
        useInkWell: true,
        tapHeaderToToggle: true,
        tapBodyToExpand: false,
        tapBodyToCollapse: false,
        expandIcon: null,
        collapseIcon: null,
      ),
      expandMotion: M3EMotion.expressiveSpatialFast,
      collapseMotion: M3EMotion.standardSpatialFast,
      onToggle: () => _toggleExpand(index, alarms),
      headerBuilder: (context, idx, progress) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (val) {
                  HapticFeedback.mediumImpact();
                  ref.read(alarmListProvider.notifier).toggleAlarm(alarm.id);
                },
              ),
            ],
          ),
        );
      },
      bodyBuilder: (context, idx, progress) {
        return ClipRect(
          child: Align(
            heightFactor: progress,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1, indent: 20, endIndent: 20),
                _ExpandedAlarmPanel(
                  alarm: alarm,
                  cs: cs,
                  onDelete: () =>
                      ref.read(alarmListProvider.notifier).removeAlarm(alarm.id),
                  onUpdateLabel: (label) =>
                      ref.read(alarmListProvider.notifier).updateAlarmLabel(alarm.id, label),
                  onUpdateRepeatDays: (days) =>
                      ref.read(alarmListProvider.notifier).updateAlarmRepeatDays(alarm.id, days),
                  onUpdateSound: (sound) =>
                      ref.read(alarmListProvider.notifier).updateAlarmSound(alarm.id, sound),
                ),
              ],
            ),
          ),
        );
      },
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
