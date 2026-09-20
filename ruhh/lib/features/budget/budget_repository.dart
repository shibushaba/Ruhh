import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/services/local_data_sync.dart';
import 'package:ruhh/core/services/overlay_runtime.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/budget/budget_defaults.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';
import 'package:ruhh/features/budget/ledger/budget_calculations.dart';
import 'package:ruhh/features/budget/ledger/budget_category_ids.dart';
import 'package:ruhh/features/budget/ledger/budget_month_key.dart';
import 'package:ruhh/features/budget/ledger/budget_salary_engine.dart';
import 'package:uuid/uuid.dart';

part 'budget_repository_ledger.dart';

class MonthRange {
  MonthRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

MonthRange monthRange(DateTime month) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  return MonthRange(start, end);
}

class WalletBalance {
  WalletBalance(this.wallet, this.balance);
  final WalletLocal wallet;
  final double balance;
}

class BudgetRepository {
  BudgetRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  Isar get isar => _isar;
  String get userId => _userId;
  static const _uuid = Uuid();

  void _markCloudBackupNeeded() => notifyLocalDataChanged();

  String newRemoteId() => _uuid.v4();

  Future<void> ensureDefaults() async {
    final walletCount =
        await _isar.walletLocals.filter().userIdEqualTo(_userId).count();
    if (walletCount == 0) {
      await _isar.writeTxn(() async {
        await _isar.walletLocals.put(
          WalletLocal()
            ..remoteId = _uuid.v4()
            ..userId = _userId
            ..name = 'Cash'
            ..currency = 'INR'
            ..colorValue = NBColors.budget.toARGB32()
            ..sortOrder = 0
            ..openingBalance = 0,
        );
      });
    }
    final catCount =
        await _isar.categoryLocals.filter().userIdEqualTo(_userId).count();
    if (catCount == 0) {
      await _isar.writeTxn(() async {
        for (final c in indianDefaultCategories) {
          await _isar.categoryLocals.put(
            CategoryLocal()
              ..remoteId = c.remoteId
              ..userId = _userId
              ..name = c.name
              ..isIncome = c.isIncome
              ..colorValue = c.color.toARGB32()
              ..sortOrder = c.sortOrder
              ..iconKey = c.iconKey
              ..emoji = defaultCategoryEmoji(c.name)
              ..isCustom = false
              ..isArchived = false,
          );
        }
      });
    }
    await migrateLedgerFields();
    await ensureMonthlySalary();
    await backfillCategoryEmojis();
  }

  Future<void> backfillCategoryEmojis() async {
    await _isar.writeTxn(() async {
      final cats = await _isar.categoryLocals
          .filter()
          .userIdEqualTo(_userId)
          .findAll();
      for (final c in cats) {
        if (c.emoji.trim().isNotEmpty) continue;
        final emoji = defaultCategoryEmoji(c.name);
        if (emoji.isEmpty) continue;
        c.emoji = emoji;
        await _isar.categoryLocals.put(c);
      }
    });
  }

  Future<List<TransactionLocal>> getAll() => _isar.transactionLocals
      .filter()
      .userIdEqualTo(_userId)
      .sortByOccurredAtDesc()
      .findAll();

  Future<List<TransactionLocal>> forMonth(DateTime month) async {
    final range = monthRange(month);
    final all = await _rangeTransactions(range.start, range.end);
    return all
        .where((t) =>
            t.scheduleType == BudgetScheduleType.normal ||
            (t.paid && t.scheduleType != BudgetScheduleType.normal))
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  Future<List<TransactionLocal>> scheduledUnpaid() async {
    final all = await getAll();
    return all
        .where((t) =>
            t.scheduleType != BudgetScheduleType.normal && !t.paid)
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }

  Future<List<TransactionLocal>> overdueScheduled() async {
    final scheduled = await scheduledUnpaid();
    return scheduled.where(isTransactionOverdue).toList();
  }

  Future<TransactionLocal?> getTransaction(int id) =>
      _isar.transactionLocals.get(id);

  Future<List<WalletLocal>> wallets() => _isar.walletLocals
      .filter()
      .userIdEqualTo(_userId)
      .sortBySortOrder()
      .findAll();

  Future<List<CategoryLocal>> categories({bool? income}) async {
    final all = await _isar.categoryLocals
        .filter()
        .userIdEqualTo(_userId)
        .sortBySortOrder()
        .findAll();
    if (income == null) return all;
    return all.where((c) => c.isIncome == income).toList();
  }

  Future<List<BudgetPeriodLocal>> budgets({bool hideArchived = true}) async {
    final all = await _isar.budgetPeriodLocals
        .filter()
        .userIdEqualTo(_userId)
        .findAll();
    if (!hideArchived) return all;
    return all.where((b) => !b.archived).toList();
  }

  Future<void> add({
    required double amount,
    required bool isIncome,
    required String category,
    String account = 'Cash',
    String title = '',
    String note = '',
    DateTime? occurredAt,
    BudgetScheduleType scheduleType = BudgetScheduleType.normal,
    bool? paid,
    String recurrence = 'none',
    int periodLength = 1,
    DateTime? recurrenceEnd,
    String? objectiveRemoteId,
  }) async {
    final when = occurredAt ?? DateTime.now();
    final isScheduled = scheduleType != BudgetScheduleType.normal;
    final tx = TransactionLocal()
      ..remoteId = _uuid.v4()
      ..userId = _userId
      ..amount = amount
      ..isIncome = isIncome
      ..title = title
      ..category = category
      ..account = account
      ..note = note
      ..occurredAt = when
      ..scheduleType = scheduleType
      ..paid = paid ?? (!isScheduled)
      ..recurrence = isScheduled && recurrence == 'none' ? 'monthly' : recurrence
      ..periodLength = periodLength
      ..recurrenceEnd = recurrenceEnd
      ..objectiveRemoteId = objectiveRemoteId;
    await _isar.writeTxn(() => _isar.transactionLocals.put(tx));
    _markCloudBackupNeeded();
  }

  Future<void> markScheduledPaid(int id) async {
    final tx = await getTransaction(id);
    if (tx == null || tx.scheduleType == BudgetScheduleType.normal) return;
    tx.paid = true;
    if (tx.occurredAt.isAfter(DateTime.now())) {
      tx.occurredAt = DateTime.now();
    }
    await updateTransaction(tx);
    if (tx.scheduleType == BudgetScheduleType.repetitive ||
        tx.scheduleType == BudgetScheduleType.subscription) {
      await _spawnNextOccurrence(tx);
    }
  }

  Future<void> skipScheduled(int id) async {
    final tx = await getTransaction(id);
    if (tx == null || tx.scheduleType == BudgetScheduleType.normal) return;
    if (tx.scheduleType == BudgetScheduleType.upcoming) {
      await delete(id);
      return;
    }
    final next = addRecurrence(tx.occurredAt, tx.recurrence, tx.periodLength);
    if (tx.recurrenceEnd != null && next.isAfter(tx.recurrenceEnd!)) {
      await delete(id);
      return;
    }
    tx.occurredAt = next;
    tx.paid = false;
    await updateTransaction(tx);
  }

  Future<void> _spawnNextOccurrence(TransactionLocal paid) async {
    var nextDate =
        addRecurrence(paid.occurredAt, paid.recurrence, paid.periodLength);
    if (paid.recurrenceEnd != null && nextDate.isAfter(paid.recurrenceEnd!)) {
      return;
    }
    await add(
      amount: paid.amount,
      isIncome: paid.isIncome,
      category: paid.category,
      account: paid.account,
      title: paid.title,
      note: paid.note,
      occurredAt: nextDate,
      scheduleType: paid.scheduleType,
      paid: false,
      recurrence: paid.recurrence,
      periodLength: paid.periodLength,
      recurrenceEnd: paid.recurrenceEnd,
      objectiveRemoteId: paid.objectiveRemoteId,
    );
  }

  Future<void> updateTransaction(TransactionLocal tx) async {
    await _isar.writeTxn(() => _isar.transactionLocals.put(tx));
    _markCloudBackupNeeded();
  }

  Future<void> delete(Id id) async {
    await _isar.writeTxn(() => _isar.transactionLocals.delete(id));
    _markCloudBackupNeeded();
  }

  Future<double> walletBalance(WalletLocal wallet) async {
    final txs = await _isar.transactionLocals
        .filter()
        .userIdEqualTo(_userId)
        .accountEqualTo(wallet.name)
        .findAll();
    var balance = wallet.openingBalance;
    if (!balance.isFinite) balance = 0;
    for (final t in txs) {
      if (!transactionCountsInLedger(t)) continue;
      final amount = t.amount;
      if (!amount.isFinite) continue;
      balance += t.isIncome ? amount : -amount;
    }
    return balance.isFinite ? balance : 0;
  }

  Future<List<WalletBalance>> allWalletBalances() async {
    final ws = await wallets();
    final out = <WalletBalance>[];
    for (final w in ws) {
      out.add(WalletBalance(w, await walletBalance(w)));
    }
    return out;
  }

  Future<double> spentInRange(DateTime start, DateTime end) async {
    final txs = await _rangeTransactions(start, end);
    return txs
        .where((t) => !t.isIncome && transactionCountsInLedger(t))
        .fold<double>(0, (s, t) => s + t.amount);
  }

  Future<double> incomeInRange(DateTime start, DateTime end) async {
    final txs = await _rangeTransactions(start, end);
    return txs
        .where((t) => t.isIncome && transactionCountsInLedger(t))
        .fold<double>(0, (s, t) => s + t.amount);
  }

  Future<double> spentThisMonth([DateTime? month]) async {
    final m = month ?? DateTime.now();
    final range = monthRange(m);
    return spentInRange(range.start, range.end);
  }

  Future<Map<String, double>> spendByCategoryInRange(
    DateTime start,
    DateTime end,
  ) async {
    final txs = await _rangeTransactions(start, end);
    final map = <String, double>{};
    for (final t in txs.where((x) => !x.isIncome && transactionCountsInLedger(x))) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Future<Map<String, double>> spendByCategoryThisMonth([DateTime? month]) async {
    final m = month ?? DateTime.now();
    final range = monthRange(m);
    return spendByCategoryInRange(range.start, range.end);
  }

  Future<List<TransactionLocal>> recent({int limit = 12}) async {
    final all = await getAll();
    return all.take(limit).toList();
  }

  Future<List<TransactionLocal>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    final all = await getAll();
    return all
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.note.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            t.account.toLowerCase().contains(q))
        .toList();
  }

  Future<void> upsertWallet({
    Id? id,
    required String name,
    String currency = 'USD',
    int? colorValue,
    double openingBalance = 0,
  }) async {
    await _isar.writeTxn(() async {
      WalletLocal w;
      if (id != null) {
        w = (await _isar.walletLocals.get(id))!;
        w.name = name;
        w.currency = currency;
        w.openingBalance = openingBalance;
        if (colorValue != null) w.colorValue = colorValue;
      } else {
        final count =
            await _isar.walletLocals.filter().userIdEqualTo(_userId).count();
        w = WalletLocal()
          ..remoteId = _uuid.v4()
          ..userId = _userId
          ..name = name
          ..currency = currency
          ..colorValue = colorValue ?? NBColors.budget.toARGB32()
          ..sortOrder = count
          ..openingBalance = openingBalance;
      }
      await _isar.walletLocals.put(w);
    });
    _markCloudBackupNeeded();
  }

  Future<void> deleteWallet(Id id) async {
    await _isar.writeTxn(() => _isar.walletLocals.delete(id));
    _markCloudBackupNeeded();
  }

  Future<void> upsertCategory({
    Id? id,
    required String name,
    required bool isIncome,
    int? colorValue,
    int? sortOrder,
    String? emoji,
  }) async {
    await _isar.writeTxn(() async {
      CategoryLocal c;
      if (id != null) {
        c = (await _isar.categoryLocals.get(id))!;
        c.name = name;
        c.isIncome = isIncome;
        if (colorValue != null) c.colorValue = colorValue;
        if (emoji != null) c.emoji = emoji;
      } else {
        final count =
            await _isar.categoryLocals.filter().userIdEqualTo(_userId).count();
        c = CategoryLocal()
          ..remoteId = newRemoteId()
          ..userId = _userId
          ..name = name
          ..isIncome = isIncome
          ..colorValue = colorValue ?? NBColors.budget.toARGB32()
          ..sortOrder = sortOrder ?? count
          ..isCustom = true
          ..iconKey = 'label'
          ..emoji = (emoji != null && emoji.trim().isNotEmpty)
              ? emoji.trim()
              : defaultCategoryEmoji(name);
      }
      await _isar.categoryLocals.put(c);
    });
    _markCloudBackupNeeded();
  }

  Future<void> deleteCategory(Id id) async {
    await _isar.writeTxn(() async {
      final c = await _isar.categoryLocals.get(id);
      if (c == null) return;
      c.isArchived = true;
      await _isar.categoryLocals.put(c);
    });
    _markCloudBackupNeeded();
  }

  Future<void> upsertBudgetPeriod({
    Id? id,
    required String name,
    required double limitAmount,
    String period = 'monthly',
    DateTime? startsAt,
    int? colorValue,
    bool archived = false,
  }) async {
    await _isar.writeTxn(() async {
      BudgetPeriodLocal b;
      if (id != null) {
        b = (await _isar.budgetPeriodLocals.get(id))!;
        b.name = name;
        b.limitAmount = limitAmount;
        b.period = period;
        b.archived = archived;
        if (startsAt != null) b.startsAt = startsAt;
        if (colorValue != null) b.colorValue = colorValue;
      } else {
        b = BudgetPeriodLocal()
          ..remoteId = _uuid.v4()
          ..userId = _userId
          ..name = name
          ..limitAmount = limitAmount
          ..period = period
          ..startsAt = startsAt ?? DateTime(DateTime.now().year, DateTime.now().month)
          ..colorValue = colorValue ?? NBColors.budget.toARGB32()
          ..archived = archived;
      }
      await _isar.budgetPeriodLocals.put(b);
    });
    _markCloudBackupNeeded();
  }

  Future<void> deleteBudgetPeriod(Id id) async {
    await _isar.writeTxn(() async {
      final b = await _isar.budgetPeriodLocals.get(id);
      if (b != null) {
        final limits = await _isar.categoryBudgetLimitLocals
            .filter()
            .userIdEqualTo(_userId)
            .budgetRemoteIdEqualTo(b.remoteId)
            .findAll();
        for (final l in limits) {
          await _isar.categoryBudgetLimitLocals.delete(l.id);
        }
      }
      await _isar.budgetPeriodLocals.delete(id);
    });
    _markCloudBackupNeeded();
  }

  // ——— Objectives ———

  Future<List<ObjectiveLocal>> objectives({bool hideArchived = true}) async {
    final all = await _isar.objectiveLocals
        .filter()
        .userIdEqualTo(_userId)
        .sortBySortOrder()
        .findAll();
    if (!hideArchived) return all;
    return all.where((o) => !o.archived).toList();
  }

  Future<double> objectiveContributed(ObjectiveLocal objective) async {
    final txs = await getAll();
    return txs
        .where((t) =>
            t.objectiveRemoteId == objective.remoteId &&
            transactionCountsInLedger(t))
        .fold<double>(0, (s, t) => s + t.amount);
  }

  Future<void> upsertObjective({
    Id? id,
    required String name,
    required double targetAmount,
    String kind = 'savings',
    String walletName = 'Cash',
    int? colorValue,
    bool pinned = true,
    bool archived = false,
    DateTime? endDate,
  }) async {
    await _isar.writeTxn(() async {
      ObjectiveLocal o;
      if (id != null) {
        o = (await _isar.objectiveLocals.get(id))!;
        o.name = name;
        o.targetAmount = targetAmount;
        o.kind = kind;
        o.walletName = walletName;
        o.pinned = pinned;
        o.archived = archived;
        o.endDate = endDate;
        if (colorValue != null) o.colorValue = colorValue;
      } else {
        final count =
            await _isar.objectiveLocals.filter().userIdEqualTo(_userId).count();
        o = ObjectiveLocal()
          ..remoteId = _uuid.v4()
          ..userId = _userId
          ..name = name
          ..targetAmount = targetAmount
          ..kind = kind
          ..walletName = walletName
          ..colorValue = colorValue ?? NBColors.budget.toARGB32()
          ..pinned = pinned
          ..archived = archived
          ..endDate = endDate
          ..sortOrder = count;
      }
      await _isar.objectiveLocals.put(o);
    });
    _markCloudBackupNeeded();
  }

  Future<void> deleteObjective(Id id) async {
    await _isar.writeTxn(() => _isar.objectiveLocals.delete(id));
    _markCloudBackupNeeded();
  }

  // ——— Category budget limits ———

  Future<List<CategoryBudgetLimitLocal>> categoryLimitsForBudget(
    String budgetRemoteId,
  ) =>
      _isar.categoryBudgetLimitLocals
          .filter()
          .userIdEqualTo(_userId)
          .budgetRemoteIdEqualTo(budgetRemoteId)
          .findAll();

  Future<double> categorySpentInRange(
    String categoryName,
    DateTime start,
    DateTime end,
  ) async {
    final txs = await _rangeTransactions(start, end);
    return txs
        .where((t) =>
            t.category == categoryName &&
            !t.isIncome &&
            transactionCountsInLedger(t))
        .fold<double>(0, (s, t) => s + t.amount);
  }

  Future<void> upsertCategoryLimit({
    Id? id,
    required String budgetRemoteId,
    required String categoryName,
    required double limitAmount,
  }) async {
    await _isar.writeTxn(() async {
      CategoryBudgetLimitLocal l;
      if (id != null) {
        l = (await _isar.categoryBudgetLimitLocals.get(id))!;
        l.categoryName = categoryName;
        l.limitAmount = limitAmount;
      } else {
        l = CategoryBudgetLimitLocal()
          ..remoteId = _uuid.v4()
          ..userId = _userId
          ..budgetRemoteId = budgetRemoteId
          ..categoryName = categoryName
          ..limitAmount = limitAmount;
      }
      await _isar.categoryBudgetLimitLocals.put(l);
    });
    _markCloudBackupNeeded();
  }

  Future<void> deleteCategoryLimit(Id id) async {
    await _isar.writeTxn(() => _isar.categoryBudgetLimitLocals.delete(id));
    _markCloudBackupNeeded();
  }

  Future<List<TransactionLocal>> _rangeTransactions(
    DateTime start,
    DateTime end,
  ) =>
      _isar.transactionLocals
          .filter()
          .userIdEqualTo(_userId)
          .occurredAtGreaterThan(start, include: true)
          .occurredAtLessThan(end, include: false)
          .findAll();
}

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  final repo = BudgetRepository(isar, user.supabaseId ?? user.id.toString());
  await repo.ensureDefaults();
  await repo.ensureMonthlySalary();
  return repo;
});

/// Bump to refresh lists after mutations.
final budgetRefreshProvider = StateProvider<int>((ref) => 0);

void bumpBudgetRefresh(WidgetRef ref, {bool scheduleCloudSync = true}) {
  ref.read(budgetRefreshProvider.notifier).state++;
  if (scheduleCloudSync && !ruhhOverlayIsolate) {
    scheduleCloudSyncFromWidget(ref);
  }
}
