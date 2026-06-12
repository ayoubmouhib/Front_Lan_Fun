import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/follow_model.dart';
import '../../controllers/follow_controller.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';

/// Shows the signed-in user's followers and following lists side by side in
/// tabs — reached by tapping the counts on the profile header. Lets the user
/// open any account's public profile ("discover") and unfollow people they follow.
class MyConnectionsScreen extends StatelessWidget {
  const MyConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final initialTab = args['tab'] == 'following' ? 1 : 0;
    final ctrl = Get.find<FollowController>();

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connections'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Get.back(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: Obx(() {
          if (ctrl.isLoadingConnections.value &&
              ctrl.myFollowers.isEmpty &&
              ctrl.myFollowing.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _ConnectionsList(
                users: ctrl.myFollowers,
                ctrl: ctrl,
                showUnfollow: false,
                emptyTitle: 'No followers yet',
                emptySubtitle: 'When people follow you, they\'ll show up here.',
              ),
              _ConnectionsList(
                users: ctrl.myFollowing,
                ctrl: ctrl,
                showUnfollow: true,
                emptyTitle: 'Not following anyone',
                emptySubtitle: 'People you follow will show up here.',
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  const _ConnectionsList({
    required this.users,
    required this.ctrl,
    required this.showUnfollow,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final RxList<UserSummary> users;
  final FollowController ctrl;
  final bool showUnfollow;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (users.isEmpty) {
        return EmptyState(
          icon: Icons.people_outline_rounded,
          title: emptyTitle,
          subtitle: emptySubtitle,
        );
      }

      return RefreshIndicator(
        onRefresh: ctrl.loadMyConnections,
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ConnectionTile(user: users[i], ctrl: ctrl, showUnfollow: showUnfollow),
        ),
      );
    });
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({required this.user, required this.ctrl, required this.showUnfollow});

  final UserSummary user;
  final FollowController ctrl;
  final bool showUnfollow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = ctrl.isBusy(user.id);

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
              AvatarWidget(imageUrl: user.profilePictureUrl, initials: user.initials, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('@${user.username}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.lightOnSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showUnfollow)
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: busy ? null : () => _confirmUnfollow(context),
                    child: busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                          )
                        : const Text('Unfollow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmUnfollow(BuildContext context) {
    Get.dialog(AlertDialog(
      title: const Text('Unfollow user?'),
      content: Text('You will stop following ${user.name}.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.unfollow(user.id);
          },
          child: const Text('Unfollow', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}
