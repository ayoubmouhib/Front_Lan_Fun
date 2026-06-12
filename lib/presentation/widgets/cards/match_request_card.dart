import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../common/avatar_widget.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

class MatchRequestCard extends StatelessWidget {
  const MatchRequestCard({
    super.key,
    required this.requestId,
    required this.requesterName,
    required this.nativeLanguage,
    required this.learningLanguage,
    this.imageUrl,
    this.compatibilityScore,
    this.onAccept,
    this.onReject,
    this.onViewProfile,
  });

  final int requestId;
  final String requesterName;
  final String nativeLanguage;
  final String learningLanguage;
  final String? imageUrl;
  final int? compatibilityScore;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final subtle = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarWidget(
                  imageUrl: imageUrl,
                  initials: requesterName,
                  radius: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$nativeLanguage → $learningLanguage',
                        style: TextStyle(fontSize: 12, color: subtle),
                      ),
                    ],
                  ),
                ),
                if (compatibilityScore != null)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$compatibilityScore%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'match',
                        style: TextStyle(fontSize: 10, color: subtle),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: outline, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Decline',
                    onPressed: onReject,
                    height: 40,
                    color: AppColors.error,
                    icon: Icons.close_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Accept',
                    onPressed: onAccept,
                    height: 40,
                    icon: Icons.check_rounded,
                  ),
                ),
              ],
            ),
            if (onViewProfile != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onViewProfile,
                child: Center(
                  child: Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
