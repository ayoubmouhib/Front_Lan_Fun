import 'package:flutter/material.dart';

import '../../../config/theme.dart';

enum IconButtonVariant { filled, outlined, ghost }

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = IconButtonVariant.ghost,
    this.color,
    this.size = 44,
    this.iconSize = 22,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final IconButtonVariant variant;
  final Color? color;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primary;
    final surfaceColor = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    BoxDecoration decoration;
    Color iconColor;

    switch (variant) {
      case IconButtonVariant.filled:
        decoration = BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        );
        iconColor = Colors.white;
      case IconButtonVariant.outlined:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activeColor, width: 1.5),
        );
        iconColor = activeColor;
      case IconButtonVariant.ghost:
        decoration = BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        );
        iconColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    }

    Widget button = GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: size,
          height: size,
          decoration: decoration,
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
