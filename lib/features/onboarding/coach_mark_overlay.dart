import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A reusable coach-mark / spotlight overlay for guided tutorials.
///
/// Usage:
/// 1. Wrap target widgets with [CoachMarkTarget] and assign a unique [targetKey]
/// 2. Show the overlay via [CoachMarkOverlay.show] with a list of [CoachMarkStep]s
/// 3. Each step highlights one target with a cutout, shows tooltip text, and waits for "Next"
///
/// The overlay manages its own stack entry and cleans up on dismiss/completion.
class CoachMarkOverlay {
  CoachMarkOverlay._();

  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  /// Shows a multi-step coach mark tutorial.
  ///
  /// - [context]: BuildContext to access the overlay
  /// - [steps]: Ordered list of steps to show
  /// - [onComplete]: Called when all steps complete or user dismisses
  /// - [onStepChange]: Optional callback when step index changes
  static void show({
    required BuildContext context,
    required List<CoachMarkStep> steps,
    VoidCallback? onComplete,
    ValueChanged<int>? onStepChange,
  }) {
    if (_isShowing) return;
    _isShowing = true;

    final overlay = Overlay.of(context);

    void dismiss() {
      _currentEntry?.remove();
      _currentEntry = null;
      _isShowing = false;
      onComplete?.call();
    }

    void showStep(int index) {
      if (index >= steps.length) {
        dismiss();
        return;
      }

      onStepChange?.call(index);

      final step = steps[index];
      final targetContext = step.targetKey.currentContext;
      if (targetContext == null) {
        // Target not rendered yet — skip to next
        showStep(index + 1);
        return;
      }

      final renderBox = targetContext.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) {
        showStep(index + 1);
        return;
      }

      final targetRect = renderBox.localToGlobal(Offset.zero, ancestor: overlay.context.findRenderObject())
          & renderBox.size;

      _currentEntry?.remove();
      _currentEntry = OverlayEntry(
        builder: (context) => _CoachMarkOverlayWidget(
          targetRect: targetRect,
          step: step,
          stepIndex: index,
          totalSteps: steps.length,
          onNext: () => showStep(index + 1),
          onSkip: dismiss,
        ),
      );
      overlay.insert(_currentEntry!);
    }

    showStep(0);
  }

  /// Dismisses any currently showing coach mark overlay.
  static void dismiss() {
    if (_isShowing) {
      _currentEntry?.remove();
      _currentEntry = null;
      _isShowing = false;
    }
  }

  /// Whether a coach mark is currently visible.
  static bool get isShowing => _isShowing;
}

/// Configuration for a single coach mark step.
class CoachMarkStep {
  CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.shape = CoachMarkShape.circle,
    this.radius = 8.0,
    this.offset = Offset.zero,
    this.alignment = Alignment.center,
    this.showArrow = true,
    this.arrowOffset = 0.0,
  });

  /// GlobalKey attached to the target widget via [CoachMarkTarget].
  final GlobalKey targetKey;

  /// Title shown in the tooltip.
  final String title;

  /// Description shown below the title.
  final String description;

  /// Shape of the cutout highlight.
  final CoachMarkShape shape;

  /// Corner radius for rounded rect shape.
  final double radius;

  /// Offset from the target's center for positioning the tooltip.
  final Offset offset;

  /// Alignment of tooltip relative to target.
  final Alignment alignment;

  /// Whether to show an arrow pointing to the target.
  final bool showArrow;

  /// Additional offset for arrow positioning.
  final double arrowOffset;
}

/// Shape of the coach mark cutout.
enum CoachMarkShape {
  circle,
  roundedRect,
}

/// Wrapper widget that registers a GlobalKey for coach mark targeting.
///
/// Wrap any widget you want to highlight in a tutorial:
/// ```dart
/// CoachMarkTarget(
///   key: myTargetKey,
///   child: MyWidget(),
/// )
/// ```
class CoachMarkTarget extends StatelessWidget {
  const CoachMarkTarget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _CoachMarkOverlayWidget extends StatelessWidget {
  const _CoachMarkOverlayWidget({
    required this.targetRect,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  final Rect targetRect;
  final CoachMarkStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);

    // Calculate tooltip position
    final tooltipPosition = _calculateTooltipPosition(screenSize, safePadding);

    return Stack(
      children: [
        // Semi-transparent backdrop with cutout
        _BackdropWithCutout(
          targetRect: targetRect,
          shape: step.shape,
          radius: step.radius,
        ),

        // Tooltip card
        Positioned(
          left: tooltipPosition.dx,
          top: tooltipPosition.dy,
          child: _TooltipCard(
            step: step,
            stepIndex: stepIndex,
            totalSteps: totalSteps,
            onNext: onNext,
            onSkip: onSkip,
            targetRect: targetRect,
          ),
        ),

        // Pulse animation on target area
        Positioned(
          left: targetRect.left - 4,
          top: targetRect.top - 4,
          child: _PulseRing(
            size: Size(targetRect.width + 8, targetRect.height + 8),
            shape: step.shape,
            radius: step.radius,
          ),
        ),
      ],
    );
  }

  Offset _calculateTooltipPosition(Size screenSize, EdgeInsets safePadding) {
    const tooltipWidth = 300.0;
    const tooltipHeight = 160.0;
    const margin = 24.0;

    // Start with preferred position based on alignment
    double left, top;

    switch (step.alignment) {
      case Alignment.topLeft:
      case Alignment.topCenter:
      case Alignment.topRight:
        top = targetRect.top - tooltipHeight - margin + step.offset.dy;
        break;
      case Alignment.bottomLeft:
      case Alignment.bottomCenter:
      case Alignment.bottomRight:
        top = targetRect.bottom + margin + step.offset.dy;
        break;
      default:
        top = targetRect.bottom + margin + step.offset.dy;
    }

    switch (step.alignment) {
      case Alignment.topLeft:
      case Alignment.centerLeft:
      case Alignment.bottomLeft:
        left = targetRect.left + step.offset.dx;
        break;
      case Alignment.topRight:
      case Alignment.centerRight:
      case Alignment.bottomRight:
        left = targetRect.right - tooltipWidth + step.offset.dx;
        break;
      default:
        left = targetRect.center.dx - tooltipWidth / 2 + step.offset.dx;
    }

    // Clamp to screen bounds with safe area
    left = left.clamp(safePadding.left + margin, screenSize.width - tooltipWidth - safePadding.right - margin);
    top = top.clamp(safePadding.top + margin, screenSize.height - tooltipHeight - safePadding.bottom - margin);

    return Offset(left, top);
  }
}

class _BackdropWithCutout extends StatelessWidget {
  const _BackdropWithCutout({
    required this.targetRect,
    required this.shape,
    required this.radius,
  });

  final Rect targetRect;
  final CoachMarkShape shape;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackdropPainter(
        cutoutRect: targetRect,
        shape: shape,
        radius: radius,
      ),
      size: Size.infinite,
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.cutoutRect,
    required this.shape,
    required this.radius,
  });

  final Rect cutoutRect;
  final CoachMarkShape shape;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = _createCutoutPath();
    path.addPath(cutoutPath, Offset.zero);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  Path _createCutoutPath() {
    final inflatedRect = cutoutRect.inflate(8);

    switch (shape) {
      case CoachMarkShape.circle:
        final center = inflatedRect.center;
        final radius = inflatedRect.shortestSide / 2;
        return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      case CoachMarkShape.roundedRect:
        return Path()..addRRect(RRect.fromRectAndRadius(inflatedRect, Radius.circular(radius)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    required this.targetRect,
  });

  final CoachMarkStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Rect targetRect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 260),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldSeed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Step ${stepIndex + 1} of $totalSteps',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.goldAccentDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: scheme.onSurfaceVariant),
                    onPressed: onSkip,
                    tooltip: 'Skip tutorial',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                step.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                step.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (stepIndex > 0)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        'Skip',
                        style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    )
                  else
                    const Spacer(),

                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldSeed,
                      foregroundColor: AppColors.royalBlueSeed,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      stepIndex == totalSteps - 1 ? 'Finish' : 'Next',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  }

class _PulseRing extends StatefulWidget {
  const _PulseRing({
    required this.size,
    required this.shape,
    required this.radius,
  });

  final Size size;
  final CoachMarkShape shape;
  final double radius;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _PulseRingPainter(
            progress: _animation.value,
            size: widget.size,
            shape: widget.shape,
            radius: widget.radius,
          ),
          size: widget.size,
        );
      },
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter({
    required this.progress,
    required this.size,
    required this.shape,
    required this.radius,
  });

  final double progress;
  final Size size;
  final CoachMarkShape shape;
  final double radius;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = AppColors.goldSeed.withValues(alpha: (1.0 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final animatedRadius = (size.shortestSide / 2) * (0.8 + progress * 0.4);

    switch (shape) {
      case CoachMarkShape.circle:
        canvas.drawCircle(center, animatedRadius, paint);
      case CoachMarkShape.roundedRect:
        final rect = Rect.fromCenter(
          center: center,
          width: size.width * (0.8 + progress * 0.4),
          height: size.height * (0.8 + progress * 0.4),
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}