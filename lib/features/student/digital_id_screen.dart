import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/feature_providers.dart';

class DigitalIdScreen extends ConsumerStatefulWidget {
  const DigitalIdScreen({super.key});

  @override
  ConsumerState<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

/// The ID card "materializes" on open — a small scale + fade that suits a
/// digital ID being conjured up, rather than the plainer fade used
/// elsewhere in the app. Runs once per screen visit, not on every rebuild.
class _DigitalIdScreenState extends ConsumerState<DigitalIdScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.emphasized);
    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.emphasizedCurve);
    _fade = curved;
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const LoadingView();
    final profileAsync = ref.watch(studentProfileProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Student ID')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.royalBlueSeed, const Color(0xFF1A5088)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/pgpc_logo.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            AppConfig.collegeFullName,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 28),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white24,
                      child: Text(
                        user.name.trim().split(RegExp(r'\s+')).map((s) => s[0]).take(2).join(),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    profileAsync.when(
                      data: (profile) => Text(
                        profile == null ? 'Student' : '${profile.program} • Year ${profile.yearLevel}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.loginId,
                      style: const TextStyle(
                        color: AppColors.goldAccentDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: QrImageView(
                        data: 'PGPC-ID|${user.loginId}|${user.id}',
                        version: QrVersions.auto,
                        size: 170,
                        gapless: false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Present this QR for attendance, library, and campus access.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
