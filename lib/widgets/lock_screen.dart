import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
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
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _entryAnimation;
  AudioPlayer? _audioPlayer;
  Timer? _autoDismissTimer;
  Timer? _vibrateTimer;

  @override
  void initState() {
    super.initState();

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
    final cs = Theme.of(context).colorScheme;

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
              Container(color: Colors.black),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildPulseIcon(),
                    const SizedBox(height: 32),
                    _buildTimeCard(cs),
                    if (widget.title.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.title.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                    if (widget.autoDismissMinutes > 0) ...[
                      const SizedBox(height: 20),
                      AutoDismissIndicator(
                        minutes: widget.autoDismissMinutes,
                        onDismiss: _autoDismiss,
                        key: ValueKey(widget.autoDismissMinutes),
                      ),
                    ],
                    const Spacer(flex: 2),
                    _buildActions(cs),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseIcon() {
    return AnimatedBuilder(
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
    );
  }

  Widget _buildTimeCard(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: M3EContainer.gem(
        color: const Color(0xFF1A1A1A),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.liveTime != null
                ? ListenableBuilder(
                    listenable: widget.liveTime!,
                    builder: (context, _) => Text(
                      widget.liveTime!.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 82,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        letterSpacing: 6,
                        height: 1.0,
                      ),
                    ),
                  )
                : Text(
                    widget.timeDisplay,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 82,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: 6,
                      height: 1.0,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSnooze && widget.mode == LockScreenMode.alarm) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: M3EOutlinedButton.icon(
                onPressed: _snooze,
                size: M3EButtonSize.lg,
                icon: const Icon(Icons.nightlight_round, color: Colors.white70, size: 22),
                label: Text(
                  'SNOOZE 5 MIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                decoration: M3EButtonDecoration(
                  side: WidgetStatePropertyAll(
                    BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            child: M3EFilledButton.icon(
              onPressed: _stop,
              size: M3EButtonSize.lg,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 24),
              label: Text(
                widget.mode == LockScreenMode.alarm ? 'DISMISS' : 'STOP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              decoration: M3EButtonDecoration(
                backgroundColor: WidgetStatePropertyAll(Colors.red.withValues(alpha: 0.85)),
                side: WidgetStatePropertyAll(
                  BorderSide(color: Colors.red.withValues(alpha: 0.4), width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        'Auto-dismiss in $mins:${secs.toString().padLeft(2, '0')}',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
