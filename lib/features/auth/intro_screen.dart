import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/routing/route_names.dart';

/// Full-screen intro sequence:
/// 1. Logo fade in → hold → fade out
/// 2. Play PGPCIntroScene.mp4
/// 3. Navigate to role selection
/// A skip button lets the user bypass the entire sequence immediately.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  late final AnimationController _logoAnimController;
  late final Animation<double> _logoOpacity;

  bool _videoInitialized = false;
  bool _videoCompleted = false;
  bool _logoSequenceCompleted = false;

  @override
  void initState() {
    super.initState();

    // Video controller
    _videoController = VideoPlayerController.asset('assets/videos/PGPCIntroScene.mp4');

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
    try {
      // Initialize video in background while logo plays - with timeout for large files
      await _videoController.initialize().timeout(const Duration(seconds: 10));
      _videoController.setLooping(false);

      if (!mounted) return;
      setState(() => _videoInitialized = true);

      // Start logo animation
      _logoAnimController.forward().then((_) {
        if (!mounted) return;
        setState(() => _logoSequenceCompleted = true);
        _videoController.play();
        _videoController.addListener(_videoListener);
      });
    } catch (e) {
      // If video fails or times out, just play logo animation then go to role select
      debugPrint('Video initialization failed/timed out: $e');
      if (!mounted) return;
      setState(() => _videoInitialized = true);
      _logoAnimController.forward().then((_) {
        if (mounted) _navigateToRoleSelect();
      });
    }
  }

  void _videoListener() {
    if (!_videoCompleted && _videoController.value.isInitialized &&
        _videoController.value.position >= _videoController.value.duration) {
      _videoCompleted = true;
      _navigateToRoleSelect();
    }
  }

  void _navigateToRoleSelect() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.roleSelect);
  }

  void _skip() {
    _logoAnimController.stop();
    _videoController.removeListener(_videoListener);
    _navigateToRoleSelect();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Phase 1: Logo animation (shows first)
          if (!_logoSequenceCompleted)
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
            )
          else if (_videoInitialized)
            // Phase 2: Video playback (after logo fades out)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            // Fallback loading while video initializes
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Full-screen tap-to-skip overlay (above content, below skip button)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _skip,
            child: const SizedBox.expand(),
          ),

          // Skip button - top right (always visible during sequence, on top)
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