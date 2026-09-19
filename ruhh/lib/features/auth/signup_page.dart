import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_pin_input.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/features/auth/auth_controller.dart';
import 'package:ruhh/features/auth/username_availability.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _username = TextEditingController();
  final _pinKey = GlobalKey<NBPinInputState>();
  Timer? _debounce;
  UsernameAvailability _availability = UsernameAvailability.tooShort;
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
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      setState(() => _availability = UsernameAvailability.tooShort);
      return;
    }
    setState(() => _availability = UsernameAvailability.checking);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final result = await ref
          .read(authControllerProvider.notifier)
          .checkUsernameAvailability(value);
      if (mounted) setState(() => _availability = result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: ruhhAppBar(context, title: 'Sign up'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          NBTextField(
            controller: _username,
            label: 'Username',
            onChanged: _checkUsername,
            suffix: _availabilitySuffix(),
          ),
          const SizedBox(height: 6),
          Text(
            _availabilityMessage(),
            style: theme.bodySmall?.copyWith(
              color: _availabilityColor(),
              fontWeight: FontWeight.w600,
            ),
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

  String _availabilityMessage() {
    return switch (_availability) {
      UsernameAvailability.tooShort => 'At least 3 characters',
      UsernameAvailability.checking => 'Checking availability…',
      UsernameAvailability.available => 'Username is available',
      UsernameAvailability.offlineAvailable =>
        'Available on this device (offline check)',
      UsernameAvailability.taken => 'Username is taken',
      UsernameAvailability.checkFailed =>
        'Could not reach server — try again',
    };
  }

  Color _availabilityColor() {
    return switch (_availability) {
      UsernameAvailability.available ||
      UsernameAvailability.offlineAvailable =>
        NBMetrics.incomeGreen,
      UsernameAvailability.taken => NBMetrics.expenseRed,
      UsernameAvailability.checkFailed => Colors.orange,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  Widget? _availabilitySuffix() {
    return switch (_availability) {
      UsernameAvailability.checking => const SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      UsernameAvailability.available ||
      UsernameAvailability.offlineAvailable =>
        Icon(Icons.check_circle_outline, color: NBMetrics.incomeGreen),
      UsernameAvailability.taken =>
        Icon(Icons.cancel_outlined, color: NBMetrics.expenseRed),
      UsernameAvailability.checkFailed =>
        Icon(Icons.cloud_off_outlined, color: Colors.orange.shade300),
      _ => null,
    };
  }

  bool get _canSubmitUsername {
    return _availability == UsernameAvailability.available ||
        _availability == UsernameAvailability.offlineAvailable;
  }

  Future<void> _onPin(String pin) async {
    if (!_canSubmitUsername) {
      setState(() => _error = _availabilityMessage());
      _pinKey.currentState?.clear();
      return;
    }
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
