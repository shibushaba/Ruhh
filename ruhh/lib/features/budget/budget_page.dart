import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/icons/app_icons.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/budget/budget_home_page.dart';
import 'package:ruhh/features/budget/budget_income_page.dart';
import 'package:ruhh/features/budget/budget_manage_page.dart';
import 'package:ruhh/features/budget/budget_transactions_page.dart';
import 'package:ruhh/features/budget/budget_trends_page.dart';

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
    final tab = widget.initialTab.clamp(0, 4);
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
    final t = context.ruhh;

    return NBModuleScaffold(
      title: 'Budget',
      wrapBody: false,
      moduleTabLabels: const ['Home', 'List', 'Income', 'Trends', 'Manage'],
      moduleTabIndex: index,
      onModuleTab: _onTab,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: () => context.push('/budget/add'),
        child: Icon(AppIcons.plus(filled: true)),
      ),
      body: PageView(
        controller: _pages,
        onPageChanged: (i) =>
            ref.read(budgetTabIndexProvider.notifier).state = i,
        children: const [
          BudgetHomePage(),
          BudgetTransactionsPage(),
          BudgetIncomePage(),
          BudgetTrendsPage(),
          BudgetManagePage(),
        ],
      ),
    );
  }
}
