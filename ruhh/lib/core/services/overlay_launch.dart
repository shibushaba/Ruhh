import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/services/overlay_service.dart';

/// Opens the quick overlay on Android, or the setup screen if permission is missing.
Future<void> openQuickAction(BuildContext context, WidgetRef ref) async {
  if (!ref.read(overlaySupportedProvider)) return;

  final ok = await ref.read(overlayServiceProvider).showQuickAction();
  if (!context.mounted) return;

  if (!ok) {
    context.push('/settings/overlay');
  }
}
