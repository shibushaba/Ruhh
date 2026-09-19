import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/overlay/quick_action_stepper.dart';

/// Full-screen quick overlay: dimmed backdrop + light frosted sheet.
class OverlayEntryWidget extends ConsumerStatefulWidget {
  const OverlayEntryWidget({super.key});

  @override
  ConsumerState<OverlayEntryWidget> createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends ConsumerState<OverlayEntryWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final h = MediaQuery.sizeOf(context).height;
      await FlutterOverlayWindow.resizeOverlay(
        WindowSize.matchParent,
        h.round(),
        false,
      );
    });
  }

  void _close() => ref.read(overlayServiceProvider).close();

  @override
  Widget build(BuildContext context) {
    final t = RuhhTokens.light;
    final size = MediaQuery.sizeOf(context);
    final sheetMaxH = (size.height * 0.78).clamp(420.0, 720.0);
    final sheetW = (size.width * 0.92).clamp(320.0, 440.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: ColoredBox(color: t.textPrimary.withValues(alpha: 0.45)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              child: SizedBox(
                width: sheetW,
                height: sheetMaxH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(t.radiusNavBar),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.surfacePrimary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(t.radiusNavBar),
                        boxShadow: t.shadowNav,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quick log',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: t.textPrimary,
                                          ),
                                    ),
                                    Text(
                                      'Pick a module — tap outside to close',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: t.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _close,
                                  icon: Icon(Icons.close, color: t.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: t.divider),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: QuickActionStepper(
                                onClose: _close,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
