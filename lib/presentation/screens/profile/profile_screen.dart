import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/user_model.dart';
import '../../controllers/follow_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProfileController>();

    return Scaffold(
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.user.value == null) {
          return const LoadingWidget();
        }
        final u = ctrl.user.value;
        if (u == null) {
          return EmptyState(
            icon: Icons.person_off_outlined,
            title: 'Profile not loaded',
            actionLabel: 'Retry',
            onAction: ctrl.refresh,
          );
        }
        return RefreshIndicator(
          onRefresh: ctrl.refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Gradient SliverAppBar ─────────────────────────
              _ProfileSliverAppBar(user: u, ctrl: ctrl),

              // ── Stats row ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _StatsRow(ctrl: ctrl),
                ),
              ),

              // ── Languages section ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _LanguagesSection(user: u, ctrl: ctrl),
                ),
              ),

              // ── Bio section ──────────────────────────────────
              SliverToBoxAdapter(
                child: Obx(() {
                  final b = ctrl.bio.value;
                  if (b.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _Section(
                      title: 'About',
                      child: Text(b,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis),
                    ),
                  );
                }),
              ),

              // ── Interests section ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _InterestsSection(user: u),
                ),
              ),

              // ── Action buttons ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
                  child: _ActionButtons(ctrl: ctrl),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Sliver app bar ───────────────────────────────────────────────────────────

class _ProfileSliverAppBar extends StatelessWidget {
  const _ProfileSliverAppBar({required this.user, required this.ctrl});
  final UserModel user;
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 325,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Get.toNamed(Routes.settings),
          tooltip: 'Settings',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Avatar with edit overlay
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.editProfile),
                  child: Stack(
                    children: [
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
                          initials: user.fullName,
                          imageUrl: user.profilePictureUrl,
                          radius: 52,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: AppColors.purpleGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 8),

                // Location + online status
                Obx(() {
                  final loc = ctrl.location.value;
                  return Row(
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
                        loc.isNotEmpty ? '$loc • Online' : 'Online',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 12),

                _ConnectionsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Followers / Following row ────────────────────────────────────────────────

class _ConnectionsRow extends StatelessWidget {
  const _ConnectionsRow();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FollowController>();
    return Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConnectionStat(
              count: ctrl.myFollowers.length,
              label: 'Followers',
              onTap: () => _openConnections(ctrl, 'followers'),
            ),
            Container(
              width: 1,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: Colors.white.withValues(alpha: 0.25),
            ),
            _ConnectionStat(
              count: ctrl.myFollowing.length,
              label: 'Following',
              onTap: () => _openConnections(ctrl, 'following'),
            ),
          ],
        ));
  }

  /// Refreshes the lists right before opening them so a recently
  /// accepted/declined follow always shows up — counts can change
  /// without this widget being rebuilt with fresh list contents.
  void _openConnections(FollowController ctrl, String tab) {
    ctrl.loadMyConnections();
    Get.toNamed(Routes.myConnections, arguments: {'tab': tab});
  }
}

class _ConnectionStat extends StatelessWidget {
  const _ConnectionStat({required this.count, required this.label, required this.onTap});
  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    // Pull live stats from HomeController if available
    int xp = 0, level = 1, streak = 0, convCount = 0;
    try {
      final home = Get.find<HomeController>();
      xp        = home.xpPoints.value;
      level     = home.level.value;
      streak    = home.streakDays.value;
      convCount = home.totalConversations;
    } catch (_) {}

    final stats = [
      _StatItem(value: _fmt(xp),       label: 'XP',          icon: Icons.bolt_rounded,            color: AppColors.amber),
      _StatItem(value: 'Lv $level',    label: 'Level',        icon: Icons.military_tech_rounded,   color: AppColors.primary),
      _StatItem(value: '${streak}d',   label: 'Streak',       icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF6B35)),
      _StatItem(value: '$convCount',   label: 'Convos',       icon: Icons.chat_bubble_rounded,     color: AppColors.secondary),
    ];

    return Row(
      children: stats.asMap().entries.map((e) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final s = e.value;
        final last = e.key == stats.length - 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: last ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(s.icon, color: s.color, size: 20),
                const SizedBox(height: 6),
                Text(s.value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(s.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatItem {
  const _StatItem({required this.value, required this.label, required this.icon, required this.color});
  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

// ─── Languages section ────────────────────────────────────────────────────────

class _LanguagesSection extends StatelessWidget {
  const _LanguagesSection({required this.user, required this.ctrl});
  final UserModel user;
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    final langs = user.languages;
    if (langs.isEmpty) {
      return _Section(
        title: 'Languages',
        child: Text(
          'No languages added yet. Edit your profile to add languages.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
        ),
      );
    }

    return _Section(
      title: 'Languages',
      child: Column(
        children: langs.map((lang) {
          final flag = _isoToFlag(lang.language?.isoCode ?? '');
          final level = ctrl.languageLevelLabel(lang.level);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(flag.isNotEmpty ? flag : '🌐', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.language?.name ?? 'Language ${lang.languageId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        level,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                _LevelBadge(level: lang.level),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _isoToFlag(String iso) {
    final match = AppConstants.supportedLanguages.where((l) => l['iso'] == iso).toList();
    return match.isNotEmpty ? match.first['flag']! : '';
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final String level;

  Color get _color => switch (level) {
        'advanced'     => AppColors.success,
        'intermediate' => AppColors.primary,
        _              => AppColors.lightOutlineVariant,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level,
        style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Interests section ────────────────────────────────────────────────────────

class _InterestsSection extends StatelessWidget {
  const _InterestsSection({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final interests = user.interests;
    if (interests.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Interests',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: interests
            .map((i) => _InterestChip(name: i.name))
            .toList(),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Edit profile
        _ActionTile(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: () => Get.toNamed(Routes.editProfile),
          gradient: AppColors.primaryGradient,
        ),
        const SizedBox(height: 12),
        // My Vocabulary
        _ActionTile(
          icon: Icons.menu_book_outlined,
          label: 'My Vocabulary',
          onTap: () => Get.toNamed(Routes.vocabulary),
        ),
        const SizedBox(height: 12),
        // Settings
        _ActionTile(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => Get.toNamed(Routes.settings),
        ),
        const SizedBox(height: 20),

        // Logout
        GestureDetector(
          onTap: () => _confirmLogout(context, ctrl),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 10),
                Text('Log Out',
                    style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext ctx, ProfileController ctrl) {
    Get.dialog(AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () { Get.back(); ctrl.logout(); },
          child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: gradient != null ? Colors.white : AppColors.primary,
                size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: gradient != null
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: gradient != null
                  ? Colors.white.withValues(alpha: 0.7)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
