import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModuleSettings {
  const ModuleSettings({
    required this.budgetEnabled,
    required this.onboardingComplete,
    required this.loaded,
    required this.darkMode,
    required this.notifyBudget,
    required this.notifyHabit,
    required this.notifyPrayer,
    required this.notifyMovie,
  });

  final bool budgetEnabled;
  final bool onboardingComplete;
  final bool loaded;
  final bool darkMode;
  final bool notifyBudget;
  final bool notifyHabit;
  final bool notifyPrayer;
  final bool notifyMovie;

  ModuleSettings copyWith({
    bool? budgetEnabled,
    bool? onboardingComplete,
    bool? loaded,
    bool? darkMode,
    bool? notifyBudget,
    bool? notifyHabit,
    bool? notifyPrayer,
    bool? notifyMovie,
  }) {
    return ModuleSettings(
      budgetEnabled: budgetEnabled ?? this.budgetEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      loaded: loaded ?? this.loaded,
      darkMode: darkMode ?? this.darkMode,
      notifyBudget: notifyBudget ?? this.notifyBudget,
      notifyHabit: notifyHabit ?? this.notifyHabit,
      notifyPrayer: notifyPrayer ?? this.notifyPrayer,
      notifyMovie: notifyMovie ?? this.notifyMovie,
    );
  }
}

class SettingsController extends Notifier<ModuleSettings> {
  static const _legacyBudgetKey = 'mod_budget';
  static const _legacyOnboardingKey = 'onboarding_done';
  static const _darkKey = 'dark_mode';
  static const _glassThemeKey = 'theme_glass_v2';
  static const _nBudget = 'notify_budget';
  static const _nHabit = 'notify_habit';
  static const _nPrayer = 'notify_prayer';
  static const _nMovie = 'notify_movie';

  String? _loadedForUsername;
  int _loadGeneration = 0;

  @override
  ModuleSettings build() {
    ref.listen(
      authControllerProvider,
      (previous, next) {
        if (next.loading) return;
        unawaited(
          reloadForCurrentUser(force: previous?.username != next.username),
        );
      },
      fireImmediately: true,
    );

    return const ModuleSettings(
      budgetEnabled: false,
      onboardingComplete: false,
      loaded: false,
      darkMode: true,
      notifyBudget: true,
      notifyHabit: true,
      notifyPrayer: true,
      notifyMovie: true,
    );
  }

  Future<void> reloadForCurrentUser({bool force = false}) async {
    final generation = ++_loadGeneration;
    final auth = ref.read(authControllerProvider);
    final username = auth.username;
    if (auth.loading) return;
    if (!force && username == _loadedForUsername && state.loaded) return;

    final p = await SharedPreferences.getInstance();
    if (generation != _loadGeneration) return;

    if (!p.containsKey(_glassThemeKey)) {
      await p.setBool(_darkKey, true);
      await p.setBool(_glassThemeKey, true);
    }

    final device = ModuleSettings(
      budgetEnabled: false,
      onboardingComplete: false,
      loaded: false,
      darkMode: p.getBool(_darkKey) ?? true,
      notifyBudget: p.getBool(_nBudget) ?? true,
      notifyHabit: p.getBool(_nHabit) ?? true,
      notifyPrayer: p.getBool(_nPrayer) ?? true,
      notifyMovie: p.getBool(_nMovie) ?? true,
    );

    if (username == null) {
      _loadedForUsername = null;
      if (generation != _loadGeneration) return;
      state = device.copyWith(loaded: true);
      return;
    }

    final isar = await ref.read(isarProvider.future);
    if (generation != _loadGeneration) return;

    final user =
        await isar.userLocals.filter().usernameEqualTo(username).findFirst();

    var onboarding = user?.onboardingComplete ?? false;
    var budget = user?.budgetEnabled ?? false;

    if (user != null && !onboarding) {
      final legacyDone = p.getBool(_legacyOnboardingKey) ?? false;
      if (legacyDone) {
        onboarding = true;
        budget = p.getBool(_legacyBudgetKey) ?? budget;
        user.onboardingComplete = true;
        user.budgetEnabled = budget;
        await isar.writeTxn(() async {
          await isar.userLocals.put(user);
        });
      }
    }

    _loadedForUsername = username;
    if (generation != _loadGeneration) return;
    state = device.copyWith(
      budgetEnabled: budget,
      onboardingComplete: onboarding,
      loaded: true,
    );
  }

  Future<void> _persistAccountSettings() async {
    final username = ref.read(authControllerProvider).username;
    if (username == null) return;

    final isar = await ref.read(isarProvider.future);
    final user =
        await isar.userLocals.filter().usernameEqualTo(username).findFirst();
    if (user == null) return;

    user.budgetEnabled = state.budgetEnabled;
    user.onboardingComplete = state.onboardingComplete;
    await isar.writeTxn(() async {
      await isar.userLocals.put(user);
    });
    scheduleCloudSyncFromNotifier(ref);
  }

  Future<void> setBudgetEnabled(bool value) async {
    state = state.copyWith(budgetEnabled: value);
    await _persistAccountSettings();
  }

  Future<void> setOnboardingComplete(bool value) async {
    state = state.copyWith(onboardingComplete: value);
    await _persistAccountSettings();
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
