import 'package:shared_preferences/shared_preferences.dart';

abstract final class NotificationPrefs {
  static const streakMinuteKey = 'notif_streak_minute_of_day';
  static const defaultStreakMinute = 20 * 60; // 8:00 PM

  static Future<int> streakMinuteOfDay() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(streakMinuteKey) ?? defaultStreakMinute;
  }

  static Future<void> setStreakMinuteOfDay(int minute) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(streakMinuteKey, minute);
  }
}
