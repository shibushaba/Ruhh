import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neubrutalism_ui/neubrutalism_ui.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/overlay/quick_action_stepper.dart';

class OverlayEntryWidget extends ConsumerWidget {
  const OverlayEntryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(overlayServiceProvider).close(),
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: size.height * 0.82,
              ),
              child: NeuCard(
                cardColor: Colors.white.withValues(alpha: 0.88),
                cardBorderColor: NBColors.black,
                cardBorderWidth: NBMetrics.borderWidth,
                shadowColor: NBColors.shadow,
                offset: NBMetrics.shadowOffset,
                borderRadius: BorderRadius.circular(NBMetrics.radius),
                paddingData: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NBMetrics.radius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Quick action',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            NBButton(
                              expand: false,
                              label: 'Close',
                              color: NBColors.offWhite,
                              onPressed: () =>
                                  ref.read(overlayServiceProvider).close(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: SingleChildScrollView(
                            child: const QuickActionStepper(),
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
