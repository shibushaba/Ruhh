import 'package:flutter/material.dart';
import 'package:ruhh/features/v14/art/art_catalog.dart';
import 'package:ruhh/features/v14/art/plate_cover.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';

class LivingHomeView extends StatelessWidget {
  const LivingHomeView({
    super.key,
    required this.petId,
    required this.world,
    required this.level,
    required this.subStage,
    required this.callName,
    required this.hero,
    required this.showLabels,
    required this.habitCount,
    required this.questCount,
    required this.prayerChip,
    required this.onOpen,
    required this.onToggleLabels,
    this.banner,
  });

  final String petId;
  final int world;
  final int level;
  final int subStage;
  final String callName;
  final String hero;
  final bool showLabels;
  final int habitCount;
  final int questCount;
  final String prayerChip;
  final ValueChanged<String> onOpen;
  final VoidCallback onToggleLabels;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final pack = petPackFor(petId);
    final scene = artWorldOf(petId, world);
    final form = artFormForLevel(petId, level);
    final accent = Color(scene.accent);
    final pins = hotspotsFor(petId: petId, world: world);
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final cover = PlateCover(size);
          final feet = cover.at((scene.tapX0 + scene.tapX1) / 2, scene.tapY1);
          final spriteHeight = form.heightDp * (size.width / 390);
          final spriteWidth = spriteHeight * 1.15;
          final tapOrigin = cover.at(scene.tapX0, scene.tapY0);
          final tapEnd = cover.at(scene.tapX1, scene.tapY1);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(scene.plate, fit: BoxFit.cover),
              ),
              const _EdgeShade(top: true),
              const _EdgeShade(top: false),
              Positioned(
                left: feet.dx - spriteWidth / 2,
                top: feet.dy - spriteHeight,
                width: spriteWidth,
                height: spriteHeight,
                child: IgnorePointer(
                  child: Image.asset(
                    form.sprite,
                    key: const Key('companion-sprite'),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: tapOrigin.dx,
                top: tapOrigin.dy,
                width: (tapEnd.dx - tapOrigin.dx).abs(),
                height: (tapEnd.dy - tapOrigin.dy).abs(),
                child: GestureDetector(
                  key: const Key('companion-tap'),
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onOpen('/chat'),
                ),
              ),
              _anchored(
                cover.at(0.1026, 0.0853),
                _Chip(
                  key: const Key('level-ring'),
                  label: 'Lv $level',
                  color: V14Colors.jade,
                  onTap: () => onOpen('/settings'),
                ),
              ),
              _anchored(
                cover.at(0.3846, 0.0853),
                SizedBox(
                  width: 190,
                  child: _Chip(
                    key: const Key('chapter-title'),
                    label: 'Chapter $world · ${pack.worldName(world)}',
                    color: accent,
                    onTap: () => onOpen('/journey'),
                  ),
                ),
              ),
              _anchored(
                cover.at(0.8846, 0.0853),
                _Chip(
                  key: const Key('prayer-chip'),
                  label: prayerChip,
                  color: V14Colors.lavender,
                  onTap: () => onOpen('/prayer'),
                ),
              ),
              for (final pin in pins)
                _anchored(
                  cover.at(pin.x, pin.y),
                  _Pin(
                    id: pin.id,
                    label: pin.id == 'habits' ? hero : pin.label,
                    count: pin.id == 'habits'
                        ? '$habitCount'
                        : pin.id == 'quests'
                        ? '$questCount'
                        : null,
                    showLabel: showLabels || pin.id == 'habits',
                    labelSide: pin.labelSide,
                    accent: accent,
                    onTap: () => onOpen(pin.route),
                  ),
                ),
              _anchored(
                cover.at(scene.heroX, scene.heroY),
                _Chip(
                  key: const Key('hero-pill'),
                  label: hero,
                  color: accent,
                  onTap: () => onOpen('/habit'),
                ),
                align: Alignment.centerLeft,
              ),
              if (banner != null)
                Positioned(left: 16, right: 16, top: 72, child: banner!),
              Positioned(
                left: 20,
                right: 20,
                top: cover.at(0.5, 0.7701).dy - 24,
                child: _Chip(
                  key: const Key('chat-bubble'),
                  label: callName.isEmpty
                      ? '${form.name} is here'
                      : '${form.name} · $callName',
                  color: accent,
                  onTap: () => onOpen('/chat'),
                ),
              ),
              _anchored(
                cover.at(0.8846, 0.9147),
                _Chip(
                  key: const Key('labels-chip'),
                  label: showLabels ? 'Labels on' : 'Labels',
                  color: showLabels ? accent : V14Colors.text,
                  onTap: onToggleLabels,
                ),
              ),
              _anchored(
                cover.at(0.1026, 0.9147),
                _Chip(
                  key: const Key('streak-chip'),
                  label: '$habitCount lit',
                  color: accent,
                  onTap: () => onOpen('/habit'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _anchored(
    Offset point,
    Widget child, {
    Alignment align = Alignment.center,
  }) {
    return Positioned(
      left: point.dx,
      top: point.dy,
      child: FractionalTranslation(translation: _shift(align), child: child),
    );
  }

  Offset _shift(Alignment align) {
    return Offset(-(align.x + 1) / 2, -(align.y + 1) / 2);
  }
}

class _EdgeShade extends StatelessWidget {
  const _EdgeShade({required this.top});

  final bool top;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: top ? 0.14 : 0.22,
        widthFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                V14Colors.base.withValues(alpha: 0.85),
                V14Colors.base.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: V14Colors.base.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: v14Text(13, weight: FontWeight.w700, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.id,
    required this.label,
    required this.showLabel,
    required this.accent,
    required this.onTap,
    this.count,
    this.labelSide = 'r',
  });

  final String id;
  final String label;
  final String? count;
  final bool showLabel;
  final String labelSide;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: Key('pin-$id'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: V14Colors.base.withValues(alpha: 0.88),
                  border: Border.all(color: accent, width: 2),
                ),
              ),
              if (count != null)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Text(count!, style: v14Text(11, color: accent)),
                ),
              if (showLabel)
                Positioned(
                  left: labelSide == 'l' ? null : 48,
                  right: labelSide == 'l' ? 48 : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: v14Text(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
