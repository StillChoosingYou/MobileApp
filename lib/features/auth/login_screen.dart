// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/routing/route_names.dart';
import '../../core/utils/validators.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.role});
  final UserRole role;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _errorText;

  String get _loginIdLabel {
    switch (widget.role) {
      case UserRole.student:
        return 'Student Number';
      default:
        return 'Employee ID';
    }
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final result = await ref.read(authControllerProvider.notifier).login(
          role: widget.role,
          loginId: _loginIdController.text.trim(),
          password: _passwordController.text,
        );

    if (!context.mounted) return;
    setState(() => _submitting = false);

    result.when(
      ok: (user) => context.push(Routes.twoFactor, extra: user),
      error: (message) => setState(() => _errorText = message),
    );
  }

 Future<void> _tryBiometric() async {
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) {
        // ignore: use_build_context_synchronously
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This device has no biometric hardware enrolled.')),
          );
        }
        return;
      }
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Sign in to PGPC Campus',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      // ignore: use_build_context_synchronously
      if (didAuthenticate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric verified — enter your ID once to link this device.')),
        );
      }
    } catch (_) {
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication is not available right now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.role.label} Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Use your ${_loginIdLabel.toLowerCase()} and password.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _loginIdController,
                  decoration: InputDecoration(labelText: _loginIdLabel),
                  validator: (v) => Validators.required(v, field: _loginIdLabel),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => Validators.required(v, field: 'Password'),
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorText!, style: TextStyle(color: scheme.error)),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(Routes.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use biometric sign-in'),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                ]),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Google Sign-In needs an OAuth client from your Firebase project — '
                          'see the README for setup.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Choose a different role'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
