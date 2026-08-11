import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../auth_providers.dart';

final _phonePattern = RegExp(r'^\+[1-9][0-9]{6,14}$');
final _emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

enum AuthMode { phone, email }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  AuthMode _mode = AuthMode.phone;
  final _inputController = TextEditingController();
  String? _error;
  bool _isSubmitting = false;

  bool _otpSent = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final input = _inputController.text.trim();
    if (_mode == AuthMode.phone) {
      if (!_phonePattern.hasMatch(input)) {
        setState(
          () => _error =
              'Enter a valid phone number with country code, e.g. +91 98765 43210',
        );
        return;
      }
    } else {
      if (!_emailPattern.hasMatch(input)) {
        setState(
          () => _error = 'Enter a valid email address',
        );
        return;
      }
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_mode == AuthMode.phone) {
        await repo.requestOtp(input);
      } else {
        try {
          await repo.requestEmailOtp(input);
        } catch (_) {
          await (repo as dynamic).requestEmailOtp(input);
        }
      }

      if (!mounted) return;
      _startTimer();
      setState(() => _otpSent = true);

      try {
        context.push(RoutePaths.otp, extra: input);
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Could not send the code. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      dynamic session;
      try {
        session = await repo.loginAsGuest();
      } catch (_) {
        try {
          session = await (repo as dynamic).guestLogin();
        } catch (_) {
          session = await (repo as dynamic).createGuestSession();
        }
      }
      await ref.read(sessionProvider.notifier).signIn(session);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Could not start guest session. Try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _mode == AuthMode.phone;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.location_on_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'LocalLens',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your neighborhood, working together.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              SegmentedButton<AuthMode>(
                segments: const [
                  ButtonSegment<AuthMode>(
                    value: AuthMode.phone,
                    label: Text('Phone'),
                    icon: Icon(Icons.phone_outlined),
                  ),
                  ButtonSegment<AuthMode>(
                    value: AuthMode.email,
                    label: Text('Email'),
                    icon: Icon(Icons.email_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _mode = selection.first;
                    _inputController.clear();
                    _error = null;
                    _otpSent = false;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _inputController,
                keyboardType:
                    isPhone ? TextInputType.phone : TextInputType.emailAddress,
                inputFormatters: isPhone
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))]
                    : null,
                decoration: InputDecoration(
                  labelText: isPhone ? 'Phone number' : 'Email',
                  hintText: isPhone ? '+91 98765 43210' : 'citizen@example.com',
                  prefixIcon: Icon(
                    isPhone ? Icons.phone_outlined : Icons.email_outlined,
                  ),
                ),
                onSubmitted: (_) => _sendOtp(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSubmitting ? null : _sendOtp,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send OTP'),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                if (_secondsRemaining > 0)
                  Text(
                    'Resend OTP in ${_secondsRemaining}s',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  TextButton(
                    onPressed: _isSubmitting ? null : _sendOtp,
                    child: const Text('Resend OTP'),
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                'No account needed — an OTP signs you in.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _isSubmitting ? null : _continueAsGuest,
                child: const Text('Continue as Guest'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
