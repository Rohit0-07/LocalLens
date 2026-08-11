import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/session.dart';
import '../auth_providers.dart';
import '../widgets/otp_field.dart';

enum OtpMode { phone, email }

/// Typed arguments passed to the OTP route via `extra`.
class OtpRouteArgs {
  const OtpRouteArgs({required this.identifier, required this.mode});

  final String identifier;
  final OtpMode mode;

  bool get isPhone => mode == OtpMode.phone;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.args});

  final OtpRouteArgs? args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String? _error;
  bool _isVerifying = false;

  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
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

  Future<void> _resendOtp() async {
    final args = widget.args;
    if (args == null) return;
    setState(() {
      _error = null;
      _isVerifying = true;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      if (args.isPhone) {
        await repository.requestOtp(args.identifier);
      } else {
        await repository.requestEmailOtp(args.identifier);
      }
      if (!mounted) return;
      _startTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFor(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = context.tr('otp_network_error'));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _messageFor(ApiException e) {
    if (e is ApiNetworkException) return context.tr('otp_network_error');
    if (e is ApiServerException) {
      switch (e.code) {
        case 'rate_limited':
          return context.tr('otp_rate_limited');
        case 'otp_invalid':
          return context.tr('otp_invalid');
        default:
          return context.tr('otp_generic_error');
      }
    }
    return context.tr('otp_generic_error');
  }

  Future<void> _verify(String code) async {
    final args = widget.args;
    if (args == null) return;
    setState(() {
      _error = null;
      _isVerifying = true;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      final Session session;
      if (args.isPhone) {
        session = await repository.verifyOtp(
          phone: args.identifier,
          code: code,
        );
      } else {
        session = await repository.verifyEmailOtp(
          email: args.identifier,
          code: code,
        );
      }
      await ref.read(sessionProvider.notifier).signIn(session);
      if (!mounted) return;
      context.go(RoutePaths.feed);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(e);
        _isVerifying = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.tr('otp_invalid');
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final isPhone = args?.isPhone ?? true;
    final identifier = args?.identifier ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isPhone ? context.tr('otp_title') : context.tr('otp_email_title')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                context.tr('otp_sent_to'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                identifier,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),
              OtpField(
                enabled: !_isVerifying,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onCompleted: _verify,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              if (_isVerifying)
                const Center(child: CircularProgressIndicator())
              else if (_secondsRemaining > 0)
                Text(
                  '${context.tr('otp_resend_in')} ${_secondsRemaining}s',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                TextButton(
                  key: const Key('otpResendButton'),
                  onPressed: _resendOtp,
                  child: Text(context.tr('otp_resend')),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(context.tr('otp_change')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
