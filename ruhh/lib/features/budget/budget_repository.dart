import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:uuid/uuid.dart';

class BudgetRepository {
  BudgetRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  Future<void> ensureDefaults() async {
    final walletCount =
        await _isar.walletLocals.filter().userIdEqualTo(_userId).count();
    if (walletCount > 0) return;
    await _isar.writeTxn(() async {
      await _isar.walletLocals.put(
        WalletLocal()
          ..remoteId = const Uuid().v4()
          ..userId = _userId
          ..name = 'Cash'
          ..currency = 'USD'
          ..colorValue = NBColors.budget.toARGB32()
          ..sortOrder = 0,
      );
      for (final name in ['Food', 'Transport', 'Bills', 'Fun', 'Salary']) {
        await _isar.categoryLocals.put(
          CategoryLocal()
            ..remoteId = const Uuid().v4()
            ..userId = _userId
            ..name = name
            ..isIncome = name == 'Salary'
            ..colorValue = NBColors.budget.toARGB32(),
        );
      }
      await _isar.budgetPeriodLocals.put(
        BudgetPeriodLocal()
          ..remoteId = const Uuid().v4()
          ..userId = _userId
          ..name = 'Monthly budget'
          ..limitAmount = 2000
          ..period = 'monthly'
          ..startsAt = DateTime(DateTime.now().year, DateTime.now().month),
      );
    });
  }

  Future<List<TransactionLocal>> getAll() => _isar.transactionLocals
      .filter()
      .userIdEqualTo(_userId)
      .sortByOccurredAtDesc()
      .findAll();

  Future<List<WalletLocal>> wallets() =>
      _isar.walletLocals.filter().userIdEqualTo(_userId).sortBySortOrder().findAll();

  Future<List<CategoryLocal>> categories() =>
      _isar.categoryLocals.filter().userIdEqualTo(_userId).findAll();

  Future<List<BudgetPeriodLocal>> budgets() => _isar.budgetPeriodLocals
      .filter()
      .userIdEqualTo(_userId)
      .findAll();

  Future<void> add({
    required double amount,
    required bool isIncome,
    required String category,
    String account = 'Cash',
    String note = '',
    DateTime? occurredAt,
  }) async {
    final tx = TransactionLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..amount = amount
      ..isIncome = isIncome
      ..category = category
      ..account = account
      ..note = note
      ..occurredAt = occurredAt ?? DateTime.now();
    await _isar.writeTxn(() => _isar.transactionLocals.put(tx));
  }

  Future<void> delete(Id id) async {
    await _isar.writeTxn(() => _isar.transactionLocals.delete(id));
  }

  Future<double> spentThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final txs = await _isar.transactionLocals
        .filter()
        .userIdEqualTo(_userId)
        .occurredAtGreaterThan(start)
        .findAll();
    return txs
        .where((t) => !t.isIncome)
        .fold<double>(0.0, (s, t) => s + t.amount);
  }

  Future<Map<String, double>> spendByCategoryThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final txs = await _isar.transactionLocals
        .filter()
        .userIdEqualTo(_userId)
        .occurredAtGreaterThan(start)
        .findAll();
    final map = <String, double>{};
    for (final t in txs.where((x) => !x.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  final repo = BudgetRepository(isar, user.supabaseId ?? user.id.toString());
  await repo.ensureDefaults();
  return repo;
});
