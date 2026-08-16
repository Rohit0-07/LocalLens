import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/error_copy.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../auth_providers.dart';
import 'otp_screen.dart';

final _emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

const _countryCodes = ['+91', '+1', '+44', '+61', '+971'];

enum AuthMode { phone, email }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  AuthMode _mode = AuthMode.phone;
  final _inputController = TextEditingController();
  String _countryCode = '+91';
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  /// Normalizes the raw input into an E.164 number.
  ///
  /// A `+` prefix means the user typed their own country code and it is kept
  /// as-is. A 12-digit number starting with `91` is treated as an Indian
  /// number with country code. Everything else is prefixed with the selected
  /// [country code][_countryCode].
  String _normalizePhone(String input) {
    final trimmed = input.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (trimmed.startsWith('+')) return '+$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return '$_countryCode$digits';
  }

  Future<void> _sendOtp() async {
    if (_mode == AuthMode.phone) {
      final digits = _inputController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 6) {
        setState(
          () => _error = context.tr('sign_in_phone_invalid'),
        );
        return;
      }
    } else {
      if (!_emailPattern.hasMatch(_inputController.text.trim())) {
        setState(
          () => _error = context.tr('sign_in_email_invalid'),
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
      final identifier = _mode == AuthMode.phone
          ? _normalizePhone(_inputController.text)
          : _inputController.text.trim();
      if (_mode == AuthMode.phone) {
        await repo.requestOtp(identifier);
      } else {
        await repo.requestEmailOtp(identifier);
      }

      if (!mounted) return;
      context.push(
        RoutePaths.otp,
        extra: OtpRouteArgs(
          identifier: identifier,
          mode: _mode == AuthMode.phone ? OtpMode.phone : OtpMode.email,
        ),
      );
    } catch (err) {
      if (!mounted) return;
      setState(
        () => _error = friendlyErrorMessage(
          err,
          fallback: context.tr('sign_in_otp_failed'),
        ),
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
      final session = await repo.loginAsGuest();
      await ref.read(sessionProvider.notifier).signIn(session);
      if (!mounted) return;
      context.go(RoutePaths.feed);
    } catch (err) {
      if (!mounted) return;
      setState(
        () => _error = friendlyErrorMessage(
          err,
          fallback: context.tr('sign_in_guest_failed'),
        ),
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
                context.tr('sign_in_tagline'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              SegmentedButton<AuthMode>(
                segments: [
                  ButtonSegment<AuthMode>(
                    value: AuthMode.phone,
                    label: Text(context.tr('sign_in_phone_tab')),
                    icon: const Icon(Icons.phone_outlined),
                  ),
                  ButtonSegment<AuthMode>(
                    value: AuthMode.email,
                    label: Text(context.tr('sign_in_email_tab')),
                    icon: const Icon(Icons.email_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _mode = selection.first;
                    _inputController.clear();
                    _error = null;
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
                  labelText: isPhone
                      ? context.tr('sign_in_phone_label')
                      : context.tr('sign_in_email_label'),
                  hintText: isPhone
                      ? context.tr('sign_in_phone_hint')
                      : context.tr('sign_in_email_hint'),
                  prefixIcon: isPhone
                      ? Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: DropdownButton<String>(
                            value: _countryCode,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(12),
                            items: _countryCodes
                                .map(
                                  (code) => DropdownMenuItem<String>(
                                    value: code,
                                    child: Text(code),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _countryCode = value);
                            },
                          ),
                        )
                      : const Icon(Icons.email_outlined),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _sendOtp,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('sign_in_send_otp')),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('sign_in_otp_note'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _isSubmitting ? null : _continueAsGuest,
                child: Text(context.tr('sign_in_guest')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
