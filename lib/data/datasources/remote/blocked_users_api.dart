import 'api_client.dart';

class BlockedUsersApi {
  BlockedUsersApi(this._client);
  final ApiClient _client;

  // POST /blocked-users/block
  Future<void> blockUser(int userId, {String? reason}) async {
    await _client.post('/blocked-users/block', data: {
      'blocked_user_id': userId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  // POST /blocked-users/unblock
  Future<void> unblockUser(int userId) async {
    await _client.post('/blocked-users/unblock', data: {
      'blocked_user_id': userId,
    });
  }

  // GET /blocked-users/my-blocks
  // Returns { total, blocked_users: [ { id, blocked_user_id, username, name, reason, blocked_at } ] }
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final res = await _client.get('/blocked-users/my-blocks');
    final data = res.data as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(
        data?['blocked_users'] as List? ?? []);
  }

  // GET /blocked-users/check/:userId
  // Returns { is_blocked, blocked_user_id }
  Future<bool> isUserBlocked(int userId) async {
    final res = await _client.get('/blocked-users/check/$userId');
    return (res.data as Map<String, dynamic>?)?['is_blocked'] as bool? ??
        false;
  }

  // DELETE /blocked-users/:blockedUserId
  Future<void> deleteBlock(int blockedUserId) async {
    await _client.delete('/blocked-users/$blockedUserId');
  }

  // POST /blocked-users/:blockedUserId/reason
  Future<void> updateBlockReason(int blockedUserId, String reason) async {
    await _client.post(
      '/blocked-users/$blockedUserId/reason',
      data: {'reason': reason},
    );
  }
}
