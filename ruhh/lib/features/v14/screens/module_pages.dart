import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/features/book/book_repository.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/data/v14_store.dart';
import 'package:ruhh/features/v14/logic/chat_intent.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/logic/undo_ticket.dart';
import 'package:ruhh/features/v14/logic/world_map.dart';
import 'package:ruhh/features/v14/logic/xp_rules.dart';
import 'package:ruhh/features/v14/screens/module_views.dart';
import 'package:ruhh/features/v14/v14_providers.dart';

class HabitsOrbitPage extends ConsumerStatefulWidget {
  const HabitsOrbitPage({super.key, this.preview});
  final List<OrbitHabit>? preview;

  @override
  ConsumerState<HabitsOrbitPage> createState() => _HabitsOrbitPageState();
}

class _HabitsOrbitPageState extends ConsumerState<HabitsOrbitPage> {
  List<OrbitHabit> _habits = const [];
  final _undo = UndoBuffer();
  String? _undoLabel;
  String? _undoId;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.preview != null) {
      _habits = widget.preview!;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final repo = await ref.read(habitRepositoryProvider.future);
      final active = await repo.activeHabits();
      final rows = <OrbitHabit>[];
      for (final habit in active) {
        rows.add(
          OrbitHabit(
            id: habit.remoteId,
            name: habit.name,
            done: await repo.isDoneToday(habit),
          ),
        );
      }
      if (mounted) setState(() => _habits = rows);
    } catch (_) {}
  }

  Future<void> _toggle(OrbitHabit habit) async {
    if (widget.preview != null) {
      setState(() {
        _habits = [
          for (final row in _habits)
            if (row.id == habit.id)
              OrbitHabit(id: row.id, name: row.name, done: !row.done)
            else
              row,
        ];
      });
      return;
    }
    final repo = await ref.read(habitRepositoryProvider.future);
    final full = await repo.byRemoteId(habit.id);
    if (full == null) return;
    await repo.toggleToday(full);
    final store = await ref.read(v14StoreProvider.future);
    final refId = 'habit:${habit.id}:${dateKeyFrom(DateTime.now())}';
    final nowDone = !habit.done;
    if (nowDone) {
      await store.award(
        source: 'habit',
        sourceRef: refId,
        amount: XpRules.habit,
      );
    } else {
      await store.reverse(refId);
    }
    final now = DateTime.now();
    final ticket = _undo.push(
      label: nowDone ? 'Lit ${habit.name}' : 'Cleared ${habit.name}',
      now: now,
      revert: () async {
        await repo.toggleToday(full);
        if (nowDone) {
          await store.reverse(refId);
        } else {
          await store.award(
            source: 'habit',
            sourceRef: refId,
            amount: XpRules.habit,
          );
        }
        await _load();
      },
    );
    setState(() {
      _undoLabel = ticket.label;
      _undoId = ticket.id;
    });
    await _load();
    _armTimer(ticket.id);
  }

  void _armTimer(String id) {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _undoId != id) return;
      _undo.expire(DateTime.now());
      setState(() {
        _undoLabel = null;
        _undoId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(habitRefreshProvider, (previous, next) {
      _load();
    });
    return HabitsOrbitView(
      habits: _habits,
      undoLabel: _undoLabel,
      onUndo: _undoId == null
          ? null
          : () async {
              await _undo.undo(_undoId!, DateTime.now());
              if (mounted) {
                setState(() {
                  _undoLabel = null;
                  _undoId = null;
                });
              }
            },
      onToggle: (habit) => _toggle(habit),
      onAdd: () => context.push('/habit/new'),
      onOpenQuests: () => context.go('/quests'),
      onOpenClassic: () => context.push('/habit/board?tab=1'),
    );
  }
}

class QuestsPage extends ConsumerStatefulWidget {
  const QuestsPage({super.key, this.store});
  final MemoryV14Store? store;
  @override
  ConsumerState<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends ConsumerState<QuestsPage> {
  List<QuestData> _quests = const [];
  final _undo = UndoBuffer();
  String? _undoLabel;
  String? _undoId;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<V14Store> _store() async =>
      widget.store ?? await ref.read(v14StoreProvider.future);

  Future<void> _load() async {
    final store = await _store();
    final rows = await store.quests();
    if (mounted) setState(() => _quests = rows);
  }

  void _expire(String id) {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _undoId != id) return;
      setState(() {
        _undoLabel = null;
        _undoId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return QuestsBoardView(
      quests: _quests,
      undoLabel: _undoLabel,
      onUndo: _undoId == null
          ? null
          : () async {
              await _undo.undo(_undoId!, DateTime.now());
              if (mounted) {
                setState(() {
                  _undoLabel = null;
                  _undoId = null;
                });
              }
            },
      onAdd: (title) async {
        final store = await _store();
        await store.addQuest(title);
        await _load();
      },
      onDelete: (quest) async {
        final store = await _store();
        await store.deleteQuest(quest.remoteId);
        await store.reverse('quest:${quest.remoteId}');
        final ticket = _undo.push(
          label: 'Removed ${quest.title}',
          now: DateTime.now(),
          revert: () async {
            await store.addQuest(quest.title);
            await _load();
          },
        );
        setState(() {
          _undoLabel = ticket.label;
          _undoId = ticket.id;
        });
        _expire(ticket.id);
        await _load();
      },
      onDone: (quest) async {
        final store = await _store();
        final next = !quest.done;
        await store.setQuestDone(quest.remoteId, next);
        final refId = 'quest:${quest.remoteId}';
        if (next) {
          await store.award(
            source: 'quest',
            sourceRef: refId,
            amount: XpRules.quest,
          );
        } else {
          await store.reverse(refId);
        }
        final ticket = _undo.push(
          label: next ? 'Done ${quest.title}' : 'Reopened ${quest.title}',
          now: DateTime.now(),
          revert: () async {
            await store.setQuestDone(quest.remoteId, !next);
            if (next) {
              await store.reverse(refId);
            } else {
              await store.award(
                source: 'quest',
                sourceRef: refId,
                amount: XpRules.quest,
              );
            }
            await _load();
          },
        );
        setState(() {
          _undoLabel = ticket.label;
          _undoId = ticket.id;
        });
        _expire(ticket.id);
        await _load();
      },
    );
  }
}

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key, this.store});
  final MemoryV14Store? store;
  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  List<GoalData> _goals = const [];
  Map<String, List<MilestoneData>> _miles = const {};
  final _undo = UndoBuffer();
  String? _undoLabel;
  String? _undoId;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<V14Store> _store() async =>
      widget.store ?? await ref.read(v14StoreProvider.future);

  Future<void> _load() async {
    final store = await _store();
    final goals = await store.goals();
    final miles = <String, List<MilestoneData>>{};
    for (final goal in goals) {
      miles[goal.remoteId] = await store.milestones(goal.remoteId);
    }
    if (mounted) {
      setState(() {
        _goals = goals;
        _miles = miles;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoalClimbView(
      goals: _goals,
      milestones: _miles,
      undoLabel: _undoLabel,
      onUndo: _undoId == null
          ? null
          : () async {
              await _undo.undo(_undoId!, DateTime.now());
              if (mounted) setState(() => _undoLabel = null);
            },
      onAddGoal: (title) async {
        await (await _store()).addGoal(title);
        await _load();
      },
      onAddMilestone: (goalId, title) async {
        await (await _store()).addMilestone(goalId, title);
        await _load();
      },
      onToggleGoal: (goal) async {
        final store = await _store();
        final next = !goal.done;
        await store.setGoalDone(goal.remoteId, next);
        final refId = 'goal:${goal.remoteId}';
        if (next) {
          await store.award(
            source: 'goal',
            sourceRef: refId,
            amount: XpRules.goal,
          );
        } else {
          await store.reverse(refId);
        }
        _arm('Goal ${goal.title}', () async {
          await store.setGoalDone(goal.remoteId, !next);
          if (next) {
            await store.reverse(refId);
          }
          await _load();
        });
        await _load();
      },
      onToggleMilestone: (mile) async {
        final store = await _store();
        final next = !mile.done;
        await store.setMilestoneDone(mile.remoteId, next);
        final refId = 'milestone:${mile.remoteId}';
        if (next) {
          await store.award(
            source: 'milestone',
            sourceRef: refId,
            amount: XpRules.milestone,
          );
        } else {
          await store.reverse(refId);
        }
        _arm(mile.title, () async {
          await store.setMilestoneDone(mile.remoteId, !next);
          if (next) await store.reverse(refId);
          await _load();
        });
        await _load();
      },
    );
  }

  void _arm(String label, Future<void> Function() revert) {
    final ticket = _undo.push(
      label: label,
      now: DateTime.now(),
      revert: revert,
    );
    setState(() {
      _undoLabel = ticket.label;
      _undoId = ticket.id;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted && _undoId == ticket.id) {
        setState(() => _undoLabel = null);
      }
    });
  }
}

class MoneyBlocksPage extends ConsumerStatefulWidget {
  const MoneyBlocksPage({super.key, this.spend, this.recent});
  final Map<String, double>? spend;
  final List<String>? recent;

  @override
  ConsumerState<MoneyBlocksPage> createState() => _MoneyBlocksPageState();
}

class _MoneyBlocksPageState extends ConsumerState<MoneyBlocksPage> {
  Map<String, double> _spend = const {};
  List<String> _recent = const [];
  List<int> _ids = const [];
  String? _undoLabel;
  Timer? _moneyTimer;

  @override
  void dispose() {
    _moneyTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.spend != null) {
      _spend = widget.spend!;
      _recent = widget.recent ?? const [];
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      final spend = await repo.spendByCategoryThisMonth();
      final recent = await repo.recent(limit: 6);
      if (!mounted) return;
      setState(() {
        _spend = spend;
        _recent = [
          for (final tx in recent)
            '${tx.category} · ${BudgetInr.format(tx.amount)}',
        ];
        _ids = [for (final tx in recent) tx.id];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(budgetRefreshProvider, (previous, next) {
      _load();
    });
    final spent = _spend.values.fold<double>(0, (s, v) => s + v);
    return MoneyBlocksView(
      spend: _spend,
      spent: spent,
      recent: _recent,
      undoLabel: _undoLabel,
      onUndo: _pending == null
          ? null
          : () async {
              final action = _pending;
              _pending = null;
              if (action != null) await action();
            },
      onAdd: () => context.push('/budget/add'),
      onLedger: () => context.push('/budget/ledger?tab=1'),
      onDelete: (index) async {
        if (widget.spend != null || index >= _ids.length) return;
        final repo = await ref.read(budgetRepositoryProvider.future);
        final id = _ids[index];
        final tx = await repo.getTransaction(id);
        if (tx == null) return;
        await repo.delete(id);
        _pending = () async {
          await repo.add(
            amount: tx.amount,
            isIncome: tx.isIncome,
            category: tx.category,
            account: tx.account,
            title: tx.title,
            note: tx.note,
            occurredAt: tx.occurredAt,
          );
          if (mounted) setState(() => _undoLabel = null);
          await _load();
        };
        if (mounted) setState(() => _undoLabel = 'Removed ${tx.category}');
        await _load();
        _moneyTimer?.cancel();
        _moneyTimer = Timer(const Duration(seconds: 5), () {
          if (!mounted) return;
          _pending = null;
          setState(() => _undoLabel = null);
        });
      },
    );
  }

  Future<void> Function()? _pending;
}

class PrayerSkyPage extends ConsumerStatefulWidget {
  const PrayerSkyPage({super.key, this.marks, this.onToggle});
  final Map<String, String>? marks;
  final ValueChanged<String>? onToggle;

  @override
  ConsumerState<PrayerSkyPage> createState() => _PrayerSkyPageState();
}

class _PrayerSkyPageState extends ConsumerState<PrayerSkyPage> {
  Map<String, String> _marks = const {
    'fajr': 'unmarked',
    'dhuhr': 'unmarked',
    'asr': 'unmarked',
    'maghrib': 'unmarked',
    'isha': 'unmarked',
  };
  String? _undo;

  @override
  void initState() {
    super.initState();
    if (widget.marks != null) {
      _marks = widget.marks!;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final repo = await ref.read(prayerRepositoryProvider.future);
      final log = await repo.dailyLogFor(dateKeyFrom(DateTime.now()));
      if (!mounted) return;
      setState(() {
        _marks = {
          for (final name in PrayerName.values)
            name.name: log.statuses[name]!.name,
        };
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PrayerSkyView(
      marks: _marks,
      undoLabel: _undo,
      onUndo: _undo == null
          ? null
          : () async {
              final name = _undo!.split(' ').last;
              await _toggle(name, fromUndo: true);
              if (mounted) setState(() => _undo = null);
            },
      onToggle: (name) {
        if (widget.onToggle != null) {
          widget.onToggle!(name);
          setState(() {
            final current = _marks[name] ?? 'unmarked';
            _marks = {
              ..._marks,
              name: current == 'prayed' ? 'unmarked' : 'prayed',
            };
            _undo = 'Prayer $name';
          });
          return;
        }
        _toggle(name);
      },
      onOpenFull: () => context.push('/prayer/full'),
    );
  }

  Future<void> _toggle(String name, {bool fromUndo = false}) async {
    final repo = await ref.read(prayerRepositoryProvider.future);
    await repo.toggleTrackerPrayer(
      dateKeyFrom(DateTime.now()),
      PrayerName.values.byName(name),
    );
    if (!fromUndo && mounted) setState(() => _undo = 'Prayer $name');
    await _load();
  }
}

class NightNookPage extends ConsumerStatefulWidget {
  const NightNookPage({
    super.key,
    this.books,
    this.movies,
    this.booksRoute = true,
  });
  final List<String>? books;
  final List<String>? movies;
  final bool booksRoute;

  @override
  ConsumerState<NightNookPage> createState() => _NightNookPageState();
}

class _NightNookPageState extends ConsumerState<NightNookPage> {
  List<String> _books = const [];
  List<String> _movies = const [];

  @override
  void initState() {
    super.initState();
    if (widget.books != null || widget.movies != null) {
      _books = widget.books ?? const [];
      _movies = widget.movies ?? const [];
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final books = await ref.read(bookRepositoryProvider.future);
      final shelf = await books.wantToRead();
      final movies = await ref.read(movieRepositoryProvider.future);
      final all = await movies.all();
      if (!mounted) return;
      setState(() {
        _books = [for (final book in shelf) book.title];
        _movies = [for (final movie in all.take(12)) movie.title];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return NightNookView(
      books: _books,
      movies: _movies,
      onAddBook: () => context.push('/book/add'),
      onAddMovie: () => context.push('/movie/add'),
      onOpenBooks: () => context.push('/book/library'),
      onOpenMovies: () => context.push('/movie/library'),
    );
  }
}

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key, this.store, this.now});
  final MemoryV14Store? store;
  final DateTime? now;

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  List<PlannerStopData> _stops = const [];
  String? _undo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _key => dateKeyFrom(widget.now ?? DateTime.now());

  Future<V14Store> _store() async =>
      widget.store ?? await ref.read(v14StoreProvider.future);

  Future<void> _load() async {
    final rows = await (await _store()).stops(_key);
    if (mounted) setState(() => _stops = rows);
  }

  @override
  Widget build(BuildContext context) {
    return PlannerDialView(
      dateKey: _key,
      stops: _stops,
      undoLabel: _undo,
      onUndo: _undoRevert == null
          ? null
          : () async {
              final action = _undoRevert;
              _undoRevert = null;
              if (action != null) await action();
              if (mounted) setState(() => _undo = null);
            },
      onAdd: (label, minute) async {
        final store = await _store();
        final created = await store.addStop(_key, label, minute);
        _undoRevert = () async {
          await store.deleteStop(created.id);
          await _load();
        };
        setState(() => _undo = 'Added $label');
        await _load();
      },
      onMove: (id, minute) async {
        final store = await _store();
        final before = _stops.firstWhere((s) => s.id == id).minuteOfDay;
        await store.moveStop(id, minute);
        _undoRevert = () async {
          await store.moveStop(id, before);
          await _load();
        };
        setState(() => _undo = 'Moved');
        await _load();
      },
    );
  }

  Future<void> Function()? _undoRevert;
}

class JourneyPage extends ConsumerStatefulWidget {
  const JourneyPage({super.key, this.store});
  final MemoryV14Store? store;
  @override
  ConsumerState<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends ConsumerState<JourneyPage> {
  List<JourneyMarkData> _marks = const [];
  var _level = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<V14Store> _store() async {
    final injected = widget.store;
    if (injected != null) return injected;
    return ref.read(v14StoreProvider.future);
  }

  Future<void> _load() async {
    final store = await _store();
    final marks = await store.marks();
    final xp = await store.lifetimeXp();
    if (mounted) {
      setState(() {
        _marks = marks;
        _level = const WorldMap().progress(xp).level;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.store == null
        ? ref.watch(v14ProfileProvider).value
        : widget.store!.profile;
    final pet = petPackFor(profile?.petId);
    final map = const WorldMap();
    final progress = map.progress(map.curve.threshold(_level));
    return JourneyView(
      worldName: pet.worldName(progress.world),
      formName: pet.formName(progress.world, progress.subStage),
      level: _level,
      marks: _marks,
      onAddRelic: (title) async {
        final store = await _store();
        await store.addMark(title, 'relic');
        await _load();
      },
    );
  }
}

class CompanionChatPage extends ConsumerStatefulWidget {
  const CompanionChatPage({super.key, this.store, this.sink});
  final MemoryV14Store? store;
  final ChatSink? sink;

  @override
  ConsumerState<CompanionChatPage> createState() => _CompanionChatPageState();
}

class _CompanionChatPageState extends ConsumerState<CompanionChatPage> {
  final _lines = <String>[];
  ChatProposal? _proposal;

  @override
  Widget build(BuildContext context) {
    final profile = widget.store == null
        ? ref.watch(v14ProfileProvider).value
        : widget.store!.profile;
    final pet = petPackFor(profile?.petId);
    final name = profile?.displayPetName(pet.defaultName) ?? pet.defaultName;
    return CompanionChatView(
      companionName: name,
      lines: _lines,
      proposal: _proposal,
      onSubmit: (text) {
        final proposal = parseCompanionUtterance(text);
        setState(() {
          _lines.add(text);
          _lines.add(proposal.summary);
          _proposal = proposal.actionable ? proposal : null;
        });
      },
      onCancel: () => setState(() {
        _lines.add('Cancelled.');
        _proposal = null;
      }),
      onEdit: (text) {
        final parsed = parseCompanionUtterance(text);
        setState(() {
          if (parsed.actionable) {
            _proposal = parsed;
          } else if (_proposal != null && text.trim().isNotEmpty) {
            _proposal = ChatProposal(
              effect: _proposal!.effect,
              summary: 'Updated to “$text”.',
              grantsXp: _proposal!.grantsXp,
              title: text.trim(),
              amount: _proposal!.amount,
              category: text.trim().isEmpty
                  ? _proposal!.category
                  : _proposal!.category,
            );
          }
          _lines.add('Edited.');
        });
      },
      onConfirm: () async {
        final proposal = _proposal;
        if (proposal == null) return;
        final sink = widget.sink ?? _RepoSink(ref);
        await applyChatProposal(proposal, sink);
        if (widget.store != null) {
          await widget.store!.addChat(
            'user',
            proposal.summary,
            proposalState: 'confirmed',
          );
        } else {
          final store = await ref.read(v14StoreProvider.future);
          await store.addChat(
            'user',
            proposal.summary,
            proposalState: 'confirmed',
          );
        }
        if (mounted) {
          setState(() {
            _lines.add('Saved on this device.');
            _proposal = null;
          });
        }
      },
    );
  }
}

class _RepoSink implements ChatSink {
  _RepoSink(this.ref);
  final WidgetRef ref;

  @override
  Future<void> addHabit(String name) async {
    final repo = await ref.read(habitRepositoryProvider.future);
    await repo.addHabit(name: name, colorValue: 0xFF3FC08A);
  }

  @override
  Future<void> completeHabit(String name) async {
    final repo = await ref.read(habitRepositoryProvider.future);
    final habits = await repo.activeHabits();
    final match = habits.where((h) => h.name == name);
    if (match.isEmpty) return;
    final habit = match.first;
    await repo.toggleToday(habit);
    final store = await ref.read(v14StoreProvider.future);
    await store.award(
      source: 'habit',
      sourceRef: 'habit:${habit.remoteId}:${dateKeyFrom(DateTime.now())}',
      amount: XpRules.habit,
    );
  }

  @override
  Future<void> logPrayer(String name) async {
    final repo = await ref.read(prayerRepositoryProvider.future);
    await repo.toggleTrackerPrayer(
      dateKeyFrom(DateTime.now()),
      PrayerName.values.byName(name),
    );
  }

  @override
  Future<void> addSpend(double amount, String category) async {
    final repo = await ref.read(budgetRepositoryProvider.future);
    await repo.add(
      amount: amount,
      isIncome: false,
      category: category,
      title: category,
    );
  }

  @override
  Future<void> addQuest(String title) async {
    final store = await ref.read(v14StoreProvider.future);
    await store.addQuest(title);
  }

  @override
  Future<void> completeQuest(String title) async {
    final store = await ref.read(v14StoreProvider.future);
    final quests = await store.quests();
    final match = quests.where((q) => q.title == title);
    if (match.isEmpty) return;
    final quest = match.first;
    await store.setQuestDone(quest.remoteId, true);
    await store.award(
      source: 'quest',
      sourceRef: 'quest:${quest.remoteId}',
      amount: XpRules.quest,
    );
  }

  @override
  Future<void> addGoal(String title) async {
    final store = await ref.read(v14StoreProvider.future);
    await store.addGoal(title);
  }
}

class V14SettingsPage extends ConsumerWidget {
  const V14SettingsPage({super.key, this.profile, this.onProfile});
  final V14ProfileData? profile;
  final ValueChanged<V14ProfileData>? onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        profile ??
        ref.watch(v14ProfileProvider).value ??
        const V14ProfileData();
    final pet = petPackFor(data.petId);
    return SettingsTilesView(
      listMode: data.listMode,
      leftHand: data.leftHandOrb,
      petLabel: data.petId == null
          ? 'Not chosen'
          : '${pet.kind} · ${data.displayPetName(pet.defaultName)}',
      onListMode: (value) =>
          _save(context, ref, data.copyWith(listMode: value)),
      onLeftHand: (value) =>
          _save(context, ref, data.copyWith(leftHandOrb: value)),
      onCallName: (name) => _save(context, ref, data.copyWith(callName: name)),
      onNotifications: () => context.push('/settings/notifications'),
      onOverlay: () => context.push('/settings/overlay'),
      onAnalytics: () => context.go('/analytics'),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    V14ProfileData next,
  ) async {
    if (onProfile != null) {
      onProfile!(next);
      return;
    }
    final store = await ref.read(v14StoreProvider.future);
    await store.saveProfile(next);
    ref.invalidate(v14ProfileProvider);
  }
}

class PetPickerPage extends ConsumerStatefulWidget {
  const PetPickerPage({super.key});

  @override
  ConsumerState<PetPickerPage> createState() => _PetPickerPageState();
}

class _PetPickerPageState extends ConsumerState<PetPickerPage> {
  String _selected = 'dragon';
  var _confirm = false;
  var _checked = false;
  String _petName = '';
  String _callName = '';

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(v14ProfileProvider).value;
    final locked = profile?.petId != null;
    if (_confirm && !locked) {
      return PetConfirmView(
        petId: _selected,
        checked: _checked,
        onChecked: (value) => setState(() => _checked = value),
        onBack: () => setState(() => _confirm = false),
        onNames: (pet, call) {
          _petName = pet;
          _callName = call;
        },
        onConfirm: () async {
          final store = await ref.read(v14StoreProvider.future);
          final result = await store.choosePet(
            petId: _selected,
            petName: _petName.isEmpty
                ? petPackFor(_selected).defaultName
                : _petName,
            callName: _callName,
            understandPermanent: _checked,
            now: DateTime.now(),
          );
          if (!context.mounted) return;
          if (result == PetWrite.saved) {
            ref.invalidate(v14ProfileProvider);
            ref.read(tryPetProvider.notifier).clear();
            context.go('/home');
          }
        },
      );
    }
    return PetPickerView(
      selected: _selected,
      locked: locked,
      onSelect: (id) => setState(() => _selected = id),
      onTry: () {
        ref.read(tryPetProvider.notifier).start(_selected);
        context.go('/home');
      },
      onChoose: locked ? () {} : () => setState(() => _confirm = true),
    );
  }
}
