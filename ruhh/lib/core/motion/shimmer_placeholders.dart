import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:shimmer/shimmer.dart';

/// B.10 shimmer skeleton stat card.
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final h = compact ? 100.0 : 120.0;
    return Shimmer.fromColors(
      baseColor: t.divider,
      highlightColor: t.surfaceSecondary,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: t.surfacePrimary,
          borderRadius: BorderRadius.circular(
            compact ? t.radiusCardMedium : t.radiusCardLarge,
          ),
        ),
      ),
    );
  }
}

class ShimmerListRow extends StatelessWidget {
  const ShimmerListRow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Shimmer.fromColors(
      baseColor: t.divider,
      highlightColor: t.surfaceSecondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.surfacePrimary,
                borderRadius: BorderRadius.circular(t.radiusChip),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: t.surfacePrimary,
                  ),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 120, color: t.surfacePrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
