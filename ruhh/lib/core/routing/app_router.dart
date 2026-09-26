import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/motion/page_transitions.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/auth/login_page.dart';
import 'package:ruhh/features/auth/signup_page.dart';
import 'package:ruhh/features/auth/welcome_auth_page.dart';
import 'package:ruhh/features/budget/add_transaction_page.dart';
import 'package:ruhh/features/budget/budget_page.dart';
import 'package:ruhh/features/habit/habit_detail_page.dart';
import 'package:ruhh/features/habit/habit_form_page.dart';
import 'package:ruhh/features/habit/habit_page.dart';
import 'package:ruhh/features/home/analytics_page.dart';
import 'package:ruhh/features/home/home_page.dart';
import 'package:ruhh/features/home/home_shell.dart';
import 'package:ruhh/features/movie/movie_categories_page.dart';
import 'package:ruhh/features/movie/movie_detail_page.dart';
import 'package:ruhh/features/movie/movie_form_page.dart';
import 'package:ruhh/features/movie/movie_page.dart';
import 'package:ruhh/features/onboarding/notification_onboarding_page.dart';
import 'package:ruhh/features/onboarding/onboarding_page.dart';
import 'package:ruhh/features/settings/notification_settings_page.dart';
import 'package:ruhh/features/prayer/prayer_page.dart';
import 'package:ruhh/features/settings/overlay_setup_page.dart';
import 'package:ruhh/features/settings/settings_page.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create(WidgetRef ref) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
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

        if (!settings.onboardingComplete &&
            loc != '/onboarding' &&
            loc != '/onboarding/notifications') {
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
        GoRoute(
          path: '/onboarding/notifications',
          builder: (_, __) => const NotificationOnboardingPage(),
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (c, s) =>
              ruhhPage(child: const SettingsPage(), state: s),
        ),
        GoRoute(
          path: '/settings/notifications',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (c, s) =>
              ruhhPage(child: const NotificationSettingsPage(), state: s),
        ),
        GoRoute(
          path: '/settings/overlay',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (c, s) =>
              ruhhPage(child: const OverlaySetupPage(), state: s),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              HomeShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const HomePage(),
                ),
                GoRoute(
                  path: '/analytics',
                  builder: (_, __) => const AnalyticsPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/budget',
                  builder: (context, state) {
                    final tab =
                        int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
                            0;
                    return BudgetPage(initialTab: tab.clamp(0, 4));
                  },
                  routes: [
                    GoRoute(
                      path: 'add',
                      pageBuilder: (c, s) => ruhhPage(
                          child: const AddTransactionPage(), state: s),
                    ),
                    GoRoute(
                      path: 'edit/:id',
                      pageBuilder: (c, s) => ruhhPage(
                        child: AddTransactionPage(
                          transactionId:
                              int.tryParse(s.pathParameters['id'] ?? ''),
                        ),
                        state: s,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/habit',
                  builder: (context, state) {
                    final tab =
                        int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
                            0;
                    return HabitPage(initialTab: tab.clamp(0, 2));
                  },
                  routes: [
                    GoRoute(
                      path: 'new',
                      pageBuilder: (c, s) =>
                          ruhhPage(child: const HabitFormPage(), state: s),
                    ),
                    GoRoute(
                      path: 'edit/:id',
                      pageBuilder: (c, s) => ruhhPage(
                        child: HabitFormPage(
                          remoteId: s.pathParameters['id'],
                        ),
                        state: s,
                      ),
                    ),
                    GoRoute(
                      path: 'detail/:id',
                      pageBuilder: (c, s) => ruhhPage(
                        child: HabitDetailPage(
                          remoteId: s.pathParameters['id'] ?? '',
                        ),
                        state: s,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/prayer',
                  builder: (context, state) {
                    final tab =
                        int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
                            0;
                    return PrayerPage(initialTab: tab.clamp(0, 2));
                  },
                  routes: [
                    GoRoute(
                      path: 'stats',
                      builder: (_, __) => const PrayerStatsRedirect(),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movie',
                  builder: (context, state) {
                    final tab =
                        int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
                            0;
                    return MoviePage(initialTab: tab.clamp(0, 1));
                  },
                  routes: [
                    GoRoute(
                      path: 'add',
                      pageBuilder: (c, s) =>
                          ruhhPage(child: const MovieFormPage(), state: s),
                    ),
                    GoRoute(
                      path: 'edit/:remoteId',
                      pageBuilder: (c, s) => ruhhPage(
                        child: MovieFormPage(
                          remoteId: s.pathParameters['remoteId'] ?? '',
                        ),
                        state: s,
                      ),
                    ),
                    GoRoute(
                      path: 'categories',
                      pageBuilder: (c, s) => ruhhPage(
                          child: const MovieCategoriesPage(), state: s),
                    ),
                    GoRoute(
                      path: 'detail/:mediaType/:tmdbId',
                      builder: (context, state) {
                        final id =
                            int.tryParse(state.pathParameters['tmdbId'] ?? '');
                        final type =
                            state.pathParameters['mediaType'] ?? 'movie';
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
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    ref.watch(settingsControllerProvider);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(_c),
            child: Text(
              'RUHH',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('Router must be created in RuhhApp');
});
