import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverlayService {
  Future<bool> isPermissionGranted() {
    if (!Platform.isAndroid) return Future.value(false);
    return FlutterOverlayWindow.isPermissionGranted();
  }

  Future<bool?> requestPermission() {
    if (!Platform.isAndroid) return Future.value(false);
    return FlutterOverlayWindow.requestPermission();
  }

  Future<bool> showQuickAction() async {
    if (!Platform.isAndroid) return false;

    var granted = await isPermissionGranted();
    if (!granted) {
      await requestPermission();
      granted = await isPermissionGranted();
    }
    if (!granted) return false;

    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }

    await FlutterOverlayWindow.showOverlay(
      height: 520,
      width: 340,
      alignment: OverlayAlignment.center,
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      overlayTitle: 'RUHH',
      overlayContent: 'Quick log',
      flag: OverlayFlag.focusPointer,
      visibility: NotificationVisibility.visibilityPublic,
    );
    return true;
  }

  Future<void> close() => FlutterOverlayWindow.closeOverlay();
}

final overlayServiceProvider = Provider<OverlayService>((ref) {
  return OverlayService();
});

final overlaySupportedProvider = Provider<bool>((ref) {
  return !kIsWeb && Platform.isAndroid;
});
