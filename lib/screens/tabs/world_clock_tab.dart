import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:intl/intl.dart';
import '../../core/hive_helper.dart';
import '../../services/timezone_service.dart';
import '../../widgets/searchable_timezone_picker.dart';
import '../../widgets/world_clock_card.dart';

final worldClockProvider =
    NotifierProvider<WorldClockNotifier, List<String>>(
  WorldClockNotifier.new,
);

class WorldClockNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    TimezoneService.instance.initialize();
    final data = HiveHelper.worldClock.get('favorites') as String?;
    if (data != null) {
      return (jsonDecode(data) as List).cast<String>();
    }
    return ['America/New_York', 'Europe/London', 'Asia/Tokyo'];
  }

  Future<void> _save() async {
    await HiveHelper.worldClock.put('favorites', jsonEncode(state));
  }

  Future<void> add(String tzId) async {
    state = [...state, tzId];
    await _save();
  }

  Future<void> removeAt(int index) async {
    state = [...state.take(index), ...state.skip(index + 1)];
    await _save();
  }
}

class WorldClockTab extends ConsumerStatefulWidget {
  const WorldClockTab({super.key});

  @override
  ConsumerState<WorldClockTab> createState() => _WorldClockTabState();
}

class _WorldClockTabState extends ConsumerState<WorldClockTab> {
  Timer? _localTimer;
  DateTime _localNow = DateTime.now();

  @override
  void initState() {
    super.initState();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _localNow = DateTime.now());
    });
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  Future<void> _addLocation() async {
    final favorites = ref.read(worldClockProvider);
    final result = await showSearchableTimezonePicker(
      context,
      exclude: favorites.toSet(),
    );
    if (result != null && mounted) {
      ref.read(worldClockProvider.notifier).add(result);
    }
  }

  String _localTime() => DateFormat('h:mm').format(_localNow);
  String _localAmPm() => DateFormat('a').format(_localNow).toLowerCase();
  String _localDate() =>
      DateFormat('EEEE, d MMM').format(_localNow).toUpperCase();

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
              Text('World Clock',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32, fontWeight: FontWeight.w800,
                  color: cs.onSurface, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(_localTime(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 56, fontWeight: FontWeight.w200,
                            color: cs.onSurface, letterSpacing: -2, height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(_localAmPm(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20, fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_localDate(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant, letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('LOCATIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant, letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: favorites.length,
                  padding: const EdgeInsets.only(bottom: 140),
                  itemBuilder: (ctx, index) {
                    final tzId = favorites[index];
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
                        child: Icon(Icons.delete_outline, color: cs.error),
                      ),
                      onDismissed: (_) {
                        ref.read(worldClockProvider.notifier).removeAt(index);
                      },
                      child: WorldClockCard(tzId: tzId),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 96,
          child: GestureDetector(
            onTap: _addLocation,
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
              child: Icon(Icons.add, color: cs.onPrimary, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}
