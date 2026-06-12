class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.status,
    required this.type,
    this.language,
    this.partner,
    this.lastMessage,
    this.unreadCount = 0,
    this.messageCount = 0,
    this.callCount = 0,
    this.lastActivityAt,
    this.createdAt,
  });

  final int id;
  final String status; // 'active' | 'archived' | 'deleted'
  final String type;   // 'text' | 'audio' | 'video' | 'mixed'
  final ConversationLanguage? language;
  final ConversationPartner? partner;
  final LastMessage? lastMessage;
  final int unreadCount;
  final int messageCount;
  final int callCount;
  final DateTime? lastActivityAt;
  final DateTime? createdAt;

  factory ConversationModel.fromJson(Map<String, dynamic> j) =>
      ConversationModel(
        id: j['id'] as int,
        status: j['status'] as String? ?? 'active',
        type: j['type'] as String? ?? 'text',
        language: j['language'] != null
            ? ConversationLanguage.fromJson(j['language'] as Map<String, dynamic>)
            : null,
        partner: j['partner'] != null
            ? ConversationPartner.fromJson(j['partner'] as Map<String, dynamic>)
            : null,
        lastMessage: j['last_message'] != null
            ? LastMessage.fromJson(j['last_message'] as Map<String, dynamic>)
            : null,
        unreadCount: j['unread_count'] as int? ?? 0,
        messageCount: j['message_count'] as int? ?? 0,
        callCount: j['call_count'] as int? ?? 0,
        lastActivityAt: j['last_activity_at'] != null
            ? DateTime.tryParse(j['last_activity_at'] as String)
            : null,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  DateTime get sortDate => lastActivityAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool get isActive => status == 'active';
}

class ConversationPartner {
  const ConversationPartner({
    required this.id,
    required this.name,
    this.avatar,
  });

  final int id;
  final String name;
  final String? avatar;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory ConversationPartner.fromJson(Map<String, dynamic> j) =>
      ConversationPartner(
        id: j['id'] as int,
        name: j['name'] as String? ?? 'Unknown',
        avatar: j['avatar'] as String?,
      );
}

class ConversationLanguage {
  const ConversationLanguage({required this.id, required this.name});
  final int id;
  final String name;

  factory ConversationLanguage.fromJson(Map<String, dynamic> j) =>
      ConversationLanguage(
        id: j['id'] as int,
        name: j['name'] as String,
      );
}

class LastMessage {
  const LastMessage({
    required this.content,
    required this.sentByMe,
    this.at,
  });

  final String content;
  final bool sentByMe;
  final DateTime? at;

  factory LastMessage.fromJson(Map<String, dynamic> j) => LastMessage(
        content: j['content'] as String? ?? '',
        sentByMe: j['sent_by_me'] as bool? ?? false,
        at: j['at'] != null ? DateTime.tryParse(j['at'] as String) : null,
      );
}

// ─── Message model (for chat detail screen) ──────────────────────────────────

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.isEdited = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.reactions = const {},
    this.replyTo,
    this.readAt,
    this.editedAt,
  });

  final int id;
  final int conversationId;
  final String content;
  final String type;   // 'text' | 'image' | 'audio' | 'video' | 'file' | 'system'
  final String status; // 'sent' | 'delivered' | 'read'
  final DateTime createdAt;
  final int? senderId;
  final String? senderName;
  final bool isEdited;
  final bool isDeleted;
  final bool isPinned;
  final Map<String, dynamic> reactions;
  final ReplyPreview? replyTo;
  final DateTime? readAt;
  final DateTime? editedAt;

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'] as int,
        conversationId: j['conversation_id'] as int,
        content: j['content'] as String? ?? '',
        type: j['type'] as String? ?? 'text',
        status: j['status'] as String? ?? 'sent',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        senderId: j['sender'] != null ? j['sender']['id'] as int? : null,
        senderName: j['sender'] != null ? j['sender']['name'] as String? : null,
        isEdited: j['is_edited'] as bool? ?? false,
        isDeleted: j['is_deleted'] as bool? ?? false,
        isPinned: j['is_pinned'] as bool? ?? false,
        reactions: j['reactions'] as Map<String, dynamic>? ?? {},
        replyTo: j['reply_to'] != null
            ? ReplyPreview.fromJson(j['reply_to'] as Map<String, dynamic>)
            : null,
        readAt: j['read_at'] != null
            ? DateTime.tryParse(j['read_at'] as String)
            : null,
        editedAt: j['edited_at'] != null
            ? DateTime.tryParse(j['edited_at'] as String)
            : null,
      );
}

/// Compact summary of the message a reply is quoting.
class ReplyPreview {
  const ReplyPreview({required this.id, required this.content, this.senderName});

  final int id;
  final String content;
  final String? senderName;

  factory ReplyPreview.fromJson(Map<String, dynamic> j) => ReplyPreview(
        id: j['id'] as int,
        content: j['content'] as String? ?? '',
        senderName: j['sender_name'] as String?,
      );
}
