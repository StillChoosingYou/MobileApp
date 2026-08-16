import 'package:flutter/material.dart';

/// Breakpoints and layout helpers for phones, landscape phones, tablets, and
/// desktop/web widths.
abstract final class Responsive {
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 840;
  static const double compactHeightBreakpoint = 500;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static EdgeInsets viewPaddingOf(BuildContext context) =>
      MediaQuery.viewPaddingOf(context);

  static bool isLandscape(BuildContext context) {
    final size = sizeOf(context);
    return size.width > size.height;
  }

  /// True on landscape phones and other short viewports.
  static bool isCompactHeight(BuildContext context) =>
      sizeOf(context).height < compactHeightBreakpoint;

  static bool isTabletOrWider(BuildContext context) =>
      sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktopOrWider(BuildContext context) =>
      sizeOf(context).width >= desktopBreakpoint;

  /// Side [NavigationRail] saves vertical space in landscape and scales up
  /// naturally on tablets/desktop.
  static bool useSideNavigation(BuildContext context) =>
      isTabletOrWider(context) || (isLandscape(context) && isCompactHeight(context));

  static bool shouldExtendNavigationRail(BuildContext context) =>
      isDesktopOrWider(context);

  static int gridCrossAxisCount(
    BuildContext context, {
    int compact = 2,
    int medium = 3,
    int expanded = 4,
  }) {
    final width = sizeOf(context).width;
    if (width >= desktopBreakpoint) return expanded;
    if (width >= tabletBreakpoint) return medium;
    return compact;
  }

  static double gridChildAspectRatio(BuildContext context) {
    if (isCompactHeight(context)) return 1.35;
    if (isTabletOrWider(context)) return 1.25;
    return 1.2;
  }

  static double contentMaxWidth(BuildContext context) {
    final width = sizeOf(context).width;
    if (width >= desktopBreakpoint) return 960;
    if (width >= tabletBreakpoint) return 720;
    return width;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final horizontal = isDesktopOrWider(context)
        ? 32.0
        : isTabletOrWider(context)
            ? 24.0
            : isCompactHeight(context)
                ? 16.0
                : 20.0;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  /// Padding for scrollable page content — tighter on short/landscape viewports.
  static EdgeInsets scrollPadding(BuildContext context) {
    final horizontal = pagePadding(context).horizontal / 2;
    final vertical = isCompactHeight(context)
        ? 12.0
        : isTabletOrWider(context)
            ? 20.0
            : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Form/auth screens — accounts for keyboard and compact height.
  static EdgeInsets formPadding(BuildContext context) {
    final base = scrollPadding(context);
    return base.copyWith(
      top: isCompactHeight(context) ? 16.0 : 24.0,
      bottom: isCompactHeight(context) ? 16.0 : 24.0,
    );
  }

  /// Fluid spacing that scales down on compact viewports.
  static double spacing(BuildContext context, {double normal = 16, double compact = 10}) =>
      isCompactHeight(context) ? compact : normal;

  /// Fluid width clamped between [min] and [max], scaled by [fraction] of
  /// the current viewport width.
  static double fluidWidth(
    BuildContext context, {
    required double min,
    required double max,
    double fraction = 0.9,
  }) {
    return (sizeOf(context).width * fraction).clamp(min, max);
  }

  /// Receipt/card overlay width — never fixed pixels on small screens.
  static double receiptWidth(BuildContext context) =>
      fluidWidth(context, min: 280, max: 420, fraction: 0.88);

  /// QR scan frame — scales with the shortest viewport side.
  static double scanFrameSize(BuildContext context) {
    final shortest = sizeOf(context).shortestSide;
    return (shortest * 0.55).clamp(180.0, 320.0);
  }
}

/// Centers content and caps width on larger screens.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({required this.child, super.key, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? Responsive.contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}

/// A row of stat cards that scrolls horizontally when horizontal space is tight.
class ResponsiveStatRow extends StatelessWidget {
  const ResponsiveStatRow({required this.children, super.key, this.spacing = 12});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);
    final width = Responsive.sizeOf(context).width;
    final useHorizontalScroll = width < 400 || Responsive.isCompactHeight(context);

    if (useHorizontalScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              SizedBox(width: 148, child: children[i]),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
