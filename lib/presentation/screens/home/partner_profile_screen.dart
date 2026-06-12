import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../controllers/matching_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/avatar_widget.dart';

class PartnerProfileScreen extends StatelessWidget {
  const PartnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final userId = args['user_id'] as int?;
    final userName = args['user_name'] as String? ?? 'Partner';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient SliverAppBar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onPressed: () => _showOptions(context, userId),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AvatarWidget(
                          initials: userName,
                          radius: 52,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Profile body ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating row
                  _InfoCard(
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text('New Member',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const Spacer(),
                        Text(
                          'ID: ${userId ?? '—'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Languages section
                  _SectionHeader('Languages'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    child: Column(
                      children: [
                        _LanguageRow(
                          icon: '🎯',
                          label: 'Practicing',
                          value: 'See profile',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Interests
                  _SectionHeader('Interests'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Language Exchange', 'Culture', 'Travel']
                        .map((i) => _InterestChip(label: i))
                        .toList(),
                  ),

                  const SizedBox(height: 28),

                  // Action buttons
                  PrimaryButton(
                    label: 'Start Chatting',
                    icon: Icons.chat_bubble_rounded,
                    onPressed: () {
                      // Navigate to conversation detail
                      Get.back();
                      Get.find<MatchingController>().startChatting();
                    },
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Accept Match',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(height: 16),

                  // Danger zone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _confirmBlock(context, userId),
                        icon: const Icon(Icons.block_rounded,
                            size: 16, color: AppColors.error),
                        label: const Text('Block',
                            style: TextStyle(color: AppColors.error)),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => _confirmReport(context, userId),
                        icon: const Icon(Icons.flag_outlined,
                            size: 16, color: AppColors.warning),
                        label: const Text('Report',
                            style:
                                TextStyle(color: AppColors.warning)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext ctx, int? userId) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.error),
              title: const Text('Block User'),
              onTap: () {
                Get.back();
                _confirmBlock(ctx, userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.warning),
              title: const Text('Report User'),
              onTap: () {
                Get.back();
                _confirmReport(ctx, userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext ctx, int? userId) {
    Get.dialog(AlertDialog(
      title: const Text('Block User'),
      content: const Text(
          'Are you sure? You will no longer see this user in matches.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            Get.back();
            Get.snackbar('Blocked', 'User has been blocked.',
                snackPosition: SnackPosition.BOTTOM);
          },
          child: const Text('Block',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }

  void _confirmReport(BuildContext ctx, int? userId) {
    Get.dialog(AlertDialog(
      title: const Text('Report User'),
      content:
          const Text('This will send a report to our moderation team.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            Get.snackbar('Reported', 'Thank you for keeping our community safe.',
                snackPosition: SnackPosition.BOTTOM);
          },
          child: const Text('Report',
              style: TextStyle(color: AppColors.warning)),
        ),
      ],
    ));
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
        const Spacer(),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
