import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../common/avatar_widget.dart';

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    super.key,
    required this.conversationId,
    required this.partnerName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.partnerImageUrl,
    this.languageFlag = '',
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    this.onTap,
  });

  final int conversationId;
  final String partnerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? partnerImageUrl;
  final String languageFlag;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback? onTap;

  String get _timeLabel {
    final now = DateTime.now();
    final diff = now.difference(lastMessageTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(lastMessageTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final subtle = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AvatarWidget(
              imageUrl: partnerImageUrl,
              initials: partnerName,
              radius: 26,
              showOnlineIndicator: true,
              isOnline: isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (languageFlag.isNotEmpty) ...[
                        Text(languageFlag, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          partnerName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? AppColors.primary : subtle,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: isTyping
                            ? Text(
                                'typing...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                lastMessage,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasUnread
                                      ? (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)
                                      : subtle,
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
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
    );
  }
}
