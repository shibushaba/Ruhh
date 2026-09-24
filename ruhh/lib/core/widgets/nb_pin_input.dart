import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';

class NBPinInput extends StatefulWidget {
  const NBPinInput({
    super.key,
    required this.length,
    required this.onCompleted,
    this.title = 'Enter PIN',
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final String title;

  @override
  State<NBPinInput> createState() => NBPinInputState();
}

class NBPinInputState extends State<NBPinInput> {
  final _digits = <String>[];

  void _add(String d) {
    if (_digits.length >= widget.length) return;
    setState(() => _digits.add(d));
    if (_digits.length == widget.length) {
      widget.onCompleted(_digits.join());
    }
  }

  void clear() => setState(() => _digits.clear());

  void backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: theme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            final filled = i < _digits.length;
            return Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: t.textPrimary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(2),
                color: filled ? t.textPrimary : Colors.transparent,
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        _Keypad(onDigit: _add, onBack: backspace),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBack});

  final ValueChanged<String> onDigit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: _KeypadKey(
                      label: key,
                      onPressed: () => onDigit(key),
                    ),
                  ),
                ),
            ],
          ),
        ],
        Row(
          children: [
            const Expanded(child: SizedBox(height: 52)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: _KeypadKey(
                  label: '0',
                  onPressed: () => onDigit('0'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: _KeypadKey(
                  label: '',
                  icon: Icons.backspace_outlined,
                  onPressed: onBack,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return SizedBox(
      height: 52,
      child: Material(
        color: t.textPrimary,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: icon != null
                ? Icon(icon, color: t.surfacePrimary, size: 22)
                : Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: t.surfacePrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
