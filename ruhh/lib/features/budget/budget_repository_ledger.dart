part of 'budget_repository.dart';

const _ledgerBudgetRemoteId = 'inr-ledger';

extension BudgetRepositoryLedger on BudgetRepository {
  Future<void> migrateLedgerFields() async {
    final txs = await isar.transactionLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    await isar.writeTxn(() async {
      for (final t in txs) {
        budgetNormalizeTransaction(t);
        await isar.transactionLocals.put(t);
      }
      final limits = await isar.categoryBudgetLimitLocals
          .filter()
          .userIdEqualTo(userId)
          .findAll();
      for (final l in limits) {
        if (l.categoryRemoteId.isEmpty) {
          final cat = await isar.categoryLocals
              .filter()
              .userIdEqualTo(userId)
              .nameEqualTo(l.categoryName)
              .findFirst();
          l.categoryRemoteId = cat?.remoteId ?? l.categoryName;
        }
        if (l.budgetRemoteId.isEmpty) {
          l.budgetRemoteId = _ledgerBudgetRemoteId;
        }
        await isar.categoryBudgetLimitLocals.put(l);
      }
    });
  }

  Future<List<BudgetLedgerRow>> ledgerRows() async {
    final txs = await isar.transactionLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    final rows = <BudgetLedgerRow>[];
    for (final t in txs) {
      budgetNormalizeTransaction(t);
      if (!budgetTransactionInLedger(t)) continue;
      rows.add(
        BudgetLedgerRow(
          id: t.remoteId,
          type: t.ledgerType,
          amount: t.amount,
          categoryId: t.categoryRemoteId.isNotEmpty
              ? t.categoryRemoteId
              : t.category,
          monthKey: t.monthKey,
        ),
      );
    }
    return rows;
  }

  Future<List<BudgetRuleRow>> budgetRules() async {
    final limits = await isar.categoryBudgetLimitLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    return limits
        .map(
          (l) => BudgetRuleRow(
            categoryId: l.categoryRemoteId.isNotEmpty
                ? l.categoryRemoteId
                : l.categoryName,
            monthKey: l.monthKey,
            limitAmount: l.limitAmount,
            rolloverEnabled: l.rolloverEnabled,
          ),
        )
        .toList();
  }

  Future<BudgetMonthTotals> monthTotals(DateTime month) async {
    final key = budgetMonthKey(month);
    return BudgetCalculations.monthTotals(await ledgerRows(), key);
  }

  Future<Map<String, double>> expenseByCategory(DateTime month) async {
    final key = budgetMonthKey(month);
    return BudgetCalculations.expenseByCategory(await ledgerRows(), key);
  }

  Future<List<TransactionLocal>> ledgerTransactionsForMonth(DateTime month) async {
    final key = budgetMonthKey(month);
    final range = monthRange(month);
    final all = await isar.transactionLocals
        .filter()
        .userIdEqualTo(userId)
        .occurredAtGreaterThan(range.start, include: true)
        .occurredAtLessThan(range.end, include: false)
        .sortByOccurredAtDesc()
        .findAll();
    for (final t in all) {
      budgetNormalizeTransaction(t);
    }
    final stale = all.where((t) => t.monthKey != key).toList();
    if (stale.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final t in stale) {
          t.monthKey = key;
          await isar.transactionLocals.put(t);
        }
      });
    }
    return all.where(budgetTransactionInLedger).toList();
  }

  Future<StandingSalaryLocal?> standingSalary() async {
    return isar.standingSalaryLocals
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
  }

  Future<void> setStandingSalary(double amount) async {
    final key = budgetMonthKey(DateTime.now());
    await isar.writeTxn(() async {
      var row = await isar.standingSalaryLocals
          .filter()
          .userIdEqualTo(userId)
          .findFirst();
      row ??= StandingSalaryLocal()
        ..userId = userId
        ..effectiveFromMonthKey = key;
      row.amount = amount;
      if (row.effectiveFromMonthKey.isEmpty) {
        row.effectiveFromMonthKey = key;
      }
      await isar.standingSalaryLocals.put(row);
    });
    await ensureMonthlySalary();
    _markCloudBackupNeeded();
  }

  Future<void> ensureMonthlySalary() async {
    final standing = await standingSalary();
    if (standing == null || standing.amount <= 0) return;
    final monthKey = budgetMonthKey(DateTime.now());
    if (monthKey.compareTo(standing.effectiveFromMonthKey) < 0) return;

    final txs = await isar.transactionLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    if (BudgetSalaryEngine.hasSalaryForMonth(txs, monthKey)) return;

    final wallet = (await wallets()).firstOrNull?.name ?? 'Cash';
    final tx = BudgetSalaryEngine.buildAutoSalary(
      userId: userId,
      remoteId: newRemoteId(),
      amount: standing.amount,
      monthKey: monthKey,
      walletName: wallet,
    );
    await isar.writeTxn(() => isar.transactionLocals.put(tx));
    _markCloudBackupNeeded();
  }

  Future<void> upsertLedgerTransaction({
    Id? id,
    required BudgetLedgerType type,
    required double amount,
    required CategoryLocal category,
    String note = '',
    required DateTime date,
    bool? isAutoGenerated,
  }) async {
    if (amount <= 0) return;
    final walletName = (await wallets()).firstOrNull?.name ?? 'Cash';
    await isar.writeTxn(() async {
      TransactionLocal t;
      if (id != null) {
        t = (await isar.transactionLocals.get(id))!;
      } else {
        t = TransactionLocal()
          ..remoteId = newRemoteId()
          ..userId = userId
          ..scheduleType = BudgetScheduleType.normal
          ..paid = true
          ..recurrence = 'none'
          ..title = category.name;
      }
      t.amount = amount;
      t.ledgerType = type;
      t.isIncome = type != BudgetLedgerType.expense;
      t.category = category.name;
      t.categoryRemoteId = category.remoteId;
      t.note = note;
      t.occurredAt = date;
      t.monthKey = budgetMonthKey(date);
      t.account = walletName;
      if (isAutoGenerated != null) t.isAutoGenerated = isAutoGenerated;
      await isar.transactionLocals.put(t);
    });
    _markCloudBackupNeeded();
  }

  Future<void> deleteLedgerTransaction(Id id) async {
    await isar.writeTxn(() => isar.transactionLocals.delete(id));
    _markCloudBackupNeeded();
  }

  Future<List<CategoryLocal>> activeCategories({bool? income}) async {
    final all = await categories(income: income);
    return all.where((c) => !c.isArchived).toList();
  }

  Future<void> archiveCategory(CategoryLocal cat) async {
    await isar.writeTxn(() async {
      cat.isArchived = true;
      await isar.categoryLocals.put(cat);
    });
    _markCloudBackupNeeded();
  }

  Future<List<CategoryBudgetLimitLocal>> allCategoryBudgets() async {
    return isar.categoryBudgetLimitLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
  }

  Future<void> upsertCategoryBudget({
    Id? id,
    required String categoryRemoteId,
    required String categoryName,
    required double limitAmount,
    String monthKey = BudgetLedgerKeys.recurringBudgetMonth,
    bool rolloverEnabled = false,
  }) async {
    await isar.writeTxn(() async {
      CategoryBudgetLimitLocal l;
      if (id != null) {
        l = (await isar.categoryBudgetLimitLocals.get(id))!;
      } else {
        l = CategoryBudgetLimitLocal()
          ..remoteId = newRemoteId()
          ..userId = userId
          ..budgetRemoteId = _ledgerBudgetRemoteId;
      }
      l.categoryRemoteId = categoryRemoteId;
      l.categoryName = categoryName;
      l.limitAmount = limitAmount;
      l.monthKey = monthKey;
      l.rolloverEnabled = rolloverEnabled;
      await isar.categoryBudgetLimitLocals.put(l);
    });
    _markCloudBackupNeeded();
  }

  Future<void> deleteCategoryBudget(Id id) async {
    await isar.writeTxn(() => isar.categoryBudgetLimitLocals.delete(id));
    _markCloudBackupNeeded();
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
