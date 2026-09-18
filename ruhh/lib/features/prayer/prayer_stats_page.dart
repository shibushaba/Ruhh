import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

class PrayerStatsPage extends ConsumerStatefulWidget {
  const PrayerStatsPage({super.key});

  @override
  ConsumerState<PrayerStatsPage> createState() => _PrayerStatsPageState();
}

class _PrayerStatsPageState extends ConsumerState<PrayerStatsPage> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(prayerRepositoryProvider);
    return repo.when(
      data: (r) => NBModuleScaffold(
        title: 'Prayer stats',
        body: FutureBuilder(
          future: Future.wait([
            r.logsInMonth(_year, _month),
            r.points(),
            r.streak(),
            r.qadhaCount(),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final logs = snap.data![0] as List<PrayerLogLocal>;
            final points = snap.data![1] as int;
            final streak = snap.data![2] as int;
            final qadha = snap.data![3] as int;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                NBCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_month/$_year'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              if (_month == 1) {
                                _month = 12;
                                _year--;
                              } else {
                                _month--;
                              }
                            }),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              if (_month == 12) {
                                _month = 1;
                                _year++;
                              } else {
                                _month++;
                              }
                            }),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                NBCard(
                  color: NBColors.prayer.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score: $points'),
                      Text('Streak: $streak days'),
                      Text('Missed (all time logs): $qadha'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Monthly log', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...logs.map(
                  (l) => ListTile(
                    title: Text(
                      '${l.day.toIso8601String().split('T').first} · ${PrayerRepository.label(l.prayer)}',
                    ),
                    subtitle: Text(PrayerRepository.statusLabel(l.status)),
                    leading: CircleAvatar(
                      backgroundColor:
                          PrayerRepository.statusColor(l.status),
                      radius: 8,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
