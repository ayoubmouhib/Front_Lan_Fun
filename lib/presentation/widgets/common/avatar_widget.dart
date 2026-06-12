import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
  });

  final String? imageUrl;
  final String? initials;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _initials(radius),
                  errorWidget: (_, _, _) => _initials(radius),
                )
              : _initials(radius),
        ),
      ),
    );

    if (!showOnlineIndicator) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.55,
            height: radius * 0.55,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.lightOutlineVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initials(double r) {
    final label = initials?.isNotEmpty == true
        ? initials!.substring(0, initials!.length > 2 ? 2 : initials!.length).toUpperCase()
        : '?';
    return Container(
      width: r * 2,
      height: r * 2,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: r * 0.65,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
