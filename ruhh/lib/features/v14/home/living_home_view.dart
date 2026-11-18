import 'package:flutter/material.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';
import 'package:ruhh/features/v14/widgets/v14_chrome.dart';

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
    final accent = pack.accent(world);
    final pins = hotspotsFor(petId: petId, world: world);
    return Material(
      type: MaterialType.transparency,
      child: V14Scene(
        petId: petId,
        world: world,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 16,
                top: 8,
                child: _Chip(
                  key: const Key('level-ring'),
                  label: 'Lv $level',
                  color: V14Colors.jade,
                  onTap: () => onOpen('/settings'),
                ),
              ),
              Positioned(
                left: 88,
                right: 108,
                top: 8,
                child: _Chip(
                  key: const Key('chapter-title'),
                  label: 'Chapter $world · ${pack.worldName(world)}',
                  color: accent,
                  onTap: () => onOpen('/journey'),
                ),
              ),
              Positioned(
                right: 12,
                top: 8,
                child: _Chip(
                  key: const Key('prayer-chip'),
                  label: prayerChip,
                  color: V14Colors.lavender,
                  onTap: () => onOpen('/prayer'),
                ),
              ),
              for (final pin in pins)
                Positioned(
                  left: pin.x * MediaQuery.sizeOf(context).width - 22,
                  top: pin.y * MediaQuery.sizeOf(context).height - 22,
                  child: _Pin(
                    id: pin.id,
                    label: pin.id == 'habits' ? hero : pin.label,
                    count: pin.id == 'habits'
                        ? '$habitCount'
                        : pin.id == 'quests'
                        ? '$questCount'
                        : null,
                    showLabel: showLabels || pin.id == 'habits',
                    accent: accent,
                    onTap: () => onOpen(pin.route),
                  ),
                ),
              if (banner != null)
                Positioned(left: 16, right: 16, top: 64, child: banner!),
              Positioned(
                left: 16,
                right: 16,
                bottom: 108,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Chip(
                    key: const Key('chat-bubble'),
                    label: callName.isEmpty ? 'Talk' : callName,
                    color: accent,
                    onTap: () => onOpen('/chat'),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 108,
                child: _Chip(
                  key: const Key('labels-chip'),
                  label: showLabels ? 'Labels on' : 'Labels',
                  color: showLabels ? accent : V14Colors.muted,
                  onTap: onToggleLabels,
                ),
              ),
              Positioned(
                left: 16,
                bottom: 148,
                child: Text(
                  pack.formName(world, subStage),
                  style: v14Text(12, color: V14Colors.muted),
                ),
              ),
            ],
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
        color: V14Colors.base.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
  });

  final String id;
  final String label;
  final String? count;
  final bool showLabel;
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
                  color: V14Colors.base,
                  border: Border.all(color: accent),
                ),
              ),
              if (count != null)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Text(count!, style: v14Text(11, color: accent)),
                ),
              if (showLabel)
                Positioned(
                  left: 46,
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
