import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/v14/art/art_catalog.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/home/living_home_view.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/logic/world_map.dart';
import 'package:ruhh/features/v14/logic/xp_rules.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';
import 'package:ruhh/features/v14/v14_providers.dart';
import 'package:ruhh/features/v14/widgets/v14_chrome.dart';

class LivingHomePage extends ConsumerStatefulWidget {
  const LivingHomePage({super.key, this.preview});

  final LivingHomePreview? preview;

  @override
  ConsumerState<LivingHomePage> createState() => _LivingHomePageState();
}

class LivingHomePreview {
  const LivingHomePreview({
    required this.profile,
    required this.petId,
    required this.level,
    required this.subStage,
    required this.world,
    required this.hero,
    required this.habitCount,
    required this.questCount,
    required this.prayerChip,
    this.banner,
  });

  final V14ProfileData profile;
  final String petId;
  final int level;
  final int subStage;
  final int world;
  final String hero;
  final int habitCount;
  final int questCount;
  final String prayerChip;
  final Widget? banner;
}

class _LivingHomePageState extends ConsumerState<LivingHomePage> {
  var _askedForPet = false;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    if (preview != null) {
      return LivingHomeView(
        petId: preview.petId,
        world: preview.world,
        level: preview.level,
        subStage: preview.subStage,
        callName: preview.profile.callName,
        hero: preview.hero,
        showLabels: preview.profile.showLabels,
        habitCount: preview.habitCount,
        questCount: preview.questCount,
        prayerChip: preview.prayerChip,
        banner: preview.banner,
        onOpen: (route) => context.go(route),
        onToggleLabels: () {},
      );
    }
    final profileAsync = ref.watch(v14ProfileProvider);
    final tryPet = ref.watch(tryPetProvider);
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Could not open home', style: v14Text(14))),
      data: (profile) {
        final needsPet = profile.petId == null && tryPet == null;
        if (needsPet && !_askedForPet) {
          _askedForPet = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _askedForPet = false;
            final latest = ref.read(v14ProfileProvider);
            if (latest.isLoading || latest.isRefreshing) return;
            if (ref.read(tryPetProvider) != null) return;
            if (latest.value?.petId != null) return;
            context.go('/pet');
          });
        }
        return _LoadedHome(profile: profile);
      },
    );
  }
}

class _LoadedHome extends ConsumerStatefulWidget {
  const _LoadedHome({required this.profile});
  final V14ProfileData profile;

  @override
  ConsumerState<_LoadedHome> createState() => _LoadedHomeState();
}

class _LoadedHomeState extends ConsumerState<_LoadedHome> {
  var _habitCount = 0;
  var _questCount = 0;
  var _hero = 'Habits';
  var _prayer = 'Prayer';
  var _level = 1;
  var _world = 1;
  var _sub = 0;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await ref.read(v14StoreProvider.future);
    final quests = await store.quests();
    final xp = await store.lifetimeXp();
    final progress = const WorldMap().progress(xp);
    var habits = 0;
    var hero = 'No habit due';
    try {
      final repo = await ref.read(habitRepositoryProvider.future);
      final active = await repo.activeHabits();
      habits = active.length;
      final next = await repo.nextDueHabit();
      hero =
          next?.name ?? (active.isEmpty ? 'No habit due' : active.first.name);
      final today = dateKeyFrom(DateTime.now());
      for (final habit in active) {
        final done = await repo.isDoneToday(habit);
        final refId = 'habit:${habit.remoteId}:$today';
        if (done) {
          await store.award(
            source: 'habit',
            sourceRef: refId,
            amount: XpRules.habit,
          );
        } else {
          await store.reverse(refId);
        }
      }
    } catch (_) {}
    var prayer = 'Prayer';
    try {
      final prayers = await ref.read(prayerRepositoryProvider.future);
      final log = await prayers.dailyLogFor(dateKeyFrom(DateTime.now()));
      final done = log.statuses.values.where((s) => s.name == 'prayed').length;
      prayer = '$done of 5';
    } catch (_) {}
    final now = DateTime.now();
    String? banner;
    if (now.hour >= 7 &&
        now.hour < 11 &&
        widget.profile.morningSeenKey != dateKeyFrom(now)) {
      banner = 'Morning';
    } else if (now.hour >= 21 &&
        widget.profile.eveningSeenKey != dateKeyFrom(now)) {
      banner = 'Evening';
    }
    if (!mounted) return;
    setState(() {
      _habitCount = habits;
      _questCount = quests.where((q) => !q.done).length;
      _hero = hero;
      _prayer = prayer;
      _level = progress.level;
      _world = progress.world;
      _sub = progress.subStage;
      _banner = banner;
    });
    // Re-read after the awaits. The profile this page was built with can be
    // from a pet try, and writing it back would wipe a choice made since.
    final fresh = await store.loadProfile();
    if (fresh.lastSeenLevel == 0) {
      await store.saveProfile(fresh.copyWith(lastSeenLevel: progress.level));
    } else if (progress.level > fresh.lastSeenLevel && mounted) {
      await store.saveProfile(fresh.copyWith(lastSeenLevel: progress.level));
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) {
            final form = artFormForLevel(
              fresh.petId ?? 'dragon',
              progress.level,
            );
            return AlertDialog(
              key: const Key('level-up'),
              backgroundColor: V14Colors.surface,
              title: Text(
                'Level ${progress.level}',
                style: v14Text(
                  22,
                  family: V14Fonts.display,
                  color: V14Colors.gold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(form.sprite, height: 180, fit: BoxFit.contain),
                  const SizedBox(height: 8),
                  Text(form.name, style: v14Text(16, color: V14Colors.gold)),
                  const SizedBox(height: 8),
                  Text(
                    'The world follows the existing curve. Nothing here is sent to the cloud.',
                    style: v14Text(14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Stay',
                    style: v14Text(14, color: V14Colors.jade),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _dismissSheet(String which) async {
    final store = await ref.read(v14StoreProvider.future);
    final key = dateKeyFrom(DateTime.now());
    final next = which == 'Morning'
        ? widget.profile.copyWith(morningSeenKey: key)
        : widget.profile.copyWith(eveningSeenKey: key);
    await store.saveProfile(next);
    ref.invalidate(v14ProfileProvider);
    if (mounted) setState(() => _banner = null);
  }

  @override
  Widget build(BuildContext context) {
    final tryPet = ref.watch(tryPetProvider);
    final petId = tryPet ?? widget.profile.petId ?? 'dragon';
    final pack = petPackFor(petId);
    return LivingHomeView(
      petId: petId,
      world: _world,
      level: _level,
      subStage: _sub,
      callName: widget.profile.callName,
      hero: _hero,
      showLabels: widget.profile.showLabels,
      habitCount: _habitCount,
      questCount: _questCount,
      prayerChip: _prayer,
      banner: _banner == null
          ? (tryPet == null
                ? null
                : V14Panel(
                    child: Text(
                      'Trying ${pack.kind} · nothing is saved',
                      key: const Key('try-banner'),
                      style: v14Text(14),
                    ),
                  ))
          : V14Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _banner!,
                    key: Key('sheet-$_banner'),
                    style: v14Text(16, family: V14Fonts.display),
                  ),
                  Text(
                    _banner == 'Morning'
                        ? 'A quiet start. Prayer is not scored.'
                        : 'Wrap up the day. Nothing here grants XP by itself.',
                    style: v14Text(13, color: V14Colors.muted),
                  ),
                  TextButton(
                    onPressed: () => _dismissSheet(_banner!),
                    child: Text(
                      'Close',
                      style: v14Text(14, color: V14Colors.jade),
                    ),
                  ),
                ],
              ),
            ),
      onOpen: (route) {
        if (route == '/wrap') {
          setState(() => _banner = 'Evening');
          return;
        }
        context.go(route);
      },
      onToggleLabels: () async {
        final store = await ref.read(v14StoreProvider.future);
        await store.saveProfile(
          widget.profile.copyWith(showLabels: !widget.profile.showLabels),
        );
        ref.invalidate(v14ProfileProvider);
      },
    );
  }
}
