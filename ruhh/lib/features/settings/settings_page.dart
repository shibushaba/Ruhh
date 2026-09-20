import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/ruhh_file_backup_service.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

String formatLastCloudSync(DateTime? at) {
  if (at == null) return 'No successful sync yet this session';
  final local = at.toLocal();
  final now = DateTime.now();
  final time = DateFormat.jm().format(local);
  final sameDay =
      local.year == now.year && local.month == now.month && local.day == now.day;
  if (sameDay) return 'Last sync: today at $time';
  final yesterday = now.subtract(const Duration(days: 1));
  final wasYesterday = local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day;
  if (wasYesterday) return 'Last sync: yesterday at $time';
  return 'Last sync: ${DateFormat.yMMMd().format(local)} at $time';
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final t = context.ruhh;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ruhhAppBar(context, title: 'Settings'),
      body: NBPageBody(
        extraBottomPadding: false,
        child: ListView(
          children: [
            NBSection(
              title: 'Modules',
              subtitle: 'Turn trackers on or off for this account.',
              child: NBCard(
                child: _SettingsSwitch(
                  title: 'Budget tracker',
                  subtitle: 'Expenses, goals, and accounts',
                  value: settings.budgetEnabled,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setBudgetEnabled(v),
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBSection(
              title: 'Notifications',
              subtitle: 'Android reminders when enabled.',
              child: NBCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsSwitch(
                      title: 'Budget',
                      value: settings.notifyBudget,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(budget: v),
                    ),
                    Divider(height: 1, color: t.divider),
                    _SettingsSwitch(
                      title: 'Habit',
                      value: settings.notifyHabit,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(habit: v),
                    ),
                    Divider(height: 1, color: t.divider),
                    _SettingsSwitch(
                      title: 'Prayer',
                      value: settings.notifyPrayer,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(prayer: v),
                    ),
                    Divider(height: 1, color: t.divider),
                    _SettingsSwitch(
                      title: 'Movie',
                      value: settings.notifyMovie,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setNotification(movie: v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBSection(
              title: 'Appearance',
              child: NBCard(
                child: _SettingsSwitch(
                  title: 'Dark mode',
                  value: settings.darkMode,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setDarkMode(v),
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBSection(
              title: 'Download backup (CSV)',
              subtitle:
                  'Save a full copy of this account — budget, habits, prayer, movies, todos, and settings. Restore it on a fresh install after you log in.',
              child: const NBCard(
                child: _LocalBackupSection(),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBSection(
              title: 'Cloud backup',
              subtitle: SupabaseService.client == null
                  ? 'Add SUPABASE_URL and SUPABASE_ANON_KEY in .env, then rebuild the app.'
                  : 'Backup runs automatically while you\'re signed in (after edits, on open, and about every minute).',
              child: NBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        SupabaseService.client == null
                            ? 'Not configured'
                            : 'Cloud configured',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: t.textPrimary),
                      ),
                      subtitle: Text(
                        SupabaseService.client == null
                            ? 'This build has no Supabase URL or anon key.'
                            : 'Automatic backup while you\'re signed in.',
                        style: t.caption(Theme.of(context).textTheme),
                      ),
                      trailing: Icon(
                        SupabaseService.client == null
                            ? Icons.cloud_off_outlined
                            : Icons.cloud_done_outlined,
                        color: SupabaseService.client == null
                            ? t.textSecondary
                            : t.textPrimary,
                      ),
                    ),
                    if (SupabaseService.client != null) ...[
                      Divider(height: 1, color: t.divider),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatLastCloudSync(
                                ref.watch(lastCloudSyncAtProvider),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: t.textPrimary),
                            ),
                            if (ref.watch(cloudSyncBusyProvider))
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: t.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Syncing…',
                                      style: t.caption(
                                        Theme.of(context).textTheme,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (ref.watch(lastCloudSyncErrorProvider) !=
                                null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  ref.watch(lastCloudSyncErrorProvider)!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: t.textSecondary),
                                ),
                              ),
                          ],
                        ),
                      ),
                      NBButton(
                        label: ref.watch(cloudSyncBusyProvider)
                            ? 'Syncing…'
                            : 'Sync now',
                        primary: false,
                        onPressed: ref.watch(cloudSyncBusyProvider)
                            ? null
                            : () async {
                                final ok = await runCloudSyncFromWidget(ref);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? formatLastCloudSync(
                                              ref.read(
                                                lastCloudSyncAtProvider,
                                              ),
                                            )
                                          : (ref.read(
                                                    lastCloudSyncErrorProvider,
                                                  ) ??
                                                  'Sync could not complete'),
                                    ),
                                  ),
                                );
                              },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: NBLayout.sectionGap),
            NBButton(
              label: 'Quick action setup',
              onPressed: () => context.push('/settings/overlay'),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: 'Log out',
              color: t.textPrimary,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/auth/welcome');
              },
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
          ],
        ),
      ),
    );
  }
}

class _LocalBackupSection extends ConsumerStatefulWidget {
  const _LocalBackupSection();

  @override
  ConsumerState<_LocalBackupSection> createState() => _LocalBackupSectionState();
}

class _LocalBackupSectionState extends ConsumerState<_LocalBackupSection> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadBackup() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      _snack('Log in to download a backup.');
      return;
    }
    final user = await currentUserLocal(ref);
    if (user == null) {
      _snack('Could not load your account.');
      return;
    }
    final backupAsync = ref.read(ruhhFileBackupServiceProvider);
    final service = backupAsync.maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    if (service == null) {
      final service2 = await ref.read(ruhhFileBackupServiceProvider.future);
      await _exportWith(service2, user);
      return;
    }
    await _exportWith(service, user);
  }

  Future<void> _exportWith(RuhhFileBackupService service, UserLocal user) async {
    final settings = ref.read(settingsControllerProvider);
    final file = await service.exportBackupCsv(
      user: user,
      deviceSettings: settings,
    );
    await service.shareBackupFile(file);
    if (mounted) {
      _snack('Backup ready — save the CSV file from the share sheet.');
    }
  }

  Future<void> _restoreBackup() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      _snack('Log in first, then restore a backup into this account.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'This replaces all data in your current RUHH account with the backup file. '
          'Your username and PIN stay the same.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;
    final bytes = pick.files.single.bytes;
    if (bytes == null) {
      _snack('Could not read the selected file.');
      return;
    }
    final csv = String.fromCharCodes(bytes);

    final user = await currentUserLocal(ref);
    if (user == null || !mounted) {
      _snack('Could not load your account.');
      return;
    }

    try {
      final service = await ref.read(ruhhFileBackupServiceProvider.future);
      final result = await service.importBackupCsv(
        user: user,
        csvContents: csv,
        settingsController: ref.read(settingsControllerProvider.notifier),
      );
      await refreshAppAfterFileBackupImport(ref);
      if (!mounted) return;
      final from = result.sourceUsername;
      final fromNote = from != null && from != user.username
          ? ' (from account "$from")'
          : '';
      _snack('Restored ${result.entityCount} items$fromNote.');
    } catch (e) {
      if (mounted) _snack('Restore failed: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NBButton(
          label: _busy ? 'Working…' : 'Download backup CSV',
          onPressed: _busy ? null : () => _run(_downloadBackup),
        ),
        const SizedBox(height: 12),
        NBButton(
          label: _busy ? 'Working…' : 'Restore from backup CSV',
          primary: false,
          onPressed: _busy ? null : () => _run(_restoreBackup),
        ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: theme.titleMedium?.copyWith(color: t.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: t.caption(theme))
          : null,
      value: value,
      activeThumbColor: t.canvas,
      activeTrackColor: t.textPrimary,
      inactiveThumbColor: t.textSecondary,
      inactiveTrackColor: t.divider,
      onChanged: onChanged,
    );
  }
}
