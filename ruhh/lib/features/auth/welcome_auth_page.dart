import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';

class WelcomeAuthPage extends StatelessWidget {
  const WelcomeAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NBColors.canvas(Theme.of(context).brightness),
      appBar: AppBar(title: const Text('RUHH')),
      body: NBPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'One app for budget, habits, prayer, and movies.',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Create an account or log in to sync across devices.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            NBButton(
              label: 'Create account',
              onPressed: () => context.push('/auth/signup'),
            ),
            const SizedBox(height: 12),
            NBButton(
              label: 'Log in',
              color: Theme.of(context).colorScheme.surface,
              onPressed: () => context.push('/auth/login'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
