import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:m3e_core/m3e_core.dart';
import '../../main.dart' show notificationsPlugin;
import '../../widgets/orange_ring_painter.dart';

class TimerTab extends StatefulWidget {
  const TimerTab({super.key});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  Timer? _timer;
  int _remainingMs = 0;
  int _initialMs = 0;
  bool _isRunning = false;
  bool _isFinished = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _inputHours = 0;
  int _inputMinutes = 0;
  int _inputSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.release();
    super.dispose();
  }

  void _setDuration() {
    final total =
        (_inputHours * 3600 + _inputMinutes * 60 + _inputSeconds) * 1000;
    if (total <= 0) return;
    setState(() {
      _remainingMs = total;
      _initialMs = total;
      _isFinished = false;
    });
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isFinished) {
      _resetTimer();
      return;
    }
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
      } else {
        if (_remainingMs <= 0) return;
        _isRunning = true;
        _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
          setState(() {
            _remainingMs -= 10;
            if (_remainingMs <= 0) {
              _remainingMs = 0;
              _timer?.cancel();
              _isRunning = false;
              _isFinished = true;
              _playFinishSound();
            }
          });
        });
      }
    });
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _isRunning = false;
      _isFinished = false;
      _remainingMs = _initialMs;
    });
  }

  Future<void> _playFinishSound() async {
    HapticFeedback.heavyImpact();
    try {
      await _audioPlayer.setSource(AssetSource('audio/sound1.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.resume();
    } catch (_) {}

    _showTimerNotification();
  }

  void _showTimerNotification() {
    const androidDetails = AndroidNotificationDetails(
      'tempo_alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Plays when an alarm triggers',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('stop', 'Stop', showsUserInterface: true),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      'Timer Finished',
      'Your countdown timer has ended.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  String _formatTime(int ms) {
    if (ms <= 0 && _initialMs > 0 && !_isRunning && _isFinished) {
      return '00:00';
    }
    final hours = ms ~/ 3600000;
    final minutes = (ms ~/ 60000) % 60;
    final seconds = (ms ~/ 1000) % 60;
    if (hours > 0) {
      final mins = (ms ~/ 60000) % 60;
      return '$hours:${mins.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_initialMs <= 0) return 1.0;
    return (_remainingMs / _initialMs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDuration = _initialMs > 0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timer',
            style: TextStyle(
              fontFamily: 'GoogleFonts.plusJakartaSans',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (!hasDuration)
            _buildInputSection(cs)
          else
            _buildTimerSection(cs),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildInputSection(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeInput(
                'HOUR', _inputHours, (v) => _inputHours = v.clamp(0, 99), 99,
                cs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(':',
                  style: TextStyle(
                    fontFamily: 'GoogleFonts.plusJakartaSans',
                    fontSize: 36,
                    fontWeight: FontWeight.w200,
                    color: cs.onSurface,
                  )),
            ),
            _buildTimeInput(
                'MIN', _inputMinutes, (v) => _inputMinutes = v.clamp(0, 59), 59,
                cs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(':',
                  style: TextStyle(
                    fontFamily: 'GoogleFonts.plusJakartaSans',
                    fontSize: 36,
                    fontWeight: FontWeight.w200,
                    color: cs.onSurface,
                  )),
            ),
            _buildTimeInput(
                'SEC', _inputSeconds, (v) => _inputSeconds = v.clamp(0, 59), 59,
                cs),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          child: M3EFilledButton(
            onPressed: _setDuration,
            size: M3EButtonSize.md,
            decoration: M3EButtonDecoration(
              borderRadius: 18,
            ),
            child: const Text(
              'START TIMER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInput(String label, int value, ValueChanged<int> onChanged,
      int max, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 32,
          child: TextButton(
            onPressed: () {
              final next = (value + 1).clamp(0, max);
              if (next != value) onChanged(next);
              setState(() {});
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),
            child: Icon(Icons.add, size: 16, color: cs.onSurface),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () =>
              _showNumberPicker(context, label, value, onChanged, max, cs),
          child: Container(
            width: 72,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontFamily: 'GoogleFonts.plusJakartaSans',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 56,
          height: 32,
          child: TextButton(
            onPressed: () {
              final next = (value - 1).clamp(0, max);
              if (next != value) onChanged(next);
              setState(() {});
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),
            child: Icon(Icons.remove, size: 16, color: cs.onSurface),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontFamily: 'GoogleFonts.plusJakartaSans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            )),
      ],
    );
  }

  void _showNumberPicker(BuildContext context, String label, int current,
      ValueChanged<int> onChanged, int max, ColorScheme cs) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(label,
            style: TextStyle(
              fontFamily: 'GoogleFonts.plusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            )),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontFamily: 'GoogleFonts.plusJakartaSans',
            fontSize: 36,
            fontWeight: FontWeight.w200,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(
                  fontFamily: 'GoogleFonts.plusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                )),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              onChanged(val.clamp(0, max));
              setState(() {});
              Navigator.pop(ctx);
            },
            child: Text('SET',
                style: TextStyle(
                  fontFamily: 'GoogleFonts.plusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
              ),
            ),
            CustomPaint(
              size: const Size(270, 270),
              painter: OrangeRingPainter(
                progress: _progress,
                trackColor: cs.surfaceContainerHigh,
                ringColor: _isFinished ? Colors.green : cs.primary,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    _formatTime(_remainingMs),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts.plusJakartaSans',
                      fontSize: _initialMs >= 3600000 ? 28 : 36,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFinished
                      ? "TIME'S UP!"
                      : (_isRunning ? 'RUNNING' : 'READY'),
                  style: TextStyle(
                    fontFamily: 'GoogleFonts.plusJakartaSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isFinished ? Colors.green : cs.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            M3EOutlinedButton(
              onPressed: _resetTimer,
              size: M3EButtonSize.md,
              decoration: M3EButtonDecoration(
                side: WidgetStatePropertyAll(
                    BorderSide(color: cs.outlineVariant)),
                borderRadius: 18,
                fixedSize: const Size(84, 56),
              ),
              child: Icon(Icons.refresh, color: cs.onSurface, size: 24),
            ),
            const SizedBox(width: 20),
            M3EFilledButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(
                _isFinished
                    ? Icons.refresh
                    : (_isRunning ? Icons.pause : Icons.play_arrow),
                color: cs.onPrimary,
                size: 24,
              ),
              label: Text(
                _isFinished ? 'RESET' : (_isRunning ? 'PAUSE' : 'START'),
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              size: M3EButtonSize.md,
              decoration: M3EButtonDecoration(
                backgroundColor: WidgetStatePropertyAll(
                  _isFinished ? Colors.green : cs.primary,
                ),
                borderRadius: 18,
                fixedSize: const Size(112, 56),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
