import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/overlay/quick_action_stepper.dart';

/// Full-screen quick overlay: dimmed backdrop + centered dark glass sheet.
class OverlayEntryWidget extends ConsumerWidget {
  const OverlayEntryWidget({super.key});

  void _close(WidgetRef ref) => ref.read(overlayServiceProvider).close();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RuhhTokens.dark;
    final back = ref.watch(overlayQuickBackProvider);
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;
    final pad = media.viewPadding;

    final availableH = screenH - pad.top - pad.bottom;
    final sheetW = (screenW * 0.92).clamp(300.0, 440.0);
    final sheetH = (availableH * 0.72).clamp(340.0, 580.0);
    final left = (screenW - sheetW) / 2;
    final top = pad.top + (availableH - sheetH) / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _close(ref),
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.58)),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: sheetW,
            height: sheetH,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414).withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                          child: Row(
                            children: [
                              if (back.visible)
                                IconButton(
                                  onPressed: back.onBack,
                                  icon: Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 20,
                                    color: t.textPrimary,
                                  ),
                                  tooltip: 'Back',
                                ),
                              Expanded(
                                child: Column(
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
                                            letterSpacing: -0.3,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      back.visible
                                          ? 'Back to modules'
                                          : 'Tap outside to close',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: t.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _close(ref),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: t.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(18, 10, 18, 18),
                            child: QuickActionStepper(
                              onClose: () => _close(ref),
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
        ],
      ),
    );
  }
}
