class BlockedUserModel {
  const BlockedUserModel({
    required this.blockId,
    required this.userId,
    required this.name,
    required this.username,
    required this.blockedAt,
    this.reason,
  });

  final int blockId;       // id of the block record (used to unblock)
  final int userId;        // id of the blocked user
  final String name;
  final String username;
  final String? reason;
  final DateTime blockedAt;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory BlockedUserModel.fromJson(Map<String, dynamic> j) => BlockedUserModel(
        blockId: j['id'] as int,
        userId: j['blocked_user_id'] as int,
        name: (j['name'] as String?)?.trim().isNotEmpty == true
            ? (j['name'] as String).trim()
            : 'Unknown user',
        username: j['username'] as String? ?? '',
        reason: j['reason'] as String?,
        blockedAt: j['blocked_at'] != null
            ? DateTime.tryParse(j['blocked_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
