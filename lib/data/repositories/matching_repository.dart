import '../datasources/remote/matching_api.dart';
import '../models/match_model.dart';

class MatchingRepository {
  MatchingRepository(this._api);
  final MatchingApi _api;

  // ─── Active search ────────────────────────────────────────────────────────

  /// POST /matching/request/active-search
  /// Returns immediately with either a matched partner or a searching ticket.
  Future<SearchResponse> initiateActiveSearch({
    required int languageId,
    int timeoutSeconds = 600,
  }) =>
      _api.initiateActiveSearch(
        languageId: languageId,
        timeoutSeconds: timeoutSeconds,
      );

  /// GET /matching/search-status/:requestId
  /// Call repeatedly until status == 'matched' or 'expired'.
  Future<SearchStatus> getSearchStatus(int requestId) =>
      _api.getSearchStatus(requestId);

  /// DELETE /matching/requests/:requestId
  /// Cancel an active search before it times out.
  Future<void> cancelSearch(int requestId) =>
      _api.cancelActiveSearch(requestId);

  // ─── Match requests ───────────────────────────────────────────────────────

  /// GET /matching/pending-requests
  Future<List<MatchRequest>> getPendingRequests() =>
      _api.getPendingRequests();

  /// POST /matching/requests/:requestId/accept
  Future<Map<String, dynamic>> acceptRequest(
    int requestId, {
    int? plannedDurationMinutes,
  }) =>
      _api.acceptRequest(requestId, plannedDurationMinutes: plannedDurationMinutes);

  /// POST /matching/requests/:requestId/reject
  Future<void> rejectRequest(int requestId) =>
      _api.rejectRequest(requestId);

  /// DELETE /matching/requests/:requestId — cancel a sent pending request
  Future<void> cancelRequest(int requestId) =>
      _api.cancelRequest(requestId);

  // ─── Ratings ──────────────────────────────────────────────────────────────

  /// GET /matching/ratings/received — reviews left by partners about this user
  Future<Map<String, dynamic>> getMyRatings({int limit = 50, int offset = 0}) =>
      _api.getMyRatings(limit: limit, offset: offset);

  // ─── Sessions ─────────────────────────────────────────────────────────────

  /// GET /matching/active
  Future<List<dynamic>> getActiveMatches() => _api.getActiveMatches();

  /// GET /matching/history
  Future<List<Map<String, dynamic>>> getHistory() =>
      _api.getConversationHistory();

  /// GET /matching/sessions/:sessionId
  Future<Map<String, dynamic>> getSessionDetails(int sessionId) =>
      _api.getSessionDetails(sessionId);

  /// POST /matching/sessions/:sessionId/start
  Future<Map<String, dynamic>> startSession(
    int sessionId, {
    int? plannedDurationMinutes,
  }) =>
      _api.startSession(sessionId, plannedDurationMinutes: plannedDurationMinutes);

  /// POST /matching/sessions/:sessionId/end
  Future<Map<String, dynamic>> endSession(int sessionId) =>
      _api.endSession(sessionId);

  // ─── Rating ───────────────────────────────────────────────────────────────

  /// POST /matching/sessions/:sessionId/rate
  Future<Map<String, dynamic>> rateSession(
    int sessionId, {
    required int overallScore,
    required int communicationScore,
    required int helpfulnessScore,
    required int patienceScore,
    String? comment,
  }) =>
      _api.rateSession(
        sessionId,
        overallScore: overallScore,
        communicationScore: communicationScore,
        helpfulnessScore: helpfulnessScore,
        patienceScore: patienceScore,
        comment: comment,
      );
}
