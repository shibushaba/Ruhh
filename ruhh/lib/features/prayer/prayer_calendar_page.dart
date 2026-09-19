import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import 'package:table_calendar/table_calendar.dart';

import 'package:ruhh/core/data/models/prayer_local.dart';

import 'package:ruhh/core/theme/ruhh_tokens.dart';

import 'package:ruhh/core/widgets/nb_layout.dart';

import 'package:ruhh/core/widgets/ruhh_components.dart';

import 'package:ruhh/features/prayer/prayer_repository.dart';

import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';

import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';

import 'package:ruhh/features/prayer/tracker/prayer_theme.dart';

import 'package:ruhh/features/prayer/widgets/prayer_tracker_widgets.dart';



class PrayerCalendarPage extends ConsumerStatefulWidget {

  const PrayerCalendarPage({super.key});



  @override

  ConsumerState<PrayerCalendarPage> createState() => _PrayerCalendarPageState();

}



class _PrayerCalendarPageState extends ConsumerState<PrayerCalendarPage> {

  DateTime _focused = DateTime.now();

  CalendarFormat _format = CalendarFormat.month;



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

          final monthStats = monthlyStats(
            year: _focused.year,
            month: _focused.month,
            logsByDate: logs,
            todayKey: todayKey,
          );

          final summary = repo.computeSummary(logs);



          return NBPageBody(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                _MonthSummaryCard(

                  month: _focused,

                  stats: monthStats,

                  streak: summary.currentStreak,

                ),

                const SizedBox(height: 12),

                const NBPrayerCalendarLegend(),

                const SizedBox(height: 12),

                Expanded(

                  child: RuhhSoftCard(

                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),

                    child: TableCalendar<void>(

                      firstDay: DateTime(2020),

                      lastDay: DateTime.now().add(const Duration(days: 365)),

                      focusedDay: _focused,

                      calendarFormat: _format,

                      onFormatChanged: (f) => setState(() => _format = f),

                      onPageChanged: (d) => setState(() => _focused = d),

                      rowHeight: 58,

                      daysOfWeekHeight: 26,

                      headerStyle: HeaderStyle(

                        formatButtonVisible: true,

                        titleCentered: true,

                        titleTextStyle: t.cardTitle(

                          Theme.of(context).textTheme,

                        ),

                        leftChevronIcon: Icon(

                          Icons.chevron_left,

                          color: t.textPrimary,

                        ),

                        rightChevronIcon: Icon(

                          Icons.chevron_right,

                          color: t.textPrimary,

                        ),

                        formatButtonTextStyle: t.caption(

                          Theme.of(context).textTheme,

                        ),

                        formatButtonDecoration: BoxDecoration(

                          borderRadius: BorderRadius.circular(t.radiusChip),

                          border: Border.all(color: t.textPrimary, width: 1),

                        ),

                      ),

                      daysOfWeekStyle: DaysOfWeekStyle(

                        weekdayStyle: t.micro(Theme.of(context).textTheme)

                            .copyWith(color: t.textSecondary),

                        weekendStyle: t.micro(Theme.of(context).textTheme)

                            .copyWith(color: t.textSecondary),

                      ),

                      calendarStyle: CalendarStyle(

                        outsideDaysVisible: false,

                        cellMargin: const EdgeInsets.all(1),

                        defaultTextStyle: Theme.of(context)

                            .textTheme

                            .labelLarge!

                            .copyWith(color: t.textPrimary),

                        weekendTextStyle: Theme.of(context)

                            .textTheme

                            .labelLarge!

                            .copyWith(color: t.textPrimary),

                        todayTextStyle: Theme.of(context)

                            .textTheme

                            .labelLarge!

                            .copyWith(color: t.textPrimary),

                        selectedTextStyle: Theme.of(context)

                            .textTheme

                            .labelLarge!

                            .copyWith(color: t.textPrimary),

                        todayDecoration: const BoxDecoration(

                          color: Colors.transparent,

                        ),

                        selectedDecoration: const BoxDecoration(

                          color: Colors.transparent,

                        ),

                        defaultDecoration: const BoxDecoration(

                          color: Colors.transparent,

                        ),

                        markerDecoration: const BoxDecoration(

                          color: Colors.transparent,

                        ),

                      ),

                      calendarBuilders: CalendarBuilders(

                        defaultBuilder: (context, day, focused) =>

                            _cell(context, day, logs, todayKey),

                        todayBuilder: (context, day, focused) =>

                            _cell(context, day, logs, todayKey),

                        selectedBuilder: (context, day, focused) =>

                            _cell(context, day, logs, todayKey),

                        outsideBuilder: (context, day, focused) =>

                            const SizedBox.shrink(),

                      ),

                      onDaySelected: (selected, focused) {

                        setState(() => _focused = focused);

                        if (selected.isAfter(DateTime.now())) return;

                        _openDaySheet(repo, selected, logs, todayKey);

                      },

                    ),

                  ),

                ),

              ],

            ),

          );

        },

      ),

    );

  }



  Widget _cell(

    BuildContext context,

    DateTime day,

    Map<String, DailyPrayerLog> logs,

    String todayKey,

  ) {

    final key = dateKeyFrom(day);

    final log = resolveDayLog(key, logs, todayKey);

    final kind = dayVisualKind(log, todayKey);

    return NBCalendarCell(

      day: day.day,

      kind: kind,

      log: log,

      isTodayHighlight: key == todayKey,

    );

  }



  Future<void> _openDaySheet(

    PrayerRepository repo,

    DateTime day,

    Map<String, DailyPrayerLog> logs,

    String todayKey,

  ) async {

    final key = dateKeyFrom(day);

    var log = resolveDayLog(key, logs, todayKey);

    final isToday = key == todayKey;

    final label = DateFormat.yMMMEd().format(day);



    await showModalBottomSheet<void>(

      context: context,

      showDragHandle: true,

      isScrollControlled: true,

      backgroundColor: Theme.of(context).colorScheme.surface,

      builder: (ctx) {

        return StatefulBuilder(

          builder: (ctx, setSheet) {

            final t = Theme.of(ctx).extension<RuhhTokens>()!;

            return Padding(

              padding: EdgeInsets.only(

                left: 16,

                right: 16,

                bottom: MediaQuery.paddingOf(ctx).bottom + 16,

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  Text(

                    label,

                    style: Theme.of(ctx).textTheme.titleLarge,

                    textAlign: TextAlign.center,

                  ),

                  const SizedBox(height: 4),

                  Text(

                    '${prayedCount(log)}/5 prayed',

                    textAlign: TextAlign.center,

                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(

                          color: t.textSecondary,

                        ),

                  ),

                  const SizedBox(height: 12),

                  ...prayerOrder.map((p) {

                    final prayed =

                        log.statuses[p] == TrackerPrayerStatus.prayed;

                    return NBPrayerCheckTile(

                      prayer: p,

                      prayed: prayed,

                      enabled: true,

                      onTap: () async {

                        log = await repo.toggleTrackerPrayer(key, p);

                        log = resolveDayLog(

                          key,

                          {...logs, key: log},

                          todayKey,

                        );

                        bumpPrayerRefresh(ref);

                        setSheet(() {});

                      },

                    );

                  }),

                  const SizedBox(height: 8),

                  RuhhSegmentedChips(

                    labels: const ['Normal', 'Excused'],

                    selectedIndex: log.isExcusedDay ? 1 : 0,

                    onSelected: (i) async {

                      log = await repo.setExcusedDay(key, i == 1);

                      bumpPrayerRefresh(ref);

                      setSheet(() {});

                    },

                  ),

                  if (!isToday) ...[

                    const SizedBox(height: 8),

                    Text(

                      'Tap each prayer to toggle prayed / missed.',

                      textAlign: TextAlign.center,

                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(

                            color: t.textSecondary,

                          ),

                    ),

                  ],

                ],

              ),

            );

          },

        );

      },

    );

  }

}



class _MonthSummaryCard extends StatelessWidget {

  const _MonthSummaryCard({

    required this.month,

    required this.stats,

    required this.streak,

  });



  final DateTime month;

  final MonthlyPrayerStats stats;

  final int streak;



  @override

  Widget build(BuildContext context) {

    final t = context.ruhh;

    final theme = Theme.of(context).textTheme;

    final pct = (stats.completionPercent * 100).round();



    return RuhhSoftCard(

      padding: const EdgeInsets.all(14),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text(

            DateFormat.yMMMM().format(month),

            style: t.cardTitle(theme),

          ),

          const SizedBox(height: 10),

          Row(

            children: [

              _StatPill(

                label: 'Perfect days',

                value: '${stats.fullyPrayedDays}',

                color: PrayerTheme.dhuhr,

              ),

              const SizedBox(width: 8),

              _StatPill(

                label: 'Completion',

                value: '$pct%',

                color: PrayerTheme.fajr,

              ),

              const SizedBox(width: 8),

              _StatPill(

                label: 'Streak',

                value: '$streak',

                color: PrayerTheme.maghrib,

              ),

            ],

          ),

        ],

      ),

    );

  }

}



class _StatPill extends StatelessWidget {

  const _StatPill({

    required this.label,

    required this.value,

    required this.color,

  });



  final String label;

  final String value;

  final Color color;



  @override

  Widget build(BuildContext context) {

    final t = context.ruhh;

    final theme = Theme.of(context).textTheme;

    return Expanded(

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

        decoration: BoxDecoration(

          color: color.withValues(alpha: 0.12),

          borderRadius: BorderRadius.circular(t.radiusChip),

          border: Border.all(color: color.withValues(alpha: 0.55)),

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(label, style: t.micro(theme)),

            Text(

              value,

              style: t.statMedium(theme).copyWith(color: color),

            ),

          ],

        ),

      ),

    );

  }

}


