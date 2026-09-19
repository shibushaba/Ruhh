import 'package:flutter/material.dart';
import 'package:ruhh/features/budget/ledger/budget_category_ids.dart';

class BudgetDefaultCategorySeed {
  const BudgetDefaultCategorySeed({
    required this.remoteId,
    required this.name,
    required this.isIncome,
    required this.color,
    required this.iconKey,
    required this.sortOrder,
  });

  final String remoteId;
  final String name;
  final bool isIncome;
  final Color color;
  final String iconKey;
  final int sortOrder;
}

const indianDefaultCategories = <BudgetDefaultCategorySeed>[
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.food,
    name: 'Food',
    isIncome: false,
    color: Color(0xFFE65100),
    iconKey: 'restaurant',
    sortOrder: 0,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.medical,
    name: 'Medical',
    isIncome: false,
    color: Color(0xFFC62828),
    iconKey: 'medical',
    sortOrder: 1,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.transport,
    name: 'Transport',
    isIncome: false,
    color: Color(0xFF1565C0),
    iconKey: 'directions_bus',
    sortOrder: 2,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.rent,
    name: 'Rent',
    isIncome: false,
    color: Color(0xFF6A1B9A),
    iconKey: 'home',
    sortOrder: 3,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.utilities,
    name: 'Utilities',
    isIncome: false,
    color: Color(0xFF00838F),
    iconKey: 'bolt',
    sortOrder: 4,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.shopping,
    name: 'Shopping',
    isIncome: false,
    color: Color(0xFFAD1457),
    iconKey: 'shopping_bag',
    sortOrder: 5,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.entertainment,
    name: 'Entertainment',
    isIncome: false,
    color: Color(0xFF4527A0),
    iconKey: 'movie',
    sortOrder: 6,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.otherExpense,
    name: 'Other',
    isIncome: false,
    color: Color(0xFF546E7A),
    iconKey: 'more_horiz',
    sortOrder: 7,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.salary,
    name: 'Salary',
    isIncome: true,
    color: Color(0xFF2E7D32),
    iconKey: 'payments',
    sortOrder: 8,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.bonus,
    name: 'Bonus',
    isIncome: true,
    color: Color(0xFF558B2F),
    iconKey: 'stars',
    sortOrder: 9,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.refund,
    name: 'Refund/Cashback',
    isIncome: true,
    color: Color(0xFF00796B),
    iconKey: 'replay',
    sortOrder: 10,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.giftIncome,
    name: 'Gift',
    isIncome: true,
    color: Color(0xFFEF6C00),
    iconKey: 'card_giftcard',
    sortOrder: 11,
  ),
  BudgetDefaultCategorySeed(
    remoteId: BudgetCategoryIds.otherIncome,
    name: 'Other Income',
    isIncome: true,
    color: Color(0xFF5D4037),
    iconKey: 'account_balance_wallet',
    sortOrder: 12,
  ),
];

/// Legacy export for files still importing cashew list.
typedef BudgetDefaultCategory = BudgetDefaultCategorySeed;
const cashewDefaultCategories = indianDefaultCategories;
