import '../../models/match_model.dart';
import 'api_client.dart';

class MatchingApi {
  MatchingApi(this._client);
  final ApiClient _client;

  // POST /matching/request/active-search
  // Returns SearchResponse (matched OR searching ticket)
  Future<SearchResponse> initiateActiveSearch({
    required int languageId,
    int timeoutSeconds = 600,
  }) async {
    final res = await _client.post(
      '/matching/request/active-search',
      data: {
        'requester_language_id': languageId,
        'timeout_seconds': timeoutSeconds,
      },
    );
    return SearchResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /matching/search-status/:requestId
  Future<SearchStatus> getSearchStatus(int requestId) async {
    final res = await _client.get('/matching/search-status/$requestId');
    return SearchStatus.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /matching/request  — manual request (Discover like)
  Future<Map<String, dynamic>> createRequest({
    required int languageId,
    String role = 'learner',
  }) async {
    final res = await _client.post('/matching/request', data: {
      'requester_language_id': languageId,
      'requester_role': role,
    });
    return res.data as Map<String, dynamic>;
  }

  // GET /matching/pending-requests
  Future<List<MatchRequest>> getPendingRequests() async {
    final res = await _client.get('/matching/pending-requests');
    final data = res.data;
    final list = (data is Map ? data['requests'] ?? [] : data) as List<dynamic>;
    return list
        .map((e) => MatchRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /matching/active
  Future<List<dynamic>> getActiveMatches() async {
    final res = await _client.get('/matching/active');
    return res.data as List<dynamic>;
  }

  // POST /matching/requests/:requestId/accept
  Future<Map<String, dynamic>> acceptRequest(
    int requestId, {
    int? plannedDurationMinutes,
  }) async {
    final res = await _client.post('/matching/requests/$requestId/accept',
        data: <String, dynamic>{
          'session_type': 'text',
          if (plannedDurationMinutes != null)
            'planned_duration_minutes': plannedDurationMinutes,
        });
    return res.data as Map<String, dynamic>;
  }

  // POST /matching/requests/:requestId/reject
  Future<void> rejectRequest(int requestId) async {
    await _client.post('/matching/requests/$requestId/reject');
  }

  // DELETE /matching/requests/:requestId  — cancel active search
  Future<void> cancelRequest(int requestId) async {
    await _client.delete('/matching/requests/$requestId');
  }

  // POST /matching/sessions/:sessionId/rate
  Future<Map<String, dynamic>> rateSession(
    int sessionId, {
    required int overallScore,
    required int communicationScore,
    required int helpfulnessScore,
    required int patienceScore,
    String? comment,
  }) async {
    final res = await _client.post('/matching/sessions/$sessionId/rate', data: {
      'overall_score': overallScore,
      'communication_score': communicationScore,
      'helpfulness_score': helpfulnessScore,
      'patience_score': patienceScore,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return res.data as Map<String, dynamic>;
  }

  // GET /matching/ratings/received
  Future<Map<String, dynamic>> getMyRatings({int limit = 50, int offset = 0}) async {
    final res = await _client.get(
      '/matching/ratings/received',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return res.data as Map<String, dynamic>;
  }

  // GET /matching/history
  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    final res = await _client.get('/matching/history');
    final data = res.data;
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map) {
      final list = data['sessions'] ?? data['history'] ?? [];
      return List<Map<String, dynamic>>.from(list as List);
    }
    return [];
  }

  // GET /matching/sessions/:sessionId
  Future<Map<String, dynamic>> getSessionDetails(int sessionId) async {
    final res = await _client.get('/matching/sessions/$sessionId');
    return res.data as Map<String, dynamic>;
  }

  // POST /matching/sessions/:sessionId/start
  Future<Map<String, dynamic>> startSession(
    int sessionId, {
    int? plannedDurationMinutes,
  }) async {
    final res = await _client.post(
      '/matching/sessions/$sessionId/start',
      data: <String, dynamic>{
        if (plannedDurationMinutes != null)
          'planned_duration_minutes': plannedDurationMinutes,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  // POST /matching/sessions/:sessionId/end
  Future<Map<String, dynamic>> endSession(int sessionId) async {
    final res = await _client.post(
      '/matching/sessions/$sessionId/end',
      data: <String, dynamic>{},
    );
    return res.data as Map<String, dynamic>;
  }

  // DELETE /matching/requests/:requestId  (alias of cancelRequest, named for clarity)
  Future<void> cancelActiveSearch(int requestId) =>
      cancelRequest(requestId);
}
