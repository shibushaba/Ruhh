import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

class PrayerProgressCards extends StatelessWidget {
  const PrayerProgressCards({
    super.key,
    required this.streak,
    required this.points,
    required this.groupPercent,
  });

  final int streak;
  final int points;
  final int groupPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Streak',
            value: '$streak days',
            color: const Color(0x88FFD54F),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'Score',
            value: '$points',
            color: const Color(0x88B3E5FC),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'Group',
            value: '$groupPercent%',
            color: const Color(0x88C8E6C9),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NBCard(
      color: color,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class PrayerDailyChallenge extends StatelessWidget {
  const PrayerDailyChallenge({super.key, required this.completed});

  final Map<PrayerName, bool> completed;

  @override
  Widget build(BuildContext context) {
    return NBCard(
      color: NBColors.prayer.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Daily challenge',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const Text(
            'On time or with group for each prayer today',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: PrayerName.values.map((p) {
              final ok = completed[p] ?? false;
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ok ? const Color(0xFF13b601) : Colors.grey,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Icon(
                      ok ? Icons.check : Icons.close,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PrayerRepository.label(p),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class PrayerWeeklyFajrChallenge extends StatelessWidget {
  const PrayerWeeklyFajrChallenge({super.key, required this.weekStatus});

  final Map<int, PrayerStatus> weekStatus;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return NBCard(
      color: const Color(0x77E1BEE7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Fajr',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final s = weekStatus[i] ?? PrayerStatus.none;
              final ok = s == PrayerStatus.withGroup ||
                  s == PrayerStatus.onTimeAlone;
              return Column(
                children: [
                  Text(_days[i], style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ok
                          ? Colors.green
                          : PrayerRepository.gridColor(s),
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
