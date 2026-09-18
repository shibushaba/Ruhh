import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/theme/nb_colors.dart';

class WelcomeAuthPage extends StatelessWidget {
  const WelcomeAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RUHH')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track life in one brutal place.',
                style: Theme.of(context).textTheme.displayLarge),
            const Spacer(),
            NBButton(
              label: 'Create account',
              color: NBColors.habit,
              onPressed: () => context.push('/auth/signup'),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: 'Log in',
              color: NBColors.prayer,
              onPressed: () => context.push('/auth/login'),
            ),
          ],
        ),
      ),
    );
  }
}
