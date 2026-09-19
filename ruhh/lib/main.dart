import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/routing/app_router.dart';
import 'package:ruhh/core/data/isar_service.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/services/home_widget_service.dart';
import 'package:ruhh/core/services/smart_notification_scheduler.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/theme/ruhh_theme.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/settings/settings_controller.dart';
import 'package:ruhh/overlay/overlay_entry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: RuhhApp()));
}

class RuhhApp extends ConsumerStatefulWidget {
  const RuhhApp({super.key});

  @override
  ConsumerState<RuhhApp> createState() => _RuhhAppState();
}

class _RuhhAppState extends ConsumerState<RuhhApp> {
  GoRouter? _router;
  var _notificationsBootstrapped = false;

  @override
  Widget build(BuildContext context) {
    _router ??= AppRouter.create(ref);
    ref.listen(authControllerProvider, (_, __) => _router?.refresh());
    ref.listen(settingsControllerProvider, (_, __) => _router?.refresh());
    final auth = ref.watch(authControllerProvider);
    if (auth.isLoggedIn && !_notificationsBootstrapped) {
      _notificationsBootstrapped = true;
      if (!kIsWeb && Platform.isAndroid) {
        ref.read(smartNotificationSchedulerProvider.future).then((s) async {
          await s.refreshAll();
          final repo = await ref.read(habitRepositoryProvider.future);
          await HomeWidgetService.sync(repo);
        });
      }
    }
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'RUHH',
      debugShowCheckedModeBanner: false,
      theme: RuhhTheme.light(),
      darkTheme: RuhhTheme.dark(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) => NBGlassBackground(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

@pragma('vm:entry-point')
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await IsarService.open();
  runApp(const ProviderScope(child: OverlayApp()));
}

@pragma('vm:entry-point')
void overlayTriggerMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final overlay = OverlayService();
  await overlay.showQuickAction();
}

class OverlayApp extends ConsumerWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: RuhhTheme.dark(),
      builder: (context, child) =>
          NBGlassBackground(child: child ?? const SizedBox.shrink()),
      home: const OverlayEntryWidget(),
    );
  }
}
