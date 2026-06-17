import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import '../../providers/timer_provider.dart';

class StopwatchTab extends ConsumerStatefulWidget {
  const StopwatchTab({super.key});

  @override
  ConsumerState<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends ConsumerState<StopwatchTab>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
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
    final sw = ref.read(stopwatchProvider.notifier);
    if (ref.read(stopwatchProvider).isRunning) {
      _timer?.cancel();
      sw.stop();
      _progressAnim.animateTo(
        _customProgressPercent / 100.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      sw.start();
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        ref.read(stopwatchProvider.notifier).tick();
        _progressAnim.value =
            (ref.read(stopwatchProvider).elapsedMs % 60000) / 60000.0;
      });
    }
  }

  void _resetStopwatch() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    ref.read(stopwatchProvider.notifier).reset();
    setState(() {
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
    final elapsedMs = ref.read(stopwatchProvider).elapsedMs;
    setState(() {
      _laps.insert(0, elapsedMs);
    });
  }

  static String _formatTime(int ms) {
    final minutes = (ms ~/ 60000) % 60;
    final seconds = (ms ~/ 1000) % 60;
    final hundredths = (ms ~/ 10) % 100;
    final hours = ms ~/ 3600000;
    if (hours > 0) {
      final mins = (ms ~/ 60000) % 60;
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
  }

  void _showEditTaskDialog() {
    final cs = Theme.of(context).colorScheme;
    final titleController = TextEditingController(text: _taskTitle);
    final statusController = TextEditingController(text: _taskStatus);
    final progressController = TextEditingController(
      text: _customProgressPercent.round().toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'EDIT TASK DETAILS',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'TASK NAME',
                labelStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusController,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'TASK STATUS',
                labelStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: progressController,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PROGRESS PERCENT (%)',
                labelStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
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
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
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
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sw = ref.watch(stopwatchProvider);
    final elapsedMs = sw.elapsedMs;
    final isRunning = sw.isRunning;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'StopWatch',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          Center(
            child: ColoredBox(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surfaceContainerHighest.withValues(
                              alpha: isRunning ? 0.5 : 0.2),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          _formatTime(elapsedMs),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRunning ? 'ELAPSED' : 'STOPPED',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (_laps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Lap ${_formatTime(_laps.first)}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lap ${lapIndex + 1}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTime(lapMs),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
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
              onTap: isRunning ? null : _showEditTaskDialog,
              behavior: isRunning
                  ? HitTestBehavior.translucent
                  : HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    _taskTitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _taskStatus,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isRunning ? 0.0 : 1.0,
                    child: Text(
                      '${_customProgressPercent.round()}% work done  (Tap to edit)',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
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
              M3EOutlinedButton(
                onPressed: isRunning ? _recordLap : _resetStopwatch,
                size: M3EButtonSize.md,
                decoration: M3EButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(
                    isRunning ? cs.surfaceContainerHigh : cs.primary,
                  ),
                  side: isRunning
                      ? WidgetStatePropertyAll(
                          BorderSide(color: cs.outlineVariant))
                      : null,
                  borderRadius: 18,
                  fixedSize: const Size(84, 56),
                ),
                child: Icon(
                  isRunning ? Icons.flag_outlined : Icons.stop,
                  color: isRunning ? cs.onSurface : cs.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              M3EFilledButton.icon(
                onPressed: _toggleStopwatch,
                icon: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  color: isRunning ? cs.onSurface : cs.onPrimary,
                  size: 24,
                ),
                label: Text(
                  isRunning ? 'PAUSE' : 'START',
                  style: TextStyle(
                    color: isRunning ? cs.onSurface : cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                size: M3EButtonSize.md,
                decoration: M3EButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(
                    isRunning ? cs.surfaceContainerHigh : cs.primary,
                  ),
                  side: isRunning
                      ? WidgetStatePropertyAll(
                          BorderSide(color: cs.outlineVariant))
                      : null,
                  borderRadius: 18,
                  fixedSize: const Size(112, 56),
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
