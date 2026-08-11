import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../auth_providers.dart';
import '../widgets/otp_field.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.phone});

  final String? phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String? _error;
  bool _isVerifying = false;

  Future<void> _verify(String code) async {
    setState(() {
      _error = null;
      _isVerifying = true;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.verifyOtp(
        phone: widget.phone ?? '',
        code: code,
      );
      await ref.read(sessionProvider.notifier).signIn(session);
      if (!mounted) return;
      context.go(RoutePaths.feed);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'That code did not work. Check it and try again.';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Enter the 6-digit code sent to',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.phone ?? '',
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
              else
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Change number'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
