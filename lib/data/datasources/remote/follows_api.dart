import '../../models/follow_model.dart';
import 'api_client.dart';

class FollowsApi {
  FollowsApi(this._client);
  final ApiClient _client;

  // POST /follows/requests
  Future<FollowRequestModel> sendRequest(int userId) async {
    final res = await _client.post('/follows/requests', data: {'user_id': userId});
    return FollowRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /follows/requests/incoming
  Future<List<FollowRequestModel>> getIncomingRequests() async {
    final res = await _client.get('/follows/requests/incoming');
    return (res.data as List<dynamic>)
        .map((e) => FollowRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /follows/requests/outgoing
  Future<List<FollowRequestModel>> getOutgoingRequests() async {
    final res = await _client.get('/follows/requests/outgoing');
    return (res.data as List<dynamic>)
        .map((e) => FollowRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /follows/requests/:id/accept — returns { conversation_id, ... }
  Future<Map<String, dynamic>> acceptRequest(int requestId) async {
    final res = await _client.post('/follows/requests/$requestId/accept');
    return res.data as Map<String, dynamic>;
  }

  // POST /follows/requests/:id/decline
  Future<void> declineRequest(int requestId) async {
    await _client.post('/follows/requests/$requestId/decline');
  }

  // DELETE /follows/requests/:id — cancel a request you sent
  Future<void> cancelRequest(int requestId) async {
    await _client.delete('/follows/requests/$requestId');
  }

  // DELETE /follows/:userId — unfollow
  Future<void> unfollow(int userId) async {
    await _client.delete('/follows/$userId');
  }

  // GET /follows/followers
  Future<List<UserSummary>> getMyFollowers() async {
    final res = await _client.get('/follows/followers');
    return (res.data as List<dynamic>)
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /follows/following
  Future<List<UserSummary>> getMyFollowing() async {
    final res = await _client.get('/follows/following');
    return (res.data as List<dynamic>)
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
