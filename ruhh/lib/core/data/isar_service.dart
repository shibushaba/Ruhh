import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/focus_session_local.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/todo_local.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
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
        HabitLogLocalSchema,
        TodoLocalSchema,
        FocusSessionLocalSchema,
        PrayerLogLocalSchema,
        PrayerTimeLocalSchema,
        DailyPrayerLogLocalSchema,
        MovieLocalSchema,
        MovieCategoryLocalSchema,
        WalletLocalSchema,
        CategoryLocalSchema,
        BudgetPeriodLocalSchema,
        ObjectiveLocalSchema,
        CategoryBudgetLimitLocalSchema,
        StandingSalaryLocalSchema,
      ],
      directory: dir.path,
      name: 'ruhh',
    );
    await _repairCorruptMovieCollectionsIfNeeded(_instance!);
    return _instance!;
  }

  /// Older app builds wrote [MovieLocal] / [MovieCategoryLocal] with a different
  /// field layout; reading them throws [RangeError] during Isar deserialize.
  static Future<void> _repairCorruptMovieCollectionsIfNeeded(Isar isar) async {
    var moviesOk = true;
    var categoriesOk = true;
    try {
      await isar.movieLocals.where().findAll();
    } catch (_) {
      moviesOk = false;
    }
    try {
      await isar.movieCategoryLocals.where().findAll();
    } catch (_) {
      categoriesOk = false;
    }
    if (moviesOk && categoriesOk) return;

    await isar.writeTxn(() async {
      if (!moviesOk) await isar.movieLocals.clear();
      if (!categoriesOk) await isar.movieCategoryLocals.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ruhh_movie_isar_repaired', true);
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  static Future<void> repairMovieCollections(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.movieLocals.clear();
      await isar.movieCategoryLocals.clear();
    });
  }

  /// Clears every local collection (dev / reset). App must restart Isar after this.
  static Future<void> wipeAllLocalData(Isar isar) async {
    await isar.writeTxn(() => isar.clear());
  }
}
