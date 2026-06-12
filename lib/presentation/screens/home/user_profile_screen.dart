import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/follow_model.dart';
import '../../controllers/follow_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/avatar_widget.dart';

/// Public profile of another user, reached from "Find People" search results.
/// Shows their followers/following, score and rank, and lets the viewer send,
/// cancel, or accept a follow request — connecting opens a normal conversation.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final userId = args['user_id'] as int? ?? 0;
    final ctrl = Get.find<FollowController>();

    return Scaffold(
      body: Obx(() {
        final profile = ctrl.viewedProfile.value;
        final error = ctrl.profileError.value;

        if (profile == null && ctrl.isLoadingProfile.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profile == null && error != null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Get.back(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      label: 'Try again',
                      width: 160,
                      height: 44,
                      onPressed: () => ctrl.reloadProfile(userId),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (profile == null) return const SizedBox.shrink();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: AvatarWidget(
                            imageUrl: profile.profilePictureUrl,
                            initials: profile.initials,
                            radius: 48,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(profile.name,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('@${profile.username}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats: followers / following / score / rank ─────
                    _StatsRow(profile: profile),

                    const SizedBox(height: 20),

                    if (profile.nativeLanguage != null) ...[
                      _SectionHeader('Native language'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        child: Row(
                          children: [
                            const Text('🌐', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Text(profile.nativeLanguage!.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (profile.learningLanguages.isNotEmpty) ...[
                      _SectionHeader('Learning'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        child: Column(
                          children: [
                            for (var i = 0; i < profile.learningLanguages.length; i++) ...[
                              if (i > 0) const Divider(height: 20),
                              _LearningLanguageRow(lang: profile.learningLanguages[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (profile.interests.isNotEmpty) ...[
                      _SectionHeader('Interests'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.interests.map((i) => _InterestChip(label: i.name)).toList(),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Connection action ────────────────────────────────
                    _ConnectionAction(profile: profile, ctrl: ctrl),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final PublicProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(label: 'Followers', value: '${profile.followersCount}', icon: Icons.group_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'Following', value: '${profile.followingCount}', icon: Icons.person_add_alt_1_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'Score', value: '${profile.score}', icon: Icons.bolt_rounded)),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Rank',
            value: profile.rank != null ? '#${profile.rank}' : '—',
            icon: Icons.emoji_events_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightOnSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LearningLanguageRow extends StatelessWidget {
  const _LearningLanguageRow({required this.lang});
  final PublicProfileLanguage lang;

  @override
  Widget build(BuildContext context) {
    final name = lang.language?.name ?? 'Language ${lang.languageId}';
    return Row(
      children: [
        const Text('🎯', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (lang.cefrLevel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(lang.cefrLevel!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryDark)),
          ),
        const SizedBox(width: 8),
        Text('${lang.xpPoints} XP',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant)),
      ],
    );
  }
}

class _ConnectionAction extends StatelessWidget {
  const _ConnectionAction({required this.profile, required this.ctrl});
  final PublicProfileModel profile;
  final FollowController ctrl;

  @override
  Widget build(BuildContext context) {
    final busy = ctrl.isBusy(profile.id);

    switch (profile.relationship) {
      case RelationshipStatus.self:
        return const SizedBox.shrink();

      case RelationshipStatus.following:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('You follow each other — keep chatting!',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Unfollow',
              icon: Icons.person_remove_alt_1_rounded,
              isLoading: busy,
              onPressed: () => _confirmUnfollow(context),
            ),
          ],
        );

      case RelationshipStatus.requestSent:
        return SecondaryButton(
          label: 'Cancel request',
          icon: Icons.hourglass_top_rounded,
          isLoading: busy,
          onPressed: profile.followRequestId == null
              ? null
              : () => ctrl.cancelOutgoingRequest(profile.id, profile.followRequestId!),
        );

      case RelationshipStatus.requestReceived:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('${profile.name} wants to follow you',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.info)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Accept',
                    icon: Icons.check_rounded,
                    isLoading: busy,
                    onPressed: profile.followRequestId == null
                        ? null
                        : () => ctrl.acceptRequest(
                              profile.followRequestId!,
                              fromUserId: profile.id,
                              partnerName: profile.name,
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: 'Decline',
                    icon: Icons.close_rounded,
                    isLoading: busy,
                    onPressed: profile.followRequestId == null
                        ? null
                        : () => ctrl.declineRequest(profile.followRequestId!),
                  ),
                ),
              ],
            ),
          ],
        );

      case RelationshipStatus.none:
        return PrimaryButton(
          label: 'Send follow request',
          icon: Icons.person_add_rounded,
          isLoading: busy,
          onPressed: () => ctrl.sendFollowRequest(profile.id),
        );
    }
  }

  void _confirmUnfollow(BuildContext context) {
    Get.dialog(AlertDialog(
      title: const Text('Unfollow user?'),
      content: Text('You will stop following ${profile.name}. Your conversation stays available.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.unfollow(profile.id);
          },
          child: const Text('Unfollow', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline, width: 0.5),
      ),
      child: child,
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
