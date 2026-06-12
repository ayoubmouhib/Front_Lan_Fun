import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/quiz_model.dart';
import '../../controllers/gamification_controller.dart';
import '../../controllers/profile_controller.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late final GamificationController _ctrl;

  // Quiz timer (counts up)
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = GamificationController.to;

    // Pre-select first language if user has one
    ever(_ctrl.quizPhase, _onPhaseChange);

    if (_ctrl.selectedLanguageId.value == null) {
      _tryPreSelectLanguage();
    }
  }

  void _tryPreSelectLanguage() {
    try {
      final u = ProfileController.to.user.value;
      if (u != null && u.languages.isNotEmpty) {
        final lang = u.languages.first;
        _ctrl.selectedLanguageId.value   = lang.languageId;
        _ctrl.selectedLanguageName.value = lang.language?.name ?? '';
      }
    } catch (_) {}
  }

  void _onPhaseChange(QuizPhase phase) {
    if (phase == QuizPhase.question) {
      _startTimer();
    } else if (phase == QuizPhase.results || phase == QuizPhase.error) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final phase = _ctrl.quizPhase.value;

        return switch (phase) {
          QuizPhase.idle     => _buildIdle(context),
          QuizPhase.loading  => _buildLoading(context, 'Loading challenge...'),
          QuizPhase.preview  => _buildPreview(context),
          QuizPhase.starting => _buildLoading(context, 'Starting quiz...'),
          QuizPhase.question || QuizPhase.submitting || QuizPhase.feedback
                             => _buildQuiz(context, phase),
          QuizPhase.completing => _buildLoading(context, 'Calculating results...'),
          QuizPhase.results  => _buildResults(context),
          QuizPhase.error    => _buildError(context),
        };
      }),
    );
  }

  // ─── Idle — language selector ─────────────────────────────────────────────

  Widget _buildIdle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<_LangOption> languages = [];
    try {
      final u = ProfileController.to.user.value;
      if (u != null) {
        languages = u.languages
            .map((l) => _LangOption(
                  id:   l.languageId,
                  name: l.language?.name ?? 'Language ${l.languageId}',
                  iso:  l.language?.isoCode ?? '',
                  level: l.level,
                ))
            .toList();
      }
    } catch (_) {}

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, showBack: false),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                _InfoCard(isDark: isDark),
                const SizedBox(height: 28),

                Text(
                  'Choose a Language',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the language you want to practice today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 16),

                if (languages.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.language_rounded,
                            size: 56,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No languages in your profile.\nAdd learning languages to take challenges.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  ...languages.map((lang) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LanguageTile(
                          lang: lang,
                          isDark: isDark,
                          onTap: () => _ctrl.loadChallenge(
                              lang.id, lang.name),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Loading ──────────────────────────────────────────────────────────────

  Widget _buildLoading(BuildContext context, String message) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Preview — challenge card ──────────────────────────────────────────────

  Widget _buildPreview(BuildContext context) {
    final quiz  = _ctrl.availableQuiz.value!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, showBack: true,
            onBack: _ctrl.resetChallenge),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge header card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.quiz_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quiz.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Obx(() => Text(
                                  _ctrl.selectedLanguageName.value,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (quiz.description != null &&
                          quiz.description!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          quiz.description!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _QuizStatBadge(
                            icon: Icons.help_outline_rounded,
                            label: '${quiz.totalQuestions} questions',
                          ),
                          const SizedBox(width: 10),
                          _QuizStatBadge(
                            icon: Icons.timer_outlined,
                            label: '${quiz.timeLimitMinutes} min',
                          ),
                          const SizedBox(width: 10),
                          _QuizStatBadge(
                            icon: Icons.bolt_rounded,
                            label: '+${quiz.xpReward} XP',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Skills breakdown
                if (quiz.questions.isNotEmpty) ...[
                  Text(
                    'Skills Covered',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _SkillsBreakdown(questions: quiz.questions, isDark: isDark),
                  const SizedBox(height: 28),
                ],

                // CEFR levels
                Text(
                  'CEFR Levels',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _CefrBreakdown(questions: quiz.questions),
                const SizedBox(height: 32),

                // Start button
                _GradientButton(
                  label: 'Start Challenge',
                  icon: Icons.play_arrow_rounded,
                  onTap: _ctrl.startChallenge,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Quiz — question view ─────────────────────────────────────────────────

  Widget _buildQuiz(BuildContext context, QuizPhase phase) {
    final quiz = _ctrl.availableQuiz.value;
    if (quiz == null) return const SizedBox.shrink();

    final qIdx    = _ctrl.currentQuestionIndex.value;
    final total   = quiz.questions.length;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    if (qIdx >= total) return _buildLoading(context, 'Finishing...');

    final q        = quiz.questions[qIdx];
    final feedback = _ctrl.lastAnswerResponse.value;
    final isFeedback = phase == QuizPhase.feedback;

    return SafeArea(
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showAbortDialog(context),
                  child: const Icon(Icons.close_rounded, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${qIdx + 1} / $total',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (qIdx + 1) / total,
                          minHeight: 6,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _TimerBadge(elapsed: _elapsedSeconds),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1,
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline),

          // ── Question content ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill + CEFR badge row
                  Row(
                    children: [
                      _SkillBadge(skill: q.skillCategory),
                      const SizedBox(width: 8),
                      _CefrBadge(level: q.cefrLevel),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Question text
                  Text(
                    q.questionText,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Answer area
                  if (q.isMultipleChoice)
                    _MultipleChoiceOptions(
                      options: q.options ?? [],
                      feedback: feedback,
                      isFeedback: isFeedback,
                      isSubmitting: phase == QuizPhase.submitting,
                      onAnswer: _ctrl.submitAnswer,
                    )
                  else if (q.isTrueFalse)
                    _TrueFalseOptions(
                      feedback: feedback,
                      isFeedback: isFeedback,
                      isSubmitting: phase == QuizPhase.submitting,
                      onAnswer: _ctrl.submitAnswer,
                    )
                  else
                    _FillBlankInput(
                      isFeedback: isFeedback,
                      isSubmitting: phase == QuizPhase.submitting,
                      feedback: feedback,
                      onAnswer: _ctrl.submitAnswer,
                    ),

                  // Feedback section
                  if (isFeedback && feedback != null) ...[
                    const SizedBox(height: 24),
                    _FeedbackPanel(feedback: feedback),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom bar ──────────────────────────────────────────
          if (isFeedback)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _GradientButton(
                label: qIdx + 1 >= total ? 'See Results' : 'Next Question',
                icon: qIdx + 1 >= total
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                onTap: _ctrl.nextQuestion,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Results ──────────────────────────────────────────────────────────────

  Widget _buildResults(BuildContext context) {
    final result = _ctrl.quizResult.value;
    if (result == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score  = result.scorePercentage;
    final passed = score >= 60;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Big score circle
                  _ScoreCircle(score: score, passed: passed),
                  const SizedBox(height: 20),

                  Text(
                    passed ? 'Great Job! 🎉' : 'Keep Practicing! 💪',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    passed
                        ? 'You passed this challenge!'
                        : 'You can try again tomorrow.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 28),

                  // Stats grid
                  _ResultsGrid(result: result, isDark: isDark),
                  const SizedBox(height: 20),

                  // Level up banner
                  if (result.leveledUp)
                    _LevelUpBanner(
                        previous: result.previousLevel ?? '',
                        next: result.newLevel ?? ''),

                  const SizedBox(height: 20),

                  // XP earned
                  _XpEarnedCard(xp: result.xpEarned),
                  const SizedBox(height: 28),

                  // Performance by skill
                  if (result.performanceBySkill.isNotEmpty) ...[
                    _SkillPerformance(
                        performance: result.performanceBySkill,
                        isDark: isDark),
                    const SizedBox(height: 28),
                  ],

                  // Done button
                  _GradientButton(
                    label: 'Back to Challenges',
                    icon: Icons.home_rounded,
                    onTap: () {
                      _ctrl.resetChallenge();
                      _ctrl.refreshStats();
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error.withValues(alpha: 0.5)),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Obx(() => Text(
                    _ctrl.challengeError.value ??
                        'No challenge available for this language.\nTry again later.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                    textAlign: TextAlign.center,
                  )),
              const SizedBox(height: 28),
              _GradientButton(
                label: 'Go Back',
                icon: Icons.arrow_back_rounded,
                onTap: _ctrl.resetChallenge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared sliver app bar ────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar(BuildContext context,
      {required bool showBack, VoidCallback? onBack}) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: const Text('Daily Challenge'),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? Get.back,
            )
          : null,
    );
  }

  void _showAbortDialog(BuildContext ctx) {
    Get.dialog(AlertDialog(
      title: const Text('Quit Quiz?'),
      content: const Text(
          'Your progress will be lost. Are you sure you want to quit?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Continue')),
        TextButton(
          onPressed: () {
            Get.back();
            _ctrl.resetChallenge();
          },
          child: const Text('Quit',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

// ─── Language option & tile ───────────────────────────────────────────────────

class _LangOption {
  const _LangOption(
      {required this.id,
      required this.name,
      required this.iso,
      required this.level});
  final int id;
  final String name;
  final String iso;
  final String level;
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile(
      {required this.lang, required this.isDark, required this.onTap});
  final _LangOption lang;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final flag = _isoToFlag(lang.iso);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? AppColors.darkOutline
                  : AppColors.lightOutline),
        ),
        child: Row(
          children: [
            Text(flag.isNotEmpty ? flag : '🌐',
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    lang.level,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_rounded,
                color: AppColors.primary, size: 32),
          ],
        ),
      ),
    );
  }

  String _isoToFlag(String iso) {
    if (iso.length != 2) return '';
    final base = 0x1F1E6 - 0x41;
    return String.fromCharCodes(
        iso.toUpperCase().codeUnits.map((c) => base + c));
  }
}

// ─── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: AppColors.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Language Challenge',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete a quiz to earn XP and improve your CEFR level. '
                  'New challenges are available every week.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiz stat badge ──────────────────────────────────────────────────────────

class _QuizStatBadge extends StatelessWidget {
  const _QuizStatBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Skills breakdown ─────────────────────────────────────────────────────────

class _SkillsBreakdown extends StatelessWidget {
  const _SkillsBreakdown(
      {required this.questions, required this.isDark});
  final List<QuizQuestion> questions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.skillCategory] = (counts[q.skillCategory] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: counts.entries.map((e) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _skillColor(e.key).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _skillColor(e.key).withValues(alpha: 0.35)),
          ),
          child: Text(
            '${_skillLabel(e.key)}  ${e.value}',
            style: TextStyle(
              color: _skillColor(e.key),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _skillColor(String skill) => switch (skill) {
        'grammar'    => AppColors.primary,
        'vocabulary' => AppColors.secondary,
        'reading'    => AppColors.info,
        'listening'  => AppColors.purple,
        'writing'    => AppColors.amber,
        _            => AppColors.lightOutlineVariant,
      };

  String _skillLabel(String skill) => switch (skill) {
        'grammar'    => '📖 Grammar',
        'vocabulary' => '📝 Vocabulary',
        'reading'    => '📚 Reading',
        'listening'  => '🎧 Listening',
        'writing'    => '✍️ Writing',
        _            => skill,
      };
}

// ─── CEFR breakdown ───────────────────────────────────────────────────────────

class _CefrBreakdown extends StatelessWidget {
  const _CefrBreakdown({required this.questions});
  final List<QuizQuestion> questions;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.cefrLevel] = (counts[q.cefrLevel] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sorted.map((e) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('${e.key}  ×${e.value}',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        );
      }).toList(),
    );
  }
}

// ─── Timer badge ──────────────────────────────────────────────────────────────

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.elapsed});
  final int elapsed;

  @override
  Widget build(BuildContext context) {
    final m = elapsed ~/ 60;
    final s = (elapsed % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$m:$s',
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    );
  }
}

// ─── Skill/CEFR badges for question ──────────────────────────────────────────

class _SkillBadge extends StatelessWidget {
  const _SkillBadge({required this.skill});
  final String skill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        skill.capitalize ?? skill,
        style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CefrBadge extends StatelessWidget {
  const _CefrBadge({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(level,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Multiple choice options ──────────────────────────────────────────────────

class _MultipleChoiceOptions extends StatefulWidget {
  const _MultipleChoiceOptions({
    required this.options,
    required this.feedback,
    required this.isFeedback,
    required this.isSubmitting,
    required this.onAnswer,
  });
  final List<String> options;
  final QuizAnswerResponse? feedback;
  final bool isFeedback;
  final bool isSubmitting;
  final Future<void> Function(String) onAnswer;

  @override
  State<_MultipleChoiceOptions> createState() =>
      _MultipleChoiceOptionsState();
}

class _MultipleChoiceOptionsState
    extends State<_MultipleChoiceOptions> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.map((opt) {
        Color? optColor;
        if (widget.isFeedback && widget.feedback != null) {
          final correct = widget.feedback!.correctAnswer;
          if (opt == correct) {
            optColor = AppColors.success;
          } else if (opt == _selected && opt != correct) {
            optColor = AppColors.error;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: widget.isFeedback || widget.isSubmitting
                ? null
                : () {
                    setState(() => _selected = opt);
                    widget.onAnswer(opt);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: optColor != null
                    ? optColor.withValues(alpha: 0.1)
                    : (_selected == opt
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Theme.of(context).colorScheme.surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: optColor ??
                      (_selected == opt
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.outline),
                  width: _selected == opt ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (widget.isFeedback && widget.feedback != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        opt == widget.feedback!.correctAnswer
                            ? Icons.check_circle_rounded
                            : (opt == _selected
                                ? Icons.cancel_rounded
                                : Icons.radio_button_unchecked_rounded),
                        color: optColor ??
                            Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                        size: 20,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        _selected == opt
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _selected == opt
                            ? AppColors.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ),
                  Expanded(
                      child: Text(opt,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── True / False options ─────────────────────────────────────────────────────

class _TrueFalseOptions extends StatefulWidget {
  const _TrueFalseOptions({
    required this.feedback,
    required this.isFeedback,
    required this.isSubmitting,
    required this.onAnswer,
  });
  final QuizAnswerResponse? feedback;
  final bool isFeedback;
  final bool isSubmitting;
  final Future<void> Function(String) onAnswer;

  @override
  State<_TrueFalseOptions> createState() => _TrueFalseOptionsState();
}

class _TrueFalseOptionsState extends State<_TrueFalseOptions> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['True', 'False'].map((option) {
        final isCorrect = widget.feedback?.correctAnswer.toLowerCase() ==
            option.toLowerCase();

        Color buttonColor = AppColors.primary;
        if (widget.isFeedback) {
          buttonColor = isCorrect ? AppColors.success : AppColors.error;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: option == 'True' ? 8 : 0),
            child: GestureDetector(
              onTap: widget.isFeedback || widget.isSubmitting
                  ? null
                  : () {
                      setState(() => _selected = option);
                      widget.onAnswer(option.toLowerCase());
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 60,
                decoration: BoxDecoration(
                  color: _selected == option
                      ? (widget.isFeedback
                          ? buttonColor.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.1))
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selected == option
                        ? (widget.isFeedback ? buttonColor : AppColors.primary)
                        : Theme.of(context).colorScheme.outline,
                    width: _selected == option ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: _selected == option
                          ? (widget.isFeedback
                              ? buttonColor
                              : AppColors.primary)
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Fill blank input ─────────────────────────────────────────────────────────

class _FillBlankInput extends StatefulWidget {
  const _FillBlankInput({
    required this.isFeedback,
    required this.isSubmitting,
    required this.feedback,
    required this.onAnswer,
  });
  final bool isFeedback;
  final bool isSubmitting;
  final QuizAnswerResponse? feedback;
  final Future<void> Function(String) onAnswer;

  @override
  State<_FillBlankInput> createState() => _FillBlankInputState();
}

class _FillBlankInputState extends State<_FillBlankInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          enabled: !widget.isFeedback && !widget.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) widget.onAnswer(v.trim());
          },
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            suffixIcon: widget.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        if (!widget.isFeedback)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isSubmitting
                  ? null
                  : () {
                      final v = _ctrl.text.trim();
                      if (v.isNotEmpty) widget.onAnswer(v);
                    },
              child: const Text('Submit'),
            ),
          ),
      ],
    );
  }
}

// ─── Answer feedback panel ────────────────────────────────────────────────────

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.feedback});
  final QuizAnswerResponse feedback;

  @override
  Widget build(BuildContext context) {
    final color = feedback.isCorrect ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                feedback.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                feedback.isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ],
          ),
          if (!feedback.isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Correct answer: ${feedback.correctAnswer}',
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ],
          if (feedback.explanation != null &&
              feedback.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              feedback.explanation!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Result widgets ───────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({required this.score, required this.passed});
  final double score;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            strokeWidth: 10,
            backgroundColor:
                (passed ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
                passed ? AppColors.success : AppColors.error),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${score.round()}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: passed ? AppColors.success : AppColors.error,
              ),
            ),
            Text(
              passed ? 'Passed' : 'Failed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        (passed ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.result, required this.isDark});
  final QuizResultData result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Correct', '${result.correctAnswers}', AppColors.success, Icons.check_circle_rounded),
      ('Incorrect', '${result.incorrectAnswers}', AppColors.error, Icons.cancel_rounded),
      ('Total', '${result.totalQuestions}', AppColors.primary, Icons.quiz_rounded),
      ('XP Earned', '+${result.xpEarned}', AppColors.amber, Icons.bolt_rounded),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark
                    ? AppColors.darkOutline
                    : AppColors.lightOutline),
          ),
          child: Row(
            children: [
              Icon(item.$4, color: item.$3, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$2,
                      style: TextStyle(
                          color: item.$3,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  Text(item.$1,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({required this.previous, required this.next});
  final String previous;
  final String next;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Level Up! 🎉',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text(
                '$previous → $next',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _XpEarnedCard extends StatelessWidget {
  const _XpEarnedCard({required this.xp});
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded,
              color: AppColors.amber, size: 28),
          const SizedBox(width: 10),
          Text(
            '+$xp XP earned',
            style: const TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w800,
                fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _SkillPerformance extends StatelessWidget {
  const _SkillPerformance(
      {required this.performance, required this.isDark});
  final Map<String, dynamic> performance;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance by Skill',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...performance.entries.map((e) {
          final data = e.value as Map<String, dynamic>?;
          final pct = (data?['percentage'] as num?)?.toDouble() ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key.capitalize ?? e.key,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${pct.round()}%',
                      style: TextStyle(
                          color: pct >= 60
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 60 ? AppColors.success : AppColors.error),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Gradient button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
