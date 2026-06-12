import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.height = 56,
    this.borderRadius = 14,
    this.textStyle,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Gradient? gradient;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final double width;

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _disabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: _disabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: _disabled
                ? null
                : (gradient ?? AppColors.primaryGradient),
            color: _disabled ? AppColors.lightOutlineVariant : null,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: _disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: textStyle ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
