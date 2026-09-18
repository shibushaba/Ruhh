import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/habit/habit_repository.dart';

class HabitPage extends ConsumerStatefulWidget {
  const HabitPage({super.key});

  @override
  ConsumerState<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends ConsumerState<HabitPage> {
  final _name = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(habitRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: repo.when(
        data: (r) => FutureBuilder(
          future: r.activeHabits(),
          builder: (context, snap) {
            final habits = snap.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: NBTextField(
                        controller: _name,
                        label: 'New habit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                NBButton(
                  label: 'Add habit',
                  color: NBColors.habit,
                  onPressed: () async {
                    if (_name.text.trim().isEmpty) return;
                    await r.addHabit(
                      name: _name.text.trim(),
                      colorValue: NBColors.habit.toARGB32(),
                    );
                    _name.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                ...habits.map((h) => FutureBuilder(
                      future: Future.wait([
                        r.streakFor(h),
                        r.isDoneToday(h),
                      ]),
                      builder: (context, snap) {
                        final streak = snap.data?[0] as int? ?? 0;
                        final done = snap.data?[1] as bool? ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NBCard(
                            color: Color(h.colorValue).withValues(alpha: 0.5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(h.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                      Text('$streak day streak'),
                                    ],
                                  ),
                                ),
                                NBButton(
                                  expand: false,
                                  label: done ? 'Done' : 'Check in',
                                  color: done
                                      ? Colors.grey.shade400
                                      : NBColors.habit,
                                  onPressed: done
                                      ? null
                                      : () async {
                                          await r.markDone(h);
                                          setState(() {});
                                        },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
