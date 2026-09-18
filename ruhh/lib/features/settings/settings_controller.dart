import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModuleSettings {
  const ModuleSettings({
    required this.budgetEnabled,
    required this.onboardingComplete,
    required this.darkMode,
    required this.notifyBudget,
    required this.notifyHabit,
    required this.notifyPrayer,
    required this.notifyMovie,
  });

  final bool budgetEnabled;
  final bool onboardingComplete;
  final bool darkMode;
  final bool notifyBudget;
  final bool notifyHabit;
  final bool notifyPrayer;
  final bool notifyMovie;

  ModuleSettings copyWith({
    bool? budgetEnabled,
    bool? onboardingComplete,
    bool? darkMode,
    bool? notifyBudget,
    bool? notifyHabit,
    bool? notifyPrayer,
    bool? notifyMovie,
  }) {
    return ModuleSettings(
      budgetEnabled: budgetEnabled ?? this.budgetEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      darkMode: darkMode ?? this.darkMode,
      notifyBudget: notifyBudget ?? this.notifyBudget,
      notifyHabit: notifyHabit ?? this.notifyHabit,
      notifyPrayer: notifyPrayer ?? this.notifyPrayer,
      notifyMovie: notifyMovie ?? this.notifyMovie,
    );
  }
}

class SettingsController extends Notifier<ModuleSettings> {
  static const _budgetKey = 'mod_budget';
  static const _onboardingKey = 'onboarding_done';
  static const _darkKey = 'dark_mode';
  static const _nBudget = 'notify_budget';
  static const _nHabit = 'notify_habit';
  static const _nPrayer = 'notify_prayer';
  static const _nMovie = 'notify_movie';

  @override
  ModuleSettings build() {
    _load();
    return const ModuleSettings(
      budgetEnabled: false,
      onboardingComplete: false,
      darkMode: false,
      notifyBudget: true,
      notifyHabit: true,
      notifyPrayer: true,
      notifyMovie: true,
    );
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = ModuleSettings(
      budgetEnabled: p.getBool(_budgetKey) ?? false,
      onboardingComplete: p.getBool(_onboardingKey) ?? false,
      darkMode: p.getBool(_darkKey) ?? false,
      notifyBudget: p.getBool(_nBudget) ?? true,
      notifyHabit: p.getBool(_nHabit) ?? true,
      notifyPrayer: p.getBool(_nPrayer) ?? true,
      notifyMovie: p.getBool(_nMovie) ?? true,
    );
  }

  Future<void> setBudgetEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_budgetKey, value);
    state = state.copyWith(budgetEnabled: value);
  }

  Future<void> setOnboardingComplete(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_onboardingKey, value);
    state = state.copyWith(onboardingComplete: value);
  }

  Future<void> setDarkMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_darkKey, value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setNotification({
    bool? budget,
    bool? habit,
    bool? prayer,
    bool? movie,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (budget != null) await p.setBool(_nBudget, budget);
    if (habit != null) await p.setBool(_nHabit, habit);
    if (prayer != null) await p.setBool(_nPrayer, prayer);
    if (movie != null) await p.setBool(_nMovie, movie);
    state = state.copyWith(
      notifyBudget: budget ?? state.notifyBudget,
      notifyHabit: habit ?? state.notifyHabit,
      notifyPrayer: prayer ?? state.notifyPrayer,
      notifyMovie: movie ?? state.notifyMovie,
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, ModuleSettings>(
  SettingsController.new,
);
