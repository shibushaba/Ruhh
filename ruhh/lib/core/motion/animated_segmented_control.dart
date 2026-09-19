import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/portfolio_palette.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

/// B.6 sliding pill segmented control.
class AnimatedSegmentedControl extends StatefulWidget {
  const AnimatedSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<AnimatedSegmentedControl> createState() =>
      _AnimatedSegmentedControlState();
}

class _AnimatedSegmentedControlState extends State<AnimatedSegmentedControl> {
  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final count = widget.labels.length;
    if (count == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final segW = constraints.maxWidth / count;
        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: t.surfaceSecondary,
            borderRadius: BorderRadius.circular(t.radiusChip),
            border: Border.all(color: PortfolioPalette.borderHighlight),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: segW * widget.selectedIndex.clamp(0, count - 1),
                top: 0,
                bottom: 0,
                width: segW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.textPrimary,
                    borderRadius: BorderRadius.circular(t.radiusChip),
                    border: Border.all(color: PortfolioPalette.borderHighlight),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onSelected(i),
                          borderRadius: BorderRadius.circular(t.radiusChip),
                          child: Center(
                            child: Text(
                              widget.labels[i],
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: widget.selectedIndex == i
                                        ? (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? PortfolioPalette.background
                                            : PortfolioPalette.foreground)
                                        : t.textSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
