import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_pin_input.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/features/auth/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController();
  final _pinKey = GlobalKey<NBPinInputState>();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ruhhAppBar(context, title: 'Log in'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          NBTextField(controller: _username, label: 'Username'),
          const SizedBox(height: 24),
          NBPinInput(
            key: _pinKey,
            length: AuthController.pinLength,
            title: 'PIN',
            onCompleted: _submit,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          NBButton(label: 'Unlock', color: NBColors.prayer, onPressed: () {}),
        ],
      ),
    );
  }

  Future<void> _submit(String pin) async {
    final err = await ref
        .read(authControllerProvider.notifier)
        .login(_username.text, pin);
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
      _pinKey.currentState?.clear();
      return;
    }
    final notice = ref.read(cloudRestoreNoticeProvider);
    if (notice != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notice)),
      );
    }
    context.go('/home');
  }
}
