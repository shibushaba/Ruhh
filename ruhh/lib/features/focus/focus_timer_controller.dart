import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/features/focus/focus_repository.dart';
import 'package:ruhh/features/habit/habit_repository.dart';

class FocusTimerState {
  const FocusTimerState({
    this.running = false,
    this.paused = false,
    this.habitRemoteId,
    this.targetMinutes = 25,
    this.elapsedSeconds = 0,
  });

  final bool running;
  final bool paused;
  final String? habitRemoteId;
  final int targetMinutes;
  final int elapsedSeconds;

  FocusTimerState copyWith({
    bool? running,
    bool? paused,
    String? habitRemoteId,
    int? targetMinutes,
    int? elapsedSeconds,
  }) =>
      FocusTimerState(
        running: running ?? this.running,
        paused: paused ?? this.paused,
        habitRemoteId: habitRemoteId ?? this.habitRemoteId,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      );
}

class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  FocusTimerNotifier(this._ref) : super(const FocusTimerState());

  final Ref _ref;
  Timer? _tick;

  void start({required String habitId, int minutes = 25}) {
    _tick?.cancel();
    state = FocusTimerState(
      running: true,
      habitRemoteId: habitId,
      targetMinutes: minutes,
    );
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.running || state.paused) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pause() => state = state.copyWith(paused: true);

  void resume() => state = state.copyWith(paused: false);

  Future<void> stop() async {
    _tick?.cancel();
    final s = state;
    state = const FocusTimerState();
    if (s.habitRemoteId == null) return;
    final repo = await _ref.read(focusRepositoryProvider.future);
    await repo.saveSession(
      habitRemoteId: s.habitRemoteId!,
      targetMinutes: s.targetMinutes,
      seconds: s.elapsedSeconds,
      completed: s.elapsedSeconds >= s.targetMinutes * 60,
    );
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerState>(
  (ref) => FocusTimerNotifier(ref),
);

String formatFocusDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
