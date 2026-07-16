import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../../models/app_user.dart';

/// A mock OTP step. Because there's no real SMS/email provider wired up in
/// this scaffold, the "sent" code is shown on-screen — swap `_demoCode` for
/// a real one-time code from Firebase Auth's phone/email verification, or
/// a Cloud Function that sends via a provider like Semaphore or Twilio.
class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key, required this.pendingUser});
  final AppUser pendingUser;

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  static const _demoCode = '246810';
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    if (_controller.text.trim() == _demoCode) {
      goToRoleHome(context, widget.pendingUser);
    } else {
      setState(() => _error = 'Incorrect code. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter the code we sent you', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Hi ${widget.pendingUser.name.split(' ').first}, enter the 6-digit code to '
                'finish signing in.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Demo mode — your code is $_demoCode (no real SMS/email is sent).',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(counterText: ''),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 12),
              FilledButton(onPressed: _verify, child: const Text('Verify')),
            ],
          ),
        ),
      ),
    );
  }
}
