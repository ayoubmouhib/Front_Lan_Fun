import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/conversation_model.dart';
import '../../controllers/conversation_controller.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/input/search_input_field.dart';

class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ConversationController>();

    return Scaffold(
      appBar: _MessagesAppBar(ctrl: ctrl),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchInputField(
              hint: 'Search conversations…',
              onChanged: ctrl.setSearch,
            ),
          ),

          // ── Filter tabs ───────────────────────────────────────
          Obx(() => _FilterTabs(
                currentTab: ctrl.activeTab.value,
                onTab: ctrl.setTab,
              )),

          // ── List ──────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.conversations.isEmpty) {
                return const LoadingWidget();
              }

              final list = ctrl.filtered;

              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: ctrl.searchQuery.value.isNotEmpty
                      ? 'No results'
                      : ctrl.activeTab.value == 2
                          ? 'No archived conversations'
                          : 'No conversations yet',
                  subtitle: ctrl.searchQuery.value.isEmpty
                      ? 'Find a language partner and start chatting!'
                      : null,
                  actionLabel: ctrl.searchQuery.value.isEmpty
                      ? 'Find a Partner'
                      : null,
                  onAction: ctrl.searchQuery.value.isEmpty
                      ? () => Get.toNamed(Routes.searchPartner)
                      : null,
                );
              }

              return RefreshIndicator(
                onRefresh: ctrl.refresh,
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 72,
                    color: Theme.of(context).dividerColor,
                  ),
                  itemBuilder: (_, i) => _ConversationListTile(
                    conv: list[i],
                    onTap: () => _openConversation(list[i]),
                    onArchive: () => ctrl.archive(list[i].id),
                    onDelete: () => _confirmDelete(context, ctrl, list[i]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openConversation(ConversationModel conv) {
    Get.toNamed(Routes.conversationDetail, arguments: {
      'id': conv.id,
      'partner_name': conv.partner?.name ?? 'Partner',
      'partner_id': conv.partner?.id,
    });
  }

  void _confirmDelete(
    BuildContext ctx,
    ConversationController ctrl,
    ConversationModel conv,
  ) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Conversation'),
      content: Text(
        'Are you sure you want to delete your conversation with ${conv.partner?.name ?? 'this user'}? This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.delete(conv.id);
          },
          child: const Text('Delete',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _MessagesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MessagesAppBar({required this.ctrl});
  final ConversationController ctrl;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Text('Messages'),
          const SizedBox(width: 8),
          Obx(() {
            final unread = ctrl.totalUnread;
            if (unread == 0) return const SizedBox.shrink();
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'New conversation',
          onPressed: () => Get.toNamed(Routes.searchPartner),
        ),
      ],
    );
  }
}

// ─── Filter tabs ──────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.currentTab, required this.onTab});
  final int currentTab;
  final ValueChanged<int> onTab;

  static const _labels = ['All', 'Active', 'Archived'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == currentTab;
          return GestureDetector(
            onTap: () => onTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < _labels.length - 1 ? 8 : 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: active ? AppColors.primaryGradient : null,
                color: active
                    ? null
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _labels[i],
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Swipeable conversation row ───────────────────────────────────────────────

class _ConversationListTile extends StatelessWidget {
  const _ConversationListTile({
    required this.conv,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  final ConversationModel conv;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(conv.id),
      background: _SwipeBg(
        color: AppColors.warning,
        icon: Icons.archive_outlined,
        label: 'Archive',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBg(
        color: AppColors.error,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onArchive();
          return false; // don't remove from list — status update handles it
        } else {
          onDelete();
          return false;
        }
      },
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online indicator
              AvatarWidget(
                imageUrl: conv.partner?.avatar,
                initials: conv.partner?.name ?? '?',
                radius: 26,
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
                            conv.partner?.name ?? 'Unknown',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: conv.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Language chip
                        if (conv.language != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(width: 8),
                        // Time
                        Text(
                          _timeLabel(conv.sortDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: conv.unreadCount > 0
                                ? AppColors.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Sent indicator
                        if (conv.lastMessage?.sentByMe == true) ...[
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Last message
                        Expanded(
                          child: Text(
                            conv.lastMessage?.content ??
                                'Start a conversation!',
                            style: TextStyle(
                              fontSize: 13,
                              color: conv.unreadCount > 0
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                              fontWeight: conv.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              fontStyle: conv.lastMessage == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread badge
                        if (conv.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(5),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
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

// ─── Swipe action background ──────────────────────────────────────────────────

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
