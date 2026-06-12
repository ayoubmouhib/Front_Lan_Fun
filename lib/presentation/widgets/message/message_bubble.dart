import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../data/models/conversation_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
    this.onLongPress,
    this.onReact,
  });

  final MessageModel message;
  final bool isMe;
  final bool showSenderName;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _DeletedBubble(isMe: isMe);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) const SizedBox(width: 8),

            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (showSenderName && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 2),
                      child: Text(
                        message.senderName ?? 'Partner',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Main bubble
                  _BubbleContent(message: message, isMe: isMe),

                  // Reactions bar
                  if (message.reactions.isNotEmpty)
                    _ReactionsBar(reactions: message.reactions),

                  // Timestamp + status
                  const SizedBox(height: 2),
                  _MessageMeta(message: message, isMe: isMe),
                ],
              ),
            ),

            if (isMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Bubble body ──────────────────────────────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message, required this.isMe});
  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe
        ? null // gradient applied via BoxDecoration
        : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE5E7EB));

    final textColor = isMe
        ? Colors.white
        : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        gradient: isMe ? AppColors.primaryGradient : null,
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null)
            _ReplyQuote(reply: message.replyTo!, isMe: isMe),
          Text(
            message.isDeleted ? 'Message deleted' : message.content,
            style: TextStyle(
              color: textColor,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quoted-reply preview shown inside a bubble ───────────────────────────────

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.reply, required this.isMe});
  final ReplyPreview reply;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final tint = isMe ? Colors.white : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: isMe ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: tint, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reply.senderName ?? 'Message',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            reply.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: (isMe ? Colors.white : tint).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta row: time + status ──────────────────────────────────────────────────

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({required this.message, required this.isMe});
  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final subtleColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited)
          Text(
            'edited · ',
            style: TextStyle(fontSize: 10, color: subtleColor),
          ),
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(fontSize: 10, color: subtleColor),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _StatusIcon(status: message.status),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
}

// ─── Message status ticks ─────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all_rounded,
            size: 14, color: AppColors.primary);
      case 'delivered':
        return Icon(Icons.done_all_rounded,
            size: 14,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.4));
      default: // 'sent'
        return Icon(Icons.done_rounded,
            size: 14,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.4));
    }
  }
}

// ─── Reactions bar ────────────────────────────────────────────────────────────

class _ReactionsBar extends StatelessWidget {
  const _ReactionsBar({required this.reactions});
  final Map<String, dynamic> reactions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 4,
      children: reactions.entries.map((e) {
        final emoji = e.key;
        final users = (e.value as List?)?.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            ),
          ),
          child: Text('$emoji $users', style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    );
  }
}

// ─── Deleted message tombstone ────────────────────────────────────────────────

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.isMe});
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  'Message deleted',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timestamp divider ────────────────────────────────────────────────────────

class MessageTimestampDivider extends StatelessWidget {
  const MessageTimestampDivider({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = _buildLabel(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _buildLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    if (msgDay == today) return 'Today';
    if (msgDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(dt);
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, required this.partnerName});
  final String partnerName;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) {
                    final offset = ((_ctrl.value - i * 0.2) % 1.0);
                    final y = offset < 0.5 ? -4.0 * offset : -4.0 * (1 - offset);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.partnerName} is typing…',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
