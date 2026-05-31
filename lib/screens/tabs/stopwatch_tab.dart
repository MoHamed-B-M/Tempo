import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> {
  Timer? _timer;
  int _milliseconds = 0;
  bool _isRunning = false;

  // Task details customizable to match mockup Screen 2
  String _taskTitle = 'Wash and dry';
  String _taskStatus = 'Currently drying';
  double _customProgressPercent = 65.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleStopwatch() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
      } else {
        _isRunning = true;
        _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
          setState(() {
            _milliseconds += 10;
          });
        });
      }
    });
  }

  void _resetStopwatch() {
    HapticFeedback.mediumImpact();
    setState(() {
      _timer?.cancel();
      _isRunning = false;
      _milliseconds = 0;
    });
  }

  String _formatElapsedTime() {
    final seconds = (_milliseconds ~/ 1000) % 60;
    final minutes = (_milliseconds ~/ 60000) % 60;
    final hours = _milliseconds ~/ 3600000;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
  }

  void _showEditTaskDialog() {
    final titleController = TextEditingController(text: _taskTitle);
    final statusController = TextEditingController(text: _taskStatus);
    final progressController = TextEditingController(text: _customProgressPercent.round().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCardOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'EDIT TASK DETAILS',
          style: AppTextStyles.buttonLabel(context).copyWith(fontSize: 14),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: 'TASK NAME',
                labelStyle: AppTextStyles.subheading(context),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderOf(context))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: 'TASK STATUS',
                labelStyle: AppTextStyles.subheading(context),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderOf(context))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: progressController,
              style: AppTextStyles.body(context),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PROGRESS PERCENT (%)',
                labelStyle: AppTextStyles.subheading(context),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderOf(context))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTextStyles.buttonLabel(context).copyWith(color: AppColors.secondaryTextOf(context))),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _taskTitle = titleController.text;
                _taskStatus = statusController.text;
                _customProgressPercent = double.tryParse(progressController.text) ?? 65.0;
              });
              Navigator.pop(ctx);
            },
            child: Text('SAVE', style: AppTextStyles.buttonLabel(context).copyWith(color: AppColors.accentOf(context))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate a dynamic progress ratio for the painter
    // If running, we loop around, otherwise we use the user's custom progress percent (e.g. 65% = 0.65)
    double progressRatio = _customProgressPercent / 100.0;
    if (_isRunning) {
      // Loop the progress circle every 60 seconds
      progressRatio = (_milliseconds % 60000) / 60000.0;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'StopWatch',
            style: AppTextStyles.heading(context),
          ),
          const Spacer(),
          // Wavy Progress Circle in Center
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceCardOf(context).withValues(alpha: 0.3),
                  ),
                ),
                CustomPaint(
                  size: const Size(260, 260),
                  painter: WavyCirclePainter(
                    progress: progressRatio,
                    baseColor: AppColors.surfaceCardOf(context),
                    waveColor: AppColors.accentOf(context),
                  ),
                ),
                // Inner Text Display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatElapsedTime(),
                      style: AppTextStyles.alarmTime(context).copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRunning ? 'ELAPSED' : 'REMAINING',
                      style: AppTextStyles.subheading(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRunning ? 'Ticking...' : '${(_customProgressPercent).round()}% complete',
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 13,
                        color: AppColors.secondaryTextOf(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Editable Task Description Area (Screen 2 style)
          Center(
            child: GestureDetector(
              onTap: _showEditTaskDialog,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    _taskTitle,
                    style: AppTextStyles.alarmTime(context).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _taskStatus,
                    style: AppTextStyles.subheading(context).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_customProgressPercent.round()}% work done already  (Tap to edit)',
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 12,
                      color: AppColors.secondaryTextOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Controller Buttons (Grey Play/Pause, Orange Stop/Reset)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play / Pause Button
              GestureDetector(
                onTap: _toggleStopwatch,
                child: Container(
                  width: 72,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderOf(context), width: 1),
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: AppColors.primaryTextOf(context),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Stop / Reset Button
              GestureDetector(
                onTap: _resetStopwatch,
                child: Container(
                  width: 72,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accentOf(context),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentOf(context).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// Highly precise CustomPainter for hand-drawn style wavy progress track
class WavyCirclePainter extends CustomPainter {
  final double progress; // Range: 0.0 to 1.0
  final Color baseColor;
  final Color waveColor;

  WavyCirclePainter({
    required this.progress,
    required this.baseColor,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 12;

    // 1. Draw solid thin base circle track
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, basePaint);

    if (progress <= 0) return;

    // 2. Draw progress orange wavy track
    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double frequency = 32.0;  // Number of wavy peaks around circle
    const double amplitude = 3.5;   // Scale of the wave ripples

    final int steps = (360 * progress).round();
    for (int i = 0; i <= steps; i++) {
      // Convert degrees to radians, starting at top (-pi/2)
      final double angle = (i * (math.pi / 180.0)) - (math.pi / 2.0);
      
      // Perturb the radius with a sine wave based on the angle
      final double currentRadius = radius + amplitude * math.sin(angle * frequency);
      
      final double x = center.dx + currentRadius * math.cos(angle);
      final double y = center.dy + currentRadius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant WavyCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.waveColor != waveColor;
  }
}
