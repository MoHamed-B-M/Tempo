import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/screen_wake_handler.dart';

enum LockScreenMode { alarm, stopwatch }

class LockScreen extends StatefulWidget {
  final LockScreenMode mode;
  final String title;
  final String? subtitle;
  final String timeDisplay;
  final ValueNotifier<String>? liveTime;
  final bool showSnooze;
  final VoidCallback? onStop;
  final VoidCallback? onSnooze;
  final int autoDismissMinutes;
  final bool vibrateEnabled;
  final double volume;

  const LockScreen({
    super.key,
    required this.mode,
    required this.title,
    this.subtitle,
    required this.timeDisplay,
    this.liveTime,
    this.showSnooze = false,
    this.onStop,
    this.onSnooze,
    this.autoDismissMinutes = 0,
    this.vibrateEnabled = true,
    this.volume = 1.0,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _entryAnimation;
  double _slideOffset = 0;
  AudioPlayer? _audioPlayer;
  Timer? _autoDismissTimer;
  Timer? _vibrateTimer;

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

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeInOutCubic,
    );

    _entryController.forward();
    ScreenWakeHandler.enable();

    if (widget.mode == LockScreenMode.alarm) {
      _startAlarmSound();
      if (widget.vibrateEnabled) {
        _startVibrateLoop();
      }
      _startAutoDismissTimer();
    }
  }

  Future<void> _startAlarmSound() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setSource(AssetSource('audio/sound1.mp3'));
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(widget.volume);
      await _audioPlayer!.resume();
    } catch (_) {}
  }

  Future<void> _stopSound() async {
    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.release();
    } catch (_) {}
  }

  void _startVibrateLoop() {
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  void _startAutoDismissTimer() {
    if (widget.autoDismissMinutes <= 0) return;
    _autoDismissTimer = Timer(
      Duration(minutes: widget.autoDismissMinutes),
      _autoDismiss,
    );
  }

  void _autoDismiss() {
    if (!mounted) return;
    _stop();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.release();
    _autoDismissTimer?.cancel();
    _vibrateTimer?.cancel();
    ScreenWakeHandler.disable();
    super.dispose();
  }

  void _stop() {
    HapticFeedback.mediumImpact();
    _stopSound();
    _autoDismissTimer?.cancel();
    _vibrateTimer?.cancel();
    widget.onStop?.call();
  }

  void _snooze() {
    HapticFeedback.mediumImpact();
    _stopSound();
    _autoDismissTimer?.cancel();
    _vibrateTimer?.cancel();
    widget.onSnooze?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _entryAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(_entryAnimation),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_gradientController, _pulseAnimation]),
                builder: (context, _) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _buildGradient(),
                    ),
                    child: _buildBlurOverlay(),
                  );
                },
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) {
                        return Icon(
                          widget.mode == LockScreenMode.alarm
                              ? Icons.alarm
                              : Icons.timer,
                          color: Colors.white.withValues(
                              alpha: 0.4 + (_pulseAnimation.value * 0.4)),
                          size: 48,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    widget.liveTime != null
                        ? ListenableBuilder(
                            listenable: widget.liveTime!,
                            builder: (context, _) => Text(
                              widget.liveTime!.value,
                              style: const TextStyle(
                                fontSize: 82,
                                fontWeight: FontWeight.w100,
                                color: Colors.white,
                                letterSpacing: 6,
                                height: 1.0,
                              ),
                            ),
                          )
                        : Text(
                            widget.timeDisplay,
                            style: const TextStyle(
                              fontSize: 82,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                              letterSpacing: 6,
                              height: 1.0,
                            ),
                          ),
                    const SizedBox(height: 8),
                    if (widget.title.isNotEmpty)
                      Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 4,
                        ),
                      ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                    if (widget.autoDismissMinutes > 0) ...[
                      const SizedBox(height: 16),
                      AutoDismissIndicator(
                        minutes: widget.autoDismissMinutes,
                        onDismiss: _autoDismiss,
                        key: ValueKey(widget.autoDismissMinutes),
                      ),
                    ],
                    const Spacer(flex: 2),
                    _buildSlideControl(),
                    const SizedBox(height: 16),
                    _buildStopButton(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurOverlay() {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        color: Colors.black.withValues(alpha: 0.15),
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
        HSVColor.fromAHSV(0.7, hue, 0.3, 0.15).toColor(),
        HSVColor.fromAHSV(0.7, nextHue, 0.2, 0.1).toColor(),
        Colors.black,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _buildSlideControl() {
    final leftLabel = widget.showSnooze ? 'SNOOZE' : '';
    final rightLabel = 'STOP';

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _slideOffset += details.delta.dx;
          _slideOffset = _slideOffset.clamp(-120.0, 120.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (widget.showSnooze && _slideOffset <= _snoozeThreshold) {
          _snooze();
        } else if (_slideOffset >= _dismissThreshold) {
          _stop();
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
                      if (widget.showSnooze) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.nightlight_round,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18),
                      ],
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
                      Icon(Icons.stop_circle_outlined,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 18),
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
                              ? Colors.red.withValues(alpha: 0.3)
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
                              ? Icons.stop
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
              if (widget.showSnooze)
                SizedBox(
                  width: 80,
                  child: Text(
                    leftLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _slideOffset <= _snoozeThreshold
                          ? Colors.blue
                          : Colors.white.withValues(alpha: 0.25),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              const SizedBox(width: 120),
              SizedBox(
                width: 80,
                child: Text(
                  rightLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _slideOffset >= _dismissThreshold
                        ? Colors.red
                        : Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: _stop,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.2),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.stop,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class AutoDismissIndicator extends StatefulWidget {
  final int minutes;
  final VoidCallback onDismiss;

  const AutoDismissIndicator({
    super.key,
    required this.minutes,
    required this.onDismiss,
  });

  @override
  State<AutoDismissIndicator> createState() => _AutoDismissIndicatorState();
}

class _AutoDismissIndicatorState extends State<AutoDismissIndicator> {
  late int _remainingSeconds;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.minutes * 60;
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _countdown?.cancel();
        widget.onDismiss();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return Text(
      'Auto-dismiss in $mins:${secs.toString().padLeft(2, '0')}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: Colors.white.withValues(alpha: 0.4),
        letterSpacing: 2,
      ),
    );
  }
}
