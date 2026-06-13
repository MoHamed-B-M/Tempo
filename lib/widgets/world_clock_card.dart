import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/timezone_service.dart';

class WorldClockCard extends StatefulWidget {
  final String tzId;
  final VoidCallback? onDismissed;

  const WorldClockCard({super.key, required this.tzId, this.onDismissed});

  @override
  State<WorldClockCard> createState() => _WorldClockCardState();
}

class _WorldClockCardState extends State<WorldClockCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  late final String _name;
  tz.Location? _location;

  @override
  void initState() {
    super.initState();
    final tz = TimezoneService.instance;
    _name = tz.cityName(widget.tzId);
    _location = tz.location(widget.tzId);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeStr {
    if (_location == null) return '--:--';
    final t = tz.TZDateTime.from(_now, _location!);
    return DateFormat('h:mm').format(t);
  }

  String get _amPm {
    if (_location == null) return '';
    final t = tz.TZDateTime.from(_now, _location!);
    return DateFormat('a').format(t).toLowerCase();
  }

  String get _offset {
    if (_location == null) return '';
    final t = tz.TZDateTime.from(_now, _location!);
    final offset = t.timeZoneOffset;
    final hours = offset.inHours;
    final mins = offset.inMinutes.remainder(60).abs();
    final sign = hours >= 0 ? '+' : '';
    return 'GMT$sign${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  String get _diff {
    if (_location == null) return '';
    final t = tz.TZDateTime.from(_now, _location!);
    final diff = t.timeZoneOffset - _now.timeZoneOffset;
    final h = diff.inHours;
    if (h == 0) return 'Same time';
    return '${h > 0 ? '+' : ''}$h{h}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('$_offset • $_diff',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(_timeStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: cs.onSurface, letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(_amPm,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
