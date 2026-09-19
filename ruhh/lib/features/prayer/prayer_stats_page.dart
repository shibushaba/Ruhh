import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/widgets/prayer_monthly_grid.dart';
import 'package:ruhh/features/prayer/widgets/prayer_stats_widgets.dart';

class PrayerStatsPage extends ConsumerStatefulWidget {
  const PrayerStatsPage({super.key});

  @override
  ConsumerState<PrayerStatsPage> createState() => _PrayerStatsPageState();
}

class _PrayerStatsPageState extends ConsumerState<PrayerStatsPage> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  final _page = PageController();

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(prayerRefreshProvider);
    final repoAsync = ref.watch(prayerRepositoryProvider);
    return repoAsync.when(
      data: (r) => FutureBuilder(
        future: Future.wait([
          r.points(),
          r.streak(),
          r.groupPercent(),
          r.dailyChallengeFor(DateTime.now()),
          r.weeklyFajrChallenge(DateTime.now()),
          r.logsGridForMonth(_year, _month),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final points = snap.data![0] as int;
          final streak = snap.data![1] as int;
          final group = snap.data![2] as int;
          final daily = snap.data![3] as Map<PrayerName, bool>;
          final weekly = snap.data![4] as Map<int, PrayerStatus>;
          final grid = snap.data![5] as List<List<PrayerLogLocal>>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text('Progress',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showInfo(context),
                    icon: const Icon(Icons.info_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PrayerProgressCards(
                streak: streak,
                points: points,
                groupPercent: group,
              ),
              const SizedBox(height: 20),
              Text('Challenges',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: PageView(
                  controller: _page,
                  children: [
                    PrayerDailyChallenge(completed: daily),
                    PrayerWeeklyFajrChallenge(weekStatus: weekly),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Prayer log',
                      style: Theme.of(context).textTheme.headlineMedium),
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
                      Text('$_month/$_year'),
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
              NBCard(
                child: PrayerMonthlyGrid(
                  year: _year,
                  month: _month,
                  dayColumns: grid,
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How stats work'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Streak',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text(
                'This is the number of days you have completed all your prayers on time. Complete Daily challenge to increase your streak.',
              ),
              SizedBox(height: 16),
              Text('Score',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text(
                'This is the total number of points you have based on your prayer statuses.',
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoChip('Group (+2)', Color(0x8884BB58)),
                  _InfoChip('Alone (+1)', Color(0x8852BFD8)),
                  _InfoChip('Late (-2)', Color(0x77E49877)),
                  _InfoChip('Missed (-4)', Color(0x88DA5B5B)),
                ],
              ),
              SizedBox(height: 16),
              Text('Group',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text(
                'This is the percentage of group prayers you have completed.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }
}
