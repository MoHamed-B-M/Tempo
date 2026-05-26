import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _slideOffset = 0;
  bool _isSnoozing = false;

  static const _snoozeThreshold = -100.0;
  static const _dismissThreshold = 100.0;

  @override
  void initState() {
    super.initState();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );

    HapticFeedback.heavyImpact();
    _vibrateLoop();
  }

  void _vibrateLoop() async {
    while (mounted && !_isSnoozing) {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted && !_isSnoozing) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _snooze() {
    setState(() => _isSnoozing = true);
    HapticFeedback.mediumImpact();
    final service = context.read<AlarmService>();
    service.toggleAlarm(widget.alarm.id);
    Future.delayed(const Duration(minutes: 5), () {
      service.toggleAlarm(widget.alarm.id);
    });
    Navigator.of(context).pop();
  }

  void _dismiss() {
    HapticFeedback.mediumImpact();
    context.read<AlarmService>().toggleAlarm(widget.alarm.id);
    if (widget.alarm.isRepeating) {
      context.read<AlarmService>().toggleAlarm(widget.alarm.id);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final timeStr = now.format(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_gradientController, _pulseAnimation]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: _buildGradient(),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 82,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                      letterSpacing: 6,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.alarm.label.isNotEmpty)
                    Text(
                      widget.alarm.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 4,
                      ),
                    ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      return Icon(
                        Icons.alarm,
                        color: Colors.white.withValues(
                            alpha: 0.4 + (_pulseAnimation.value * 0.4)),
                        size: 48,
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                  _buildSlideControl(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Gradient _buildGradient() {
    final t = _gradientController.value;
    final hue = (t * 360.0) % 360.0;
    final nextHue = (hue + 60) % 360.0;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSVColor.fromAHSV(0.6, hue, 0.3, 0.15).toColor(),
        HSVColor.fromAHSV(0.6, nextHue, 0.2, 0.1).toColor(),
        Colors.black,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _buildSlideControl() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _slideOffset += details.delta.dx;
          _slideOffset = _slideOffset.clamp(-120.0, 120.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_slideOffset <= _snoozeThreshold) {
          _snooze();
        } else if (_slideOffset >= _dismissThreshold) {
          _dismiss();
        } else {
          setState(() => _slideOffset = 0);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.nightlight_round,
                          color: Colors.white.withValues(alpha: 0.4), size: 18),
                      const Spacer(),
                      Text(
                        'SLIDE TO ACTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.alarm_off,
                          color: Colors.white.withValues(alpha: 0.4), size: 18),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(_slideOffset, 0),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _slideOffset < 0
                          ? Colors.blue.withValues(alpha: 0.3)
                          : _slideOffset > 0
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _slideOffset < -20
                          ? Icons.nightlight_round
                          : _slideOffset > 20
                              ? Icons.close
                              : Icons.circle,
                      color: _slideOffset < -20
                          ? Colors.blue.withValues(alpha: 0.8)
                          : _slideOffset > 20
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SNOOZE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _slideOffset <= _snoozeThreshold
                      ? Colors.blue
                      : Colors.white.withValues(alpha: 0.25),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: 160),
              Text(
                'DISMISS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _slideOffset >= _dismissThreshold
                      ? Colors.red
                      : Colors.white.withValues(alpha: 0.25),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
