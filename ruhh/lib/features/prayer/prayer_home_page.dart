import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

class PrayerHomePage extends ConsumerStatefulWidget {
  const PrayerHomePage({super.key});

  @override
  ConsumerState<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends ConsumerState<PrayerHomePage> {
  DateTime _selected = DateTime.now();

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selected);

  @override
  Widget build(BuildContext context) {
    ref.watch(prayerRefreshProvider);
    final repoAsync = ref.watch(prayerRepositoryProvider);
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final canGoNext = _dateKey.compareTo(todayKey) < 0;

    return repoAsync.when(
      data: (r) => FutureBuilder(
        future: Future.wait([
          r.displayTimesForDay(_selected),
          r.logsForDay(_selected),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final times = snap.data![0] as Map<PrayerName, String>;
          final logs = snap.data![1] as Map<PrayerName, PrayerLogLocal>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    iconSize: 32,
                    onPressed: () => setState(() {
                      _selected = _selected.subtract(const Duration(days: 1));
                    }),
                    icon: const Icon(Icons.navigate_before),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selected,
                          firstDate: DateTime(2020),
                          lastDate: today,
                        );
                        if (picked != null) {
                          setState(() => _selected = picked);
                        }
                      },
                      child: Text(
                        _dateKey,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 32,
                    onPressed: canGoNext
                        ? () => setState(() {
                              _selected = _selected.add(const Duration(days: 1));
                            })
                        : null,
                    icon: const Icon(Icons.navigate_next),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...PrayerName.values.map((p) {
                final status = logs[p]?.status ?? PrayerStatus.none;
                final time = times[p] ?? '--:--';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _PrayerRow(
                    prayer: p,
                    time: time.length >= 5 ? time.substring(0, 5) : time,
                    status: status,
                    onTap: () => _openStatusSheet(r, p, status),
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          );
        },
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
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.paddingOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: PrayerRepository.prayerAccent(prayer),
                child: Icon(
                  PrayerRepository.prayerIcon(prayer),
                  size: 32,
                  color: NBColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${PrayerRepository.label(prayer)} Prayer',
                style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...PrayerRepository.sheetStatuses.map(
                (s) => InkWell(
                  onTap: () async {
                    await repo.setStatus(prayer, s, day: _selected);
                    bumpPrayerRefresh(ref);
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: SizedBox(
                    height: 70,
                    child: Row(
                      children: [
                        Radio<PrayerStatus>(
                          value: s,
                          groupValue: current,
                          onChanged: (_) async {
                            await repo.setStatus(prayer, s, day: _selected);
                            bumpPrayerRefresh(ref);
                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() {});
                          },
                        ),
                        Expanded(
                          child: Text(
                            PrayerRepository.statusLabel(s),
                            style: Theme.of(ctx).textTheme.titleLarge,
                          ),
                        ),
                        Icon(
                          PrayerRepository.statusIcon(s),
                          size: 40,
                          color: PrayerRepository.statusColor(s),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.time,
    required this.status,
    required this.onTap,
  });

  final PrayerName prayer;
  final String time;
  final PrayerStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: NBColors.black, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                PrayerRepository.prayerAccent(prayer),
                            child: Icon(
                              PrayerRepository.prayerIcon(prayer),
                              color: NBColors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(time, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          PrayerRepository.label(prayer),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: PrayerRepository.statusRowTint(status),
                  alignment: Alignment.center,
                  child: Icon(
                    PrayerRepository.statusIcon(status),
                    size: 36,
                    color: PrayerRepository.statusColor(status),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
