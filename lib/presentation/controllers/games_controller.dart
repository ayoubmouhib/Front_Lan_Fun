import 'dart:async';

import 'package:get/get.dart';

import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/games_api.dart';
import '../../data/models/game_model.dart';
import '../../data/repositories/games_repository.dart';
import 'gamification_controller.dart';

class GamesController extends GetxController {
  static GamesController get to => Get.find();

  // ─── Reactive state ───────────────────────────────────────────────────────
  final phase          = GamePhase.idle.obs;
  final availableGames = Rx<GamesAvailableData?>(null);
  final session        = Rx<GameSessionData?>(null);
  final currentRound   = Rx<GameRoundData?>(null);
  final lastAnswer     = Rx<GameAnswerResponse?>(null);
  final result         = Rx<GameResultData?>(null);
  final errorMessage   = Rx<String?>(null);

  /// Selected translation option for the Word Match game.
  final selectedOption = Rx<String?>(null);

  /// Typed-in word for the Word Scramble game.
  final typedAnswer = ''.obs;

  final roundSecondsSpent = 0.obs;

  // ─── Private ──────────────────────────────────────────────────────────────
  Timer? _roundTimer;
  DateTime? _roundStartTime;

  int? _userId;
  int? _languageId;
  String _languageName = '';

  late final GamesRepository _repo;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _repo = GamesRepository(GamesApi(ApiClient.instance));
    _loadUserAndGames();
  }

  @override
  void onClose() {
    _stopRoundTimer();
    super.onClose();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadUserAndGames() async {
    phase.value = GamePhase.loading;
    errorMessage.value = null;

    final user = await StorageService.instance.getCachedUser();
    final uid  = await StorageService.instance.getUserId();

    if (user == null || uid == null) {
      phase.value = GamePhase.error;
      errorMessage.value = 'Session expired. Please log in again.';
      return;
    }
    _userId = uid;

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['languageId'] != null) {
      _languageId = args['languageId'] as int;
      _languageName = args['languageName'] as String? ?? '';
    } else {
      final candidates = user.learningLanguages.isNotEmpty
          ? user.learningLanguages
          : user.languages;
      if (candidates.isEmpty) {
        phase.value = GamePhase.error;
        errorMessage.value = 'No language found. Please complete your profile.';
        return;
      }
      final lang = candidates.first;
      _languageId = lang.languageId;
      _languageName = lang.language?.name ?? 'Language';
    }

    await loadAvailableGames();
  }

  Future<void> loadAvailableGames() async {
    if (_userId == null || _languageId == null) return;

    phase.value = GamePhase.loading;
    errorMessage.value = null;

    try {
      final data = await _repo.getAvailableGames(_userId!, _languageId!);
      availableGames.value = data;
      phase.value = GamePhase.hub;
    } catch (e) {
      phase.value = GamePhase.error;
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── Start a game ─────────────────────────────────────────────────────────

  Future<void> startGame(String gameType) async {
    if (_userId == null || _languageId == null) return;

    phase.value = GamePhase.starting;
    errorMessage.value = null;

    try {
      final data = await _repo.startGame(
        userId: _userId!,
        languageId: _languageId!,
        gameType: gameType,
      );
      session.value = data;
      currentRound.value = data.currentRound;
      lastAnswer.value = null;
      result.value = null;
      _resetRoundInputs();
      _startRoundTimer();
      phase.value = GamePhase.playing;
    } catch (e) {
      phase.value = GamePhase.hub;
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── Round interaction ────────────────────────────────────────────────────

  void selectOption(String option) {
    if (phase.value != GamePhase.playing) return;
    selectedOption.value = option;
  }

  void updateTypedAnswer(String value) {
    if (phase.value != GamePhase.playing) return;
    typedAnswer.value = value;
  }

  bool get canSubmit {
    final round = currentRound.value;
    if (round == null) return false;
    if (round.options != null) return selectedOption.value != null;
    return typedAnswer.value.trim().isNotEmpty;
  }

  Future<void> submitRound() async {
    final s = session.value;
    final round = currentRound.value;
    if (s == null || round == null || !canSubmit) return;

    final answer = round.options != null ? selectedOption.value! : typedAnswer.value.trim();

    phase.value = GamePhase.submitting;
    _stopRoundTimer();

    final timeSpent = _roundStartTime != null
        ? DateTime.now().difference(_roundStartTime!).inSeconds
        : 0;

    try {
      final response = await _repo.submitRound(
        sessionId: s.sessionId,
        roundIndex: round.roundIndex,
        userAnswer: answer,
        timeSpentSeconds: timeSpent,
      );
      lastAnswer.value = response;
      phase.value = GamePhase.feedback;
    } catch (e) {
      phase.value = GamePhase.playing;
      errorMessage.value = ApiClient.parseError(e);
      _startRoundTimer();
    }
  }

  Future<void> nextRound() async {
    final answer = lastAnswer.value;
    if (answer == null) return;

    if (answer.finished || answer.nextRound == null) {
      await _completeGame();
      return;
    }

    currentRound.value = answer.nextRound;
    lastAnswer.value = null;
    _resetRoundInputs();
    _startRoundTimer();
    phase.value = GamePhase.playing;
  }

  Future<void> _completeGame() async {
    final s = session.value;
    if (s == null) return;

    phase.value = GamePhase.completing;

    try {
      final r = await _repo.completeGame(s.sessionId);
      result.value = r;
      phase.value = GamePhase.results;
      // XP was persisted server-side — refresh the gamification stats so the
      // home dashboard reflects the new XP/level immediately.
      if (r.xpEarned > 0 && Get.isRegistered<GamificationController>()) {
        unawaited(GamificationController.to.refreshStats());
      }
    } catch (e) {
      phase.value = GamePhase.error;
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── User actions ─────────────────────────────────────────────────────────

  void backToHub() {
    _stopRoundTimer();
    session.value = null;
    currentRound.value = null;
    lastAnswer.value = null;
    result.value = null;
    selectedOption.value = null;
    typedAnswer.value = '';
    errorMessage.value = null;
    phase.value = GamePhase.hub;
  }

  void playAgain(String gameType) {
    backToHub();
    startGame(gameType);
  }

  // ─── Timers ───────────────────────────────────────────────────────────────

  void _startRoundTimer() {
    _roundStartTime = DateTime.now();
    roundSecondsSpent.value = 0;
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      roundSecondsSpent.value++;
    });
  }

  void _stopRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = null;
  }

  void _resetRoundInputs() {
    selectedOption.value = null;
    typedAnswer.value = '';
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get languageName => _languageName;

  double get progressFraction {
    final s = session.value;
    final round = currentRound.value;
    if (s == null || s.totalRounds == 0 || round == null) return 0;
    return (round.roundIndex + 1) / s.totalRounds;
  }
}
