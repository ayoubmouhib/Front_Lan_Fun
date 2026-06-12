import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../common/avatar_widget.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.userId,
    required this.name,
    required this.nativeLanguage,
    required this.learningLanguage,
    this.imageUrl,
    this.location,
    this.rating,
    this.isOnline = false,
    this.compatibilityPercent,
    this.onTap,
  });

  final String userId;
  final String name;
  final String nativeLanguage;
  final String learningLanguage;
  final String? imageUrl;
  final String? location;
  final double? rating;
  final bool isOnline;
  final int? compatibilityPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final subtle = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outline, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarWidget(
                imageUrl: imageUrl,
                initials: name,
                radius: 28,
                showOnlineIndicator: true,
                isOnline: isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (compatibilityPercent != null)
                          _CompatibilityBadge(percent: compatibilityPercent!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$nativeLanguage → $learningLanguage',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtle),
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: subtle),
                          const SizedBox(width: 2),
                          Text(
                            location!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: subtle, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    if (rating != null) ...[
                      const SizedBox(height: 4),
                      _StarRating(rating: rating!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompatibilityBadge extends StatelessWidget {
  const _CompatibilityBadge({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}
