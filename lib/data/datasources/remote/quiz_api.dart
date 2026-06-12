import '../../models/quiz_model.dart';
import 'api_client.dart';

class QuizApi {
  QuizApi(this._client);
  final ApiClient _client;

  // GET /quiz/available/:userId/:languageId
  Future<QuizAvailableData> getAvailableQuiz(int userId, int languageId) async {
    final res = await _client.get('/quiz/available/$userId/$languageId');
    return QuizAvailableData.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /quiz/start/:instanceId
  Future<void> startQuiz(int instanceId) async {
    await _client.post('/quiz/start/$instanceId');
  }

  // POST /quiz/answer/:instanceId
  Future<QuizAnswerResponse> submitAnswer({
    required int instanceId,
    required int questionId,
    required String userAnswer,
    required int timeSpentSeconds,
  }) async {
    final res = await _client.post(
      '/quiz/answer/$instanceId',
      data: {
        'questionId': questionId,
        'userAnswer': userAnswer,
        'timeSpentSeconds': timeSpentSeconds,
      },
    );
    return QuizAnswerResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /quiz/complete/:instanceId
  Future<QuizResultData> completeQuiz(int instanceId) async {
    final res = await _client.post('/quiz/complete/$instanceId');
    return QuizResultData.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /quiz/history/:userId/:languageId
  Future<List<Map<String, dynamic>>> getHistory(
      int userId, int languageId) async {
    final res = await _client.get('/quiz/history/$userId/$languageId');
    final data = res.data;
    if (data is Map) {
      return List<Map<String, dynamic>>.from(data['history'] as List? ?? []);
    }
    return List<Map<String, dynamic>>.from(data as List? ?? []);
  }

  // GET /user/:id  — used to extract languageProgress data
  Future<List<UserLanguageProgressData>> getUserLanguageProgress(
      int userId) async {
    final res = await _client.get('/user/$userId');
    final data = res.data as Map<String, dynamic>;
    final raw = data['languageProgress'] as List<dynamic>?;
    if (raw == null) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(UserLanguageProgressData.fromJson)
        .toList();
  }
}
