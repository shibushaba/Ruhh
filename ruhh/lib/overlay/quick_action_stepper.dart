import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';

enum QuickModule { budget, habit, prayer, movie }

class QuickActionStepper extends ConsumerStatefulWidget {
  const QuickActionStepper({super.key});

  @override
  ConsumerState<QuickActionStepper> createState() => _QuickActionStepperState();
}

class _QuickActionStepperState extends ConsumerState<QuickActionStepper> {
  int _step = 0;
  QuickModule? _module;
  bool _success = false;

  final _amountCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  final _movieCtrl = TextEditingController();
  bool _isIncome = false;
  String _category = 'Food';
  WatchStatus _watchStatus = WatchStatus.wantToWatch;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (user) {
        if (user == null) {
          return Text(
            'Open RUHH and sign in once, then try Quick again.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(BuildContext context, UserLocal user) {
    if (_success) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 40, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 8),
          Text('Saved', style: Theme.of(context).textTheme.titleLarge),
        ],
      );
    }

    if (_step == 0) return _pickModule(user);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _step = 0;
              _module = null;
            }),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back'),
          ),
        ),
        _moduleAction(),
      ],
    );
  }

  Widget _pickModule(UserLocal user) {
    final modules = <QuickModule>[
      QuickModule.habit,
      QuickModule.prayer,
      QuickModule.movie,
      if (user.budgetEnabled) QuickModule.budget,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Pick module', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modules.map((m) {
            return NBChip(
              label: _moduleLabel(m),
              selected: _module == m,
              color: _moduleColor(m),
              onTap: () => setState(() {
                _module = m;
                _step = 1;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _moduleAction() {
    return switch (_module) {
      QuickModule.budget => _budgetForm(),
      QuickModule.habit => _habitAction(),
      QuickModule.prayer => _prayerAction(),
      QuickModule.movie => _movieForm(),
      null => const SizedBox.shrink(),
    };
  }

  Widget _budgetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Add transaction', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        NBTextField(controller: _amountCtrl, label: 'Amount', keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        Row(
          children: [
            NBChip(label: 'Expense', selected: !_isIncome, onTap: () => setState(() => _isIncome = false)),
            const SizedBox(width: 8),
            NBChip(label: 'Income', selected: _isIncome, onTap: () => setState(() => _isIncome = true), color: NBColors.budget),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: ['Food', 'Transport', 'Bills', 'Fun']
              .map((c) => NBChip(
                    label: c,
                    selected: _category == c,
                    color: NBColors.budget,
                    onTap: () => setState(() => _category = c),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        NBTextField(controller: _noteCtrl, label: 'Note (optional)'),
        const SizedBox(height: 12),
        NBButton(label: 'Save', color: NBColors.budget, onPressed: _saveBudget),
      ],
    );
  }

  Widget _habitAction() {
    final repo = ref.watch(habitRepositoryProvider);
    return repo.when(
      data: (r) => FutureBuilder(
        future: r.nextDueHabit(),
        builder: (context, snap) {
          final habit = snap.data;
          if (habit == null) {
            return Text('No habits yet', style: Theme.of(context).textTheme.bodyLarge);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              NBButton(
                label: 'Check in',
                color: NBColors.habit,
                onPressed: () async {
                  await r.toggleToday(habit);
                  _showSuccess();
                },
              ),
            ],
          );
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('$e'),
    );
  }

  Widget _prayerAction() {
    final repo = ref.watch(prayerRepositoryProvider);
    return repo.when(
      data: (r) => FutureBuilder(
        future: r.nextPending(),
        builder: (context, snap) {
          final prayer = snap.data ?? PrayerName.dhuhr;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PrayerRepository.label(prayer),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              NBButton(
                label: 'Mark on time',
                color: NBColors.prayer,
                onPressed: () async {
                  await r.setStatus(prayer, PrayerStatus.onTimeAlone);
                  _showSuccess();
                },
              ),
              const SizedBox(height: 8),
              NBButton(
                expand: false,
                label: 'With group',
                color: NBColors.budget,
                onPressed: () async {
                  await r.setStatus(prayer, PrayerStatus.withGroup);
                  _showSuccess();
                },
              ),
              const SizedBox(height: 8),
              NBButton(
                expand: false,
                label: 'Late alone',
                color: NBColors.offWhite,
                onPressed: () async {
                  await r.setStatus(prayer, PrayerStatus.lateAlone);
                  _showSuccess();
                },
              ),
              const SizedBox(height: 8),
              NBButton(
                expand: false,
                label: 'Missed',
                color: NBColors.offWhite,
                onPressed: () async {
                  await r.setStatus(prayer, PrayerStatus.missed);
                  _showSuccess();
                },
              ),
            ],
          );
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('$e'),
    );
  }

  Widget _movieForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        NBTextField(controller: _movieCtrl, label: 'Title'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: WatchStatus.values
              .map((s) => NBChip(
                    label: watchStatusLabel(s),
                    selected: _watchStatus == s,
                    color: NBColors.movie,
                    onTap: () => setState(() => _watchStatus = s),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        NBButton(
          label: 'Add to list',
          color: NBColors.movie,
          onPressed: _saveMovie,
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    final repo = await ref.read(budgetRepositoryProvider.future);
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    await repo.add(
      amount: amount,
      isIncome: _isIncome,
      category: _category,
      note: _noteCtrl.text,
    );
    _showSuccess();
  }

  Future<void> _saveMovie() async {
    final title = _movieCtrl.text.trim();
    if (title.isEmpty) return;
    final repo = await ref.read(movieRepositoryProvider.future);
    await repo.addManual(title: title, status: _watchStatus);
    _showSuccess();
  }

  void _showSuccess() {
    setState(() => _success = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ref.read(overlayServiceProvider).close();
    });
  }

  String _moduleLabel(QuickModule m) => switch (m) {
        QuickModule.budget => 'Budget',
        QuickModule.habit => 'Habit',
        QuickModule.prayer => 'Prayer',
        QuickModule.movie => 'Movie',
      };

  Color _moduleColor(QuickModule m) => switch (m) {
        QuickModule.budget => NBColors.budget,
        QuickModule.habit => NBColors.habit,
        QuickModule.prayer => NBColors.prayer,
        QuickModule.movie => NBColors.movie,
      };
}
