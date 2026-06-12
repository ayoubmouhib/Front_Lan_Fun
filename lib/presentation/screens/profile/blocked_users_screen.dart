import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../data/models/blocked_user_model.dart';
import '../../controllers/blocked_users_controller.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_widget.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(BlockedUsersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const LoadingWidget();
        }

        if (ctrl.errorMessage.value != null && ctrl.blockedUsers.isEmpty) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load blocked users',
            subtitle: ctrl.errorMessage.value,
            actionLabel: 'Retry',
            onAction: ctrl.loadBlockedUsers,
          );
        }

        if (ctrl.blockedUsers.isEmpty) {
          return const EmptyState(
            icon: Icons.block_rounded,
            title: 'No blocked users',
            subtitle:
                "You haven't blocked anyone. People you block won't be able to "
                'message you or appear as practice partners.',
          );
        }

        return RefreshIndicator(
          onRefresh: ctrl.loadBlockedUsers,
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: ctrl.blockedUsers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final user = ctrl.blockedUsers[i];
              return Obx(() => _BlockedUserTile(
                    user: user,
                    isUnblocking: ctrl.unblockingIds.contains(user.blockId),
                    onUnblock: () => _confirmUnblock(context, ctrl, user),
                  ));
            },
          ),
        );
      }),
    );
  }

  void _confirmUnblock(
    BuildContext context,
    BlockedUsersController ctrl,
    BlockedUserModel user,
  ) {
    Get.dialog(AlertDialog(
      title: const Text('Unblock User'),
      content: Text(
        'Unblock ${user.name}? They will be able to message you and appear '
        'as a practice partner again.',
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.unblock(user);
          },
          child: const Text(
            'Unblock',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ));
  }
}

// ─── Blocked user tile ────────────────────────────────────────────────────────

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.user,
    required this.isUnblocking,
    required this.onUnblock,
  });

  final BlockedUserModel user;
  final bool isUnblocking;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(initials: user.name, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (user.username.isNotEmpty)
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                const SizedBox(height: 4),
                if (user.reason != null && user.reason!.isNotEmpty)
                  Text(
                    'Reason: ${user.reason}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                Text(
                  'Blocked ${_dateLabel(user.blockedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isUnblocking ? null : onUnblock,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isUnblocking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Unblock', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return 'today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}
