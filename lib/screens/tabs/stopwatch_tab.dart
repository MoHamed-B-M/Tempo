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

class _StopwatchTabState extends State<StopwatchTab>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _milliseconds = 0;
  bool _isRunning = false;
  late AnimationController _progressAnim;

  List<int> _laps = [];

  String _taskTitle = 'Wash and dry';
  String _taskStatus = 'Currently drying';
  double _customProgressPercent = 65.0;

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      value: _customProgressPercent / 100.0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnim.dispose();
    super.dispose();
  }

  void _toggleStopwatch() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      _progressAnim.animateTo(
        _customProgressPercent / 100.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
        setState(() {
          _milliseconds += 10;
          _progressAnim.value = (_milliseconds % 60000) / 60000.0;
        });
      });
    }
  }

  void _resetStopwatch() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _milliseconds = 0;
      _laps = [];
    });
    _progressAnim.animateTo(
      _customProgressPercent / 100.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _recordLap() {
    HapticFeedback.selectionClick();
    setState(() {
      _laps.insert(0, _milliseconds);
    });
  }

  String _formatElapsedTime() {
    final minutes = (_milliseconds ~/ 60000) % 60;
    final seconds = (_milliseconds ~/ 1000) % 60;
    final hundredths = (_milliseconds ~/ 10) % 100;

    final hours = _milliseconds ~/ 3600000;
    if (hours > 0) {
      final mins = (_milliseconds ~/ 60000) % 60;
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
  }

  String _formatLapTime(int ms) {
    final minutes = (ms ~/ 60000) % 60;
    final seconds = (ms ~/ 1000) % 60;
    final hundredths = (ms ~/ 10) % 100;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
  }

  void _showEditTaskDialog() {
    final titleController = TextEditingController(text: _taskTitle);
    final statusController = TextEditingController(text: _taskStatus);
    final progressController = TextEditingController(
      text: _customProgressPercent.round().toString(),
    );

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
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: 'TASK STATUS',
                labelStyle: AppTextStyles.subheading(context),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
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
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: AppTextStyles.buttonLabel(context).copyWith(
                color: AppColors.secondaryTextOf(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newPercent =
                  double.tryParse(progressController.text) ?? 65.0;
              setState(() {
                _taskTitle = titleController.text;
                _taskStatus = statusController.text;
                _customProgressPercent = newPercent;
              });
              _progressAnim.animateTo(
                newPercent / 100.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              );
              Navigator.pop(ctx);
            },
            child: Text(
              'SAVE',
              style: AppTextStyles.buttonLabel(context).copyWith(
                color: AppColors.accentOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressRatio = _progressAnim.value;

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
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceCardOf(context).withValues(alpha: 0.3),
                  ),
                ),
                CustomPaint(
                  size: const Size(270, 270),
                  painter: OrangeRingPainter(
                    progress: progressRatio,
                    trackColor: AppColors.surfaceCardOf(context),
                    ringColor: AppColors.accentOf(context),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        _formatElapsedTime(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.alarmTime(context).copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRunning ? 'ELAPSED' : 'STOPPED',
                      style: AppTextStyles.subheading(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_laps.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lap ${_formatLapTime(_laps.first)}',
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 13,
                          color: AppColors.accentOf(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 84,
            child: _laps.length > 1
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _laps.length - 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final lapIndex = index + 1;
                        final lapMs = _laps[lapIndex];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCardOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lap ${lapIndex + 1}',
                                style: AppTextStyles.subheading(context)
                                    .copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatLapTime(lapMs),
                                style: AppTextStyles.body(context).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Center(
            child: GestureDetector(
              onTap: _isRunning ? null : _showEditTaskDialog,
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
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isRunning ? 0.0 : 1.0,
                    child: Text(
                      '${_customProgressPercent.round()}% work done  (Tap to edit)',
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 12,
                        color: AppColors.secondaryTextOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 56,
                child: GestureDetector(
                  onTap: _isRunning ? _recordLap : _resetStopwatch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    decoration: BoxDecoration(
                      color: _isRunning
                          ? AppColors.surfaceCardOf(context)
                          : AppColors.accentOf(context),
                      borderRadius: BorderRadius.circular(18),
                      border: _isRunning
                          ? Border.all(
                              color: AppColors.borderOf(context),
                              width: 1,
                            )
                          : null,
                      boxShadow: _isRunning
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.accentOf(context)
                                    .withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Icon(
                      _isRunning ? Icons.flag_outlined : Icons.stop,
                      color: _isRunning
                          ? AppColors.primaryTextOf(context)
                          : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 112,
                height: 56,
                child: GestureDetector(
                  onTap: _toggleStopwatch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    decoration: BoxDecoration(
                      color: _isRunning
                          ? AppColors.surfaceCardOf(context)
                          : AppColors.accentOf(context),
                      borderRadius: BorderRadius.circular(18),
                      border: _isRunning
                          ? Border.all(
                              color: AppColors.borderOf(context),
                              width: 1,
                            )
                          : null,
                      boxShadow: _isRunning
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.accentOf(context)
                                    .withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          color: _isRunning
                              ? AppColors.primaryTextOf(context)
                              : Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isRunning ? 'PAUSE' : 'START',
                          style: AppTextStyles.buttonLabel(context).copyWith(
                            color: _isRunning
                                ? AppColors.primaryTextOf(context)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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

class OrangeRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color ringColor;

  OrangeRingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      ringPaint,
    );

    final dotAngle = -math.pi / 2 + sweepAngle;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);

    final dotOuterPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 7, dotOuterPaint);

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 3.5, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant OrangeRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.ringColor != ringColor;
  }
}
