import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_names.dart';

/// Full-screen intro sequence:
/// 1. Logo fade in → hold → fade out
/// 2. Navigate to role selection
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
    context.go(Routes.roleSelect);
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
      body: Center(
        child: AnimatedBuilder(
          animation: _logoOpacity,
          builder: (context, child) => Opacity(
            opacity: _logoOpacity.value,
            child: Image.asset(
              'assets/images/pgpc_logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}