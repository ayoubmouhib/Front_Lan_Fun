import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../controllers/gamification_controller.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl  = GamificationController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient app bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Leaderboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'See how you compare globally',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Period tabs ─────────────────────────────
                        Obx(() => Row(
                              children: ['week', 'month', 'all']
                                  .map((p) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: _PeriodTab(
                                          label: switch (p) {
                                            'week'  => 'This Week',
                                            'month' => 'This Month',
                                            _       => 'All Time',
                                          },
                                          selected:
                                              ctrl.leaderboardPeriod.value ==
                                                  p,
                                          onTap: () =>
                                              ctrl.leaderboardPeriod.value =
                                                  p,
                                        ),
                                      ))
                                  .toList(),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Your stats card ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _YourStatsCard(ctrl: ctrl, isDark: isDark),
            ),
          ),

          // ── Category selector ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: _CategorySelector(ctrl: ctrl),
            ),
          ),

          // ── Global rankings header ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Global Rankings',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'BETA',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Leaderboard list ─────────────────────────────────────
          Obx(() {
            if (ctrl.isLoadingLeaderboard.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (ctrl.leaderboardError.value != null) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(ctrl.leaderboardError.value!,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: ctrl.loadLeaderboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final entries = _toRows(ctrl);

            if (entries.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text('No data for this period yet.',
                      style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _LeaderboardRow(
                  entry: entries[i],
                  isHighlighted: entries[i].isCurrentUser,
                  isDark: isDark,
                ),
                childCount: entries.length,
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  List<_LeaderboardEntry> _toRows(GamificationController ctrl) {
    final category = ctrl.leaderboardCategory.value;
    return ctrl.leaderboardEntries.map((e) => _LeaderboardEntry(
      rank:          e.rank,
      name:          e.isCurrentUser ? 'You' : e.name,
      flag:          e.isCurrentUser ? '⭐' : e.initials,
      value:         e.valueFor(category),
      category:      category,
      isCurrentUser: e.isCurrentUser,
    )).toList();
  }
}

// ─── Your stats card ──────────────────────────────────────────────────────────

class _YourStatsCard extends StatelessWidget {
  const _YourStatsCard({required this.ctrl, required this.isDark});
  final GamificationController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Stats',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatPill(
                      icon: Icons.bolt_rounded,
                      label: '${ctrl.xpPoints.value} XP'),
                  const SizedBox(width: 10),
                  _StatPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${ctrl.streakDays.value}d streak'),
                  const SizedBox(width: 10),
                  _StatPill(
                      icon: Icons.chat_bubble_rounded,
                      label: '${ctrl.conversationCount.value} convos'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Level ${ctrl.level}  •  ${ctrl.xpIntoLevel} / ${ctrl.xpNeededForLevel} XP',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ctrl.levelProgress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ));
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Category selector ────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.ctrl});
  final GamificationController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: [
            _CatChip(
              label: 'Most XP',
              icon: Icons.bolt_rounded,
              selected: ctrl.leaderboardCategory.value == 'xp',
              onTap: () => ctrl.leaderboardCategory.value = 'xp',
            ),
            const SizedBox(width: 8),
            _CatChip(
              label: 'Streak',
              icon: Icons.local_fire_department_rounded,
              selected: ctrl.leaderboardCategory.value == 'streak',
              onTap: () => ctrl.leaderboardCategory.value = 'streak',
            ),
            const SizedBox(width: 8),
            _CatChip(
              label: 'Convos',
              icon: Icons.chat_bubble_rounded,
              selected: ctrl.leaderboardCategory.value == 'conversations',
              onTap: () =>
                  ctrl.leaderboardCategory.value = 'conversations',
            ),
          ],
        ));
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period tab ───────────────────────────────────────────────────────────────

class _PeriodTab extends StatelessWidget {
  const _PeriodTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Leaderboard row ──────────────────────────────────────────────────────────

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.flag,
    required this.value,
    required this.category,
    this.isCurrentUser = false,
  });
  final int rank;
  final String name;
  final String flag;
  final int value;
  final String category;
  final bool isCurrentUser;

  String get valueLabel => switch (category) {
        'streak'        => '$value days',
        'conversations' => '$value convos',
        _               => '$value XP',
      };
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.isHighlighted,
    required this.isDark,
  });
  final _LeaderboardEntry entry;
  final bool isHighlighted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (entry.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: medalColor != null
                ? Icon(Icons.emoji_events_rounded,
                    color: medalColor, size: 22)
                : Text(
                    '#${entry.rank}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isHighlighted
                              ? AppColors.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
          ),

          // Flag + Name
          Text(entry.flag,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isHighlighted
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isHighlighted
                        ? AppColors.primary
                        : null,
                  ),
            ),
          ),

          // Value
          Text(
            entry.valueLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isHighlighted ? AppColors.primary : null,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

