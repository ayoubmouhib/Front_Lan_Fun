import '../datasources/remote/follows_api.dart';
import '../models/follow_model.dart';

class FollowsRepository {
  FollowsRepository(this._api);

  final FollowsApi _api;

  Future<FollowRequestModel> sendRequest(int userId) => _api.sendRequest(userId);

  Future<List<FollowRequestModel>> getIncomingRequests() => _api.getIncomingRequests();

  Future<List<FollowRequestModel>> getOutgoingRequests() => _api.getOutgoingRequests();

  /// Returns the conversation id created/reused for the new connection.
  Future<int> acceptRequest(int requestId) async {
    final result = await _api.acceptRequest(requestId);
    return (result['conversation_id'] as num).toInt();
  }

  Future<void> declineRequest(int requestId) => _api.declineRequest(requestId);

  Future<void> cancelRequest(int requestId) => _api.cancelRequest(requestId);

  Future<void> unfollow(int userId) => _api.unfollow(userId);

  Future<List<UserSummary>> getMyFollowers() => _api.getMyFollowers();

  Future<List<UserSummary>> getMyFollowing() => _api.getMyFollowing();
}
