import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../controllers/matching_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/avatar_widget.dart';

class SearchPartnerScreen extends StatelessWidget {
  const SearchPartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MatchingController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text('Find a Partner'),
        actions: [
          Obx(() {
            if (ctrl.searchState.value == SearchState.searching) {
              return TextButton.icon(
                onPressed: ctrl.cancelSearch,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        return switch (ctrl.searchState.value) {
          SearchState.matched  => _MatchFoundView(ctrl: ctrl),
          SearchState.searching => _SearchingView(ctrl: ctrl),
          _                    => _IdleView(ctrl: ctrl),
        };
      }),
    );
  }
}

// ─── IDLE: Language picker + big CTA ─────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.ctrl});
  final MatchingController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // ── Language picker ──────────────────────────────────────
          _SectionLabel('I want to practice'),
          const SizedBox(height: 10),
          Obx(() => _LanguageDropdown(
                languages: ctrl.myLanguages,
                selectedId: ctrl.selectedLanguageId.value,
                selectedName: ctrl.selectedLanguageName.value,
                onSelected: ctrl.selectLanguage,
              )),

          const SizedBox(height: 32),

          // ── CASE 0 — Main hero CTA ───────────────────────────────
          _ActiveSearchHero(ctrl: ctrl),

          const SizedBox(height: 28),

          // ── Divider ──────────────────────────────────────────────
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or browse manually',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ]),

          const SizedBox(height: 20),

          // ── Alternative options ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _AltCard(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                  subtitle: 'Swipe profiles',
                  gradient: AppColors.purpleGradient,
                  onTap: () => Get.toNamed('/discover'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AltCard(
                  icon: Icons.inbox_rounded,
                  label: 'Requests',
                  subtitle: 'Pending matches',
                  gradient: AppColors.emeraldGradient,
                  onTap: () => _showPendingRequests(context, ctrl),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Find people by username (follow connections) ─────────
          _AltCard(
            icon: Icons.person_search_rounded,
            label: 'Find People',
            subtitle: 'Search by username, view profiles, and follow to chat',
            gradient: AppColors.primaryGradient,
            onTap: () => Get.toNamed(Routes.userSearch),
          ),

          const SizedBox(height: 24),

          // ── Error ────────────────────────────────────────────────
          Obx(() {
            final err = ctrl.errorMessage.value;
            if (err == null) return const SizedBox.shrink();
            return _ErrorBanner(message: err);
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPendingRequests(BuildContext ctx, MatchingController ctrl) {
    ctrl.refreshPendingRequests(); // always fetch fresh data when sheet opens
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PendingRequestsSheet(ctrl: ctrl),
    );
  }
}

// ─── Language dropdown ────────────────────────────────────────────────────────

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.languages,
    required this.selectedId,
    required this.selectedName,
    required this.onSelected,
  });

  final List<UserLanguageModel> languages;
  final int? selectedId;
  final String selectedName;
  final void Function(int id, String name) onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (languages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
        ),
        child: Row(
          children: [
            Icon(Icons.translate_rounded, size: 20, color: AppColors.lightOnSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add a language you\'re learning in your profile to start practicing.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedId != null
              ? AppColors.primary
              : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          width: selectedId != null ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(14),
          hint: const Text('Select a language to practice'),
          items: languages.map((l) {
            final flag = _isoToFlag(l.language?.isoCode ?? '');
            final name = l.language?.name ?? 'Language ${l.languageId}';
            return DropdownMenuItem<int>(
              value: l.languageId,
              child: Text('$flag  $name'),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final name = languages
                .firstWhere((l) => l.languageId == id)
                .language
                ?.name ?? 'Language $id';
            onSelected(id, name);
          },
        ),
      ),
    );
  }

  String _isoToFlag(String iso) {
    final match = AppConstants.supportedLanguages
        .where((l) => l['iso'] == iso)
        .toList();
    return match.isNotEmpty ? match.first['flag']! : '🌐';
  }
}

// ─── CASE 0 — Hero active search button ──────────────────────────────────────

class _ActiveSearchHero extends StatefulWidget {
  const _ActiveSearchHero({required this.ctrl});
  final MatchingController ctrl;

  @override
  State<_ActiveSearchHero> createState() => _ActiveSearchHeroState();
}

class _ActiveSearchHeroState extends State<_ActiveSearchHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = widget.ctrl.isLoading.value;

      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _pulse.value),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        ),
        child: GestureDetector(
          onTap: loading ? null : widget.ctrl.startActiveSearch,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Animated rings
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => Container(
                          width: 100 * _pulse.value + 20,
                          height: 100 * _pulse.value + 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 1 - _pulse.value),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.people_alt_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  loading ? 'Starting search…' : '⚡ START ACTIVE SEARCH',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Find an instant match!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Get paired in 1–5 seconds',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── SEARCHING state ──────────────────────────────────────────────────────────

class _SearchingView extends StatelessWidget {
  const _SearchingView({required this.ctrl});
  final MatchingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radar animation
            const _RadarAnimation(),

            const SizedBox(height: 36),

            Text(
              'Searching for your match…',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Obx(() => Text(
                  '⏱  ${ctrl.elapsedLabel}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 40,
                      ),
                )),

            const SizedBox(height: 8),

            Obx(() {
              final t = ctrl.timeoutLabel;
              if (t.isEmpty) return const SizedBox.shrink();
              return Text(
                t,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.lightOutlineVariant),
              );
            }),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Typically found within 1–5 minutes',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Cancel
            SecondaryButton(
              label: 'Cancel Search',
              icon: Icons.close_rounded,
              onPressed: ctrl.cancelSearch,
              color: AppColors.error,
              width: 200,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}

// Radar / sonar animation widget
class _RadarAnimation extends StatefulWidget {
  const _RadarAnimation();

  @override
  State<_RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<_RadarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding rings
          ...List.generate(3, (i) {
            final delay = i / 3;
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                final progress = (_ctrl.value + delay) % 1.0;
                return Container(
                  width: 160 * progress,
                  height: 160 * progress,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: (1.0 - progress) * 0.5),
                      width: 2,
                    ),
                  ),
                );
              },
            );
          }),

          // Rotating sweep
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Transform.rotate(
              angle: _ctrl.value * 2 * math.pi,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.0),
                      AppColors.primary.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center dot
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── MATCHED state ────────────────────────────────────────────────────────────

class _MatchFoundView extends StatefulWidget {
  const _MatchFoundView({required this.ctrl});
  final MatchingController ctrl;

  @override
  State<_MatchFoundView> createState() => _MatchFoundViewState();
}

class _MatchFoundViewState extends State<_MatchFoundView>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _celebCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
  }

  @override
  void dispose() {
    _celebCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = widget.ctrl.matchedUser.value;
      final score = widget.ctrl.compatibilityScore.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Celebration header
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (r) =>
                        AppColors.primaryGradient.createShader(r),
                    child: const Text(
                      'Match Found!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your language exchange partner is ready!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Partner card
            ScaleTransition(
              scale: _scale,
              child: _MatchedPartnerCard(user: user, score: score),
            ),

            const SizedBox(height: 32),

            // Action buttons
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Start Chatting',
                    icon: Icons.chat_bubble_rounded,
                    onPressed: widget.ctrl.startChatting,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'View Profile',
                    icon: Icons.person_outline_rounded,
                    onPressed: user != null
                        ? widget.ctrl.viewMatchedProfile
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.ctrl.dismissMatch,
                    child: Text(
                      'Search again',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }
}

class _MatchedPartnerCard extends StatelessWidget {
  const _MatchedPartnerCard({required this.user, required this.score});
  final MatchedUser? user;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with online ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 3),
            ),
            child: AvatarWidget(
              initials: user?.name ?? '?',
              imageUrl: user?.avatar,
              radius: 44,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            user?.name ?? 'Your Match',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 8),

          // Online indicator
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
                'Online & Ready',
                style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),

          if (score != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${score!.round()}% Compatibility',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Pending requests bottom sheet ───────────────────────────────────────────

class _PendingRequestsSheet extends StatelessWidget {
  const _PendingRequestsSheet({required this.ctrl});
  final MatchingController ctrl;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('Pending Requests',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh',
                  onPressed: ctrl.refreshPendingRequests,
                ),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ctrl.pendingRequests.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final incoming = ctrl.pendingRequests.where((r) => !r.isSender).toList();
              final sent     = ctrl.pendingRequests.where((r) =>  r.isSender).toList();

              if (incoming.isEmpty && sent.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No pending requests at the moment.'),
                  ),
                );
              }

              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (incoming.isNotEmpty) ...[
                    _SectionHeader(label: 'Incoming', icon: Icons.inbox_rounded),
                    const SizedBox(height: 8),
                    ...incoming.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestTile(
                            request: r,
                            onAccept: () => ctrl.acceptPendingRequest(r.requestId),
                            onReject: () => ctrl.rejectPendingRequest(r.requestId),
                          ),
                        )),
                  ],
                  if (sent.isNotEmpty) ...[
                    if (incoming.isNotEmpty) const SizedBox(height: 8),
                    _SectionHeader(label: 'Sent — waiting for reply', icon: Icons.send_rounded),
                    const SizedBox(height: 8),
                    ...sent.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SentRequestTile(
                            request: r,
                            onCancel: () => ctrl.cancelSentRequest(r.requestId),
                          ),
                        )),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });
  final MatchRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(
            initials: request.requester.name,
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.requester.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (request.requesterLanguageName != null)
                  Text(request.requesterLanguageName!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.error, size: 22),
          ),
          IconButton(
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 22),
          ),
        ],
      ),
    );
  }
}

class _SentRequestTile extends StatelessWidget {
  const _SentRequestTile({required this.request, required this.onCancel});
  final MatchRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AvatarWidget(initials: request.requester.name, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.requester.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  'Waiting for response…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                ),
                if (request.requesterLanguageName != null)
                  Text(request.requesterLanguageName!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
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

class _AltCard extends StatelessWidget {
  const _AltCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
