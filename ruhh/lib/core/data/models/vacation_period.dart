import 'package:ruhh/features/habit/habit_logic.dart';

class VacationPeriod {
  VacationPeriod({required DateTime start, DateTime? end, this.bulk = false})
      : start = HabitLogic.dayOnly(start),
        end = end != null ? HabitLogic.dayOnly(end) : null;

  final DateTime start;
  final DateTime? end;
  final bool bulk;

  bool get isOngoing => end == null;

  bool contains(DateTime date) {
    final day = HabitLogic.dayOnly(date);
    if (day.isBefore(start)) return false;
    final upper = end ?? HabitLogic.dayOnly(DateTime.now());
    return !day.isAfter(upper);
  }

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        if (end != null) 'end': end!.toIso8601String(),
        if (bulk) 'bulk': true,
      };

  VacationPeriod copyWith({DateTime? end}) =>
      VacationPeriod(start: start, end: end ?? this.end, bulk: bulk);

  factory VacationPeriod.fromJson(Map<String, dynamic> map) => VacationPeriod(
        start: DateTime.parse(map['start'] as String),
        end: map['end'] != null ? DateTime.tryParse(map['end'] as String) : null,
        bulk: map['bulk'] == true,
      );
}
