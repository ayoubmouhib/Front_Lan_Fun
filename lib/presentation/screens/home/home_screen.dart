import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/user_model.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_widget.dart';
import '../gamification/achievements_screen.dart';
import '../profile/profile_screen.dart';
import 'user_search_screen.dart';

// ─── Tab-page stubs imported from sibling files ────────────────────────────
import '../../controllers/app_controller.dart';
import '../conversation/conversations_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return Obx(() {
      final idx = ctrl.tabIndex.value;
      return Scaffold(
        body: IndexedStack(
          index: idx,
          children: const [
            _HomeTab(),
            UserSearchScreen(),
            ConversationsListScreen(),
            ProfileScreen(),
            AchievementsScreen(),
          ],
        ),
        bottomNavigationBar: Obx(() => BottomNavBar(
              currentIndex: ctrl.tabIndex.value,
              onTap: ctrl.setTab,
              unreadMessages: ctrl.totalUnread,
            )),
      );
    });
  }
}

// ─── Tab 0: Home dashboard ───────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return Scaffold(
      appBar: _HomeAppBar(),
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.conversations.isEmpty) {
          return const LoadingWidget();
        }
        return RefreshIndicator(
          onRefresh: ctrl.refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Welcome header card ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Obx(() => _WelcomeCard(user: ctrl.user.value)),
                ),
              ),

              // ── Stats row ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Obx(() => _StatsRow(
                        xpPoints: ctrl.xpPoints.value,
                        level: ctrl.level.value,
                        streakDays: ctrl.streakDays.value,
                        practiceHours: ctrl.practiceHours.value,
                      )),
                ),
              ),

              // ── Quick actions ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _QuickActions(ctrl: ctrl),
                ),
              ),

              // ── Recent conversations header ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Recent Conversations',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Obx(() {
                        if (ctrl.conversations.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return TextButton(
                          onPressed: () => ctrl.setTab(2),
                          child: const Text('See All'),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Conversations list ───────────────────────────
              Obx(() {
                final convs = ctrl.recentConversations;
                if (convs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No conversations yet',
                        subtitle:
                            'Find a language partner and start chatting!',
                        actionLabel: 'Find a Partner',
                        onAction: ctrl.goToSearch,
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _ConversationTile(
                        conv: convs[i],
                        onTap: () =>
                            ctrl.navigateToConversation(convs[i].id),
                      ),
                    ),
                    childCount: convs.length,
                  ),
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      }),
    );
  }
}

// ─── App bar ─────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appCtrl = Get.find<AppController>();

    return AppBar(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: ShaderMask(
        shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
        child: const Text(
          'LinguaConnect',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      actions: [
        // Theme toggle
        IconButton(
          icon: Obx(() => Icon(
                appCtrl.themeMode == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              )),
          onPressed: appCtrl.toggleTheme,
          tooltip: 'Toggle theme',
        ),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Get.toNamed(Routes.settings),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Welcome card ─────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = user?.firstName ?? 'there';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ready to practice your languages today?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AvatarWidget(
            initials: user?.firstName ?? '?',
            imageUrl: user?.profilePictureUrl,
            radius: 28,
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.xpPoints,
    required this.level,
    required this.streakDays,
    required this.practiceHours,
  });
  final int xpPoints;
  final int level;
  final int streakDays;
  final int practiceHours;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = [
      _Stat(
        icon: Icons.star_rounded,
        iconColor: AppColors.amber,
        value: _formatNum(xpPoints),
        label: 'XP Points',
      ),
      _Stat(
        icon: Icons.military_tech_rounded,
        iconColor: AppColors.primary,
        value: 'Lv $level',
        label: 'Level',
      ),
      _Stat(
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFFF6B35),
        value: '${streakDays}d',
        label: 'Streak',
      ),
      _Stat(
        icon: Icons.access_time_rounded,
        iconColor: AppColors.secondary,
        value: '${practiceHours}h',
        label: 'Practiced',
      ),
    ];

    return Row(
      children: stats.map((s) {
        final isLast = s == stats.last;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: s.iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(s.icon, color: s.iconColor, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  s.value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _Stat {
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
}

// ─── Quick actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final locked = ctrl.quizPending.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unlock hint — shown only while quiz is still pending
          if (locked) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_open_rounded,
                      color: AppColors.purple, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Complete your placement quiz to unlock all features',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 1 — Quiz (always first, always active)
          _ActionCard(
            label: 'Quiz',
            subtitle:
                locked ? 'Take your placement quiz' : 'Test yourself',
            icon: Icons.quiz_rounded,
            color: const Color(0xFF7C3AED),
            onTap: ctrl.startQuiz,
            highlight: true,
          ),
          const SizedBox(height: 10),

          // 2 — Find a Language Partner
          _ActionCard(
            label: 'Find a Partner',
            subtitle: 'Get paired in 1–5 seconds',
            icon: Icons.people_alt_rounded,
            color: AppColors.purple, // 0xFF8B5CF6
            onTap: ctrl.navigateToFindPartner,
            locked: locked,
          ),
          const SizedBox(height: 10),

          // 3 — Messages
          _ActionCard(
            label: 'Messages',
            subtitle: 'Your chats',
            icon: Icons.chat_bubble_rounded,
            color: AppColors.primary, // 0xFF6366F1 indigo-purple
            onTap: ctrl.goToMessages,
            locked: locked,
          ),
          const SizedBox(height: 10),

          // 4 — Discover
          _ActionCard(
            label: 'Discover',
            subtitle: 'Swipe & match',
            icon: Icons.explore_rounded,
            color: const Color(0xFF9333EA), // purple-600
            onTap: () => Get.toNamed(Routes.discover),
            locked: locked,
          ),
          const SizedBox(height: 10),

          // 5 — Games
          _ActionCard(
            label: 'Games',
            subtitle: 'Play & learn',
            icon: Icons.sports_esports_rounded,
            color: AppColors.purpleLight, // 0xFFA78BFA lavender
            onTap: ctrl.startGames,
            locked: locked,
          ),
        ],
      );
    });
  }
}

// Full-width horizontal action card with optional locked state
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
    this.highlight = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool locked;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = locked ? Colors.grey : color;

    // Highlighted (Quiz) card uses a filled gradient background
    if (highlight && !locked) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: locked ? 0.45 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: effectiveColor.withValues(alpha: 0.25), width: 1.2),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(
                            alpha: isDark ? 0.08 : 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.lightOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  locked
                      ? Icons.lock_rounded
                      : Icons.chevron_right_rounded,
                  color: effectiveColor.withValues(alpha: 0.55),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animated gradient CTA button with glow
class _GlowButton extends StatefulWidget {
  const _GlowButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _glow.value),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conv, required this.onTap});
  final ConversationModel conv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final subtle = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    final partner = conv.partner;
    final lastMsg = conv.lastMessage;
    final hasUnread = conv.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.3)
                : outline,
            width: hasUnread ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            AvatarWidget(
              imageUrl: partner?.avatar,
              initials: partner?.name ?? '?',
              radius: 24,
              showOnlineIndicator: true,
              isOnline: false,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          partner?.name ?? 'Unknown',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Language badge
                      if (conv.language != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            conv.language!.name,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Last message preview
                      Expanded(
                        child: lastMsg != null
                            ? Row(
                                children: [
                                  if (lastMsg.sentByMe) ...[
                                    Icon(Icons.done_all_rounded,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      lastMsg.content,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: hasUnread
                                            ? (isDark
                                                ? AppColors.darkOnSurface
                                                : AppColors.lightOnSurface)
                                            : subtle,
                                        fontWeight: hasUnread
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Start a conversation!',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: subtle,
                                    fontStyle: FontStyle.italic),
                              ),
                      ),
                      const SizedBox(width: 8),
                      // Time + unread
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeLabel(conv.sortDate),
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  hasUnread ? AppColors.primary : subtle,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 20, minHeight: 20),
                              child: Text(
                                conv.unreadCount > 99
                                    ? '99+'
                                    : '${conv.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }
}

