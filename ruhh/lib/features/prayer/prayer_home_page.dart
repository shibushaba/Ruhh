import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
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
                        const SizedBox(height: 48),
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
