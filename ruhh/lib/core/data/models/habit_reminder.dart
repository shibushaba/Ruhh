class HabitReminder {
  const HabitReminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.days,
    this.message = '',
    this.everyDays = 1,
  });

  final String id;
  final int hour;
  final int minute;
  final List<int> days;
  final String message;
  final int everyDays;

  bool get isInterval => everyDays >= 2;

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'selectedDays': days,
        'message': message,
        'everyDays': everyDays,
      };

  factory HabitReminder.fromJson(Map<String, dynamic> map) => HabitReminder(
        id: map['id'] as String,
        hour: map['hour'] as int,
        minute: map['minute'] as int,
        days: List<int>.from((map['selectedDays'] ?? map['days']) as List),
        message: (map['message'] ?? '') as String,
        everyDays: (map['everyDays'] ?? 1) as int,
      );
}
