import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.hasText,
    this.isSending = false,
    this.onAttachment,
    this.onEmojiTap,
    this.onAudioCall,
    this.onVideoCall,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool hasText;
  final bool isSending;
  final VoidCallback? onAttachment;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final pillBg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Pill ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 130, minHeight: 46),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _PillIcon(
                          icon: Icons.emoji_emotions_outlined,
                          onTap: onEmojiTap ?? () => _showEmojiPicker(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Type a message…',
                              isCollapsed: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        if (!hasText)
                          _PillIcon(
                            icon: Icons.attach_file_rounded,
                            onTap: onAttachment ?? () {},
                          ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(
                  onTap: onSend,
                  isLoading: isSending,
                  enabled: hasText,
                ),
              ],
            ),
          ),

          // ── Call buttons row ─────────────────────────────────────
          if (onAudioCall != null || onVideoCall != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  if (onAudioCall != null)
                    Expanded(
                      child: _CallButton(
                        icon: Icons.call_rounded,
                        label: 'Audio Call',
                        color: AppColors.secondary,
                        onTap: onAudioCall!,
                      ),
                    ),
                  if (onAudioCall != null && onVideoCall != null)
                    const SizedBox(width: 12),
                  if (onVideoCall != null)
                    Expanded(
                      child: _CallButton(
                        icon: Icons.videocam_rounded,
                        label: 'Video Call',
                        color: AppColors.primary,
                        onTap: onVideoCall!,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    const emojis = ['😊', '😂', '❤️', '👍', '🙏', '🔥', '🎉', '😍'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick emoji',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis
                  .map((e) => GestureDetector(
                        onTap: () {
                          controller.text += e;
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                          Navigator.pop(context);
                        },
                        child: Text(e,
                            style: const TextStyle(fontSize: 32)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Small icon button living inline inside the pill (emoji / attach).
class _PillIcon extends StatelessWidget {
  const _PillIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap, this.isLoading = false, this.enabled = true});
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : AppColors.primary.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
