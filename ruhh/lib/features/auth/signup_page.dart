import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_pin_input.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/auth/auth_controller.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _username = TextEditingController();
  final _pinKey = GlobalKey<NBPinInputState>();
  Timer? _debounce;
  bool? _available;
  String? _firstPin;
  String? _error;
  int _phase = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _username.dispose();
    super.dispose();
  }

  void _checkUsername(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().length < 3) {
        setState(() => _available = null);
        return;
      }
      final ok = await ref
          .read(authControllerProvider.notifier)
          .isUsernameAvailable(value);
      if (mounted) setState(() => _available = ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          NBTextField(
            controller: _username,
            label: 'Username',
            onChanged: _checkUsername,
            suffix: _availabilityIcon(),
          ),
          const SizedBox(height: 24),
          NBPinInput(
            key: _pinKey,
            length: AuthController.pinLength,
            title: _phase == 0 ? 'Create PIN' : 'Confirm PIN',
            onCompleted: _onPin,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Widget? _availabilityIcon() {
    if (_available == null) return null;
    return Icon(
      _available! ? Icons.check : Icons.close,
      color: _available! ? NBColors.budget : Colors.red,
    );
  }

  Future<void> _onPin(String pin) async {
    if (_phase == 0) {
      setState(() {
        _firstPin = pin;
        _phase = 1;
        _error = null;
      });
      _pinKey.currentState?.clear();
      return;
    }
    if (pin != _firstPin) {
      setState(() {
        _error = 'PINs do not match';
        _phase = 0;
        _firstPin = null;
      });
      _pinKey.currentState?.clear();
      return;
    }
    final err = await ref.read(authControllerProvider.notifier).signUp(
          _username.text,
          pin,
        );
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    context.go('/onboarding');
  }
}
