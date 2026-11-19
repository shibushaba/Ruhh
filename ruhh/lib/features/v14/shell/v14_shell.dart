import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/features/v14/art/art_catalog.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/logic/world_map.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/logic/ring_layout.dart';
import 'package:ruhh/features/v14/shell/v14_destinations.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';
import 'package:ruhh/features/v14/theme/v14_theme.dart';
import 'package:ruhh/features/v14/v14_providers.dart';
import 'package:ruhh/features/v14/widgets/v14_chrome.dart';

class V14Shell extends ConsumerStatefulWidget {
  const V14Shell({
    super.key,
    required this.child,
    this.previewProfile,
    this.peeks = const {},
    this.petIdOverride,
    this.onNavigate,
    this.onProfile,
  });

  final Widget child;
  final V14ProfileData? previewProfile;
  final Map<String, String> peeks;
  final String? petIdOverride;
  final void Function(String route)? onNavigate;
  final ValueChanged<V14ProfileData>? onProfile;

  @override
  ConsumerState<V14Shell> createState() => V14ShellState();
}

class V14ShellState extends ConsumerState<V14Shell> {
  bool _open = false;
  bool _tapMode = false;
  String? _hover;
  bool _showSubs = false;
  int _demoStep = 0;
  V14ProfileData? _profile;

  void openRing({bool tapMode = false}) {
    setState(() {
      _open = true;
      _tapMode = tapMode;
      _hover = null;
      _showSubs = false;
    });
  }

  void closeRing() {
    setState(() {
      _open = false;
      _tapMode = false;
      _hover = null;
      _showSubs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = widget.previewProfile != null
        ? AsyncValue.data(widget.previewProfile!)
        : ref.watch(v14ProfileProvider);
    final incoming = widget.previewProfile ?? asyncProfile.value;
    if (incoming != null) _profile = incoming;
    final profile = _profile ?? const V14ProfileData();
    final tryPet = ref.watch(tryPetProvider);
    final petId = widget.petIdOverride ?? tryPet ?? profile.petId ?? 'dragon';
    final pack = petPackFor(petId);
    final name = profile.displayPetName(pack.defaultName);
    final loc = GoRouterState.of(context).uri.path;
    final isHome = loc == '/home';
    final media = MediaQuery.of(context);
    final reduced = media.disableAnimations;
    final listMode = profile.listMode || media.accessibleNavigation;
    final world = worldForLevel(
      profile.lastSeenLevel == 0 ? 1 : profile.lastSeenLevel,
    );
    final scene = artWorldOf(petId, world);
    final accent = Color(scene.accent);

    return V14ArtScope(
      petId: petId,
      world: world,
      child: Theme(
        data: V14Theme.dark(),
        child: Scaffold(
          backgroundColor: V14Colors.base,
          body: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (listMode && isHome)
                  _PlacesList(onOpen: (route) => _go(route))
                else
                  widget.child,
                if (!listMode || !isHome)
                  _orb(
                    context,
                    profile,
                    name,
                    accent,
                    isHome,
                    reduced,
                    scene.orb,
                  ),
                if (_open) _ring(context, profile, name, accent, reduced),
                if (isHome && profile.petId != null && !profile.firstRunDone)
                  _demo(context, profile, name),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(String route) {
    closeRing();
    final nav = widget.onNavigate;
    if (nav != null) {
      nav(route);
    } else if (mounted) {
      context.go(route);
    }
  }

  Future<void> _patch(V14ProfileData next) async {
    final hook = widget.onProfile;
    if (hook != null) {
      hook(next);
      return;
    }
    final store = await ref.read(v14StoreProvider.future);
    await store.saveProfile(next);
    ref.invalidate(v14ProfileProvider);
  }

  Widget _orb(
    BuildContext context,
    V14ProfileData profile,
    String name,
    Color accent,
    bool isHome,
    bool reduced,
    String portrait,
  ) {
    final diameter = isHome ? 64.0 : 48.0;
    final hand = profile.leftHandOrb;
    return Positioned(
      left: hand ? 16 : 0,
      right: hand ? null : 0,
      bottom: 16 + MediaQuery.paddingOf(context).bottom,
      child: Align(
        alignment: hand ? Alignment.centerLeft : Alignment.center,
        child: V14Orb(
          label: name,
          accent: accent,
          diameter: diameter,
          portrait: portrait,
          onTap: () {
            if (!isHome && !_open) {
              _go('/home');
              return;
            }
            if (_open && _tapMode) {
              closeRing();
            } else {
              openRing(tapMode: true);
            }
          },
          onLongPressStart: reduced ? null : (_) => openRing(),
          onLongPressMove: reduced
              ? null
              : (details) => _move(details.globalPosition, hand),
          onLongPressEnd: reduced ? null : (_) => _release(),
        ),
      ),
    );
  }

  void _move(Offset global, bool leftHand) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global);
    final size = box.size;
    final origin = Offset(leftHand ? 48 : size.width / 2, size.height - 48);
    final layout = RingLayout(
      origin: origin,
      radius: _radius(size),
      leftHand: leftHand,
      bounds: Offset.zero & size,
    );
    final nodes = layout.nodes([for (final d in v14Destinations) d.id]);
    final hit = layout.hit(local, nodes);
    var subs = false;
    if (hit != null) {
      final index = v14Destinations.indexWhere((d) => d.id == hit);
      final slot = nodes[index];
      if ((local - origin).distance > (slot.center - origin).distance + 24) {
        subs = true;
      }
    }
    setState(() {
      _hover = hit;
      _showSubs = subs;
    });
  }

  void _release() {
    final id = _hover;
    if (id == null) {
      closeRing();
      return;
    }
    final node = v14Destinations.firstWhere((d) => d.id == id);
    if (_showSubs && node.subs.isNotEmpty) {
      setState(() => _tapMode = true);
      return;
    }
    _go(node.route);
  }

  double _radius(Size size) {
    final cap = size.shortestSide * 0.36;
    return cap < 160 ? cap : 160;
  }

  Widget _ring(
    BuildContext context,
    V14ProfileData profile,
    String name,
    Color accent,
    bool reduced,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final origin = Offset(
          profile.leftHandOrb ? 48 : size.width / 2,
          size.height - 48,
        );
        final layout = RingLayout(
          origin: origin,
          radius: _radius(size),
          leftHand: profile.leftHandOrb,
          bounds: Offset.zero & size,
        );
        final ids = [for (final d in v14Destinations) d.id];
        final nodes = layout.nodes(ids);
        final hover = _hover == null
            ? null
            : v14Destinations.cast<V14Destination?>().firstWhere(
                (d) => d!.id == _hover,
                orElse: () => null,
              );
        final subSlots = hover == null
            ? const <RingSlot>[]
            : layout.subs(
                hover.id,
                v14Destinations.indexWhere((d) => d.id == hover.id),
                v14Destinations.length,
                [for (final s in hover.subs) s.id],
              );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const Key('ring-dismiss'),
                onTap: closeRing,
                child: ColoredBox(
                  color: V14Colors.base.withValues(alpha: 0.55),
                ),
              ),
            ),
            for (var i = 0; i < nodes.length; i++)
              _node(
                nodes[i].center,
                v14Destinations[i],
                accent,
                selected: _hover == v14Destinations[i].id,
                onTap: () {
                  setState(() {
                    _hover = v14Destinations[i].id;
                    _showSubs = true;
                    _tapMode = true;
                  });
                },
              ),
            if (_showSubs)
              for (var i = 0; i < subSlots.length; i++)
                _node(
                  subSlots[i].center,
                  hover!.subs[i],
                  V14Colors.gold,
                  selected: false,
                  onTap: () => _go(hover.subs[i].route),
                ),
            if (_hover != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 120,
                child: Text(
                  widget.peeks[_hover!] ??
                      v14Destinations.firstWhere((d) => d.id == _hover).label,
                  key: const Key('ring-peek'),
                  textAlign: TextAlign.center,
                  style: v14Text(14, color: V14Colors.text),
                ),
              ),
            Positioned(
              top: 64 + MediaQuery.paddingOf(context).top,
              left: 0,
              right: 0,
              child: Center(
                child: SvgPicture.asset(
                  artWorldOf(
                    profile.petId ?? 'dragon',
                    worldForLevel(
                      profile.lastSeenLevel == 0 ? 1 : profile.lastSeenLevel,
                    ),
                  ).motif,
                  width: 42,
                  height: 42,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16 + MediaQuery.paddingOf(context).top,
              child: Text(
                reduced ? 'Ring' : 'Hold $name · or tap',
                key: const Key('ring-hint'),
                style: v14Text(12, color: V14Colors.muted),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _node(
    Offset center,
    V14Destination dest,
    Color accent, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: center.dx - 30,
      top: center.dy - 30,
      width: 60,
      height: 60,
      child: Semantics(
        button: true,
        label: dest.label,
        child: Material(
          color: selected ? accent : V14Colors.base,
          shape: const CircleBorder(),
          child: InkWell(
            key: Key('ring-${dest.id}'),
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  dest.label,
                  textAlign: TextAlign.center,
                  style: v14Text(
                    11,
                    weight: FontWeight.w700,
                    color: selected ? V14Colors.base : V14Colors.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demo(BuildContext context, V14ProfileData profile, String name) {
    const steps = [
      'Hold the orb, or tap it.',
      'Slide to a place, or tap the place.',
      'Pins on the scene open today.',
    ];
    final step = _demoStep.clamp(0, 2);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 110,
      child: V14Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hold $name · or tap',
              style: v14Text(16, family: V14Fonts.display),
            ),
            const SizedBox(height: 8),
            Text(steps[step], key: const Key('demo-step'), style: v14Text(14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: V14Button(
                    label: 'Skip',
                    primary: false,
                    onPressed: () =>
                        _patch(profile.copyWith(firstRunDone: true)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: V14Button(
                    label: step == 2 ? 'Done' : 'Try it',
                    onPressed: () {
                      if (step == 2) {
                        _patch(profile.copyWith(firstRunDone: true));
                      } else {
                        setState(() => _demoStep = step + 1);
                        if (step == 0) openRing(tapMode: true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacesList extends StatelessWidget {
  const _PlacesList({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = listModeRows();
    return Semantics(
      namesRoute: true,
      label: 'Places',
      child: ListView.builder(
        key: const Key('places-list'),
        padding: EdgeInsets.fromLTRB(
          12,
          MediaQuery.paddingOf(context).top + 12,
          12,
          24,
        ),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          final nested = v14Destinations.every((d) => d.id != row.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 56,
              child: Material(
                color: V14Colors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: Key('place-${row.id}'),
                  onTap: () => onOpen(row.route),
                  child: Padding(
                    padding: EdgeInsets.only(left: nested ? 28 : 16, right: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: v14Text(16, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
