import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme.dart';
import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/quiz_api.dart';
import '../../data/datasources/remote/user_api.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/quiz_model.dart';

class GamificationController extends GetxController {
  static GamificationController get to => Get.find();

  // ─── Stats (aggregated across all languages) ─────────────────────────────
  final xpPoints          = 0.obs;
  final streakDays        = 0.obs;
  final longestStreak     = 0.obs;
  final conversationCount = 0.obs;
  final practiceHours     = 0.0.obs;
  final topCefrLevel      = ''.obs;
  final quizCompleted     = 0.obs;

  // ─── Level helpers ────────────────────────────────────────────────────────
  int get level => _levelFromXp(xpPoints.value);
  int get xpForCurrentLevel => _xpThreshold(level);
  int get xpForNextLevel    => _xpThreshold(level + 1);
  int get xpIntoLevel       => xpPoints.value - xpForCurrentLevel;
  int get xpNeededForLevel  => xpForNextLevel - xpForCurrentLevel;
  double get levelProgress  =>
      xpNeededForLevel > 0 ? xpIntoLevel / xpNeededForLevel : 1.0;

  // ─── Achievements ─────────────────────────────────────────────────────────
  final achievements      = <AchievementModel>[].obs;
  final achievementFilter = 'all'.obs; // all | unlocked | locked
  final isLoadingStats    = false.obs;

  List<AchievementModel> get filteredAchievements {
    return switch (achievementFilter.value) {
      'unlocked' => achievements.where((a) => a.unlocked).toList(),
      'locked'   => achievements.where((a) => !a.unlocked).toList(),
      _          => achievements.toList(),
    };
  }

  // ─── Leaderboard ──────────────────────────────────────────────────────────
  final leaderboardPeriod    = 'week'.obs;   // week | month | all
  final leaderboardCategory  = 'xp'.obs;     // xp | streak | conversations
  final leaderboardEntries   = <LeaderboardEntry>[].obs;
  final isLoadingLeaderboard = false.obs;
  final leaderboardError     = Rx<String?>(null);
  final currentUserRank      = Rx<int?>(null);

  // ─── Daily challenge / Quiz ───────────────────────────────────────────────
  final selectedLanguageId   = Rx<int?>(null);
  final selectedLanguageName = ''.obs;
  final quizPhase            = QuizPhase.idle.obs;
  final challengeError       = Rx<String?>(null);
  final availableQuiz        = Rx<QuizAvailableData?>(null);

  // Quiz in-progress state
  final currentQuestionIndex = 0.obs;
  final questionStartTime    = Rx<DateTime?>(null);
  final lastAnswerResponse   = Rx<QuizAnswerResponse?>(null);
  final quizResult           = Rx<QuizResultData?>(null);
  final isSubmittingAnswer   = false.obs;

  int? _activeInstanceId;
  late final QuizApi _quizApi;
  late final UserApi _userApi;

  // ─── Init ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _quizApi = QuizApi(ApiClient.instance);
    _userApi = UserApi(ApiClient.instance);
    _loadStats();
    loadLeaderboard();
    ever(leaderboardPeriod,   (_) => loadLeaderboard());
    ever(leaderboardCategory, (_) => loadLeaderboard());
  }

  // ─── Stats loading ────────────────────────────────────────────────────────

  Future<void> _loadStats() async {
    isLoadingStats.value = true;
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId == null) return;

      final progresses = await _quizApi.getUserLanguageProgress(userId);

      if (progresses.isNotEmpty) {
        int totalXp   = 0;
        int maxStreak = 0;
        int maxLongest = 0;
        int totalConvos = 0;
        double totalHours = 0;
        String topLevel = '';

        for (final p in progresses) {
          totalXp     += p.xpPoints;
          totalConvos += p.conversationCount;
          totalHours  += p.practiceHours;
          if (p.currentStreakDays > maxStreak) maxStreak = p.currentStreakDays;
          if (p.longestStreakDays > maxLongest) maxLongest = p.longestStreakDays;
          if (p.cefrLevel != null && p.cefrLevel!.isNotEmpty) {
            topLevel = p.cefrLevel!;
          }
        }

        xpPoints.value          = totalXp;
        streakDays.value        = maxStreak;
        longestStreak.value     = maxLongest;
        conversationCount.value = totalConvos;
        practiceHours.value     = totalHours;
        topCefrLevel.value      = topLevel;

        // Load quiz history to count completed quizzes
        int quizCount = 0;
        for (final p in progresses) {
          try {
            final history =
                await _quizApi.getHistory(userId, p.languageId);
            quizCount += history.length;
          } catch (_) {}
        }
        quizCompleted.value = quizCount;
      }

      _buildAchievements();
    } catch (_) {
      _buildAchievements(); // Build with zeros — still shows locked state
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> refreshStats() => _loadStats();

  Future<void> loadLeaderboard() async {
    isLoadingLeaderboard.value = true;
    leaderboardError.value = null;
    try {
      final result = await _userApi.getLeaderboard(
        period:   leaderboardPeriod.value,
        category: leaderboardCategory.value,
      );
      leaderboardEntries.assignAll(result.entries);
      currentUserRank.value = result.currentUserRank;
    } catch (e) {
      leaderboardError.value = ApiClient.parseError(e);
    } finally {
      isLoadingLeaderboard.value = false;
    }
  }

  // ─── Achievements builder ─────────────────────────────────────────────────

  void _buildAchievements() {
    final convos  = conversationCount.value;
    final streak  = streakDays.value;
    final xp      = xpPoints.value;
    final quizzes = quizCompleted.value;
    final hasLevel = topCefrLevel.value.isNotEmpty;

    achievements.assignAll([
      // ── Conversations ──────────────────────────────────────────────
      AchievementModel(
        id: 'first_conversation',
        title: 'First Contact',
        description: 'Have your very first conversation',
        icon: Icons.chat_bubble_rounded,
        color: AppColors.secondary,
        progress: convos.clamp(0, 1),
        total: 1,
        unlockedAt: convos >= 1 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Complete 5 conversations',
        icon: Icons.people_rounded,
        color: AppColors.info,
        progress: convos.clamp(0, 5),
        total: 5,
        unlockedAt: convos >= 5 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'conversationalist',
        title: 'Conversationalist',
        description: 'Complete 25 conversations',
        icon: Icons.forum_rounded,
        color: AppColors.primary,
        progress: convos.clamp(0, 25),
        total: 25,
        unlockedAt: convos >= 25 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'chat_legend',
        title: 'Chat Legend',
        description: 'Complete 100 conversations',
        icon: Icons.emoji_events_rounded,
        color: AppColors.amber,
        progress: convos.clamp(0, 100),
        total: 100,
        unlockedAt: convos >= 100 ? DateTime.now() : null,
      ),

      // ── Streak ────────────────────────────────────────────────────
      AchievementModel(
        id: 'streak_starter',
        title: 'On a Roll',
        description: 'Maintain a 3-day practice streak',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF6B35),
        progress: streak.clamp(0, 3),
        total: 3,
        unlockedAt: streak >= 3 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'week_warrior',
        title: 'Week Warrior',
        description: 'Maintain a 7-day practice streak',
        icon: Icons.whatshot_rounded,
        color: AppColors.error,
        progress: streak.clamp(0, 7),
        total: 7,
        unlockedAt: streak >= 7 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'streak_master',
        title: 'Streak Master',
        description: 'Maintain a 30-day practice streak',
        icon: Icons.star_rounded,
        color: AppColors.amber,
        progress: streak.clamp(0, 30),
        total: 30,
        unlockedAt: streak >= 30 ? DateTime.now() : null,
      ),

      // ── XP ────────────────────────────────────────────────────────
      AchievementModel(
        id: 'xp_rookie',
        title: 'XP Rookie',
        description: 'Earn your first 10 XP',
        icon: Icons.bolt_rounded,
        color: AppColors.amber,
        progress: xp.clamp(0, 10),
        total: 10,
        unlockedAt: xp >= 10 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'xp_apprentice',
        title: 'XP Apprentice',
        description: 'Accumulate 500 XP',
        icon: Icons.military_tech_rounded,
        color: AppColors.primary,
        progress: xp.clamp(0, 500),
        total: 500,
        unlockedAt: xp >= 500 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'xp_legend',
        title: 'XP Legend',
        description: 'Accumulate 2000 XP',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.purple,
        progress: xp.clamp(0, 2000),
        total: 2000,
        unlockedAt: xp >= 2000 ? DateTime.now() : null,
      ),

      // ── Quiz ──────────────────────────────────────────────────────
      AchievementModel(
        id: 'daily_challenger',
        title: 'Daily Challenger',
        description: 'Complete your first daily challenge',
        icon: Icons.quiz_rounded,
        color: AppColors.secondary,
        progress: quizzes.clamp(0, 1),
        total: 1,
        unlockedAt: quizzes >= 1 ? DateTime.now() : null,
      ),
      AchievementModel(
        id: 'quiz_champion',
        title: 'Quiz Champion',
        description: 'Complete 5 daily challenges',
        icon: Icons.verified_rounded,
        color: AppColors.success,
        progress: quizzes.clamp(0, 5),
        total: 5,
        unlockedAt: quizzes >= 5 ? DateTime.now() : null,
      ),

      // ── Language level ─────────────────────────────────────────────
      AchievementModel(
        id: 'level_assessed',
        title: 'Level Assessed',
        description: 'Complete your first CEFR level assessment',
        icon: Icons.school_rounded,
        color: AppColors.info,
        progress: hasLevel ? 1 : 0,
        total: 1,
        unlockedAt: hasLevel ? DateTime.now() : null,
      ),
    ]);
  }

  // ─── Quiz / Daily Challenge ────────────────────────────────────────────────

  Future<void> loadChallenge(int languageId, String languageName) async {
    selectedLanguageId.value   = languageId;
    selectedLanguageName.value = languageName;
    quizPhase.value            = QuizPhase.loading;
    challengeError.value       = null;
    availableQuiz.value        = null;
    _resetQuizState();

    try {
      final userId = await StorageService.instance.getUserId();
      if (userId == null) throw Exception('Not logged in');
      final quiz = await _quizApi.getAvailableQuiz(userId, languageId);
      availableQuiz.value = quiz;
      quizPhase.value     = QuizPhase.preview;
    } catch (e) {
      challengeError.value = ApiClient.parseError(e);
      quizPhase.value      = QuizPhase.error;
    }
  }

  Future<void> startChallenge() async {
    final quiz = availableQuiz.value;
    if (quiz == null) return;
    quizPhase.value = QuizPhase.starting;

    try {
      await _quizApi.startQuiz(quiz.instanceId);
      _activeInstanceId      = quiz.instanceId;
      currentQuestionIndex.value = 0;
      questionStartTime.value    = DateTime.now();
      quizPhase.value            = QuizPhase.question;
    } catch (e) {
      challengeError.value = ApiClient.parseError(e);
      quizPhase.value      = QuizPhase.error;
    }
  }

  Future<void> submitAnswer(String answer) async {
    final quiz = availableQuiz.value;
    if (quiz == null || _activeInstanceId == null) return;
    if (currentQuestionIndex.value >= quiz.questions.length) return;

    isSubmittingAnswer.value = true;
    quizPhase.value          = QuizPhase.submitting;

    final q = quiz.questions[currentQuestionIndex.value];
    final elapsed = questionStartTime.value != null
        ? DateTime.now()
            .difference(questionStartTime.value!)
            .inSeconds
        : 0;

    try {
      final response = await _quizApi.submitAnswer(
        instanceId:      _activeInstanceId!,
        questionId:      q.id,
        userAnswer:      answer,
        timeSpentSeconds: elapsed,
      );
      lastAnswerResponse.value = response;
      quizPhase.value          = QuizPhase.feedback;
    } catch (e) {
      challengeError.value = ApiClient.parseError(e);
      quizPhase.value      = QuizPhase.error;
    } finally {
      isSubmittingAnswer.value = false;
    }
  }

  void nextQuestion() {
    final quiz = availableQuiz.value;
    if (quiz == null) return;

    final next = currentQuestionIndex.value + 1;
    if (next >= quiz.questions.length) {
      _completeChallenge();
    } else {
      currentQuestionIndex.value = next;
      questionStartTime.value    = DateTime.now();
      lastAnswerResponse.value   = null;
      quizPhase.value            = QuizPhase.question;
    }
  }

  Future<void> _completeChallenge() async {
    if (_activeInstanceId == null) return;
    quizPhase.value = QuizPhase.completing;

    try {
      final result = await _quizApi.completeQuiz(_activeInstanceId!);
      quizResult.value = result;
      quizPhase.value  = QuizPhase.results;

      // Update local XP and quiz count
      xpPoints.value    = (xpPoints.value + result.xpEarned).clamp(0, 999999);
      quizCompleted.value += 1;
      _buildAchievements();
    } catch (e) {
      challengeError.value = ApiClient.parseError(e);
      quizPhase.value      = QuizPhase.error;
    }
  }

  void resetChallenge() {
    _resetQuizState();
    quizPhase.value      = QuizPhase.idle;
    availableQuiz.value  = null;
    challengeError.value = null;
  }

  void _resetQuizState() {
    _activeInstanceId          = null;
    currentQuestionIndex.value = 0;
    questionStartTime.value    = null;
    lastAnswerResponse.value   = null;
    quizResult.value           = null;
    isSubmittingAnswer.value   = false;
  }

  // ─── Level helpers ────────────────────────────────────────────────────────

  static int _levelFromXp(int xp) {
    const thresholds = [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500];
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (xp >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  static int _xpThreshold(int level) {
    const thresholds = [0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 999999];
    final idx = (level - 1).clamp(0, thresholds.length - 1);
    return thresholds[idx];
  }

  // ─── Leaderboard helpers ──────────────────────────────────────────────────

  String get leaderboardCategoryLabel => switch (leaderboardCategory.value) {
        'streak'        => 'Streak',
        'conversations' => 'Conversations',
        _               => 'XP',
      };

  int get userCategoryValue => switch (leaderboardCategory.value) {
        'streak'        => streakDays.value,
        'conversations' => conversationCount.value,
        _               => xpPoints.value,
      };
}
