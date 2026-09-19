import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/focus_session_local.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/todo_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/data/models/user_local.dart';

class IsarService {
  IsarService._();
  static Isar? _instance;

  static Future<Isar> open() async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        UserLocalSchema,
        TransactionLocalSchema,
        HabitLocalSchema,
        HabitCompletionLocalSchema,
        TodoLocalSchema,
        FocusSessionLocalSchema,
        PrayerLogLocalSchema,
        PrayerTimeLocalSchema,
        MovieLocalSchema,
        WalletLocalSchema,
        CategoryLocalSchema,
        BudgetPeriodLocalSchema,
        ObjectiveLocalSchema,
        CategoryBudgetLimitLocalSchema,
      ],
      directory: dir.path,
      name: 'ruhh',
    );
    return _instance!;
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
