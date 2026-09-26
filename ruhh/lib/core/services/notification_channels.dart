import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channel ids (Section 2.3).
abstract final class RuhhNotificationChannels {
  static const prayer = 'ruhh_prayer_reminders';
  static const habit = 'ruhh_habit_reminders';
  static const streak = 'ruhh_streak_protection';
  static const budget = 'ruhh_budget_alerts';
  static const recommendations = 'ruhh_recommendations';
  static const system = 'ruhh_system';

  static const all = [
    prayer,
    habit,
    streak,
    budget,
    recommendations,
    system,
  ];

  static AndroidNotificationDetails androidDetails(
    String channelId, {
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    final (name, description) = _labels[channelId]!;
    return AndroidNotificationDetails(
      channelId,
      name,
      channelDescription: description,
      importance: importance,
      priority: priority,
    );
  }

  static const _labels = <String, (String, String)>{
    prayer: (
      'Prayer Reminders',
      'Adhan-time reminders for each salāh',
    ),
    habit: (
      'Habit Reminders',
      'Per-habit reminders on due days',
    ),
    streak: (
      'Streak Protection',
      'Evening nudge when today is still open',
    ),
    budget: (
      'Budget Alerts',
      'When a category nears or crosses its limit',
    ),
    recommendations: (
      'Recommendations',
      'Weekly insights digest',
    ),
    system: (
      'System',
      'Permissions, sync, and app health',
    ),
  };
}
