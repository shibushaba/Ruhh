import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/habit_reminder.dart';
import 'package:ruhh/core/services/habit_notification_scheduler.dart';
import 'package:ruhh/features/habit/habit_extensions.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:uuid/uuid.dart';

Future<void> showVacationSheet(
  BuildContext context,
  WidgetRef ref,
  HabitLocal habit,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      var rest = {...habit.restDays};
      var onVacation = habit.isOnVacation;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Vacation & rest days',
                    style: Theme.of(context).textTheme.titleLarge),
                SwitchListTile(
                  title: const Text('Vacation mode'),
                  subtitle: const Text('Pause habit without breaking streak'),
                  value: onVacation,
                  onChanged: (v) => setState(() => onVacation = v),
                ),
                const Text('Rest days (weekly)'),
                Wrap(
                  children: List.generate(7, (i) {
                    final wd = i + 1;
                    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return FilterChip(
                      label: Text(labels[i]),
                      selected: rest.contains(wd),
                      onSelected: (v) => setState(() {
                        if (v) {
                          rest.add(wd);
                        } else {
                          rest.remove(wd);
                        }
                      }),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final repo = await ref.read(habitRepositoryProvider.future);
                    await repo.setRestDays(habit, rest.toList());
                    await repo.setVacation(habit, onVacation);
                    await refreshHabitNotifications(ref);
                    bumpHabitRefresh(ref);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showReminderEditor(
  BuildContext context,
  WidgetRef ref,
  HabitLocal habit,
) async {
  var reminders = [...habit.reminders];
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.paddingOf(ctx).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
                ...reminders.map(
                  (r) => ListTile(
                    title: Text(
                      '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}',
                    ),
                    subtitle: Text('Days: ${r.days.join(', ')}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          setState(() => reminders.removeWhere((x) => x.id == r.id)),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked != null) {
                      setState(() {
                        reminders.add(
                          HabitReminder(
                            id: const Uuid().v4(),
                            hour: picked.hour,
                            minute: picked.minute,
                            days: [1, 2, 3, 4, 5, 6, 7],
                          ),
                        );
                      });
                    }
                  },
                  child: const Text('Add reminder'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final repo = await ref.read(habitRepositoryProvider.future);
                    await repo.setReminders(habit, reminders);
                    await refreshHabitNotifications(ref);
                    bumpHabitRefresh(ref);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save reminders'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
