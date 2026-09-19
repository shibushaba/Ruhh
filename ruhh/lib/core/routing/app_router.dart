import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/auth/login_page.dart';
import 'package:ruhh/features/auth/signup_page.dart';
import 'package:ruhh/features/auth/welcome_auth_page.dart';
import 'package:ruhh/features/budget/add_transaction_page.dart';
import 'package:ruhh/features/budget/budget_page.dart';
import 'package:ruhh/features/habit/habit_form_page.dart';
import 'package:ruhh/features/habit/habit_page.dart';
import 'package:ruhh/features/home/analytics_page.dart';
import 'package:ruhh/features/home/home_page.dart';
import 'package:ruhh/features/home/home_shell.dart';
import 'package:ruhh/features/movie/movie_detail_page.dart';
import 'package:ruhh/features/movie/movie_page.dart';
import 'package:ruhh/features/onboarding/onboarding_page.dart';
import 'package:ruhh/features/prayer/prayer_page.dart';
import 'package:ruhh/features/settings/overlay_setup_page.dart';
import 'package:ruhh/features/settings/settings_page.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class AppRouter {
  static GoRouter create(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final auth = ref.read(authControllerProvider);
        final settings = ref.read(settingsControllerProvider);
        final loc = state.matchedLocation;

        if (auth.loading) {
          return loc == '/splash' ? null : '/splash';
        }

        if (!auth.isLoggedIn) {
          if (loc.startsWith('/auth')) return null;
          return '/auth/welcome';
        }

        if (!settings.loaded) {
          return loc == '/splash' ? null : '/splash';
        }

        if (!settings.onboardingComplete && loc != '/onboarding') {
          return '/onboarding';
        }

        if (loc == '/splash' || loc.startsWith('/auth')) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(
          path: '/auth/welcome',
          builder: (_, __) => const WelcomeAuthPage(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (_, __) => const SignupPage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const HomePage(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (_, __) => const AnalyticsPage(),
            ),
            GoRoute(
              path: '/budget',
              builder: (context, state) {
                final tab =
                    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                return BudgetPage(initialTab: tab.clamp(0, 5));
              },
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, state) => AddTransactionPage(
                    objectiveRemoteId: state.uri.queryParameters['objective'],
                  ),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (_, state) => AddTransactionPage(
                    transactionId:
                        int.tryParse(state.pathParameters['id'] ?? ''),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/habit',
              builder: (context, state) {
                final tab =
                    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                return HabitPage(initialTab: tab.clamp(0, 5));
              },
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const HabitFormPage(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (_, state) => HabitFormPage(
                    remoteId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/prayer',
              builder: (context, state) {
                final tab =
                    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                return PrayerPage(initialTab: tab.clamp(0, 2));
              },
              routes: [
                GoRoute(
                  path: 'stats',
                  builder: (_, __) => const PrayerStatsRedirect(),
                ),
              ],
            ),
            GoRoute(
              path: '/movie',
              builder: (context, state) {
                final tab =
                    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                return MoviePage(initialTab: tab.clamp(0, 3));
              },
              routes: [
                GoRoute(
                  path: 'detail/:mediaType/:tmdbId',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['tmdbId'] ?? '');
                    final type = state.pathParameters['mediaType'] ?? 'movie';
                    if (id == null) {
                      return const Scaffold(
                        body: Center(child: Text('Invalid id')),
                      );
                    }
                    return MovieDetailPage(mediaType: type, tmdbId: id);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsPage(),
            ),
            GoRoute(
              path: '/settings/overlay',
              builder: (_, __) => const OverlaySetupPage(),
            ),
          ],
        ),
      ],
    );
  }
}

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    ref.watch(settingsControllerProvider);
    return Scaffold(
      body: Center(
        child: Text(
          'RUHH',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('Router must be created in RuhhApp');
});
