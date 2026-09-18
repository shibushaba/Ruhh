import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';

class OverlaySetupPage extends ConsumerWidget {
  const OverlaySetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(overlayServiceProvider);
    final supported = ref.watch(overlaySupportedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Quick action')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NBCard(
              child: Text(
                supported
                    ? 'On Samsung One UI: Settings → Advanced features → Motions and gestures → Tap back → choose **RUHH Quick Action**.'
                    : 'Back-tap quick action works on supported Android devices. Use the in-app Quick button as fallback.',
              ),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: 'Grant overlay permission',
              color: NBColors.prayer,
              onPressed: () => overlay.requestPermission(),
            ),
            const SizedBox(height: 8),
            NBButton(
              label: 'Open system settings',
              color: NBColors.habit,
              onPressed: () => launchUrl(Uri.parse('app-settings:')),
            ),
            const SizedBox(height: 8),
            NBButton(
              label: 'Test overlay now',
              onPressed: () => overlay.showQuickAction(),
            ),
          ],
        ),
      ),
    );
  }
}
