import 'package:flutter/material.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

class PrayerMonthlyGrid extends StatelessWidget {
  const PrayerMonthlyGrid({
    super.key,
    required this.year,
    required this.month,
    required this.dayColumns,
  });

  final int year;
  final int month;
  final List<List<PrayerLogLocal>> dayColumns;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = dayColumns.length;
    const prayers = PrayerName.values;
    const cell = 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: cell * prayers.length + 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    ...prayers.map(
                      (p) => SizedBox(
                        height: cell,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            PrayerRepository.label(p),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var d = 0; d < daysInMonth; d++) ...[
                        Column(
                          children: [
                            Text('${d + 1}', style: const TextStyle(fontSize: 10)),
                            ...prayers.map((p) {
                              PrayerLogLocal? log;
                              for (final l in dayColumns[d]) {
                                if (l.prayer == p) {
                                  log = l;
                                  break;
                                }
                              }
                              final status = log?.status ?? PrayerStatus.none;
                              return Container(
                                width: cell,
                                height: cell,
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: PrayerRepository.gridColor(status),
                                  border: Border.all(color: Colors.black26),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
