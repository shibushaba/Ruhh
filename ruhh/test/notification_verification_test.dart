import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/services/notification_navigation.dart';

void main() {
  group('Part 2.7 — notification tap routes', () {
    test('prayer payload opens prayer tab', () {
      final a = routeActionForPayload('prayer:fajr');
      expect(a?.kind, NotificationRouteKind.go);
      expect(a?.path, '/prayer');
    });

    test('habit payload opens habit detail', () {
      final a = routeActionForPayload('habit:abc-123');
      expect(a?.kind, NotificationRouteKind.push);
      expect(a?.path, '/habit/abc-123');
    });

    test('budget and home payloads', () {
      expect(routeActionForPayload('budget:food')?.path, '/budget');
      expect(routeActionForPayload('home')?.path, '/home');
      expect(routeActionForPayload('/settings')?.path, '/settings');
    });
  });

  group('Part 2.7 — streak protection scheduling', () {
    test('schedules when habits or prayer still open', () {
      expect(
        shouldScheduleStreakProtection(
          channelEnabled: true,
          habitsDone: 1,
          habitsDueToday: 3,
          prayerComplete: true,
        ),
        isTrue,
      );
      expect(
        shouldScheduleStreakProtection(
          channelEnabled: true,
          habitsDone: 3,
          habitsDueToday: 3,
          prayerComplete: false,
        ),
        isTrue,
      );
    });

    test('does not schedule when channel off or day complete', () {
      expect(
        shouldScheduleStreakProtection(
          channelEnabled: false,
          habitsDone: 0,
          habitsDueToday: 2,
          prayerComplete: false,
        ),
        isFalse,
      );
      expect(
        shouldScheduleStreakProtection(
          channelEnabled: true,
          habitsDone: 2,
          habitsDueToday: 2,
          prayerComplete: true,
        ),
        isFalse,
      );
      expect(
        shouldScheduleStreakProtection(
          channelEnabled: true,
          habitsDone: 0,
          habitsDueToday: 0,
          prayerComplete: true,
        ),
        isFalse,
      );
    });
  });

  group('Part 2.7 — budget threshold alerts', () {
    test('fires at 80% and 100%', () {
      expect(budgetAlertTier(spent: 79, limit: 100), isNull);
      expect(budgetAlertTier(spent: 80, limit: 100), 'nearing');
      expect(budgetAlertTier(spent: 100, limit: 100), 'over');
      expect(budgetAlertTier(spent: 120, limit: 100), 'over');
    });
  });
}
