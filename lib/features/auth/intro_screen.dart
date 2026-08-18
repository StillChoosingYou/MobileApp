import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/routing/route_names.dart';

/// Full-screen intro video that plays [assets/videos/PGPCIntroScene.mp4]
/// once on first launch, then routes to role selection. A skip button
/// lets the user bypass it immediately.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/PGPCIntroScene.mp4');
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
      _controller.setLooping(false);
      _controller.play();
      _controller.addListener(_videoListener);
    } catch (e) {
      // If video fails to load, go straight to role select
      if (mounted) _navigateToRoleSelect();
    }
  }

  void _videoListener() {
    if (!_completed && _controller.value.isInitialized && _controller.value.position >= _controller.value.duration) {
      _completed = true;
      _navigateToRoleSelect();
    }
  }

  void _navigateToRoleSelect() {
    if (!mounted) return;
    // Use goRouter to navigate to role select
    // We need context, so we'll use a post-frame callback or navigate directly
    // Since this is called from a listener, use pushReplacement
    Navigator.of(context).pushReplacementNamed(Routes.roleSelect);
  }

  void _skip() {
    _controller.removeListener(_videoListener);
    _navigateToRoleSelect();
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video fills the screen
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Skip button - top right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  label: 'Skip intro video',
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

          // Subtle tap-to-skip hint at bottom (shows briefly)
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

          // Invisible overlay to catch taps anywhere to skip
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _skip,
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}