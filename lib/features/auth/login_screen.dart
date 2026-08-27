// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({required this.role, super.key});
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

  String get _roleTitle => '${widget.role.label} Login';

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
      if (didAuthenticate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric verified — enter your ID once to link this device.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication is not available right now.')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isTabletOrWider(context);

    return Scaffold(
      // On mobile we show an AppBar; on wide screens the left panel has its
      // own back button so we skip the AppBar entirely for a cleaner look.
      appBar: isWide
          ? null
          : AppBar(title: Text(_roleTitle)),
      body: SafeArea(
        // On wide screens the left panel bleeds to the edge, so no top safe
        // area is needed (the panel handles its own padding).
        top: !isWide,
        child: isWide ? _buildWideLayout(context) : _buildNarrowLayout(context),
      ),
    );
  }

  // ── Wide / desktop layout ────────────────────────────────────────────────

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 5,
          child: _BrandingPanel(roleTitle: _roleTitle),
        ),
        // Right form panel
        Expanded(
          flex: 5,
          child: _buildFormPanel(context),
        ),
      ],
    );
  }

  // ── Narrow / mobile layout ──────────────────────────────────────────────

  Widget _buildNarrowLayout(BuildContext context) {
    return FormWidthLimiter(
      child: SingleChildScrollView(
        padding: Responsive.formPadding(context),
        child: _buildFormContent(context),
      ),
    );
  }

  // ── Right-hand form panel (scrollable, centered on wide screens) ────────

  Widget _buildFormPanel(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
            child: _buildFormContent(context),
          ),
        ),
      ),
    );
  }

  // ── Shared form content (used by both layouts) ──────────────────────────

  Widget _buildFormContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo (small, centered)
          Center(
            child: ClipOval(
              child: Image.asset(
                'assets/images/pgpc_logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Heading
          Text(
            'Welcome to ${AppConfig.appName}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.royalBlueSeed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Use your ${_loginIdLabel.toLowerCase()} and password to sign in.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Login ID field
          TextFormField(
            controller: _loginIdController,
            decoration: InputDecoration(
              labelText: _loginIdLabel,
              prefixIcon: Icon(
                widget.role == UserRole.student ? Icons.person_outline : Icons.badge_outlined,
              ),
            ),
            validator: (v) => Validators.required(v, field: _loginIdLabel),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => Validators.required(v, field: 'Password'),
            onFieldSubmitted: (_) => _submit(),
          ),

          // Error text
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            Text(_errorText!, style: TextStyle(color: scheme.error)),
          ],

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(Routes.forgotPassword),
              child: const Text(
                'Forgot password?',
                style: TextStyle(color: AppColors.royalBlueSeed),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Sign in button
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlueSeed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign in',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Biometric sign-in
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _tryBiometric,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Use biometric sign-in'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: scheme.outline),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // "or" divider
          Row(children: [
            Expanded(child: Divider(color: scheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
          ]),
          const SizedBox(height: 16),

          // Continue with Google
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
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
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: scheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Choose a different role
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Choose a different role',
                style: TextStyle(color: AppColors.royalBlueSeed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Left branding panel — campus photo background with overlaid info
// ═══════════════════════════════════════════════════════════════════════════════

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel({required this.roleTitle});

  final String roleTitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Campus background photo
        Image.asset(
          'assets/images/campus_bg.jpg',
          fit: BoxFit.cover,
        ),

        // Dark blue gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC0D1F52),
                Color(0xE6102A6D),
                Color(0xF00D1F52),
              ],
            ),
          ),
        ),

        // Content on top of the overlay
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: back arrow + role title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    roleTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Centered branding
              const Spacer(flex: 2),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PGPC seal
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldSeed.withValues(alpha: 0.6),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/pgpc_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "PGPC" large text
                    const Text(
                      'PGPC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // "C A M P U S" spaced text
                    const Text(
                      'C A M P U S',
                      style: TextStyle(
                        color: AppColors.goldSeed,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Decorative gold divider
                    Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.goldSeed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tagline
                    const Text(
                      'Your gateway to a smarter\ncampus experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // Bottom quick-link icons
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickLinkIcon(
                      icon: Icons.school_outlined,
                      label: 'Student\nServices',
                    ),
                    _QuickLinkIcon(
                      icon: Icons.calendar_month_outlined,
                      label: 'Academic\nResources',
                    ),
                    _QuickLinkIcon(
                      icon: Icons.notifications_outlined,
                      label: 'Announcements\n& Updates',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Small quick-link icon at the bottom of the branding panel ──────────────

class _QuickLinkIcon extends StatelessWidget {
  const _QuickLinkIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1.5),
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
