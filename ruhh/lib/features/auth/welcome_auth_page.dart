import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

class WelcomeAuthPage extends StatelessWidget {
  const WelcomeAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NBPageBody(
        extraBottomPadding: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RuhhGradientHero(
              title: 'RUHH',
              subtitle: 'One app for budget, habits, prayer, and movies.',
              primaryLabel: 'Create account',
              onPrimary: () => context.push('/auth/signup'),
            ),
            const SizedBox(height: 24),
            NBButton(
              label: 'Log in',
              primary: false,
              onPressed: () => context.push('/auth/login'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
