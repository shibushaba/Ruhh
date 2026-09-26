import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/services/notification_channels.dart';
import 'package:ruhh/core/services/notification_navigation.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

/// Fires immediate budget threshold notifications (Section 2.4).
class BudgetNotificationAlerts {
  BudgetNotificationAlerts(
    this._notifications,
    this._settings,
    this._repo,
  );

  final NotificationService _notifications;
  final ModuleSettings _settings;
  final BudgetRepository _repo;

  Future<void> evaluateAfterExpense({
    required String categoryName,
    required DateTime month,
  }) async {
    if (!_settings.budgetEnabled || !_settings.notifyBudget) return;

    final budgets = await _repo.budgets();
    if (budgets.isEmpty) return;
    final budget = budgets.first;
    final limits = await _repo.categoryLimitsForBudget(budget.remoteId);
    CategoryBudgetLimitLocal? match;
    for (final l in limits) {
      if (l.categoryName == categoryName) {
        match = l;
        break;
      }
    }
    if (match == null) return;

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final spent = await _repo.categorySpentInRange(categoryName, start, end);
    final cap = match.limitAmount;
    if (cap <= 0) return;

    final tier = budgetAlertTier(spent: spent, limit: cap);
    if (tier == null) return;

    final pct = spent / cap;
    final id = 11000 + categoryName.hashCode.abs() % 1000;
    final daysLeft = end.day - month.day;
    if (tier == 'over') {
      await _notifications.showInstant(
        id: id,
        title: '$categoryName over budget',
        body:
            'You\'ve used ${(pct * 100).round()}% of your $categoryName limit this month.',
        payload: 'budget:$categoryName',
        channelId: RuhhNotificationChannels.budget,
      );
    } else {
      await _notifications.showInstant(
        id: id,
        title: '$categoryName nearing limit',
        body:
            '${(pct * 100).round()}% of your $categoryName budget is used with $daysLeft days left.',
        payload: 'budget:$categoryName',
        channelId: RuhhNotificationChannels.budget,
      );
    }
  }
}
