import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/achievement_model.dart';
import '../../controllers/gamification_controller.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl  = GamificationController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        if (ctrl.isLoadingStats.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: ctrl.refreshStats,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── App bar ─────────────────────────────────────────────
              _AchievementsSliverAppBar(ctrl: ctrl, isDark: isDark),

              // ── Filter tabs ─────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                snap: false,
                floating: false,
                toolbarHeight: 56,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Obx(() => Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: ctrl.achievementFilter.value == 'all',
                            onTap: () => ctrl.achievementFilter.value = 'all',
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Unlocked',
                            selected: ctrl.achievementFilter.value == 'unlocked',
                            onTap: () => ctrl.achievementFilter.value = 'unlocked',
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Locked',
                            selected: ctrl.achievementFilter.value == 'locked',
                            onTap: () => ctrl.achievementFilter.value = 'locked',
                          ),
                        ],
                      )),
                ),
              ),

              // ── Achievement grid ─────────────────────────────────────
              Obx(() {
                final items = ctrl.filteredAchievements;
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            ctrl.achievementFilter.value == 'unlocked'
                                ? 'No achievements unlocked yet'
                                : 'All achievements unlocked!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AchievementCard(
                          achievement: items[i], isDark: isDark),
                      childCount: items.length,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Sliver app bar ───────────────────────────────────────────────────────────

class _AchievementsSliverAppBar extends StatelessWidget {
  const _AchievementsSliverAppBar(
      {required this.ctrl, required this.isDark});
  final GamificationController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
          tooltip: 'Leaderboard',
          onPressed: () => Get.toNamed(Routes.leaderboard),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.purpleGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        '${ctrl.achievements.where((a) => a.unlocked).length} / ${ctrl.achievements.length} unlocked',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      )),
                  const SizedBox(height: 16),

                  // XP Level + progress bar
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level ${ctrl.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${ctrl.xpPoints.value} XP',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ctrl.levelProgress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ctrl.xpIntoLevel} / ${ctrl.xpNeededForLevel} XP to Level ${ctrl.level + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Achievement card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard(
      {required this.achievement, required this.isDark});
  final AchievementModel achievement;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? achievement.color.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          width: unlocked ? 1.5 : 1,
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: unlocked
                    ? achievement.color.withValues(alpha: 0.15)
                    : (isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                achievement.icon,
                color: unlocked
                    ? achievement.color
                    : (isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.lightOutlineVariant),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Description
            Expanded(
              child: Text(
                achievement.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: unlocked ? 0.6 : 0.35),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 10),

            // Progress / unlocked badge
            if (unlocked)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Unlocked',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.fraction,
                      minHeight: 5,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.color.withValues(alpha: 0.7)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.progress} / ${achievement.total}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
