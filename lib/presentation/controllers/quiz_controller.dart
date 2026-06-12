import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/quiz_api.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/quiz_repository.dart';

class QuizController extends GetxController {
  static QuizController get to => Get.find();

  // ─── Reactive state ───────────────────────────────────────────────────────
  final phase          = QuizPhase.idle.obs;
  final quiz           = Rx<QuizAvailableData?>(null);
  final currentIndex   = 0.obs;
  final selectedAnswer = Rx<String?>(null);
  final lastAnswer     = Rx<QuizAnswerResponse?>(null);
  final result         = Rx<QuizResultData?>(null);
  final errorMessage   = Rx<String?>(null);
  final answeredCount  = 0.obs;

  // Timer state
  final totalSecondsLeft     = 0.obs;
  final questionSecondsSpent = 0.obs;

  // ─── Private ──────────────────────────────────────────────────────────────
  Timer? _totalTimer;
  Timer? _questionTimer;
  DateTime? _questionStartTime;

  int? _userId;
  int? _languageId;
  String _languageName = '';

  late final QuizRepository _repo;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _repo = QuizRepository(QuizApi(ApiClient.instance));
    _loadUserAndQuiz();
  }

  @override
  void onClose() {
    _stopTimers();
    super.onClose();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadUserAndQuiz() async {
    phase.value = QuizPhase.loading;
    errorMessage.value = null;

    final user = await StorageService.instance.getCachedUser();
    final uid  = await StorageService.instance.getUserId();

    if (user == null || uid == null) {
      phase.value = QuizPhase.error;
      errorMessage.value = 'Session expired. Please log in again.';
      return;
    }
    _userId = uid;

    // Accept explicit language from route args, else auto-select
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['languageId'] != null) {
      _languageId = args['languageId'] as int;
      _languageName = args['languageName'] as String? ?? '';
    } else {
      final candidates = user.learningLanguages.isNotEmpty
          ? user.learningLanguages
          : user.languages;
      if (candidates.isEmpty) {
        phase.value = QuizPhase.error;
        errorMessage.value = 'No language found. Please complete your profile.';
        return;
      }
      final lang = candidates.first;
      _languageId = lang.languageId;
      _languageName = lang.language?.name ?? 'Language';
    }

    try {
      final data = await _repo.getAvailableQuiz(_userId!, _languageId!);
      quiz.value = data;
      phase.value = QuizPhase.preview;
    } on DioException catch (e) {
      phase.value = QuizPhase.error;
      if (e.response?.statusCode == 404) {
        errorMessage.value =
            'No quiz available for $_languageName right now.\nCheck back soon!';
      } else {
        errorMessage.value = ApiClient.parseError(e);
      }
    } catch (e) {
      phase.value = QuizPhase.error;
      errorMessage.value = e.toString();
    }
  }

  // ─── Start ────────────────────────────────────────────────────────────────

  Future<void> startQuiz() async {
    final instance = quiz.value;
    if (instance == null) return;

    phase.value = QuizPhase.starting;
    errorMessage.value = null;

    try {
      await _repo.startQuiz(instance.instanceId);
      currentIndex.value   = 0;
      answeredCount.value  = 0;
      selectedAnswer.value = null;
      lastAnswer.value     = null;
      totalSecondsLeft.value = instance.timeLimitMinutes * 60;
      _startTotalTimer();
      _startQuestionTimer();
      phase.value = QuizPhase.question;
    } catch (e) {
      phase.value = QuizPhase.preview;
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── Answer ───────────────────────────────────────────────────────────────

  void selectAnswer(String answer) {
    if (phase.value != QuizPhase.question) return;
    selectedAnswer.value = answer;
  }

  Future<void> submitAnswer() async {
    final instance = quiz.value;
    final q        = currentQuestion;
    final answer   = selectedAnswer.value;
    if (instance == null || q == null || answer == null || answer.isEmpty) return;

    phase.value = QuizPhase.submitting;
    _stopQuestionTimer();

    final timeSpent = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inSeconds
        : 0;

    try {
      final response = await _repo.submitAnswer(
        instanceId:      instance.instanceId,
        questionId:      q.id,
        userAnswer:      answer,
        timeSpentSeconds: timeSpent,
      );
      lastAnswer.value = response;
      answeredCount.value++;
      phase.value = QuizPhase.feedback;
    } catch (e) {
      phase.value = QuizPhase.question;
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── Navigate through questions ───────────────────────────────────────────

  Future<void> nextQuestion() async {
    final instance = quiz.value;
    if (instance == null) return;

    final isLast = currentIndex.value >= instance.questions.length - 1;
    if (isLast) {
      await _completeQuiz();
    } else {
      currentIndex.value++;
      selectedAnswer.value = null;
      lastAnswer.value     = null;
      _startQuestionTimer();
      phase.value = QuizPhase.question;
    }
  }

  Future<void> _completeQuiz() async {
    final instance = quiz.value;
    if (instance == null) return;

    _stopTimers();
    phase.value = QuizPhase.completing;

    try {
      final r = await _repo.completeQuiz(instance.instanceId);
      result.value = r;
      phase.value  = QuizPhase.results;
    } catch (e) {
      phase.value = QuizPhase.error;
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── User actions ─────────────────────────────────────────────────────────

  void done() {
    _stopTimers();
    // Return true only if the user actually answered at least one question.
    // HomeController uses this to decide whether to unlock the rest of the app.
    Get.back(result: answeredCount.value > 0);
  }

  void retry() {
    _stopTimers();
    quiz.value           = null;
    result.value         = null;
    selectedAnswer.value = null;
    lastAnswer.value     = null;
    errorMessage.value   = null;
    _loadUserAndQuiz();
  }

  // ─── Timers ───────────────────────────────────────────────────────────────

  void _startTotalTimer() {
    _totalTimer?.cancel();
    _totalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (totalSecondsLeft.value <= 0) {
        _completeQuiz();
      } else {
        totalSecondsLeft.value--;
      }
    });
  }

  void _startQuestionTimer() {
    _questionStartTime = DateTime.now();
    questionSecondsSpent.value = 0;
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      questionSecondsSpent.value++;
    });
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  void _stopTimers() {
    _totalTimer?.cancel();
    _totalTimer = null;
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  QuizQuestion? get currentQuestion {
    final q = quiz.value;
    if (q == null || currentIndex.value >= q.questions.length) return null;
    return q.questions[currentIndex.value];
  }

  String get languageName => _languageName;

  String get timerLabel {
    final s = totalSecondsLeft.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  double get progressFraction {
    final q = quiz.value;
    if (q == null || q.questions.isEmpty) return 0;
    return (currentIndex.value + 1) / q.questions.length;
  }

  bool get isLastQuestion {
    final q = quiz.value;
    if (q == null) return false;
    return currentIndex.value >= q.questions.length - 1;
  }
}
