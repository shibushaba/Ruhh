import 'package:ruhh/core/services/overlay_runtime.dart';

typedef LocalDataChangedHook = void Function();

LocalDataChangedHook? _onLocalDataChanged;

/// Registered once from [cloudSyncLifecycleProvider].
void registerLocalDataChangedHook(LocalDataChangedHook hook) {
  _onLocalDataChanged = hook;
}

/// Call after any synced Isar mutation (habit, budget, prayer, movie, settings).
void notifyLocalDataChanged() {
  if (ruhhOverlayIsolate) return;
  _onLocalDataChanged?.call();
}
