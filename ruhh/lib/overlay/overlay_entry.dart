import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/overlay/quick_action_stepper.dart';

class OverlayEntryWidget extends ConsumerWidget {
  const OverlayEntryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: NBGlassPanel(
            expand: true,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'RUHH',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          ref.read(overlayServiceProvider).close(),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      style: IconButton.styleFrom(
                        side: BorderSide(
                          color: NBColors.glassBorder(
                            Theme.of(context).brightness,
                          ),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(NBMetrics.radius),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                const Expanded(
                  child: QuickActionStepper(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
