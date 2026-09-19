import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ruhh/core/theme/ruhh_tokens.dart';

import 'package:ruhh/core/widgets/nb_layout.dart';

import 'package:ruhh/features/prayer/prayer_repository.dart';

import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';

import 'package:ruhh/features/prayer/widgets/prayer_stats_sections.dart';



class PrayerStatsPage extends ConsumerStatefulWidget {

  const PrayerStatsPage({super.key});



  @override

  ConsumerState<PrayerStatsPage> createState() => _PrayerStatsPageState();

}



class _PrayerStatsPageState extends ConsumerState<PrayerStatsPage> {

  late DateTime _month;



  @override

  void initState() {

    super.initState();

    final now = DateTime.now();

    _month = DateTime(now.year, now.month);

  }



  @override

  Widget build(BuildContext context) {

    final logsAsync = ref.watch(dailyPrayerLogsProvider);

    final repoAsync = ref.watch(prayerRepositoryProvider);

    final t = context.ruhh;



    return repoAsync.when(

      loading: () => const Center(child: CircularProgressIndicator()),

      error: (e, _) => Center(child: Text('$e')),

      data: (repo) => logsAsync.when(

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text('$e')),

        data: (logs) {

          final todayKey = repo.todayKey;

          final now = DateTime.now();

          final currentMonth = DateTime(now.year, now.month);

          final canGoNext = _month.isBefore(currentMonth);



          final monthStats = monthlyStats(

            year: _month.year,

            month: _month.month,

            logsByDate: logs,

            todayKey: todayKey,

          );

          final summary = repo.computeSummary(logs);

          final periodDays = daysInStatsPeriod(_month, todayKey);

          final insights = buildPrayerStatsInsights(

            stats: monthStats,

            daysInPeriod: periodDays,

            currentStreak: summary.currentStreak,

            perPrayer: monthStats.perPrayerCompletion,

          );

          final week = lastSevenDays(logs, todayKey);



          return NBPageBody(

            child: ListView(

              children: [

                PrayerStatsMonthHeader(

                  month: _month,

                  canGoNext: canGoNext,

                  onPrevious: () => setState(() {

                    _month = DateTime(_month.year, _month.month - 1);

                  }),

                  onNext: () {

                    if (!canGoNext) return;

                    setState(() {

                      _month = DateTime(_month.year, _month.month + 1);

                    });

                  },

                ),

                const SizedBox(height: 8),

                PrayerStatsStreakHero(

                  current: summary.currentStreak,

                  longest: summary.longestStreak,

                ),

                SizedBox(height: t.spaceStackGap),

                Text(

                  'Month snapshot',

                  style: t.cardTitle(Theme.of(context).textTheme),

                ),

                const SizedBox(height: 8),

                PrayerStatsMonthBreakdown(

                  stats: monthStats,

                  daysInPeriod: periodDays,

                ),

                SizedBox(height: t.spaceStackGap),

                PrayerStatsInsights(lines: insights),

                SizedBox(height: t.spaceStackGap),

                if (_month.year == now.year && _month.month == now.month) ...[

                  PrayerStatsRecentWeek(days: week, todayKey: todayKey),

                  SizedBox(height: t.spaceStackGap),

                ],

                PrayerStatsPerPrayerSection(

                  perPrayer: monthStats.perPrayerCompletion,

                  daysInPeriod: periodDays,

                ),

                const SizedBox(height: 48),

              ],

            ),

          );

        },

      ),

    );

  }

}


