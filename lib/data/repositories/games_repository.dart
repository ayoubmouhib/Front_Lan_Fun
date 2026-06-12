import '../datasources/remote/games_api.dart';
import '../models/game_model.dart';

class GamesRepository {
  GamesRepository(this._api);
  final GamesApi _api;

  Future<GamesAvailableData> getAvailableGames(int userId, int languageId) =>
      _api.getAvailableGames(userId, languageId);

  Future<GameSessionData> startGame({
    required int userId,
    required int languageId,
    required String gameType,
    int? roundCount,
  }) =>
      _api.startGame(
        userId: userId,
        languageId: languageId,
        gameType: gameType,
        roundCount: roundCount,
      );

  Future<GameAnswerResponse> submitRound({
    required int sessionId,
    required int roundIndex,
    required String userAnswer,
    required int timeSpentSeconds,
  }) =>
      _api.submitRound(
        sessionId: sessionId,
        roundIndex: roundIndex,
        userAnswer: userAnswer,
        timeSpentSeconds: timeSpentSeconds,
      );

  Future<GameResultData> completeGame(int sessionId) => _api.completeGame(sessionId);

  Future<GameResultData> getGameResult(int sessionId) => _api.getGameResult(sessionId);

  Future<List<GameHistoryEntry>> getHistory(int userId, int languageId) =>
      _api.getHistory(userId, languageId);
}
