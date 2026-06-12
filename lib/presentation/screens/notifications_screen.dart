import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme.dart';
import '../../data/models/notification_model.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl  = NotificationsController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: BackButton(onPressed: Get.back),
        actions: [
          Obx(() {
            if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'mark_all') ctrl.markAllRead();
                if (v == 'clear_all') _confirmClear(context, ctrl);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'mark_all', child: Text('Mark all as read')),
                PopupMenuItem(value: 'clear_all', child: Text('Clear all')),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: ctrl.loadNotifications,
          color: AppColors.primary,
          child: Column(
            children: [
              // ── Filter chips ─────────────────────────────────────
              _FilterBar(ctrl: ctrl),

              // ── List ─────────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  final items = ctrl.filtered;
                  if (items.isEmpty) {
                    return _EmptyState(
                        filter: ctrl.activeFilter.value);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: items.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NotificationTile(
                      notification: items[i],
                      isDark: isDark,
                      onTap: () => ctrl.onTap(items[i]),
                      onDismiss: () =>
                          ctrl.deleteNotification(items[i].id),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _confirmClear(
      BuildContext context, NotificationsController ctrl) {
    Get.dialog(AlertDialog(
      title: const Text('Clear All Notifications'),
      content:
          const Text('This will remove all notifications. Continue?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.clearAll();
          },
          child: const Text('Clear All',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.ctrl});
  final NotificationsController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Obx(() => _Chip(
                label: 'All',
                selected: ctrl.activeFilter.value == null,
                onTap: () => ctrl.setFilter(null),
              )),
          const SizedBox(width: 6),
          ...NotificationType.values.map((t) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Obx(() => _Chip(
                      label: _typeLabel(t),
                      icon: _typeIcon(t),
                      selected: ctrl.activeFilter.value == t,
                      onTap: () => ctrl.setFilter(t),
                    )),
              )),
        ],
      ),
    );
  }

  String _typeLabel(NotificationType t) => switch (t) {
        NotificationType.match       => 'Match',
        NotificationType.message     => 'Message',
        NotificationType.call        => 'Call',
        NotificationType.achievement => 'Achievement',
        NotificationType.system      => 'System',
      };

  IconData _typeIcon(NotificationType t) => switch (t) {
        NotificationType.match       => Icons.people_rounded,
        NotificationType.message     => Icons.chat_bubble_rounded,
        NotificationType.call        => Icons.phone_rounded,
        NotificationType.achievement => Icons.emoji_events_rounded,
        NotificationType.system      => Icons.info_rounded,
      };
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 5),
            ],
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

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded,
            color: AppColors.error, size: 22),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread
                ? AppColors.primary.withValues(alpha: 0.06)
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : (isDark
                      ? AppColors.darkOutline
                      : AppColors.lightOutline),
              width: unread ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              _TypeIconBadge(type: notification.type),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
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

              // Chevron
              if (notification.routePath != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Type icon badge ──────────────────────────────────────────────────────────

class _TypeIconBadge extends StatelessWidget {
  const _TypeIconBadge({required this.type});
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.match       => (Icons.people_rounded,         AppColors.secondary),
      NotificationType.message     => (Icons.chat_bubble_rounded,    AppColors.primary),
      NotificationType.call        => (Icons.phone_rounded,          AppColors.info),
      NotificationType.achievement => (Icons.emoji_events_rounded,   AppColors.amber),
      NotificationType.system      => (Icons.info_rounded,           AppColors.lightOutlineVariant),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final NotificationType? filter;

  @override
  Widget build(BuildContext context) {
    final label = filter == null ? 'notifications' : '${filter!.name} notifications';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            Text(
              'No $label',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              filter == null
                  ? "You're all caught up! New notifications will appear here."
                  : 'No ${filter!.name} notifications at the moment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
