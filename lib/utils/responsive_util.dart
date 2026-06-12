import 'package:flutter/material.dart';

/// Breakpoints: phone < 600 ≤ tablet < 1200 ≤ desktop
class ResponsiveUtil {
  ResponsiveUtil._();

  // ─── Breakpoint checks ────────────────────────────────────────────────────

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1200;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1200;

  // ─── Responsive value helper ──────────────────────────────────────────────

  /// Returns [phone], [tablet], or [desktop] depending on screen width.
  /// Falls back: desktop → tablet → phone if narrower values aren't provided.
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? phone;
    if (isTablet(context))  return tablet ?? phone;
    return phone;
  }

  // ─── Common layout values ─────────────────────────────────────────────────

  /// Horizontal screen padding that grows on wider screens.
  static double horizontalPadding(BuildContext context) =>
      value(context, phone: 16.0, tablet: 32.0, desktop: 64.0);

  /// Max content width (card/column) — unlimited on phones, constrained on
  /// larger screens so content doesn't stretch painfully wide.
  static double maxContentWidth(BuildContext context) =>
      value(context, phone: double.infinity, tablet: 560.0, desktop: 900.0);

  /// Number of grid columns for an achievement/card grid.
  static int gridColumns(BuildContext context,
          {int phone = 2, int tablet = 3, int desktop = 4}) =>
      value(context, phone: phone, tablet: tablet, desktop: desktop);

  /// Whether a side-by-side (master-detail) layout makes sense.
  static bool isSideBySide(BuildContext context) => !isPhone(context);

  // ─── Raw dimensions ───────────────────────────────────────────────────────

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;
}

/// Wraps [child] in a centred, width-constrained box on tablet/desktop
/// while remaining full-width on phones.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.horizontalPadding,
  });

  final Widget child;
  final double? maxWidth;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final pad   = horizontalPadding ?? ResponsiveUtil.horizontalPadding(context);
    final maxW  = maxWidth ?? ResponsiveUtil.maxContentWidth(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        ),
      ),
    );
  }
}
