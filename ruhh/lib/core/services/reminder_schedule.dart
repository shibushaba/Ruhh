abstract final class ReminderSchedule {
  static int habitReminderId(String habitId, String reminderId, int weekday) {
    final hash = Object.hash(habitId, reminderId, weekday);
    return 20000 + (hash.abs() % 8000);
  }

  static int todoReminderId(String todoId) {
    final hash = todoId.hashCode;
    return 28000 + (hash.abs() % 2000);
  }
}
