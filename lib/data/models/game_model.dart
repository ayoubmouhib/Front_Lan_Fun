// TypeORM serializes `decimal` columns as strings (e.g. "100.00"), not numbers.
double _parseDecimal(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

// ─── Game type constants (mirror backend GameType enum) ──────────────────────

abstract class GameType {
  static const String wordMatch = 'word_match';
  static const String wordScramble = 'word_scramble';
}

// ─── Available games response ─────────────────────────────────────────────────

class GamesAvailableData {
  const GamesAvailableData({
    required this.languageId,
    required this.wordPoolSize,
    required this.games,
  });

  final int languageId;
  final int wordPoolSize;
  final List<GameInfo> games;

  factory GamesAvailableData.fromJson(Map<String, dynamic> j) => GamesAvailableData(
        languageId:   j['language_id'] as int? ?? 0,
        wordPoolSize: j['word_pool_size'] as int? ?? 0,
        games: (j['games'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(GameInfo.fromJson)
            .toList(),
      );
}

class GameInfo {
  const GameInfo({
    required this.gameType,
    required this.title,
    required this.description,
    required this.xpPerCorrect,
    required this.xpPerfectBonus,
    required this.playable,
  });

  final String gameType;
  final String title;
  final String description;
  final int xpPerCorrect;
  final int xpPerfectBonus;
  final bool playable;

  bool get isWordMatch => gameType == GameType.wordMatch;
  bool get isWordScramble => gameType == GameType.wordScramble;

  factory GameInfo.fromJson(Map<String, dynamic> j) => GameInfo(
        gameType:       j['game_type'] as String? ?? '',
        title:          j['title'] as String? ?? 'Game',
        description:    j['description'] as String? ?? '',
        xpPerCorrect:   j['xp_per_correct'] as int? ?? 0,
        xpPerfectBonus: j['xp_perfect_bonus'] as int? ?? 0,
        playable:       j['playable'] as bool? ?? false,
      );
}

// ─── Round (the prompt sent to the player — never includes the answer) ───────

class GameRoundData {
  const GameRoundData({
    required this.roundIndex,
    required this.wordId,
    required this.prompt,
    this.options,
    this.scrambled,
    this.hint,
  });

  final int roundIndex;
  final int wordId;
  final String prompt;
  final List<String>? options;
  final String? scrambled;
  final String? hint;

  factory GameRoundData.fromJson(Map<String, dynamic> j) => GameRoundData(
        roundIndex: j['round_index'] as int? ?? 0,
        wordId:     j['word_id'] as int? ?? 0,
        prompt:     j['prompt'] as String? ?? '',
        options:    (j['options'] as List<dynamic>?)?.map((o) => o.toString()).toList(),
        scrambled:  j['scrambled'] as String?,
        hint:       j['hint'] as String?,
      );
}

// ─── Session start response ───────────────────────────────────────────────────

class GameSessionData {
  const GameSessionData({
    required this.sessionId,
    required this.gameType,
    required this.status,
    required this.title,
    required this.totalRounds,
    required this.currentRoundIndex,
    this.currentRound,
  });

  final int sessionId;
  final String gameType;
  final String status;
  final String title;
  final int totalRounds;
  final int currentRoundIndex;
  final GameRoundData? currentRound;

  factory GameSessionData.fromJson(Map<String, dynamic> j) => GameSessionData(
        sessionId:         j['session_id'] as int,
        gameType:          j['game_type'] as String? ?? '',
        status:            j['status'] as String? ?? 'in_progress',
        title:             j['title'] as String? ?? 'Game',
        totalRounds:       j['total_rounds'] as int? ?? 0,
        currentRoundIndex: j['current_round_index'] as int? ?? 0,
        currentRound: j['current_round'] is Map<String, dynamic>
            ? GameRoundData.fromJson(j['current_round'] as Map<String, dynamic>)
            : null,
      );
}

// ─── Answer feedback ──────────────────────────────────────────────────────────

class GameProgressData {
  const GameProgressData({
    required this.currentRoundIndex,
    required this.totalRounds,
    required this.correctCount,
    required this.incorrectCount,
  });

  final int currentRoundIndex;
  final int totalRounds;
  final int correctCount;
  final int incorrectCount;

  factory GameProgressData.fromJson(Map<String, dynamic> j) => GameProgressData(
        currentRoundIndex: j['current_round_index'] as int? ?? 0,
        totalRounds:       j['total_rounds'] as int? ?? 0,
        correctCount:      j['correct_count'] as int? ?? 0,
        incorrectCount:    j['incorrect_count'] as int? ?? 0,
      );
}

class GameAnswerResponse {
  const GameAnswerResponse({
    required this.isCorrect,
    required this.correctAnswer,
    required this.finished,
    required this.progress,
    this.nextRound,
  });

  final bool isCorrect;
  final String correctAnswer;
  final bool finished;
  final GameProgressData progress;
  final GameRoundData? nextRound;

  factory GameAnswerResponse.fromJson(Map<String, dynamic> j) => GameAnswerResponse(
        isCorrect:     j['is_correct'] as bool? ?? false,
        correctAnswer: j['correct_answer'] as String? ?? '',
        finished:      j['finished'] as bool? ?? false,
        progress:      GameProgressData.fromJson((j['progress'] as Map<String, dynamic>?) ?? const {}),
        nextRound: j['next_round'] is Map<String, dynamic>
            ? GameRoundData.fromJson(j['next_round'] as Map<String, dynamic>)
            : null,
      );
}

// ─── Result ───────────────────────────────────────────────────────────────────

class GameRoundResult {
  const GameRoundResult({
    required this.roundIndex,
    required this.term,
    required this.prompt,
    required this.correctAnswer,
    this.userAnswer,
    this.isCorrect,
    this.timeSpentSeconds,
  });

  final int roundIndex;
  final String term;
  final String prompt;
  final String correctAnswer;
  final String? userAnswer;
  final bool? isCorrect;
  final int? timeSpentSeconds;

  factory GameRoundResult.fromJson(Map<String, dynamic> j) => GameRoundResult(
        roundIndex:       j['round_index'] as int? ?? 0,
        term:             j['term'] as String? ?? '',
        prompt:           j['prompt'] as String? ?? '',
        correctAnswer:    j['correct_answer'] as String? ?? '',
        userAnswer:       j['user_answer'] as String?,
        isCorrect:        j['is_correct'] as bool?,
        timeSpentSeconds: j['time_spent_seconds'] as int?,
      );
}

class GameResultData {
  const GameResultData({
    required this.sessionId,
    required this.gameType,
    required this.title,
    required this.totalRounds,
    required this.correctCount,
    required this.incorrectCount,
    required this.scorePercentage,
    required this.xpEarned,
    required this.rounds,
    this.timeTakenSeconds,
  });

  final int sessionId;
  final String gameType;
  final String title;
  final int totalRounds;
  final int correctCount;
  final int incorrectCount;
  final double scorePercentage;
  final int xpEarned;
  final int? timeTakenSeconds;
  final List<GameRoundResult> rounds;

  bool get isPerfect => totalRounds > 0 && correctCount == totalRounds;

  factory GameResultData.fromJson(Map<String, dynamic> j) => GameResultData(
        sessionId:        j['session_id'] as int,
        gameType:         j['game_type'] as String? ?? '',
        title:            j['title'] as String? ?? 'Game',
        totalRounds:      j['total_rounds'] as int? ?? 0,
        correctCount:     j['correct_count'] as int? ?? 0,
        incorrectCount:   j['incorrect_count'] as int? ?? 0,
        scorePercentage:  _parseDecimal(j['score_percentage']),
        xpEarned:         j['xp_earned'] as int? ?? 0,
        timeTakenSeconds: j['time_taken_seconds'] as int?,
        rounds: (j['rounds'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(GameRoundResult.fromJson)
            .toList(),
      );
}

// ─── History ──────────────────────────────────────────────────────────────────

class GameHistoryEntry {
  const GameHistoryEntry({
    required this.sessionId,
    required this.gameType,
    required this.title,
    required this.totalRounds,
    required this.correctCount,
    required this.scorePercentage,
    required this.xpEarned,
    required this.completedAt,
    this.timeTakenSeconds,
  });

  final int sessionId;
  final String gameType;
  final String title;
  final int totalRounds;
  final int correctCount;
  final double scorePercentage;
  final int xpEarned;
  final int? timeTakenSeconds;
  final DateTime completedAt;

  factory GameHistoryEntry.fromJson(Map<String, dynamic> j) => GameHistoryEntry(
        sessionId:        j['session_id'] as int,
        gameType:         j['game_type'] as String? ?? '',
        title:            j['title'] as String? ?? 'Game',
        totalRounds:      j['total_rounds'] as int? ?? 0,
        correctCount:     j['correct_count'] as int? ?? 0,
        scorePercentage:  _parseDecimal(j['score_percentage']),
        xpEarned:         j['xp_earned'] as int? ?? 0,
        timeTakenSeconds: j['time_taken_seconds'] as int?,
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ─── Phase enum ───────────────────────────────────────────────────────────────

enum GamePhase {
  idle,
  loading,
  hub,
  starting,
  playing,
  submitting,
  feedback,
  completing,
  results,
  error,
}
