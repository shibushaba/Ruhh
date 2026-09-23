import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';

abstract final class NBLayout {
  static const pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 24);
  static const sectionGap = 24.0;
  static const itemGap = 12.0;
  static const maxContentWidth = 720.0;
}

class NBPageBody extends StatelessWidget {
  const NBPageBody({
    super.key,
    required this.child,
    this.padding,
    this.extraBottomPadding = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final scrollBottom = extraBottomPadding
        ? ruhhEffectiveScrollBottomInset(context)
        : MediaQuery.paddingOf(context).bottom + 16.0;
    final fabEnd = ruhhEffectiveFabEndInset(context);
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: NBLayout.maxContentWidth),
          child: Padding(
            padding: padding ??
                EdgeInsets.fromLTRB(
                  t.spaceScreenHorizontal,
                  8,
                  t.spaceScreenHorizontal + fabEnd,
                  0,
                ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxH = constraints.maxHeight;
                final body = ruhhApplyScrollBottomInset(
                  context: context,
                  bottomInset: scrollBottom,
                  child: child,
                );
                if (!maxH.isFinite) return body;
                return SizedBox(height: maxH, child: body);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class NBSection extends StatelessWidget {
  const NBSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: t.cardTitle(theme)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: t.caption(theme)),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class NBEmptyState extends StatelessWidget {
  const NBEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return RuhhSoftCard(
      radius: t.radiusCardMedium,
      child: Text(
        message,
        style: t.caption(Theme.of(context).textTheme),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class NBStreakBadge extends StatelessWidget {
  const NBStreakBadge({super.key, required this.value, this.onTap});

  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RuhhRankBadge(
      label: 'Streak $value',
      onTap: onTap,
    );
  }
}
