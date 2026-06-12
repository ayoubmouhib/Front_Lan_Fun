import '../datasources/remote/quiz_api.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  QuizRepository(this._api);
  final QuizApi _api;

  Future<QuizAvailableData> getAvailableQuiz(int userId, int languageId) =>
      _api.getAvailableQuiz(userId, languageId);

  Future<void> startQuiz(int instanceId) => _api.startQuiz(instanceId);

  Future<QuizAnswerResponse> submitAnswer({
    required int instanceId,
    required int questionId,
    required String userAnswer,
    required int timeSpentSeconds,
  }) =>
      _api.submitAnswer(
        instanceId: instanceId,
        questionId: questionId,
        userAnswer: userAnswer,
        timeSpentSeconds: timeSpentSeconds,
      );

  Future<QuizResultData> completeQuiz(int instanceId) =>
      _api.completeQuiz(instanceId);

  Future<List<Map<String, dynamic>>> getHistory(int userId, int languageId) =>
      _api.getHistory(userId, languageId);
}
