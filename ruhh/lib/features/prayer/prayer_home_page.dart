import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/prayer/prayer_enrichment.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/prayer/widgets/prayer_tracker_widgets.dart';

class PrayerHomePage extends ConsumerStatefulWidget {
  const PrayerHomePage({super.key});

  @override
  ConsumerState<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends ConsumerState<PrayerHomePage> {
  bool _showStar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(dailyAyahProvider);
      ref.invalidate(todaySunTimesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(dailyPrayerLogsProvider);
    final repoAsync = ref.watch(prayerRepositoryProvider);

    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (repo) {
        return logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (logs) {
            final todayKey = repo.todayKey;
            final today = resolveDayLog(todayKey, logs, todayKey);
            final summary = repo.computeSummary(logs);

            return StarRewardOverlay(
              show: _showStar,
              child: NBPageBody(
                child: FutureBuilder(
                  future: repo.displayTimesForDay(DateTime.now()),
                  builder: (context, timeSnap) {
                    final times = timeSnap.data ?? {};
                    return ListView(
                      children: [
                        NBPrayerStreakBadge(
                          current: summary.currentStreak,
                          longest: summary.longestStreak,
                        ),
                        const SizedBox(height: 16),
                        NBTodayProgressBar(
                          ratio: todayRatio(today),
                          today: today,
                        ),
                        const SizedBox(height: 16),
                        const _DailyAyahCard(),
                        const SizedBox(height: 12),
                        const _SunTimesCard(),
                        const SizedBox(height: 16),
                        RuhhSoftCard(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                          child: Column(
                            children: [
                              ...prayerOrder.map((p) {
                                final prayed = today.statuses[p] ==
                                    TrackerPrayerStatus.prayed;
                                final time = times[p];
                                return NBPrayerCheckTile(
                                  prayer: p,
                                  prayed: prayed,
                                  enabled: !today.isExcusedDay,
                                  timeLabel: time != null && time.length >= 5
                                      ? time.substring(0, 5)
                                      : null,
                                  onTap: () async {
                                    final updated =
                                        await repo.toggleTrackerPrayer(
                                      todayKey,
                                      p,
                                    );
                                    bumpPrayerRefresh(ref);
                                    if (isFullyPrayed(updated)) {
                                      setState(() => _showStar = true);
                                      Future.delayed(
                                        const Duration(seconds: 2),
                                        () {
                                          if (mounted) {
                                            setState(() => _showStar = false);
                                          }
                                        },
                                      );
                                    }
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RuhhSegmentedChips(
                          labels: const ['Normal', 'Excused'],
                          selectedIndex: today.isExcusedDay ? 1 : 0,
                          onSelected: (i) async {
                            await repo.setExcusedDay(todayKey, i == 1);
                            bumpPrayerRefresh(ref);
                          },
                        ),
                        const RuhhNavClearance(),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DailyAyahCard extends ConsumerWidget {
  const _DailyAyahCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(dailyAyahProvider);
    return ayahAsync.when(
      loading: () => const RuhhSoftCard(
        child: SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (ayah) {
        if (ayah == null || ayah.textAr.isEmpty) {
          return const SizedBox.shrink();
        }
        final meta = [
          if (ayah.surahNameEn != null && ayah.surahNameEn!.isNotEmpty)
            ayah.surahNameEn,
          if (ayah.ayahKey.isNotEmpty) ayah.ayahKey,
        ].join(' · ');
        return RuhhSoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ayah of the day',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Text(
                ayah.textAr,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.6,
                    ),
              ),
              if (ayah.textEn != null && ayah.textEn!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  ayah.textEn!.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: context.ruhh.textSecondary,
                      ),
                ),
              ],
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  meta,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'via ${ayah.source}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.ruhh.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SunTimesCard extends ConsumerWidget {
  const _SunTimesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sunAsync = ref.watch(todaySunTimesProvider);
    final fmt = DateFormat.jm();
    return sunAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sun) {
        if (sun == null) return const SizedBox.shrink();
        return RuhhSoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sun & twilight',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SunMetric(
                      label: 'Dawn',
                      value: fmt.format(sun.civilTwilightBegin),
                    ),
                  ),
                  Expanded(
                    child: _SunMetric(
                      label: 'Sunrise',
                      value: fmt.format(sun.sunrise),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SunMetric(
                      label: 'Sunset',
                      value: fmt.format(sun.sunset),
                    ),
                  ),
                  Expanded(
                    child: _SunMetric(
                      label: 'Dusk',
                      value: fmt.format(sun.civilTwilightEnd),
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

class _SunMetric extends StatelessWidget {
  const _SunMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
