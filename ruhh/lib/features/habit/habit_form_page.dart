import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/widgets/habit_appearance_pickers.dart';
import 'package:ruhh/features/habit/widgets/vacation_sheet.dart';

class HabitFormPage extends ConsumerStatefulWidget {
  const HabitFormPage({super.key, this.remoteId});

  final String? remoteId;

  @override
  ConsumerState<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends ConsumerState<HabitFormPage> {
  final _name = TextEditingController();
  final _target = TextEditingController(text: '1');
  final _unit = TextEditingController();
  final _increment = TextEditingController(text: '1');

  HabitKind _kind = HabitKind.positive;
  HabitInterval _interval = HabitInterval.daily;
  int _color = HabitRepository.presetColors().first;
  String _icon = 'target';
  final _weekdays = <int>{1, 2, 3, 4, 5};
  var _monthDay = 1;
  var _customEvery = 3;
  HabitLocal? _existing;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.remoteId == null) {
      setState(() => _loading = false);
      return;
    }
    final repo = await ref.read(habitRepositoryProvider.future);
    final h = await repo.byRemoteId(widget.remoteId!);
    if (h != null) {
      _existing = h;
      _name.text = h.name;
      _kind = h.kind;
      _interval = h.interval;
      _color = h.colorValue;
      _icon = h.icon;
      _target.text = '${h.targetPerDay}';
      _unit.text = h.unitLabel;
      _increment.text = '${h.incrementAmount}';
      _weekdays
        ..clear()
        ..addAll(h.scheduleWeekdays.isEmpty ? [1, 2, 3, 4, 5] : h.scheduleWeekdays);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _unit.dispose();
    _increment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final repo = await ref.read(habitRepositoryProvider.future);
    final target = int.tryParse(_target.text) ?? 1;
    final inc = double.tryParse(_increment.text) ?? 1;

    if (_existing != null) {
      final h = _existing!
        ..name = name
        ..kind = _kind
        ..interval = _interval
        ..colorValue = _color
        ..icon = _icon
        ..targetPerDay = target
        ..unitLabel = _unit.text.trim()
        ..incrementAmount = inc
        ..scheduleEvery = _interval == HabitInterval.everyXDays
            ? _customEvery
            : _existing!.scheduleEvery
        ..scheduleWeekdays = _interval == HabitInterval.weekdays
            ? _weekdays.toList()
            : []
        ..scheduleMonthDays = _interval == HabitInterval.monthly
            ? [_monthDay]
            : [];
      await repo.updateHabit(h);
    } else {
      await repo.addHabit(
        name: name,
        colorValue: _color,
        icon: _icon,
        kind: _kind,
        interval: _interval,
        targetPerDay: target,
        incrementAmount: inc,
        unitLabel: _unit.text.trim(),
        scheduleWeekdays: _interval == HabitInterval.weekdays
            ? _weekdays.toList()
            : [],
        scheduleEvery:
            _interval == HabitInterval.everyXDays ? _customEvery : 2,
      );
    }
    bumpHabitRefresh(ref);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final editing = _existing != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(editing ? 'Edit habit' : 'New habit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RuhhSoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NBTextField(controller: _name, label: 'Name'),
                const SizedBox(height: 16),
                Text('Type', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<HabitKind>(
                  segments: const [
                    ButtonSegment(
                        value: HabitKind.positive, label: Text('Build')),
                    ButtonSegment(
                        value: HabitKind.negative, label: Text('Break')),
                    ButtonSegment(
                        value: HabitKind.quantitative, label: Text('Amount')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RuhhSoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Schedule', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HabitInterval.daily,
                    HabitInterval.weekdays,
                    HabitInterval.monthly,
                    HabitInterval.everyXDays,
                  ].map((i) {
                    return ChoiceChip(
                      label: Text(HabitRepository.intervalLabel(i)),
                      selected: _interval == i,
                      onSelected: (_) => setState(() => _interval = i),
                    );
                  }).toList(),
                ),
                if (_interval == HabitInterval.weekdays) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final wd = i + 1;
                      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return FilterChip(
                        label: Text(labels[i]),
                        selected: _weekdays.contains(wd),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _weekdays.add(wd);
                          } else {
                            _weekdays.remove(wd);
                          }
                        }),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          if (_kind == HabitKind.quantitative) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NBTextField(
                    controller: _target,
                    label: 'Target / day',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NBTextField(
                    controller: _increment,
                    label: 'Step',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            NBTextField(controller: _unit, label: 'Unit (optional)'),
          ],
          const SizedBox(height: 12),
          RuhhSoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Color', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                HabitColorPicker(
                  selected: _color,
                  onSelected: (c) => setState(() => _color = c),
                ),
                const SizedBox(height: 16),
                Text('Icon', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                HabitIconPicker(
                  selected: _icon,
                  accentArgb: _color,
                  onSelected: (id) => setState(() => _icon = id),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NBButton(
            label: editing ? 'Save changes' : 'Create habit',
            color: NBColors.habit,
            onPressed: _save,
          ),
          if (editing) ...[
            const SizedBox(height: 12),
            NBButton(
              label: 'Reminders',
              color: NBColors.offWhite,
              onPressed: () => showReminderEditor(context, ref, _existing!),
            ),
            const SizedBox(height: 8),
            NBButton(
              label: 'Vacation & rest days',
              color: NBColors.offWhite,
              onPressed: () => showVacationSheet(context, ref, _existing!),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: 'Archive habit',
              color: Colors.grey.shade400,
              onPressed: () async {
                final repo = await ref.read(habitRepositoryProvider.future);
                await repo.archiveHabit(_existing!);
                bumpHabitRefresh(ref);
                if (context.mounted) context.pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}
