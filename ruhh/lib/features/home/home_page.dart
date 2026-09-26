import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/motion/list_entrance.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/home/widgets/home_insight_widgets.dart';
import 'package:ruhh/features/home/widgets/home_redesign_sections.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.ruhh;
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NBPageBody(
        child: RefreshIndicator(
          color: t.accentMint,
          onRefresh: () async {
            ref.invalidate(habitRepositoryProvider);
            ref.invalidate(dailyPrayerLogsProvider);
            ref.invalidate(budgetRepositoryProvider);
            ref.invalidate(movieRepositoryProvider);
            bumpHabitRefresh(ref);
            bumpBudgetRefresh(ref);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const HomeScreenHeader(),
              SizedBox(height: t.spaceStackGap),
              const HomeNotificationBanner(),
              StaggeredEntranceColumn(
                children: [
                  const HomeSectionLabel(title: 'Insights'),
                  HomeInsightChipRow(budgetEnabled: settings.budgetEnabled),
                  SizedBox(height: t.spaceStackGap),
                  const HomeSectionLabel(title: 'Your Week'),
                  HomeWeeklyTrendSection(budgetEnabled: settings.budgetEnabled),
                  SizedBox(height: t.spaceStackGap),
                  const HomeSectionLabel(title: 'For you'),
                  HomeInsightsCarousel(budgetEnabled: settings.budgetEnabled),
                  SizedBox(height: t.spaceStackGap),
                  const HomeSectionLabel(title: 'Today\'s focus'),
                  const HomeTodaysFocusSection(),
                  SizedBox(height: t.spaceStackGap),
                  const HomeSectionLabel(title: 'This month'),
                  HomeMonthSnapshotGrid(budgetEnabled: settings.budgetEnabled),
                  const RuhhNavClearance(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
