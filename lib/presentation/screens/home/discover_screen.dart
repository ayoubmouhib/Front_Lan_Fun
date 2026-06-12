import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/match_model.dart';
import '../../controllers/matching_controller.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MatchingController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Partners'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final requests = ctrl.pendingRequests;

        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.explore_outlined,
            title: 'No pending requests',
            subtitle:
                'When someone wants to match with you, their\nprofile will appear here to accept or pass.',
            actionLabel: 'Start Active Search',
            onAction: () {
              Get.back();
            },
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Text(
                    '${requests.length} pending request${requests.length == 1 ? '' : 's'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Card stack
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background cards (next 2 in stack)
                  ...requests
                      .skip(1)
                      .take(2)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) {
                    final offset = (e.key + 1) * 8.0;
                    final scale = 1.0 - (e.key + 1) * 0.04;
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topCenter,
                        child: _SwipeCard(
                          request: e.value,
                          isBackground: true,
                        ),
                      ),
                    );
                  }),

                  // Top swipeable card
                  _SwipeCardInteractive(
                    key: ValueKey(requests.first.requestId),
                    request: requests.first,
                    onAccept: () =>
                        ctrl.acceptPendingRequest(requests.first.requestId),
                    onReject: () =>
                        ctrl.rejectPendingRequest(requests.first.requestId),
                  ),
                ],
              ),
            ),

            // Action row
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Obx(() {
                final req = ctrl.pendingRequests.firstOrNull;
                if (req == null) return const SizedBox.shrink();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      label: 'Pass',
                      onTap: () =>
                          ctrl.rejectPendingRequest(req.requestId),
                    ),
                    _ActionButton(
                      icon: Icons.favorite_rounded,
                      color: AppColors.success,
                      label: 'Accept',
                      onTap: () =>
                          ctrl.acceptPendingRequest(req.requestId),
                      large: true,
                    ),
                    _ActionButton(
                      icon: Icons.star_rounded,
                      color: AppColors.amber,
                      label: 'Super',
                      onTap: () =>
                          ctrl.acceptPendingRequest(req.requestId),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Swipe card (static background layers) ───────────────────────────────────

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({required this.request, this.isBackground = false});
  final MatchRequest request;
  final bool isBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarWidget(
            initials: request.requester.name,
            radius: 52,
          ),
          const SizedBox(height: 16),
          Text(
            request.requester.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (request.requesterLanguageName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Practicing: ${request.requesterLanguageName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
          if (request.compatibilityScore != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${request.compatibilityScore!.round()}% Match',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Interactive top card with swipe gesture ─────────────────────────────────

class _SwipeCardInteractive extends StatefulWidget {
  const _SwipeCardInteractive({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final MatchRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  State<_SwipeCardInteractive> createState() => _SwipeCardInteractiveState();
}

class _SwipeCardInteractiveState extends State<_SwipeCardInteractive>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _dragX = 0;
  double _dragY = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragX += d.delta.dx;
      _dragY += d.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final threshold = MediaQuery.of(context).size.width * 0.35;
    if (_dragX > threshold) {
      widget.onAccept();
    } else if (_dragX < -threshold) {
      widget.onReject();
    } else {
      setState(() { _dragX = 0; _dragY = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final angle = _dragX / 800;
    final isRight = _dragX > 40;
    final isLeft = _dragX < -40;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..translateByDouble(_dragX, _dragY, 0.0, 0.0)
          ..rotateZ(angle),
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: [
            _SwipeCard(request: widget.request),

            // LIKE label
            if (isRight)
              Positioned(
                top: 32,
                left: 32,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.success, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACCEPT',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // PASS label
            if (isLeft)
              Positioned(
                top: 32,
                right: 32,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.error, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PASS',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Round action button ──────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 56.0;
    final iconSize = large ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 2.5),
              boxShadow: large
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ],
    );
  }
}
