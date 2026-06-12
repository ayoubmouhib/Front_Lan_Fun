import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/follow_model.dart';
import '../../controllers/follow_controller.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';

/// Lets the user search the directory by username/name and open a public
/// profile to view stats and send a follow request — separate from the
/// random "Find a Partner" matching flow.
class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FollowController>();
    final searchCtrl = TextEditingController(text: ctrl.searchQuery.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find People'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_rounded),
            tooltip: 'Follow requests',
            onPressed: () => _showFollowRequests(context, ctrl),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: searchCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: ctrl.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by username or name…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Obx(() {
                  if (ctrl.searchQuery.value.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      searchCtrl.clear();
                      ctrl.onSearchChanged('');
                    },
                  );
                }),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final query = ctrl.searchQuery.value.trim();

              if (query.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'Search the community',
                  subtitle: 'Type a username or name to find people,\nview their profile, and send a follow request.',
                );
              }

              if (ctrl.isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final error = ctrl.searchError.value;
              if (error != null) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Search failed',
                  subtitle: error,
                );
              }

              final results = ctrl.searchResults;
              if (results.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  subtitle: 'No one matches "$query".\nTry a different username or name.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _UserResultTile(user: results[i], ctrl: ctrl),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showFollowRequests(BuildContext context, FollowController ctrl) {
    ctrl.loadRequests(); // always fetch fresh data when the sheet opens
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FollowRequestsSheet(ctrl: ctrl),
    );
  }
}

// ─── Follow requests bottom sheet ────────────────────────────────────────────

class _FollowRequestsSheet extends StatelessWidget {
  const _FollowRequestsSheet({required this.ctrl});
  final FollowController ctrl;

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
                Text('Follow Requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh',
                  onPressed: ctrl.loadRequests,
                ),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ctrl.incomingRequests.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoadingRequests.value &&
                  ctrl.incomingRequests.isEmpty &&
                  ctrl.outgoingRequests.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final incoming = ctrl.incomingRequests;
              final outgoing = ctrl.outgoingRequests;

              if (incoming.isEmpty && outgoing.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No follow requests right now.'),
                  ),
                );
              }

              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (incoming.isNotEmpty) ...[
                    _RequestsSectionHeader(label: 'Incoming', icon: Icons.inbox_rounded),
                    const SizedBox(height: 8),
                    ...incoming.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _IncomingRequestTile(request: r, ctrl: ctrl),
                        )),
                  ],
                  if (outgoing.isNotEmpty) ...[
                    if (incoming.isNotEmpty) const SizedBox(height: 8),
                    _RequestsSectionHeader(label: 'Sent — waiting for reply', icon: Icons.send_rounded),
                    const SizedBox(height: 8),
                    ...outgoing.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OutgoingRequestTile(request: r, ctrl: ctrl),
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

class _RequestsSectionHeader extends StatelessWidget {
  const _RequestsSectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
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

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({required this.request, required this.ctrl});
  final FollowRequestModel request;
  final FollowController ctrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = request.user;
    final busy = ctrl.isBusy(request.requestId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          AvatarWidget(
            imageUrl: user?.profilePictureUrl,
            initials: user?.initials ?? '?',
            radius: 24,
            onTap: user == null ? null : () {
              Get.back();
              ctrl.openProfile(user.id);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Unknown user',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (user != null)
                  Text('@${user.username}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.lightOnSurfaceVariant)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: busy
                              ? null
                              : () => ctrl.acceptRequest(request.requestId,
                                  fromUserId: user?.id, partnerName: user?.name),
                          child: busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: busy ? null : () => ctrl.declineRequest(request.requestId),
                          child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  const _OutgoingRequestTile({required this.request, required this.ctrl});
  final FollowRequestModel request;
  final FollowController ctrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = request.user;
    final busy = ctrl.isBusy(request.requestId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline, width: 0.5),
      ),
      child: Row(
        children: [
          AvatarWidget(imageUrl: user?.profilePictureUrl, initials: user?.initials ?? '?', radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Unknown user', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Waiting for them to respond',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightOnSurfaceVariant)),
              ],
            ),
          ),
          TextButton(
            onPressed: busy || user == null ? null : () => ctrl.cancelOutgoingRequest(user.id, request.requestId),
            child: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Cancel', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  const _UserResultTile({required this.user, required this.ctrl});

  final UserSearchResult user;
  final FollowController ctrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ctrl.openProfile(user.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AvatarWidget(
                imageUrl: user.profilePictureUrl,
                initials: user.initials,
                radius: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('@${user.username}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.lightOnSurfaceVariant)),
                    if (user.nativeLanguage != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Speaks ${user.nativeLanguage!.name}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RelationshipBadge(status: user.relationshipStatus),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationshipBadge extends StatelessWidget {
  const _RelationshipBadge({required this.status});
  final RelationshipStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final IconData icon;

    switch (status) {
      case RelationshipStatus.following:
        label = 'Following';
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case RelationshipStatus.requestSent:
        label = 'Pending';
        color = AppColors.warning;
        icon = Icons.hourglass_top_rounded;
        break;
      case RelationshipStatus.requestReceived:
        label = 'Wants to follow';
        color = AppColors.info;
        icon = Icons.move_to_inbox_rounded;
        break;
      case RelationshipStatus.self:
      case RelationshipStatus.none:
        label = 'View';
        color = AppColors.primary;
        icon = Icons.arrow_forward_ios_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
