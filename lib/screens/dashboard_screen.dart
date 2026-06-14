import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../providers/alarm_provider.dart';
import '../providers/timer_provider.dart';
import 'settings_page.dart';
import 'tabs/world_clock_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedChip = 'Wake Up';
  final List<String> _chips = ['Wake Up', 'Relax', 'Workout', 'Bloggers'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(cs: cs),
            const SizedBox(height: 20),
            _CategoryChips(
              chips: _chips,
              selected: _selectedChip,
              onSelected: (c) => setState(() => _selectedChip = c),
              cs: cs,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(flex: 7, child: _AlarmCard()),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: _ClockCard(cs: cs),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _WorldClockCard(),
                    const SizedBox(height: 12),
                    const IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _TimerCard()),
                          SizedBox(width: 12),
                          Expanded(child: _StopwatchCard()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final ColorScheme cs;
  const _HeaderRow({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tempo',
          style: GoogleFonts.nunito(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: cs.onSurface,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.settings_outlined,
              size: 22,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> chips;
  final String selected;
  final ValueChanged<String> onSelected;
  final ColorScheme cs;

  const _CategoryChips({
    required this.chips,
    required this.selected,
    required this.onSelected,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final isActive = chip == selected;
          return GestureDetector(
            onTap: () => onSelected(chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isActive
                    ? cs.primary
                    : cs.surfaceContainerHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : cs.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  chip,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final alarms = ref.watch(alarmListProvider);
    final nextAlarm = alarms.where((a) => a.enabled).isNotEmpty
        ? alarms.firstWhere((a) => a.enabled)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Next Alarm',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              nextAlarm != null
                  ? '${nextAlarm.hour.toString().padLeft(2, '0')}:${nextAlarm.minute.toString().padLeft(2, '0')}'
                  : '--:--',
              style: GoogleFonts.nunito(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: cs.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nextAlarm?.label.isNotEmpty == true
                  ? nextAlarm!.label
                  : nextAlarm != null
                      ? (nextAlarm.isRepeating
                          ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                              .where((d) => nextAlarm
                                  .repeatDays
                                  .contains(['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                                      .indexOf(d)))
                              .join(', ')
                          : 'One-time')
                      : 'No alarms set',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['Wake Up', 'Relax']
                  .map((label) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final ColorScheme cs;
  const _ClockCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm').format(now);
    final periodStr = DateFormat('a').format(now);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: cs.secondaryContainer.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: const Size.fromRadius(60),
                painter: _GeometricClockPainter(
                  primaryColor: cs.secondary,
                  containerColor: cs.secondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: cs.onSurface,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 2),
                  child: Text(
                    periodStr,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              DateFormat('EEEE, d MMM').format(now),
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldClockCard extends ConsumerStatefulWidget {
  const _WorldClockCard();

  @override
  ConsumerState<_WorldClockCard> createState() => _WorldClockCardState();
}

class _WorldClockCardState extends ConsumerState<_WorldClockCard> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final favorites = ref.watch(worldClockProvider);
    final location = favorites.isNotEmpty ? favorites.first : 'UTC';
    final now = _timeIn(location);
    final timeStr = DateFormat('h:mm').format(now);
    final periodStr = DateFormat('a').format(now);
    final offsetStr = _offsetString(location);
    final cityName = location.split('/').last.replaceAll('_', ' ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: cs.tertiaryContainer.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: SizedBox(
                width: 120,
                height: 90,
                child: CustomPaint(
                  painter: _WorldMapPainter(
                    primaryColor: cs.tertiary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.public, size: 14, color: cs.tertiary),
                          const SizedBox(width: 6),
                          Text(
                            'World Clock',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: cs.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cityName,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GMT$offsetStr',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.nunito(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      periodStr,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _timeIn(String location) {
    try {
      final loc = tz.getLocation(location);
      return tz.TZDateTime.now(loc);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _offsetString(String location) {
    try {
      final loc = tz.getLocation(location);
      final now = tz.TZDateTime.now(loc);
      final offset = now.timeZoneOffset;
      final hours = offset.inHours;
      final mins = offset.inMinutes.remainder(60).abs();
      final sign = hours >= 0 ? '+' : '';
      return '$sign$hours${mins > 0 ? ':${mins.toString().padLeft(2, '0')}' : ''}';
    } catch (_) {
      return '+0';
    }
  }
}

class _TimerCard extends StatefulWidget {
  const _TimerCard();

  @override
  State<_TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<_TimerCard>
    with SingleTickerProviderStateMixin {
  int _remainingSeconds = 600;
  final int _totalSeconds = 600;
  bool _isRunning = false;
  Timer? _timer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 600),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _progressController.stop();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          HapticFeedback.heavyImpact();
        }
      });
      _progressController.forward();
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _timer?.cancel();
    _progressController.reset();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 0.0;
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: cs.tertiaryContainer.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(72, 72),
                    painter: _CircularProgressPainter(
                      progress: progress,
                      progressColor: cs.tertiary,
                      trackColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleTimer,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey(_isRunning),
                        size: 24,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _resetTimer,
              child: Text(
                '$minutes:$seconds',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _isRunning ? 'Running' : _remainingSeconds < _totalSeconds ? 'Paused' : 'Timer',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopwatchCard extends ConsumerWidget {
  const _StopwatchCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final swState = ref.watch(stopwatchProvider);
    final swNotifier = ref.read(stopwatchProvider.notifier);

    final minutes = (swState.elapsedMs ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((swState.elapsedMs ~/ 1000) % 60).toString().padLeft(2, '0');

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              swState.isRunning ? 'LIVE' : 'STOPPED',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: swState.isRunning ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$minutes:$seconds',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MediaButton(
                  icon: Icons.skip_previous_rounded,
                  onTap: swNotifier.reset,
                  cs: cs,
                ),
                const SizedBox(width: 12),
                M3EContainer.circle(
                  color: swState.isRunning ? cs.primary : cs.primary.withValues(alpha: 0.8),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (swState.isRunning) {
                        swNotifier.stop();
                      } else {
                        swNotifier.start();
                      }
                    },
                    child: Icon(
                      swState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 20,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _MediaButton(
                  icon: Icons.skip_next_rounded,
                  onTap: swNotifier.reset,
                  cs: cs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _MediaButton({
    required this.icon,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _GeometricClockPainter extends CustomPainter {
  final Color primaryColor;
  final Color containerColor;

  _GeometricClockPainter({
    required this.primaryColor,
    required this.containerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final bgPaint = Paint()
      ..color = containerColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final ringPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.85, ringPaint);
    canvas.drawCircle(center, radius * 0.55, ringPaint);

    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final dotRadius = i % 3 == 0 ? 3.5 : 2.0;
      final dotRadius2 = i % 3 == 0 ? radius * 0.78 : radius * 0.72;
      canvas.drawCircle(
        Offset(
          center.dx + dotRadius2 * math.cos(angle),
          center.dy + dotRadius2 * math.sin(angle),
        ),
        dotRadius,
        dotPaint,
      );
    }

    final now = DateTime.now();
    final hourAngle = ((now.hour % 12) * 30 + now.minute * 0.5 - 90) * math.pi / 180;
    final minuteAngle = (now.minute * 6 + now.second * 0.1 - 90) * math.pi / 180;

    final hourHandPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(hourAngle);
    final hourPath = Path()
      ..moveTo(-3, 6)
      ..lineTo(0, -radius * 0.45)
      ..lineTo(3, 6)
      ..close();
    canvas.drawPath(hourPath, hourHandPaint);
    canvas.restore();

    final minuteHandPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(minuteAngle);
    final minutePath = Path()
      ..moveTo(-2, 8)
      ..lineTo(0, -radius * 0.65)
      ..lineTo(2, 8)
      ..close();
    canvas.drawPath(minutePath, minuteHandPaint);
    canvas.restore();

    canvas.drawCircle(
      center,
      3.5,
      Paint()..color = primaryColor..style = PaintingStyle.fill,
    );

    final accentPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.3, center.dy - radius * 0.2),
      radius * 0.25,
      accentPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy + radius * 0.35),
      radius * 0.15,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GeometricClockPainter old) => true;
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.progress != progress;
}

class _WorldMapPainter extends CustomPainter {
  final Color primaryColor;

  _WorldMapPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final blobs = [
      Offset(size.width * 0.2, size.height * 0.35),
      Offset(size.width * 0.25, size.height * 0.45),
      Offset(size.width * 0.22, size.height * 0.55),
      Offset(size.width * 0.18, size.height * 0.42),
      Offset(size.width * 0.55, size.height * 0.25),
      Offset(size.width * 0.62, size.height * 0.35),
      Offset(size.width * 0.58, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.3),
      Offset(size.width * 0.68, size.height * 0.4),
      Offset(size.width * 0.72, size.height * 0.5),
      Offset(size.width * 0.78, size.height * 0.35),
      Offset(size.width * 0.7, size.height * 0.55),
      Offset(size.width * 0.82, size.height * 0.45),
      Offset(size.width * 0.35, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.45, size.height * 0.65),
      Offset(size.width * 0.38, size.height * 0.55),
      Offset(size.width * 0.48, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.45, size.height * 0.38),
    ];

    final rng = math.Random(42);
    for (final center in blobs) {
      final path = Path();
      const points = 10;
      final baseRadius = 8.0 + rng.nextDouble() * 12;
      for (var i = 0; i < points; i++) {
        final angle = (i / points) * 2 * math.pi;
        final variation = 0.7 + rng.nextDouble() * 0.6;
        final r = baseRadius * variation;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter old) => false;
}
