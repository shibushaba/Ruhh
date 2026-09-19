import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/overlay_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/widgets/movie_category_display.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

enum QuickModule { budget, habit, prayer, movie }

enum _MovieOverlayMode { add, markWatched }

class QuickActionStepper extends ConsumerStatefulWidget {
  const QuickActionStepper({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<QuickActionStepper> createState() => _QuickActionStepperState();
}

class _QuickActionStepperState extends ConsumerState<QuickActionStepper> {
  int _step = 0;
  QuickModule? _module;
  bool _success = false;
  int _dataTick = 0;

  final _amountCtrl = TextEditingController(text: '');
  final _noteCtrl = TextEditingController();
  final _movieTitleCtrl = TextEditingController();
  final _movieSearchCtrl = TextEditingController();

  BudgetLedgerType _ledgerType = BudgetLedgerType.expense;
  CategoryLocal? _budgetCategory;
  MovieCategoryLocal? _movieCategory;
  _MovieOverlayMode _movieMode = _MovieOverlayMode.add;

  List<MovieLocal> _movieSuggestions = [];
  Timer? _movieSearchDebounce;
  StreamSubscription<dynamic>? _overlayResetSub;

  @override
  void dispose() {
    _overlayResetSub?.cancel();
    ref.read(overlayQuickBackProvider.notifier).state =
        (visible: false, onBack: null);
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _movieTitleCtrl.dispose();
    _movieSearchCtrl.dispose();
    _movieSearchDebounce?.cancel();
    super.dispose();
  }

  RuhhTokens get _t => RuhhTokens.dark;

  /// Always start on the 4-module grid when the overlay opens.
  void _resetToModulePicker({bool rebuild = true}) {
    _step = 0;
    _module = null;
    _success = false;
    _movieSuggestions = [];
    _movieMode = _MovieOverlayMode.add;
    _ledgerType = BudgetLedgerType.expense;
    _budgetCategory = null;
    _movieCategory = null;
    _amountCtrl.clear();
    _noteCtrl.clear();
    _movieTitleCtrl.clear();
    _movieSearchCtrl.clear();
    _movieSearchDebounce?.cancel();
    if (rebuild && mounted) {
      setState(() {});
    }
    _syncOverlayHeaderBack();
  }

  void _backToModulePicker() => _resetToModulePicker();

  void _syncOverlayHeaderBack() {
    final visible = !_success && _step > 0;
    ref.read(overlayQuickBackProvider.notifier).state = (
      visible: visible,
      onBack: visible ? _backToModulePicker : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _resetToModulePicker(rebuild: false);
    _overlayResetSub = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == kOverlayResetEvent && mounted) {
        _resetToModulePicker();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlayHeaderBack());
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: _t.textPrimary.withValues(alpha: 0.7),
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => _message('Could not load profile: $e'),
      data: (user) {
        if (user == null) {
          return _message(
            'Open RUHH and sign in once, then try Quick log again.',
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _success
              ? _successView(key: const ValueKey('success'))
              : _step == 0
                  ? _pickModule(user, key: const ValueKey('pick'))
                  : _modulePanel(key: ValueKey('module-${_module!.name}')),
        );
      },
    );
  }

  Widget _message(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: _t.textSecondary,
            height: 1.4,
          ),
    );
  }

  Widget _successView({Key? key}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, size: 48, color: _t.accentMint),
        const SizedBox(height: 12),
        Text(
          'Saved',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _t.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Syncing with RUHH…',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _t.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _pickModule(UserLocal user, {Key? key}) {
    final modules = <QuickModule>[
      QuickModule.habit,
      QuickModule.prayer,
      QuickModule.movie,
      if (user.budgetEnabled) QuickModule.budget,
    ];

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What do you want to log?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.08,
            children: modules
                .map(
                  (m) => _ModuleTile(
                    label: _moduleLabel(m),
                    icon: _moduleIcon(m),
                    accent: _moduleColor(m),
                    pastel: _modulePastel(m),
                    onTap: () {
                      setState(() {
                        _module = m;
                        _step = 1;
                      });
                      _syncOverlayHeaderBack();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _modulePanel({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _moduleAction(),
          ),
        ),
      ],
    );
  }

  Widget _moduleAction() {
    return switch (_module) {
      QuickModule.budget => _budgetForm(),
      QuickModule.habit => _habitPanel(),
      QuickModule.prayer => _prayerPanel(),
      QuickModule.movie => _moviePanel(),
      null => const SizedBox.shrink(),
    };
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _t.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
      ),
    );
  }

  Widget _budgetForm() {
    final repoAsync = ref.watch(budgetRepositoryProvider);
    final incomeMode = _ledgerType == BudgetLedgerType.credit;
    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (repo) => FutureBuilder<List<CategoryLocal>>(
        future: repo.activeCategories(income: incomeMode),
        builder: (context, snap) {
          final cats = snap.data ?? [];
          if (_budgetCategory == null && cats.isNotEmpty) {
            _budgetCategory = cats.first;
          }
          if (cats.isNotEmpty &&
              _budgetCategory != null &&
              !cats.any((c) => c.remoteId == _budgetCategory!.remoteId)) {
            _budgetCategory = cats.first;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Add transaction'),
              _overlayField(
                controller: _amountCtrl,
                label: 'Amount',
                keyboardType: TextInputType.number,
                hint: '₹',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _typeChip(
                      label: 'Expense',
                      selected: _ledgerType == BudgetLedgerType.expense,
                      accent: NBColors.budget,
                      onTap: () => setState(() {
                        _ledgerType = BudgetLedgerType.expense;
                        _budgetCategory = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeChip(
                      label: 'Credit',
                      selected: _ledgerType == BudgetLedgerType.credit,
                      accent: NBMetrics.incomeGreen,
                      onTap: () => setState(() {
                        _ledgerType = BudgetLedgerType.credit;
                        _budgetCategory = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (cats.isEmpty)
                Text(
                  'Add categories in Budget first.',
                  style: TextStyle(color: _t.textSecondary),
                )
              else
                CategoryEmojiChipRow(
                  categories: cats,
                  selectedRemoteId: _budgetCategory?.remoteId,
                  onSelected: (c) => setState(() => _budgetCategory = c),
                ),
              const SizedBox(height: 12),
              _overlayField(
                controller: _noteCtrl,
                label: 'Note (optional)',
              ),
              const SizedBox(height: 16),
              _primaryButton(
                label: 'Save',
                accent: NBColors.budget,
                onPressed: cats.isEmpty ? null : () => _saveBudget(repo),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _habitPanel() {
    final repoAsync = ref.watch(habitRepositoryProvider);
    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (repo) => FutureBuilder<List<({HabitLocal habit, bool done})>>(
        key: ValueKey(_dataTick),
        future: _loadDueHabits(repo),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return _sectionTitle('Nothing due today — you\'re clear.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Today\'s habits'),
              ...items.map((item) {
                final habit = item.habit;
                final done = item.done;
                final color = Color(habit.colorValue);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await repo.toggleToday(habit);
                        bumpHabitRefresh(ref);
                        setState(() => _dataTick++);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: _t.surfaceSecondary.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  habitIconData(habit.icon),
                                  color: Colors.black,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: TextStyle(
                                    color: _t.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: _t.textSecondary,
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: done
                                      ? NBColors.habit.withValues(alpha: 0.9)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: done
                                        ? NBColors.habit
                                        : _t.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: done
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.black)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<List<({HabitLocal habit, bool done})>> _loadDueHabits(
    HabitRepository repo,
  ) async {
    final habits = await repo.activeHabits();
    final todayKey = repo.todayKey;
    final due = habits.where((h) => isDue(h, todayKey)).toList();
    final out = <({HabitLocal habit, bool done})>[];
    for (final h in due) {
      out.add((habit: h, done: await repo.isDoneToday(h)));
    }
    return out;
  }

  Widget _prayerPanel() {
    final repoAsync = ref.watch(prayerRepositoryProvider);
    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (repo) => FutureBuilder<Map<PrayerName, PrayerLogLocal>>(
        key: ValueKey(_dataTick),
        future: repo.logsForDay(DateTime.now()),
        builder: (context, snap) {
          final logs = snap.data ?? {};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Today\'s prayers'),
              ...PrayerName.values.map((p) {
                final status = logs[p]?.status ?? PrayerStatus.none;
                final done = _prayerMarkedDone(status);
                final accent = PrayerRepository.prayerAccent(p);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await repo.setStatus(
                          p,
                          done ? PrayerStatus.none : PrayerStatus.onTimeAlone,
                        );
                        bumpPrayerRefresh(ref);
                        setState(() => _dataTick++);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: done ? 0.35 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: done
                                ? accent.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.12),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PrayerRepository.prayerIcon(p),
                                color: _t.textPrimary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  PrayerRepository.label(p),
                                  style: TextStyle(
                                    color: _t.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: done
                                      ? accent.withValues(alpha: 0.95)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _t.textPrimary,
                                    width: 2,
                                  ),
                                ),
                                child: done
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.black)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  bool _prayerMarkedDone(PrayerStatus status) =>
      status == PrayerStatus.onTimeAlone ||
      status == PrayerStatus.withGroup ||
      status == PrayerStatus.lateAlone;

  Widget _moviePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _typeChip(
                label: 'Add new',
                selected: _movieMode == _MovieOverlayMode.add,
                accent: NBColors.movie,
                onTap: () => setState(() {
                  _movieMode = _MovieOverlayMode.add;
                  _movieSuggestions = [];
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _typeChip(
                label: 'Mark watched',
                selected: _movieMode == _MovieOverlayMode.markWatched,
                accent: NBColors.movie,
                onTap: () => setState(() {
                  _movieMode = _MovieOverlayMode.markWatched;
                  _movieTitleCtrl.clear();
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_movieMode == _MovieOverlayMode.add) _movieAddForm() else _movieMarkWatchedForm(),
      ],
    );
  }

  Widget _movieAddForm() {
    final repoAsync = ref.watch(movieRepositoryProvider);
    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (repo) => FutureBuilder<List<MovieCategoryLocal>>(
        future: repo.categoriesActive(),
        builder: (context, snap) {
          final cats = snap.data ?? [];
          if (_movieCategory == null && cats.isNotEmpty) {
            _movieCategory = cats.first;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Add to watchlist'),
              if (cats.isNotEmpty)
                MovieCategoryEmojiChipRow(
                  categories: cats,
                  selectedRemoteId: _movieCategory?.remoteId,
                  onSelected: (c) => setState(() => _movieCategory = c),
                ),
              const SizedBox(height: 12),
              _overlayField(
                controller: _movieTitleCtrl,
                label: 'Title',
                hint: 'Movie name',
              ),
              const SizedBox(height: 16),
              _primaryButton(
                label: 'Add',
                accent: NBColors.movie,
                onPressed: cats.isEmpty ? null : () => _saveNewMovie(repo),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _movieMarkWatchedForm() {
    final repoAsync = ref.watch(movieRepositoryProvider);
    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (repo) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Mark as watched'),
          _overlayField(
            controller: _movieSearchCtrl,
            label: 'Search your list',
            hint: 'Type a title…',
            onChanged: (q) {
              _movieSearchDebounce?.cancel();
              _movieSearchDebounce = Timer(
                const Duration(milliseconds: 200),
                () async {
                  final hits = await repo.searchLocalTitles(
                    q,
                    excludeStatus: WatchStatus.watched,
                  );
                  if (!mounted) return;
                  setState(() => _movieSuggestions = hits);
                },
              );
            },
          ),
          const SizedBox(height: 8),
          if (_movieSearchCtrl.text.trim().isEmpty)
            Text(
              'Only movies already in your library.',
              style: TextStyle(color: _t.textSecondary, fontSize: 13),
            )
          else if (_movieSuggestions.isEmpty)
            Text(
              'No matches — add the title under “Add new” first.',
              style: TextStyle(color: _t.textSecondary, fontSize: 13),
            )
          else
            ..._movieSuggestions.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _markMovieWatched(repo, m),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: _t.surfaceSecondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.title,
                                style: TextStyle(
                                  color: _t.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.check_circle_outline,
                              color: NBColors.movie,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _overlayField({
    required TextEditingController controller,
    String? label,
    String? hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              color: _t.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: _t.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _t.textTertiary),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.35),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _t.textPrimary.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeChip({
    required String label,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : _t.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required Color accent,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: onPressed == null
                ? _t.textTertiary
                : accent.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBudget(BudgetRepository repo) async {
    final amount = BudgetInr.parse(_amountCtrl.text);
    if (amount == null || amount <= 0 || _budgetCategory == null) return;
    await repo.upsertLedgerTransaction(
      type: _ledgerType,
      amount: amount,
      category: _budgetCategory!,
      note: _noteCtrl.text.trim(),
      date: DateTime.now(),
    );
    bumpBudgetRefresh(ref);
    _showSuccess();
  }

  Future<void> _saveNewMovie(MovieRepository repo) async {
    final title = _movieTitleCtrl.text.trim();
    if (title.isEmpty || _movieCategory == null) return;
    await repo.addManual(
      title: title,
      status: WatchStatus.wantToWatch,
      categoryRemoteId: _movieCategory!.remoteId,
    );
    bumpMovieRefresh(ref);
    _showSuccess();
  }

  Future<void> _markMovieWatched(MovieRepository repo, MovieLocal movie) async {
    await repo.setStatus(movie, WatchStatus.watched);
    bumpMovieRefresh(ref);
    _showSuccess();
  }

  void _showSuccess() {
    setState(() => _success = true);
    _syncOverlayHeaderBack();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _resetToModulePicker(rebuild: false);
      ref.read(overlayServiceProvider).close();
    });
  }

  String _moduleLabel(QuickModule m) => switch (m) {
        QuickModule.budget => 'Budget',
        QuickModule.habit => 'Habit',
        QuickModule.prayer => 'Prayer',
        QuickModule.movie => 'Movie',
      };

  IconData _moduleIcon(QuickModule m) => switch (m) {
        QuickModule.budget => Icons.account_balance_wallet_outlined,
        QuickModule.habit => Icons.check_circle_outline,
        QuickModule.prayer => Icons.mosque_outlined,
        QuickModule.movie => Icons.movie_outlined,
      };

  Color _moduleColor(QuickModule m) => switch (m) {
        QuickModule.budget => NBColors.budget,
        QuickModule.habit => NBColors.habit,
        QuickModule.prayer => NBColors.prayer,
        QuickModule.movie => NBColors.movie,
      };

  Color _modulePastel(QuickModule m) => switch (m) {
        QuickModule.budget => _t.accentSkyPastel,
        QuickModule.habit => _t.accentMintPastel,
        QuickModule.prayer => _t.accentLavenderPastel,
        QuickModule.movie => _t.accentCoralPastel,
      };
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.pastel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color pastel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RuhhTokens.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: pastel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Icon(icon, color: Colors.black, size: 26),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
