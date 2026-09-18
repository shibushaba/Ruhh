import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';

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
    return Column(
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            final filled = i < _digits.length;
            return Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: NBColors.black,
                  width: NBMetrics.borderWidth,
                ),
                color: filled ? NBColors.black : Colors.transparent,
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
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        return NBButton(
          expand: false,
          label: key,
          color: NBColors.offWhite,
          onPressed: () {
            if (key == '⌫') {
              onBack();
            } else {
              onDigit(key);
            }
          },
        );
      },
    );
  }
}
