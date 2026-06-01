import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../core/hive_helper.dart';

final worldClockProvider =
    NotifierProvider<WorldClockNotifier, List<String>>(
  WorldClockNotifier.new,
);

class WorldClockNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final data = HiveHelper.worldClock.get('favorites') as String?;
    if (data != null) {
      return (jsonDecode(data) as List).cast<String>();
    }
    return ['America/New_York', 'Europe/London', 'Asia/Tokyo'];
  }

  Future<void> save() async {
    await HiveHelper.worldClock.put('favorites', jsonEncode(state));
  }

  Future<void> add(String tzId) async {
    state = [...state, tzId];
    await save();
  }

  Future<void> removeAt(int index) async {
    state = [...state.take(index), ...state.skip(index + 1)];
    await save();
  }
}

class WorldClockTab extends ConsumerStatefulWidget {
  const WorldClockTab({super.key});

  @override
  ConsumerState<WorldClockTab> createState() => _WorldClockTabState();
}

class _WorldClockTabState extends ConsumerState<WorldClockTab> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTimeInZone(String tzId) {
    try {
      final location = tz.getLocation(tzId);
      final t = tz.TZDateTime.from(_currentTime, location);
      return DateFormat('h:mm').format(t);
    } catch (_) {
      return '--:--';
    }
  }

  String _formatAmPmInZone(String tzId) {
    try {
      final location = tz.getLocation(tzId);
      final t = tz.TZDateTime.from(_currentTime, location);
      return DateFormat('a').format(t).toLowerCase();
    } catch (_) {
      return '';
    }
  }

  String _utcOffsetString(String tzId) {
    try {
      final location = tz.getLocation(tzId);
      final t = tz.TZDateTime.from(_currentTime, location);
      final offset = t.timeZoneOffset;
      final hours = offset.inHours;
      final mins = offset.inMinutes.remainder(60).abs();
      final sign = hours >= 0 ? '+' : '';
      return 'GMT $sign${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _relativeDiff(String tzId) {
    try {
      final location = tz.getLocation(tzId);
      final t = tz.TZDateTime.from(_currentTime, location);
      final diff = t.timeZoneOffset - _currentTime.timeZoneOffset;
      final hours = diff.inHours;
      if (hours == 0) return 'Same time';
      return '${hours > 0 ? '+' : ''}$hours{h}';
    } catch (_) {
      return '';
    }
  }

  String _cityName(String tzId) {
    final parts = tzId.split('/');
    return parts.last.replaceAll('_', ' ');
  }

  void _showAddCitySheet() {
    HapticFeedback.mediumImpact();
    final cs = Theme.of(context).colorScheme;
    final favorites = ref.read(worldClockProvider);
    final allTimezones = tz.timeZoneDatabase.locations.keys
        .where((id) =>
            !id.startsWith('Etc/') &&
            !id.startsWith('SystemV/') &&
            !id.startsWith('US/') &&
            !id.contains('/'))
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = allTimezones.where((id) {
              if (favorites.contains(id)) return false;
              if (query.isEmpty) return true;
              final lower = query.toLowerCase();
              return id.toLowerCase().contains(lower) ||
                  _cityName(id).toLowerCase().contains(lower);
            }).toList();

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
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ADD LOCATION',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => setModalState(() => query = val),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search timezone or city...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHigh,
                      prefixIcon:
                          Icon(Icons.search, color: cs.onSurfaceVariant),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                query.isEmpty
                                    ? 'Type to search timezones'
                                    : 'No timezones found',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final tzId = filtered[index];
                              final name = _cityName(tzId);
                              final offset = _utcOffsetString(tzId);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.public,
                                  color: cs.primary,
                                  size: 20,
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  offset,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                onTap: () {
                                  ref
                                      .read(worldClockProvider.notifier)
                                      .add(tzId);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final favorites = ref.watch(worldClockProvider);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World Clock',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            DateFormat('h:mm').format(_currentTime),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 56,
                              fontWeight: FontWeight.w200,
                              color: cs.onSurface,
                              letterSpacing: -2,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            DateFormat('a').format(_currentTime).toLowerCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('EEEE, d MMM')
                            .format(_currentTime)
                            .toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'LOCATIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: favorites.length,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemBuilder: (ctx, index) {
                    final tzId = favorites[index];
                    final name = _cityName(tzId);
                    final timeStr = _formatTimeInZone(tzId);
                    final amPmStr = _formatAmPmInZone(tzId);
                    final offset = _utcOffsetString(tzId);
                    final diff = _relativeDiff(tzId);

                    return Dismissible(
                      key: ValueKey(tzId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: Icon(
                          Icons.delete_outline,
                          color: cs.error,
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(worldClockProvider.notifier).removeAt(index);
                      },
                      child: RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$offset • $diff',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      amPmStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: GestureDetector(
            onTap: _showAddCitySheet,
            child: M3EContainer.gem(
              color: cs.primary,
              width: 56,
              height: 56,
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
      ],
    );
  }
}
