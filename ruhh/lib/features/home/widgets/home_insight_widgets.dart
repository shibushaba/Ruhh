import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

class HomeInsightItem {
  const HomeInsightItem({
    required this.emoji,
    required this.tag,
    required this.title,
    required this.detail,
    required this.accent,
    required this.route,
  });

  final String emoji;
  final String tag;
  final String title;
  final String detail;
  final Color accent;
  final String route;
}

class HomeInsightTile extends StatelessWidget {
  const HomeInsightTile({super.key, required this.item});

  final HomeInsightItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RuhhSoftCard(
        onTap: () => context.go(item.route),
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: item.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 26, height: 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: t.divider),
                        borderRadius: BorderRadius.circular(t.radiusChip),
                      ),
                      child: Text(
                        item.tag.toUpperCase(),
                        style: t.micro(theme),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(item.title, style: t.cardTitle(theme)),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      style: t.caption(theme),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Center(
                child: Icon(
                  Icons.north_east,
                  size: 16,
                  color: t.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeSectionLabel extends StatelessWidget {
  const HomeSectionLabel({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.cardTitle(theme)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: t.caption(theme)),
          ],
        ],
      ),
    );
  }
}

class HomeDayHero extends StatelessWidget {
  const HomeDayHero({
    super.key,
    required this.greeting,
    required this.dateLine,
    required this.headline,
    required this.habitLine,
    required this.prayerLine,
    this.budgetLine,
  });

  final String greeting;
  final String dateLine;
  final String headline;
  final String habitLine;
  final String prayerLine;
  final String? budgetLine;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return RuhhSoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            greeting,
            style: t.statLarge(theme),
          ),
          const SizedBox(height: 4),
          Text(dateLine, style: t.caption(theme)),
          const SizedBox(height: 14),
          Text(
            headline,
            style: theme.bodyLarge?.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 12),
          _HeroStatRow(icon: '✓', label: habitLine),
          const SizedBox(height: 6),
          _HeroStatRow(icon: '🕌', label: prayerLine),
          if (budgetLine != null) ...[
            const SizedBox(height: 6),
            _HeroStatRow(icon: '₹', label: budgetLine!),
          ],
        ],
      ),
    );
  }
}

class _HeroStatRow extends StatelessWidget {
  const _HeroStatRow({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(icon, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Text(
            label,
            style: t.caption(Theme.of(context).textTheme).copyWith(
                  color: t.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

String homeTimeGreeting(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  if (h < 21) return 'Good evening';
  return 'Good night';
}
