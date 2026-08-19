import 'package:flutter/material.dart';

import '../../core/routing/route_names.dart';

/// Full-screen intro sequence:
/// 1. Logo fade in → hold → fade out
/// 2. Navigate to role selection
/// A skip button lets the user bypass the entire sequence immediately.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _logoAnimController;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    // Logo animation controller: fade in (800ms) → hold (1000ms) → fade out (800ms)
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 800),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1000),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 800),
    ]).animate(_logoAnimController);

    _initSequence();
  }

  Future<void> _initSequence() async {
    // Start logo animation, then navigate to role select
    _logoAnimController.forward().then((_) {
      if (!mounted) return;
      _navigateToRoleSelect();
    });
  }

  void _navigateToRoleSelect() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.roleSelect);
  }

  void _skip() {
    _logoAnimController.stop();
    _navigateToRoleSelect();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Logo animation (fade in → hold → fade out)
          AnimatedBuilder(
            animation: _logoOpacity,
            builder: (context, child) => Opacity(
              opacity: _logoOpacity.value,
              child: Center(
                child: Image.asset(
                  'assets/images/pgpc_logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Full-screen tap-to-skip overlay
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _skip,
            child: const SizedBox.expand(),
          ),

          // Skip button - top right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  label: 'Skip intro',
                  button: true,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _skip,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Subtle tap-to-skip hint at bottom
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  'Tap to continue',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}