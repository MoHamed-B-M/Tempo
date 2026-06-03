import 'package:flutter_riverpod/flutter_riverpod.dart';

final stopwatchProvider = NotifierProvider<StopwatchNotifier, StopwatchState>(
  StopwatchNotifier.new,
);

class StopwatchState {
  final int elapsedMs;
  final bool isRunning;

  const StopwatchState({this.elapsedMs = 0, this.isRunning = false});

  StopwatchState copyWith({int? elapsedMs, bool? isRunning}) {
    return StopwatchState(
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class StopwatchNotifier extends Notifier<StopwatchState> {
  @override
  StopwatchState build() => const StopwatchState();

  void start() {
    state = state.copyWith(isRunning: true);
  }

  void stop() {
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    state = const StopwatchState();
  }

  void tick() {
    state = state.copyWith(elapsedMs: state.elapsedMs + 10);
  }

  void setElapsed(int ms) {
    state = state.copyWith(elapsedMs: ms);
  }
}
