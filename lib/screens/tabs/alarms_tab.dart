import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../../widgets/time_picker_wheel.dart';
import '../../widgets/expressive_open_container.dart';
import '../alarm_edit_page.dart';

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

class _AlarmGridCard extends StatefulWidget {
  final AlarmModel alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlarmGridCard({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_AlarmGridCard> createState() => _AlarmGridCardState();
}

class _AlarmGridCardState extends State<_AlarmGridCard> {
  late AlarmEditPage _editPage;

  @override
  void initState() {
    super.initState();
    _editPage = AlarmEditPage(alarm: widget.alarm);
  }

  @override
  void didUpdateWidget(_AlarmGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alarm.id != widget.alarm.id) {
      _editPage = AlarmEditPage(alarm: widget.alarm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.alarm.enabled;
    final cardColor = cs.primaryContainer;
    final textColor =
        enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4);
    final mutedColor =
        cs.onSurfaceVariant.withValues(alpha: enabled ? 0.9 : 0.4);
    final timeStr =
        '${widget.alarm.hour.toString().padLeft(2, '0')}:${widget.alarm.minute.toString().padLeft(2, '0')}';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String subtitle;
    if (widget.alarm.label.isNotEmpty) {
      subtitle = widget.alarm.label;
    } else if (widget.alarm.isRepeating) {
      subtitle = widget.alarm.repeatDays.map((d) => days[d - 1]).join(' ');
    } else {
      subtitle = 'Once';
    }

    return Dismissible(
      key: ValueKey(widget.alarm.id),
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
      onDismissed: (_) => widget.onDelete(),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.hardEdge,
          child: ExpressiveOpenContainer(
            closedColor: enabled ? cardColor : cardColor.withValues(alpha: 0.45),
            openColor: cs.surface,
            openChild: _editPage,
            closedChild: Padding(
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
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            switchTheme: SwitchThemeData(
                              thumbColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return cs.onPrimary;
                                }
                                return cs.onSurfaceVariant;
                              }),
                              trackColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return cs.primary;
                                }
                                return cs.surfaceContainerHighest;
                              }),
                            ),
                          ),
                          child: Switch(
                            value: enabled,
                            onChanged: (_) => widget.onToggle(),
                          ),
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
      ),
    );
  }
}
