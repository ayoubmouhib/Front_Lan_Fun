// TypeORM serializes `decimal` columns as strings (e.g. "66.67"), not numbers.
double _parseDecimal(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

// ─── Quiz available response ──────────────────────────────────────────────────

class QuizAvailableData {
  const QuizAvailableData({
    required this.instanceId,
    required this.title,
    required this.totalQuestions,
    required this.timeLimitMinutes,
    required this.xpReward,
    required this.questions,
    this.description,
  });

  final int instanceId;
  final String title;
  final String? description;
  final int totalQuestions;
  final int timeLimitMinutes;
  final int xpReward;
  final List<QuizQuestion> questions;

  factory QuizAvailableData.fromJson(Map<String, dynamic> j) =>
      QuizAvailableData(
        instanceId:      j['quiz_instance_id'] as int,
        title:           j['title'] as String? ?? 'Daily Challenge',
        description:     j['description'] as String?,
        totalQuestions:  j['total_questions'] as int? ?? 20,
        timeLimitMinutes: j['time_limit_minutes'] as int? ?? 20,
        xpReward:        j['xp_reward'] as int? ?? 50,
        questions: (j['questions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(QuizQuestion.fromJson)
            .toList(),
      );
}

// ─── Question ────────────────────────────────────────────────────────────────

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.order,
    required this.questionText,
    required this.questionType,
    required this.skillCategory,
    required this.cefrLevel,
    this.options,
    this.sourceSentence,
    this.sourceLanguage,
    this.targetLanguage,
    this.hint,
  });

  final int id;
  final int order;
  final String questionText;
  // Types: multiple_choice | true_false | fill_blank
  //        translation_to_target | translation_to_native
  final String questionType;
  final List<String>? options;
  final String skillCategory;
  final String cefrLevel;
  final String? sourceSentence;  // sentence to translate (translation types)
  final String? sourceLanguage;  // e.g. "English"
  final String? targetLanguage;  // e.g. "Spanish"
  final String? hint;            // optional clue shown to user

  bool get isMultipleChoice      => questionType == 'multiple_choice';
  bool get isTrueFalse           => questionType == 'true_false';
  bool get isFillBlank           => questionType == 'fill_blank';
  bool get isTranslationToTarget => questionType == 'translation_to_target';
  bool get isTranslationToNative => questionType == 'translation_to_native';
  bool get isTranslation         => isTranslationToTarget || isTranslationToNative;

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id:             j['question_id'] as int? ?? (j['id'] as int? ?? 0),
        order:          j['order'] as int? ?? 0,
        questionText:   j['question_text'] as String? ?? '',
        questionType:   j['question_type'] as String? ?? 'multiple_choice',
        options:        (j['options'] as List<dynamic>?)?.map((o) => o.toString()).toList(),
        skillCategory:  j['skill_category'] as String? ?? 'grammar',
        cefrLevel:      j['target_cefr_level'] as String? ?? 'A1',
        sourceSentence: j['source_sentence'] as String?,
        sourceLanguage: j['source_language'] as String?,
        targetLanguage: j['target_language'] as String?,
        hint:           j['hint'] as String?,
      );
}

// ─── Answer response ──────────────────────────────────────────────────────────

class QuizAnswerResponse {
  const QuizAnswerResponse({
    required this.isCorrect,
    required this.correctAnswer,
    this.explanation,
  });

  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;

  factory QuizAnswerResponse.fromJson(Map<String, dynamic> j) =>
      QuizAnswerResponse(
        isCorrect:     j['is_correct'] as bool? ?? false,
        correctAnswer: j['correct_answer'] as String? ?? '',
        explanation:   j['explanation'] as String?,
      );
}

// ─── Quiz result ──────────────────────────────────────────────────────────────

class QuizResultData {
  const QuizResultData({
    required this.scorePercentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.xpEarned,
    required this.leveledUp,
    this.previousLevel,
    this.newLevel,
    this.performanceBySkill = const {},
  });

  final double scorePercentage;
  final int correctAnswers;
  final int totalQuestions;
  final int xpEarned;
  final bool leveledUp;
  final String? previousLevel;
  final String? newLevel;
  final Map<String, dynamic> performanceBySkill;

  int get incorrectAnswers => totalQuestions - correctAnswers;

  factory QuizResultData.fromJson(Map<String, dynamic> j) => QuizResultData(
        scorePercentage: _parseDecimal(j['score_percentage']),
        correctAnswers:  j['correct_answers'] as int? ?? 0,
        totalQuestions:  j['total_questions'] as int? ?? 0,
        xpEarned:        j['xp_earned'] as int? ?? 0,
        leveledUp:       j['leveled_up'] as bool? ?? false,
        previousLevel:   j['previous_level'] as String?,
        newLevel:        j['new_level'] as String?,
        performanceBySkill:
            (j['performance_by_skill'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}

// ─── User language progress (from GET /user/:id → languageProgress) ──────────

class UserLanguageProgressData {
  const UserLanguageProgressData({
    required this.languageId,
    required this.xpPoints,
    required this.conversationCount,
    required this.practiceHours,
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.cefrLevel,
    this.levelVerified = false,
  });

  final int languageId;
  final int xpPoints;
  final int conversationCount;
  final double practiceHours;
  final int currentStreakDays;
  final int longestStreakDays;
  final String? cefrLevel;
  final bool levelVerified;

  factory UserLanguageProgressData.fromJson(Map<String, dynamic> j) =>
      UserLanguageProgressData(
        languageId:       j['language_id'] as int? ?? 0,
        xpPoints:         (j['xp_points'] as num?)?.toInt() ?? 0,
        conversationCount: (j['conversation_count'] as num?)?.toInt() ?? 0,
        practiceHours:    _parseDecimal(j['practice_hours']),
        currentStreakDays: (j['current_streak_days'] as num?)?.toInt() ?? 0,
        longestStreakDays:  (j['longest_streak_days'] as num?)?.toInt() ?? 0,
        cefrLevel:        j['cefr_level'] as String?,
        levelVerified:    j['level_verified'] as bool? ?? false,
      );
}

// ─── Leaderboard entry ────────────────────────────────────────────────────────

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.initials,
    required this.totalXp,
    required this.maxStreak,
    required this.totalConversations,
    this.isCurrentUser = false,
  });

  final int rank;
  final int userId;
  final String name;
  final String initials;
  final int totalXp;
  final int maxStreak;
  final int totalConversations;
  final bool isCurrentUser;

  int valueFor(String category) => switch (category) {
        'streak'        => maxStreak,
        'conversations' => totalConversations,
        _               => totalXp,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank:               (j['rank'] as num).toInt(),
        userId:             (j['userId'] as num).toInt(),
        name:               j['name'] as String,
        initials:           j['initials'] as String,
        totalXp:            (j['totalXp'] as num?)?.toInt() ?? 0,
        maxStreak:          (j['maxStreak'] as num?)?.toInt() ?? 0,
        totalConversations: (j['totalConversations'] as num?)?.toInt() ?? 0,
        isCurrentUser:      j['isCurrentUser'] as bool? ?? false,
      );
}

// ─── Quiz phase enum ─────────────────────────────────────────────────────────

enum QuizPhase {
  idle,
  loading,
  preview,
  starting,
  question,
  submitting,
  feedback,
  completing,
  results,
  error,
}
