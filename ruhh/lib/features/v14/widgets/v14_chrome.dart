import 'package:flutter/material.dart';
import 'package:ruhh/features/v14/art/art_catalog.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';

class V14Panel extends StatelessWidget {
  const V14Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: V14Colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: V14Colors.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class V14Button extends StatelessWidget {
  const V14Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? V14Colors.jade : V14Colors.raised,
          foregroundColor: primary ? V14Colors.base : V14Colors.text,
          disabledBackgroundColor: V14Colors.raised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: v14Text(
            14,
            weight: FontWeight.w700,
            color: primary ? V14Colors.base : V14Colors.text,
          ),
        ),
      ),
    );
  }
}

class V14UndoBar extends StatelessWidget {
  const V14UndoBar({super.key, required this.label, required this.onUndo});
  final String label;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: V14Colors.raised,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: v14Text(13),
              ),
            ),
            TextButton(
              onPressed: onUndo,
              child: Text(
                'Undo',
                style: v14Text(
                  14,
                  weight: FontWeight.w700,
                  color: V14Colors.jade,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class V14ArtScope extends InheritedWidget {
  const V14ArtScope({
    super.key,
    required this.petId,
    required this.world,
    required super.child,
  });

  final String petId;
  final int world;

  static V14ArtScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<V14ArtScope>();
  }

  @override
  bool updateShouldNotify(V14ArtScope oldWidget) {
    return oldWidget.petId != petId || oldWidget.world != world;
  }
}

class V14Scene extends StatelessWidget {
  const V14Scene({
    super.key,
    required this.petId,
    required this.world,
    required this.child,
  });

  final String petId;
  final int world;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scene = artWorldOf(petId, world);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(scene.plate, fit: BoxFit.cover),
        child,
      ],
    );
  }
}

class V14Orb extends StatelessWidget {
  const V14Orb({
    super.key,
    required this.label,
    required this.accent,
    required this.diameter,
    required this.onTap,
    this.portrait,
    this.onLongPressStart,
    this.onLongPressMove,
    this.onLongPressEnd,
  });

  final String label;
  final Color accent;
  final double diameter;
  final String? portrait;
  final VoidCallback onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMove;
  final GestureLongPressEndCallback? onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, open places',
      child: GestureDetector(
        key: const Key('v14-orb'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: onLongPressStart,
        onLongPressMoveUpdate: onLongPressMove,
        onLongPressEnd: onLongPressEnd,
        child: SizedBox(
          width: diameter < 52 ? 52 : diameter,
          height: diameter < 52 ? 52 : diameter,
          child: Center(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: V14Colors.base,
                border: Border.all(color: accent, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: portrait == null
                  ? Text(
                      label.isEmpty ? '?' : label.characters.first,
                      style: v14Text(
                        diameter * 0.36,
                        family: V14Fonts.display,
                        color: accent,
                      ),
                    )
                  : Image.asset(
                      portrait!,
                      width: diameter,
                      height: diameter,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
