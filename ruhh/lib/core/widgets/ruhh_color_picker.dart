import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/widgets/ruhh_preset_colors.dart';

/// Preset swatches + custom color wheel for categories, habits, and movies.
class RuhhColorPicker extends StatelessWidget {
  const RuhhColorPicker({
    super.key,
    required this.selectedArgb,
    required this.onSelected,
    this.inCard = true,
  });

  final int selectedArgb;
  final ValueChanged<int> onSelected;
  final bool inCard;

  @override
  Widget build(BuildContext context) {
    final presets = ruhhAllPresetColors();
    final selected = Color(selectedArgb);
    final customSelected =
        !presets.any((c) => c.toARGB32() == selectedArgb);

    Widget grid = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final color in presets)
          _Swatch(
            color: color,
            selected: selectedArgb == color.toARGB32(),
            onTap: () => onSelected(color.toARGB32()),
          ),
        _CustomColorSwatch(
          color: customSelected ? selected : null,
          selected: customSelected,
          onTap: () async {
            final picked = await showRuhhColorWheelDialog(
              context,
              initial: selected,
            );
            if (picked != null) onSelected(picked.toARGB32());
          },
        ),
      ],
    );

    if (inCard) {
      grid = RuhhSoftCard(padding: const EdgeInsets.all(12), child: grid);
    }
    return grid;
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusChip),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(t.radiusChip),
            border: Border.all(
              color: selected ? t.textPrimary : t.divider,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: ruhhCheckOnColor(color),
                )
              : null,
        ),
      ),
    );
  }
}

class _CustomColorSwatch extends StatelessWidget {
  const _CustomColorSwatch({
    required this.selected,
    required this.onTap,
    this.color,
  });

  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: color == null
                ? const SweepGradient(
                    colors: [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.cyan,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                  )
                : null,
            color: color,
            border: Border.all(
              color: selected ? t.textPrimary : t.divider,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Icon(
            color == null ? Icons.add : Icons.tune,
            size: 18,
            color: color != null
                ? ruhhCheckOnColor(color!)
                : t.textPrimary,
          ),
        ),
      ),
    );
  }
}

Future<Color?> showRuhhColorWheelDialog(
  BuildContext context, {
  required Color initial,
}) {
  return showDialog<Color>(
    context: context,
    builder: (ctx) => _RuhhColorWheelDialog(initial: initial),
  );
}

class _RuhhColorWheelDialog extends StatefulWidget {
  const _RuhhColorWheelDialog({required this.initial});

  final Color initial;

  @override
  State<_RuhhColorWheelDialog> createState() => _RuhhColorWheelDialogState();
}

class _RuhhColorWheelDialogState extends State<_RuhhColorWheelDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  void _pickWheel(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final v = local - center;
    final radius = size.width / 2 - 8;
    final dist = v.distance.clamp(0.0, radius);
    final angle = math.atan2(v.dy, v.dx);
    var hue = angle * 180 / math.pi;
    if (hue < 0) hue += 360;
    final sat = (dist / radius).clamp(0.0, 1.0);
    setState(() {
      _hsv = HSVColor.fromAHSV(_hsv.alpha, hue, sat, _hsv.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final current = _hsv.toColor();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: RuhhSoftCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick a color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: GestureDetector(
                    onPanDown: (d) => _pickWheel(
                      d.localPosition,
                      const Size(220, 220),
                    ),
                    onPanUpdate: (d) => _pickWheel(
                      d.localPosition,
                      const Size(220, 220),
                    ),
                    onTapDown: (d) => _pickWheel(
                      d.localPosition,
                      const Size(220, 220),
                    ),
                    child: CustomPaint(
                      painter: _HueWheelPainter(
                        value: _hsv.value,
                        selectedHue: _hsv.hue,
                        selectedSat: _hsv.saturation,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Brightness', style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: _hsv.value,
                onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: current,
                      border: Border.all(color: t.divider, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '#${current.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  NBButton(
                    label: 'Use color',
                    expand: false,
                    onPressed: () => Navigator.pop(context, current),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HueWheelPainter extends CustomPainter {
  _HueWheelPainter({
    required this.value,
    required this.selectedHue,
    required this.selectedSat,
  });

  final double value;
  final double selectedHue;
  final double selectedSat;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.black.withValues(alpha: 1 - value),
    );

    final angle = selectedHue * math.pi / 180;
    final dist = selectedSat * radius;
    final marker = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
    canvas.drawCircle(marker, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      marker,
      9,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HueWheelPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.selectedHue != selectedHue ||
      oldDelegate.selectedSat != selectedSat;
}
