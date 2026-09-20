/// True while [overlayMain] / [overlayTriggerMain] entry points are running.
/// Used to avoid cloud sync and other main-isolate work in the overlay engine.
bool ruhhOverlayIsolate = false;

void markRuhhOverlayIsolate() {
  ruhhOverlayIsolate = true;
}
