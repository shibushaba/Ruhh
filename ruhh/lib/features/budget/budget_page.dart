import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/budget/budget_objectives_page.dart';
import 'package:ruhh/features/budget/budget_upcoming_page.dart';
import 'package:ruhh/features/budget/budget_accounts_page.dart';
import 'package:ruhh/features/budget/budget_budgets_page.dart';
import 'package:ruhh/features/budget/budget_home_page.dart';
import 'package:ruhh/features/budget/budget_transactions_page.dart';

final budgetTabIndexProvider = StateProvider<int>((ref) => 0);

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab;
    _pages = PageController(initialPage: tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetTabIndexProvider.notifier).state = tab;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onTab(int i) {
    ref.read(budgetTabIndexProvider.notifier).state = i;
    _pages.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(budgetTabIndexProvider, (prev, next) {
      if (_pages.hasClients && _pages.page?.round() != next) {
        _pages.jumpToPage(next);
      }
    });
    final index = ref.watch(budgetTabIndexProvider);

    return NBModuleScaffold(
      title: 'Budget',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: NBColors.budget,
        foregroundColor: NBColors.black,
        onPressed: () => context.push('/budget/add'),
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
      ),
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(budgetTabIndexProvider.notifier).state = i,
        children: const [
          BudgetHomePage(),
          BudgetTransactionsPage(),
          BudgetUpcomingPage(),
          BudgetBudgetsPage(),
          BudgetObjectivesPage(),
          BudgetAccountsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.schedule_outlined), label: 'Upcoming'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline), label: 'Budgets'),
          NavigationDestination(
              icon: Icon(Icons.flag_outlined), label: 'Goals'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Accounts'),
        ],
      ),
    );
  }
}
