import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// A decorative header card with gradient background, used on the Home screen.
class GradientHeaderCard extends StatelessWidget {
  const GradientHeaderCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Gradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
