import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

class PrayerPage extends ConsumerStatefulWidget {
  const PrayerPage({super.key});

  @override
  ConsumerState<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends ConsumerState<PrayerPage> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(prayerRepositoryProvider);
    final fmt = DateFormat.yMMMEd();
    final timeFmt = DateFormat.jm();

    return repo.when(
      data: (r) => NBModuleScaffold(
        title: 'Prayer',
        actions: [
          IconButton(
            onPressed: () => context.push('/prayer/stats'),
            icon: const Icon(Icons.leaderboard),
          ),
        ],
        body: FutureBuilder(
          future: Future.wait([
            r.timesFor(_selected),
            r.logsForDay(_selected),
            r.points(),
            r.qadhaCount(),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final times = snap.data![0] as PrayerTimes;
            final logs = snap.data![1] as Map<PrayerName, PrayerLogLocal>;
            final points = snap.data![2] as int;
            final qadha = snap.data![3] as int;
            final entries = [
              (PrayerName.fajr, times.fajr),
              (PrayerName.dhuhr, times.dhuhr),
              (PrayerName.asr, times.asr),
              (PrayerName.maghrib, times.maghrib),
              (PrayerName.isha, times.isha),
            ];
            final today = DateTime.now();
            final canGoNext = _selected.isBefore(
              DateTime(today.year, today.month, today.day),
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                NBCard(
                  child: Row(
                    children: [
                      NBButton(
                        expand: false,
                        label: '<',
                        color: NBColors.offWhite,
                        onPressed: () => setState(() {
                          _selected = _selected.subtract(const Duration(days: 1));
                        }),
                      ),
                      Expanded(
                        child: Text(
                          fmt.format(_selected),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      NBButton(
                        expand: false,
                        label: '>',
                        color: NBColors.offWhite,
                        onPressed: canGoNext
                            ? () => setState(() {
                                  _selected =
                                      _selected.add(const Duration(days: 1));
                                })
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NBCard(
                        color: NBColors.prayer.withValues(alpha: 0.35),
                        child: Text('Points: $points'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NBCard(
                        child: Text('Qadha backlog: $qadha'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...entries.map((e) {
                  final status =
                      logs[e.$1]?.status ?? PrayerStatus.none;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NBCard(
                      color: PrayerRepository.statusColor(status)
                          .withValues(alpha: 0.35),
                      onTap: () => _openStatusSheet(r, e.$1, status),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PrayerRepository.label(e.$1),
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(timeFmt.format(e.$2)),
                                Text(PrayerRepository.statusLabel(status)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Future<void> _openStatusSheet(
    PrayerRepository repo,
    PrayerName prayer,
    PrayerStatus current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${PrayerRepository.label(prayer)} prayer',
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              ...[
                PrayerStatus.onTimeAlone,
                PrayerStatus.withGroup,
                PrayerStatus.lateAlone,
                PrayerStatus.missed,
                PrayerStatus.qadha,
              ].map(
                (s) => NBStatusChip(
                  label: PrayerRepository.statusLabel(s),
                  color: PrayerRepository.statusColor(s),
                  selected: s == current,
                  onTap: () async {
                    await repo.setStatus(prayer, s, day: _selected);
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
