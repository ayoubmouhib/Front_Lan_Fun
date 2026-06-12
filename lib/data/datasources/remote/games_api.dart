import '../../models/game_model.dart';
import 'api_client.dart';

class GamesApi {
  GamesApi(this._client);
  final ApiClient _client;

  // GET /games/available/:userId/:languageId
  Future<GamesAvailableData> getAvailableGames(int userId, int languageId) async {
    final res = await _client.get('/games/available/$userId/$languageId');
    return GamesAvailableData.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /games/start/:userId
  Future<GameSessionData> startGame({
    required int userId,
    required int languageId,
    required String gameType,
    int? roundCount,
  }) async {
    final res = await _client.post(
      '/games/start/$userId',
      data: {
        'language_id': languageId,
        'game_type': gameType,
        if (roundCount != null) 'round_count': roundCount,
      },
    );
    return GameSessionData.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /games/:sessionId/answer
  Future<GameAnswerResponse> submitRound({
    required int sessionId,
    required int roundIndex,
    required String userAnswer,
    required int timeSpentSeconds,
  }) async {
    final res = await _client.post(
      '/games/$sessionId/answer',
      data: {
        'round_index': roundIndex,
        'user_answer': userAnswer,
        'time_spent_seconds': timeSpentSeconds,
      },
    );
    return GameAnswerResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /games/:sessionId/complete
  Future<GameResultData> completeGame(int sessionId) async {
    final res = await _client.post('/games/$sessionId/complete');
    return GameResultData.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /games/result/:sessionId
  Future<GameResultData> getGameResult(int sessionId) async {
    final res = await _client.get('/games/result/$sessionId');
    return GameResultData.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /games/history/:userId/:languageId
  Future<List<GameHistoryEntry>> getHistory(int userId, int languageId) async {
    final res = await _client.get('/games/history/$userId/$languageId');
    final data = res.data as Map<String, dynamic>;
    return (data['history'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GameHistoryEntry.fromJson)
        .toList();
  }
}
