import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/conversation_model.dart';
import '../../controllers/conversation_detail_controller.dart';
import '../../controllers/vocabulary_controller.dart';
import '../profile/vocabulary_screen.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/message/message_bubble.dart';
import '../../widgets/message/message_input.dart';

class ConversationDetailScreen extends StatelessWidget {
  const ConversationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ConversationDetailController>();

    return Scaffold(
      appBar: _ChatAppBar(ctrl: ctrl),
      body: Column(
        children: [
          // ── Message list ──────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.messages.isEmpty) {
                return const LoadingWidget();
              }

              if (ctrl.messages.isEmpty && !ctrl.isLoading.value) {
                return EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Start the conversation!',
                  subtitle:
                      'Say hello to ${ctrl.partnerName} and begin your language exchange.',
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  // Load more when scrolled to top
                  if (n is ScrollStartNotification &&
                      ctrl.scrollController.position.pixels <=
                          ctrl.scrollController.position.minScrollExtent + 80) {
                    ctrl.loadMessages(loadMore: true);
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: ctrl.scrollController,
                  slivers: [
                    // Load more indicator
                    SliverToBoxAdapter(
                      child: Obx(() => ctrl.isLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: LoadingWidget(size: 24),
                            )
                          : ctrl.hasMore.value
                              ? const SizedBox(height: 8)
                              : const SizedBox.shrink()),
                    ),

                    // Messages
                    Obx(() => SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final msg = ctrl.messages[i];
                              final prev = i > 0 ? ctrl.messages[i - 1] : null;
                              final showDate = prev == null ||
                                  !_sameDay(prev.createdAt, msg.createdAt);
                              final isMe = ctrl.isMyMessage(msg);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Column(
                                  children: [
                                    if (showDate)
                                      MessageTimestampDivider(
                                          date: msg.createdAt),
                                    MessageBubble(
                                      message: msg,
                                      isMe: isMe,
                                      onLongPress: () =>
                                          _showMessageOptions(
                                              context, ctrl, msg, isMe),
                                      onReact: (emoji) =>
                                          ctrl.react(msg.id, emoji),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: ctrl.messages.length,
                          ),
                        )),

                    // Typing indicator
                    SliverToBoxAdapter(
                      child: Obx(() => ctrl.isPartnerTyping.value
                          ? TypingIndicator(partnerName: ctrl.partnerName)
                          : const SizedBox.shrink()),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
              );
            }),
          ),

          // ── Reply preview ─────────────────────────────────────
          Obx(() {
            final reply = ctrl.activeReply.value;
            if (reply == null) return const SizedBox.shrink();
            return _ReplyPreviewBar(
              message: reply,
              onCancel: ctrl.clearReply,
            );
          }),

          // ── Input bar ─────────────────────────────────────────
          Obx(() => MessageInputBar(
                controller: ctrl.textController,
                hasText: ctrl.hasText.value,
                isSending: ctrl.isSending.value,
                onSend: ctrl.sendMessage,
                onAudioCall: () =>
                    Get.toNamed(Routes.audioCall, arguments: {
                  'partner_name': ctrl.partnerName,
                  'partner_id': ctrl.partnerId,
                  'conversation_id': ctrl.conversationId,
                  'call_type': 'audio',
                }),
                onVideoCall: () =>
                    Get.toNamed(Routes.videoCall, arguments: {
                  'partner_name': ctrl.partnerName,
                  'partner_id': ctrl.partnerId,
                  'conversation_id': ctrl.conversationId,
                  'call_type': 'video',
                }),
              )),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showMessageOptions(
    BuildContext context,
    ConversationDetailController ctrl,
    MessageModel msg,
    bool isMe,
  ) {
    const quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Quick emoji reactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: quickEmojis.map((e) {
                return GestureDetector(
                  onTap: () {
                    Get.back();
                    ctrl.react(msg.id, e);
                  },
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                );
              }).toList(),
            ),

            const Divider(height: 24),

            // Options
            _OptionTile(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () {
                Get.back();
                ctrl.setReplyTarget(msg);
              },
            ),
            if (!msg.isDeleted && msg.content.trim().isNotEmpty)
              _OptionTile(
                icon: Icons.menu_book_outlined,
                label: 'Save to vocabulary',
                color: AppColors.secondary,
                onTap: () {
                  Get.back();
                  VocabularyAddSheet.show(
                    context,
                    ctrl: Get.find<VocabularyController>(),
                    initialWord: msg.content.trim(),
                  );
                },
              ),
            if (isMe && !msg.isDeleted)
              _OptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: AppColors.error,
                onTap: () {
                  Get.back();
                  ctrl.deleteMessage(msg.id);
                },
              ),
            _OptionTile(
              icon: msg.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              label: msg.isPinned ? 'Unpin message' : 'Pin message',
              onTap: () {
                Get.back();
                ctrl.togglePin(msg);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom app bar ───────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.ctrl});
  final ConversationDetailController ctrl;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Get.back(),
      ),
      title: InkWell(
        onTap: () => Get.toNamed(Routes.partnerProfile, arguments: {
          'user_id': ctrl.partnerId,
          'user_name': ctrl.partnerName,
        }),
        child: Row(
          children: [
            Obx(() => AvatarWidget(
                  initials: ctrl.partnerName,
                  radius: 18,
                  showOnlineIndicator: true,
                  isOnline: ctrl.partnerIsOnline.value,
                )),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.partnerName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Obx(() => Text(
                      ctrl.partnerIsOnline.value ? 'Online' : 'Tap to view profile',
                      style: TextStyle(
                        fontSize: 11,
                        color: ctrl.partnerIsOnline.value
                            ? AppColors.success
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                        fontWeight: ctrl.partnerIsOnline.value
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded),
          onPressed: () => Get.toNamed(Routes.audioCall, arguments: {
            'partner_name': ctrl.partnerName,
            'partner_id': ctrl.partnerId,
          }),
          tooltip: 'Audio call',
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded),
          onPressed: () => Get.toNamed(Routes.videoCall, arguments: {
            'partner_name': ctrl.partnerName,
            'partner_id': ctrl.partnerId,
          }),
          tooltip: 'Video call',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) => _onMenuAction(v, context),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'search', child: Text('Search messages')),
            PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
            PopupMenuItem(value: 'archive', child: Text('Archive')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete conversation',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ],
    );
  }

  void _onMenuAction(String action, BuildContext ctx) {
    switch (action) {
      case 'archive':
        Get.snackbar('Archived', 'Conversation archived.',
            snackPosition: SnackPosition.BOTTOM);
      case 'delete':
        Get.dialog(AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text('This will permanently delete all messages.'),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ));
    }
  }
}

// ─── Option tile for long-press menu ─────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Reply preview bar (shown above the input when composing a reply) ────────

class _ReplyPreviewBar extends StatelessWidget {
  const _ReplyPreviewBar({required this.message, required this.onCancel});

  final MessageModel message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderName ?? 'this message'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.isDeleted ? 'Message deleted' : message.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onCancel,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
