import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/logic/chat_intent.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/logic/treemap_layout.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';
import 'package:ruhh/features/v14/widgets/v14_chrome.dart';

class OrbitHabit {
  const OrbitHabit({required this.id, required this.name, required this.done});
  final String id;
  final String name;
  final bool done;
}

class HabitsOrbitView extends StatelessWidget {
  const HabitsOrbitView({
    super.key,
    required this.habits,
    required this.onToggle,
    required this.onAdd,
    required this.onOpenQuests,
    required this.onOpenClassic,
    this.undoLabel,
    this.onUndo,
  });

  final List<OrbitHabit> habits;
  final ValueChanged<OrbitHabit> onToggle;
  final VoidCallback onAdd;
  final VoidCallback onOpenQuests;
  final VoidCallback onOpenClassic;
  final String? undoLabel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Habits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hold is optional. Tap Light it.',
            style: v14Text(13, color: V14Colors.muted),
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            Text(
              'No habits yet.',
              key: const Key('habits-empty'),
              style: v14Text(16),
            )
          else
            SizedBox(
              height: 280,
              child: LayoutBuilder(
                builder: (context, c) {
                  final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
                  final radius = math.min(c.maxWidth, c.maxHeight) * 0.34;
                  return Stack(
                    children: [
                      CustomPaint(
                        size: Size(c.maxWidth, c.maxHeight),
                        painter: _OrbitPainter(center, radius),
                      ),
                      for (var i = 0; i < habits.length && i < 8; i++)
                        _orbit(
                          center,
                          radius,
                          i,
                          habits.length.clamp(1, 8),
                          habits[i],
                        ),
                    ],
                  );
                },
              ),
            ),
          if (habits.length > 8)
            for (final habit in habits.skip(8)) _habitRow(habit),
          if (undoLabel != null && onUndo != null)
            V14UndoBar(label: undoLabel!, onUndo: onUndo!),
          const SizedBox(height: 8),
          V14Button(label: 'New habit', onPressed: onAdd),
          const SizedBox(height: 8),
          V14Button(label: 'Quests', primary: false, onPressed: onOpenQuests),
          const SizedBox(height: 8),
          V14Button(
            label: 'Classic list',
            primary: false,
            onPressed: onOpenClassic,
          ),
        ],
      ),
    );
  }

  Widget _orbit(
    Offset center,
    double radius,
    int index,
    int count,
    OrbitHabit habit,
  ) {
    final angle = -math.pi / 2 + (2 * math.pi * index / count);
    final dx = center.dx + math.cos(angle) * radius - 70;
    final dy = center.dy + math.sin(angle) * radius - 28;
    return Positioned(left: dx, top: dy, width: 140, child: _habitRow(habit));
  }

  Widget _habitRow(OrbitHabit habit) {
    return Semantics(
      button: true,
      label: 'Light it ${habit.name}',
      child: TextButton(
        key: Key('habit-${habit.id}'),
        onPressed: () => onToggle(habit),
        child: Text(
          habit.done ? '${habit.name} · lit' : 'Light it · ${habit.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: v14Text(
            13,
            color: habit.done ? V14Colors.jade : V14Colors.text,
          ),
        ),
      ),
    );
  }
}

class QuestsBoardView extends StatelessWidget {
  const QuestsBoardView({
    super.key,
    required this.quests,
    required this.onAdd,
    required this.onDone,
    required this.onDelete,
    this.undoLabel,
    this.onUndo,
  });

  final List<QuestData> quests;
  final ValueChanged<String> onAdd;
  final ValueChanged<QuestData> onDone;
  final ValueChanged<QuestData> onDelete;
  final String? undoLabel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Quests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (quests.isEmpty)
            Text(
              'No quests yet.',
              key: const Key('quests-empty'),
              style: v14Text(16),
            ),
          for (final quest in quests)
            V14Panel(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.title,
                      style: v14Text(
                        15,
                        color: quest.done ? V14Colors.dim : V14Colors.text,
                      ),
                    ),
                  ),
                  TextButton(
                    key: Key('quest-done-${quest.remoteId}'),
                    onPressed: () => onDone(quest),
                    child: Text(
                      quest.done ? 'Undo done' : 'Done',
                      style: v14Text(14, color: V14Colors.jade),
                    ),
                  ),
                  IconButton(
                    key: Key('quest-delete-${quest.remoteId}'),
                    onPressed: () => onDelete(quest),
                    icon: const Icon(Icons.close, color: V14Colors.dim),
                  ),
                ],
              ),
            ),
          if (undoLabel != null && onUndo != null)
            V14UndoBar(label: undoLabel!, onUndo: onUndo!),
          V14Field(
            fieldKey: const Key('quest-title'),
            hint: 'New quest',
            button: 'Add quest',
            onSubmit: onAdd,
          ),
        ],
      ),
    );
  }
}

class GoalClimbView extends StatelessWidget {
  const GoalClimbView({
    super.key,
    required this.goals,
    required this.milestones,
    required this.onAddGoal,
    required this.onAddMilestone,
    required this.onToggleMilestone,
    required this.onToggleGoal,
    this.undoLabel,
    this.onUndo,
  });

  final List<GoalData> goals;
  final Map<String, List<MilestoneData>> milestones;
  final ValueChanged<String> onAddGoal;
  final void Function(String goalId, String title) onAddMilestone;
  final ValueChanged<MilestoneData> onToggleMilestone;
  final ValueChanged<GoalData> onToggleGoal;
  final String? undoLabel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Goal climb',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (goals.isEmpty)
            Text(
              'The climb is empty.',
              key: const Key('goals-empty'),
              style: v14Text(16),
            ),
          for (final goal in goals) ...[
            Text(
              goal.title,
              style: v14Text(
                18,
                family: V14Fonts.display,
                color: goal.done ? V14Colors.dim : V14Colors.text,
              ),
            ),
            TextButton(
              key: Key('goal-done-${goal.remoteId}'),
              onPressed: () => onToggleGoal(goal),
              child: Text(
                goal.done ? 'Reopen goal' : 'Mark goal done',
                style: v14Text(14, color: V14Colors.gold),
              ),
            ),
            for (final mile
                in milestones[goal.remoteId] ?? const <MilestoneData>[])
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: Key('mile-${mile.remoteId}'),
                  onPressed: () => onToggleMilestone(mile),
                  child: Text(
                    mile.done ? '${mile.title} · done' : mile.title,
                    style: v14Text(
                      14,
                      color: mile.done ? V14Colors.jade : V14Colors.text,
                    ),
                  ),
                ),
              ),
            V14Field(
              fieldKey: Key('mile-title-${goal.remoteId}'),
              hint: 'Milestone',
              button: 'Add milestone',
              primary: false,
              onSubmit: (title) => onAddMilestone(goal.remoteId, title),
            ),
          ],
          if (undoLabel != null && onUndo != null)
            V14UndoBar(label: undoLabel!, onUndo: onUndo!),
          V14Field(
            fieldKey: const Key('goal-title'),
            hint: 'New goal',
            button: 'Add goal',
            onSubmit: onAddGoal,
          ),
        ],
      ),
    );
  }
}

class MoneyBlocksView extends StatelessWidget {
  const MoneyBlocksView({
    super.key,
    required this.spend,
    required this.spent,
    required this.onAdd,
    required this.onLedger,
    required this.recent,
    required this.onDelete,
    this.undoLabel,
    this.onUndo,
  });

  final Map<String, double> spend;
  final double spent;
  final VoidCallback onAdd;
  final VoidCallback onLedger;
  final List<String> recent;
  final ValueChanged<int> onDelete;
  final String? undoLabel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Money',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              BudgetInr.format(spent),
              key: const Key('money-total'),
              style: v14Text(28, family: V14Fonts.display),
            ),
          ),
          Text(
            'This month · INR · never earns XP',
            style: v14Text(13, color: V14Colors.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, c) {
                final tiles = layoutTreemap(
                  Rect.fromLTWH(0, 0, c.maxWidth, c.maxHeight),
                  spend,
                );
                if (tiles.isEmpty) {
                  return Text(
                    'No spending this month.',
                    key: const Key('money-empty'),
                    style: v14Text(16),
                  );
                }
                return Stack(
                  children: [
                    for (var i = 0; i < tiles.length; i++)
                      Positioned.fromRect(
                        rect: tiles[i].rect.deflate(2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: V14Colors
                                .moneyFills[i % V14Colors.moneyFills.length],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              '${tiles[i].label}\n${BudgetInr.format(tiles[i].value)}',
                              style: v14Text(12, color: V14Colors.base),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          for (var i = 0; i < recent.length; i++)
            ListTile(
              title: Text(recent[i], style: v14Text(14)),
              trailing: IconButton(
                key: Key('tx-delete-$i'),
                onPressed: () => onDelete(i),
                icon: const Icon(Icons.delete_outline, color: V14Colors.dim),
              ),
            ),
          if (undoLabel != null && onUndo != null)
            V14UndoBar(label: undoLabel!, onUndo: onUndo!),
          V14Button(label: 'Add spend', onPressed: onAdd),
          const SizedBox(height: 8),
          V14Button(label: 'Full ledger', primary: false, onPressed: onLedger),
        ],
      ),
    );
  }
}

class PrayerSkyView extends StatelessWidget {
  const PrayerSkyView({
    super.key,
    required this.marks,
    required this.onToggle,
    required this.onOpenFull,
    this.undoLabel,
    this.onUndo,
  });

  /// name -> prayed | missed | unmarked | excused
  final Map<String, String> marks;
  final ValueChanged<String> onToggle;
  final VoidCallback onOpenFull;
  final String? undoLabel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    const names = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    return _Page(
      title: 'Prayer',
      child: Column(
        children: [
          Text(
            'Tracked, never scored · no XP',
            key: const Key('prayer-no-xp'),
            style: v14Text(13, color: V14Colors.lavender),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _ArcPainter(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final name in names)
                    _prayerDot(name, marks[name] ?? 'unmarked'),
                ],
              ),
            ),
          ),
          if (undoLabel != null && onUndo != null)
            V14UndoBar(label: undoLabel!, onUndo: onUndo!),
          V14Button(
            label: 'Full tracker',
            primary: false,
            onPressed: onOpenFull,
          ),
        ],
      ),
    );
  }

  Widget _prayerDot(String name, String status) {
    final color = switch (status) {
      'prayed' => V14Colors.lavender,
      'missed' => V14Colors.missed,
      'excused' => V14Colors.missed,
      _ => V14Colors.base,
    };
    return Semantics(
      button: true,
      label: '$name $status',
      child: InkWell(
        key: Key('prayer-$name'),
        onTap: () => onToggle(name),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: V14Colors.lavender),
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: v14Text(10, color: V14Colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = V14Colors.lavender.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromLTWH(12, 20, size.width - 24, size.height),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NightNookView extends StatelessWidget {
  const NightNookView({
    super.key,
    required this.books,
    required this.movies,
    required this.onAddBook,
    required this.onAddMovie,
    required this.onOpenBooks,
    required this.onOpenMovies,
  });

  final List<String> books;
  final List<String> movies;
  final VoidCallback onAddBook;
  final VoidCallback onAddMovie;
  final VoidCallback onOpenBooks;
  final VoidCallback onOpenMovies;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Night nook',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Books and movies award no XP.',
            key: const Key('nook-no-xp'),
            style: v14Text(13, color: V14Colors.muted),
          ),
          const SizedBox(height: 8),
          Text('Shelf', style: v14Text(16, family: V14Fonts.display)),
          if (books.isEmpty)
            Text(
              'The shelf is empty.',
              key: const Key('books-empty'),
              style: v14Text(14),
            ),
          for (final title in books) Text(title, style: v14Text(14)),
          V14Button(label: 'Add book', onPressed: onAddBook),
          V14Button(
            label: 'Book library',
            primary: false,
            onPressed: onOpenBooks,
          ),
          const SizedBox(height: 12),
          Text('Movies', style: v14Text(16, family: V14Fonts.display)),
          if (movies.isEmpty)
            Text(
              'No movies yet.',
              key: const Key('movies-empty'),
              style: v14Text(14),
            ),
          for (final title in movies)
            V14Panel(child: Text(title, style: v14Text(14))),
          V14Button(label: 'Add movie', onPressed: onAddMovie),
          V14Button(
            label: 'Movie library',
            primary: false,
            onPressed: onOpenMovies,
          ),
        ],
      ),
    );
  }
}

class PlannerDialView extends StatelessWidget {
  const PlannerDialView({
    super.key,
    required this.dateKey,
    required this.stops,
    required this.onMove,
    required this.onAdd,
    this.undoLabel,
    this.onUndo,
  });

  final String dateKey;
  final List<PlannerStopData> stops;
  final void Function(int id, int minute) onMove;
  final void Function(String label, int minute) onAdd;
  final String? undoLabel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Planner',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(dateKey, style: v14Text(13, color: V14Colors.muted)),
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _DialPainter(stops),
              child: const SizedBox.expand(),
            ),
          ),
          for (final stop in stops)
            ListTile(
              title: Text(
                '${stop.label} · ${_hhmm(stop.minuteOfDay)}',
                style: v14Text(14),
              ),
              trailing: TextButton(
                key: Key('move-${stop.id}'),
                onPressed: () =>
                    onMove(stop.id, (stop.minuteOfDay + 30) % 1440),
                child: Text('Move', style: v14Text(14, color: V14Colors.jade)),
              ),
            ),
          if (undoLabel != null && onUndo != null)
            V14UndoBar(label: undoLabel!, onUndo: onUndo!),
          V14Field(
            fieldKey: const Key('stop-label'),
            hint: 'Stop',
            button: 'Add stop',
            onSubmit: (label) => onAdd(label, 9 * 60),
          ),
        ],
      ),
    );
  }

  String _hhmm(int minute) {
    final h = (minute ~/ 60).toString().padLeft(2, '0');
    final m = (minute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.stops);
  final List<PlannerStopData> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.36;
    final paint = Paint()
      ..color = V14Colors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(c, r, paint);
    final mark = Paint()..color = V14Colors.amber;
    for (final stop in stops) {
      final angle = -math.pi / 2 + (stop.minuteOfDay / 1440) * math.pi * 2;
      canvas.drawCircle(
        c + Offset(math.cos(angle) * r, math.sin(angle) * r),
        7,
        mark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.stops != stops;
}

class JourneyView extends StatelessWidget {
  const JourneyView({
    super.key,
    required this.worldName,
    required this.formName,
    required this.level,
    required this.marks,
    required this.onAddRelic,
  });

  final String worldName;
  final String formName;
  final int level;
  final List<JourneyMarkData> marks;
  final ValueChanged<String> onAddRelic;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Journey',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lv $level · $formName',
            style: v14Text(20, family: V14Fonts.display),
          ),
          Text(worldName, style: v14Text(14, color: V14Colors.muted)),
          Text(
            'Relics live on this device.',
            style: v14Text(13, color: V14Colors.dim),
          ),
          if (marks.isEmpty)
            Text(
              'No relics yet.',
              key: const Key('relics-empty'),
              style: v14Text(14),
            ),
          for (final mark in marks)
            Text('${mark.kind} · ${mark.title}', style: v14Text(14)),
          V14Field(
            fieldKey: const Key('relic-title'),
            hint: 'Relic',
            button: 'Keep relic',
            onSubmit: onAddRelic,
          ),
        ],
      ),
    );
  }
}

class CompanionChatView extends StatefulWidget {
  const CompanionChatView({
    super.key,
    required this.lines,
    required this.proposal,
    required this.onSubmit,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
    required this.companionName,
  });

  final List<String> lines;
  final ChatProposal? proposal;
  final ValueChanged<String> onSubmit;
  final VoidCallback onConfirm;
  final ValueChanged<String> onEdit;
  final VoidCallback onCancel;
  final String companionName;

  @override
  State<CompanionChatView> createState() => _CompanionChatViewState();
}

class _CompanionChatViewState extends State<CompanionChatView> {
  final _box = TextEditingController();
  final _edit = TextEditingController();

  @override
  void didUpdateWidget(CompanionChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.proposal?.title ?? '';
    if (oldWidget.proposal?.title != widget.proposal?.title &&
        _edit.text != next) {
      _edit.text = next;
    }
  }

  @override
  void dispose() {
    _box.dispose();
    _edit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;
    return _Page(
      title: widget.companionName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in widget.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line, style: v14Text(14, family: V14Fonts.companion)),
            ),
          if (proposal != null && proposal.actionable) ...[
            V14Panel(
              child: Text(
                proposal.summary,
                key: const Key('chat-proposal'),
                style: v14Text(14),
              ),
            ),
            TextField(
              key: const Key('chat-edit'),
              controller: _edit,
              style: v14Text(14),
            ),
            Row(
              children: [
                Expanded(
                  child: V14Button(
                    label: 'Confirm',
                    onPressed: widget.onConfirm,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: V14Button(
                    label: 'Edit',
                    primary: false,
                    onPressed: () => widget.onEdit(_edit.text),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: V14Button(
                    label: 'Cancel',
                    primary: false,
                    onPressed: widget.onCancel,
                  ),
                ),
              ],
            ),
          ],
          TextField(
            key: const Key('chat-input'),
            controller: _box,
            style: v14Text(15),
            decoration: const InputDecoration(hintText: 'Ask on this device'),
          ),
          V14Button(
            label: 'Send',
            onPressed: () {
              final text = _box.text.trim();
              if (text.isEmpty) return;
              widget.onSubmit(text);
              _box.clear();
            },
          ),
        ],
      ),
    );
  }
}

class SettingsTilesView extends StatelessWidget {
  const SettingsTilesView({
    super.key,
    required this.listMode,
    required this.leftHand,
    required this.petLabel,
    required this.onListMode,
    required this.onLeftHand,
    required this.onNotifications,
    required this.onOverlay,
    required this.onAnalytics,
    required this.onCallName,
  });

  final bool listMode;
  final bool leftHand;
  final String petLabel;
  final ValueChanged<bool> onListMode;
  final ValueChanged<bool> onLeftHand;
  final VoidCallback onNotifications;
  final VoidCallback onOverlay;
  final VoidCallback onAnalytics;
  final ValueChanged<String> onCallName;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V14Panel(
            child: Text(
              'Pet · $petLabel',
              key: const Key('pet-row'),
              style: v14Text(15),
            ),
          ),
          SwitchListTile(
            key: const Key('list-mode'),
            value: listMode,
            title: Text('List mode', style: v14Text(15)),
            onChanged: onListMode,
          ),
          SwitchListTile(
            key: const Key('left-hand'),
            value: leftHand,
            title: Text('Left-hand orb', style: v14Text(15)),
            onChanged: onLeftHand,
          ),
          V14Field(
            fieldKey: const Key('call-name'),
            hint: 'Call name',
            button: 'Save call name',
            primary: false,
            onSubmit: onCallName,
          ),
          V14Button(
            label: 'Notifications',
            primary: false,
            onPressed: onNotifications,
          ),
          V14Button(label: 'Overlay', primary: false, onPressed: onOverlay),
          V14Button(label: 'Analytics', primary: false, onPressed: onAnalytics),
        ],
      ),
    );
  }
}

class PetPickerView extends StatelessWidget {
  const PetPickerView({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onTry,
    required this.onChoose,
    required this.locked,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onTry;
  final VoidCallback onChoose;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Choose a companion',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final id in const ['dragon', 'panda', 'cat'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: V14Button(
                label: '${petPackFor(id).kind} · ${petPackFor(id).defaultName}',
                primary: selected == id,
                onPressed: () => onSelect(id),
              ),
            ),
          Text(
            petPackFor(selected).worlds.first,
            style: v14Text(14, color: V14Colors.muted),
          ),
          if (petPackFor(selected).missingWorlds.isNotEmpty)
            Text(
              'Worlds 2–4 are not drawn yet.',
              style: v14Text(12, color: V14Colors.dim),
            ),
          const SizedBox(height: 12),
          if (!locked) ...[
            V14Button(label: 'Try', primary: false, onPressed: onTry),
            const SizedBox(height: 8),
            V14Button(label: 'Choose', onPressed: onChoose),
          ] else
            Text(
              'This choice is already saved on this device.',
              key: const Key('pet-locked'),
              style: v14Text(14),
            ),
        ],
      ),
    );
  }
}

class PetConfirmView extends StatefulWidget {
  const PetConfirmView({
    super.key,
    required this.petId,
    required this.checked,
    required this.onChecked,
    required this.onBack,
    required this.onConfirm,
    required this.onNames,
  });

  final String petId;
  final bool checked;
  final ValueChanged<bool> onChecked;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final void Function(String petName, String callName) onNames;

  @override
  State<PetConfirmView> createState() => _PetConfirmViewState();
}

class _PetConfirmViewState extends State<PetConfirmView> {
  late final TextEditingController _petName = TextEditingController(
    text: petPackFor(widget.petId).defaultName,
  );
  final _callName = TextEditingController();

  @override
  void dispose() {
    _petName.dispose();
    _callName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pack = petPackFor(widget.petId);
    return _Page(
      title: 'Permanent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This is the one choice in RUHH you can\'t change later.',
            style: v14Text(16),
          ),
          Text(
            'Saved on this device in your profile. It is not synced.',
            style: v14Text(13, color: V14Colors.muted),
          ),
          TextField(
            key: const Key('pet-name'),
            controller: _petName,
            style: v14Text(15),
            decoration: const InputDecoration(hintText: 'Companion name'),
          ),
          TextField(
            key: const Key('confirm-call'),
            controller: _callName,
            style: v14Text(15),
            decoration: const InputDecoration(hintText: 'What they call you'),
          ),
          CheckboxListTile(
            key: const Key('pet-permanent'),
            value: widget.checked,
            onChanged: (v) => widget.onChecked(v ?? false),
            title: Text('I understand this is permanent', style: v14Text(14)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          V14Button(label: 'Go back', primary: false, onPressed: widget.onBack),
          const SizedBox(height: 8),
          V14Button(
            label: 'Choose ${pack.kind} for good',
            onPressed: widget.checked
                ? () {
                    widget.onNames(_petName.text.trim(), _callName.text.trim());
                    widget.onConfirm();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class V14Field extends StatefulWidget {
  const V14Field({
    super.key,
    required this.fieldKey,
    required this.hint,
    required this.button,
    required this.onSubmit,
    this.primary = true,
  });

  final Key fieldKey;
  final String hint;
  final String button;
  final ValueChanged<String> onSubmit;
  final bool primary;

  @override
  State<V14Field> createState() => _V14FieldState();
}

class _V14FieldState extends State<V14Field> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: widget.fieldKey,
          controller: _controller,
          style: v14Text(15),
          decoration: InputDecoration(hintText: widget.hint),
        ),
        const SizedBox(height: 8),
        V14Button(
          label: widget.button,
          primary: widget.primary,
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            widget.onSubmit(text);
            _controller.clear();
          },
        ),
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.center, this.radius);
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = V14Colors.lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.center != center || old.radius != radius;
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V14Colors.base,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Text(title, style: v14Text(26, family: V14Fonts.display)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
