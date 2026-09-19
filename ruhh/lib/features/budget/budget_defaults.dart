import 'package:flutter/material.dart';

/// Default expense/income categories aligned with Cashew (Budget-Tracker).
class BudgetDefaultCategory {
  const BudgetDefaultCategory({
    required this.name,
    required this.isIncome,
    required this.color,
    required this.sortOrder,
  });

  final String name;
  final bool isIncome;
  final Color color;
  final int sortOrder;
}

const cashewDefaultCategories = <BudgetDefaultCategory>[
  BudgetDefaultCategory(
      name: 'Dining', isIncome: false, color: Colors.blueGrey, sortOrder: 0),
  BudgetDefaultCategory(
      name: 'Groceries', isIncome: false, color: Colors.green, sortOrder: 1),
  BudgetDefaultCategory(
      name: 'Shopping', isIncome: false, color: Colors.pink, sortOrder: 2),
  BudgetDefaultCategory(
      name: 'Transit', isIncome: false, color: Colors.amber, sortOrder: 3),
  BudgetDefaultCategory(
      name: 'Entertainment',
      isIncome: false,
      color: Colors.blue,
      sortOrder: 4),
  BudgetDefaultCategory(
      name: 'Bills & Fees',
      isIncome: false,
      color: Colors.teal,
      sortOrder: 5),
  BudgetDefaultCategory(
      name: 'Gifts', isIncome: false, color: Colors.red, sortOrder: 6),
  BudgetDefaultCategory(
      name: 'Beauty', isIncome: false, color: Colors.purple, sortOrder: 7),
  BudgetDefaultCategory(
      name: 'Work', isIncome: false, color: Colors.brown, sortOrder: 8),
  BudgetDefaultCategory(
      name: 'Travel', isIncome: false, color: Colors.orange, sortOrder: 9),
  BudgetDefaultCategory(
      name: 'Income',
      isIncome: true,
      color: Colors.deepPurple,
      sortOrder: 10),
];
