import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/quiz_model.dart';
import '../../controllers/quiz_controller.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<QuizController>();

    return Obx(() {
      switch (ctrl.phase.value) {
        case QuizPhase.idle:
        case QuizPhase.loading:
        case QuizPhase.starting:
          return _LoadingView(
            message: ctrl.phase.value == QuizPhase.starting
                ? 'Preparing your quiz…'
                : 'Loading quiz…',
          );

        case QuizPhase.preview:
          return _LobbyView(ctrl: ctrl);

        case QuizPhase.question:
        case QuizPhase.submitting:
        case QuizPhase.feedback:
          return _QuestionView(ctrl: ctrl);

        case QuizPhase.completing:
          return const _LoadingView(message: 'Calculating results…');

        case QuizPhase.results:
          return _ResultView(ctrl: ctrl);

        case QuizPhase.error:
          return _ErrorView(ctrl: ctrl);
      }
    });
  }
}

// ─── Loading ─────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({this.message = 'Loading…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.ctrl});
  final QuizController ctrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                ctrl.errorMessage.value ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: ctrl.retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Lobby ────────────────────────────────────────────────────────────────────

class _LobbyView extends StatelessWidget {
  const _LobbyView({required this.ctrl});
  final QuizController ctrl;

  @override
  Widget build(BuildContext context) {
    final quiz = ctrl.quiz.value!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.quiz_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            quiz.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (quiz.description != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        quiz.description!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      ctrl.languageName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.help_outline_rounded,
                    label: '${quiz.totalQuestions} Questions',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: '${quiz.timeLimitMinutes} min',
                    color: AppColors.amber,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.bolt_rounded,
                    label: '+${quiz.xpReward} XP',
                    color: AppColors.secondary,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'How it works',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ..._buildInstructions(quiz).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.$1, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 40),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() => FilledButton(
                      onPressed: ctrl.phase.value == QuizPhase.starting
                          ? null
                          : ctrl.startQuiz,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: ctrl.phase.value == QuizPhase.starting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Start Quiz',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    )),
              ),

              if (ctrl.errorMessage.value != null) ...[
                const SizedBox(height: 16),
                Text(
                  ctrl.errorMessage.value!,
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<(IconData, String)> _buildInstructions(QuizAvailableData quiz) {
    final types = quiz.questions.map((q) => q.questionType).toSet();
    final hasTranslation = types.any((t) => t.contains('translation'));
    final hasMC   = types.contains('multiple_choice');
    final hasTF   = types.contains('true_false');
    final hasFill = types.contains('fill_blank');

    final interactive = [
      if (hasMC)   'multiple-choice',
      if (hasTF)   'true/false',
      if (hasFill) 'fill-in-the-blank',
    ];

    return [
      if (hasTranslation)
        (Icons.translate_rounded,
            'Translate sentences from your native language into the target language — and vice versa.'),
      if (interactive.isNotEmpty)
        (Icons.touch_app_rounded,
            'Also answer ${interactive.join(', ')} questions.'),
      (Icons.feedback_outlined,
          'After every answer you\'ll see the correct answer and a brief explanation.'),
      (Icons.bar_chart_rounded,
          'Your answers determine your placement level — answer as honestly as you can!'),
    ];
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Question ─────────────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.ctrl});
  final QuizController ctrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => _showQuitDialog(context),
        ),
        title: Obx(() {
          final q = ctrl.quiz.value;
          if (q == null) return const SizedBox.shrink();
          return Text(
            'Question ${ctrl.currentIndex.value + 1} of ${q.totalQuestions}',
            style: const TextStyle(fontSize: 16),
          );
        }),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _TimerBadge(seconds: ctrl.totalSecondsLeft.value),
              )),
        ],
      ),
      body: Obx(() {
        final q = ctrl.currentQuestion;
        if (q == null) return const SizedBox.shrink();

        return Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: ctrl.progressFraction,
              backgroundColor:
                  isDark ? AppColors.darkSurfaceVariant : AppColors.lightOutline,
              color: AppColors.primary,
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skill + level badges
                    Row(
                      children: [
                        _Badge(
                          label: q.isTranslation
                              ? 'TRANSLATION'
                              : q.skillCategory.toUpperCase(),
                          color: q.isTranslation
                              ? AppColors.secondary
                              : AppColors.purple,
                        ),
                        const SizedBox(width: 8),
                        _Badge(label: q.cefrLevel, color: AppColors.amber),
                        if (q.isTranslationToTarget) ...[
                          const SizedBox(width: 8),
                          _Badge(
                            label: '→ ${q.targetLanguage ?? 'target'}',
                            color: AppColors.primary,
                          ),
                        ] else if (q.isTranslationToNative) ...[
                          const SizedBox(width: 8),
                          _Badge(
                            label: '→ ${q.sourceLanguage ?? 'native'}',
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Question text
                    Text(
                      q.questionText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 28),

                    // Answer widget
                    _AnswerWidget(ctrl: ctrl, question: q),

                    const SizedBox(height: 28),

                    // Feedback banner
                    if (ctrl.phase.value == QuizPhase.feedback)
                      _FeedbackBanner(
                        response: ctrl.lastAnswer.value!,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            _BottomBar(ctrl: ctrl, isDark: isDark),
          ],
        );
      }),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text(
            'Your progress will not be saved. Are you sure you want to quit?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () {
              Get.back(); // close dialog
              ctrl.done();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final isLow = seconds <= 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: isLow ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isLow ? AppColors.error : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Answer widget (adapts to question type) ──────────────────────────────────

class _AnswerWidget extends StatelessWidget {
  const _AnswerWidget({required this.ctrl, required this.question});
  final QuizController ctrl;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final isDisabled = ctrl.phase.value == QuizPhase.feedback ||
        ctrl.phase.value == QuizPhase.submitting;

    // Translation questions: source-sentence card + multiline input
    if (question.isTranslation) {
      return _TranslationAnswerWidget(
        ctrl: ctrl,
        question: question,
        isDisabled: isDisabled,
      );
    }

    // Multiple-choice / true-false: tappable option tiles
    if (question.isMultipleChoice || question.isTrueFalse) {
      final options = question.options ??
          (question.isTrueFalse ? ['True', 'False'] : []);
      return Column(
        children: options
            .map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Obx(() {
                    final selected = ctrl.selectedAnswer.value == opt;
                    final fb = ctrl.lastAnswer.value;
                    Color? borderColor;
                    Color? bgColor;
                    if (fb != null) {
                      if (opt == fb.correctAnswer) {
                        borderColor = AppColors.success;
                        bgColor = AppColors.success.withValues(alpha: 0.08);
                      } else if (selected && !fb.isCorrect) {
                        borderColor = AppColors.error;
                        bgColor = AppColors.error.withValues(alpha: 0.08);
                      }
                    } else if (selected) {
                      borderColor = AppColors.primary;
                      bgColor = AppColors.primary.withValues(alpha: 0.08);
                    }

                    return GestureDetector(
                      onTap: isDisabled ? null : () => ctrl.selectAnswer(opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor ??
                              (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface),
                          border: Border.all(
                            color: borderColor ??
                                (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkOutline
                                    : AppColors.lightOutline),
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.normal),
                              ),
                            ),
                            if (fb != null && opt == fb.correctAnswer)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 20)
                            else if (fb != null && selected && !fb.isCorrect)
                              const Icon(Icons.cancel_rounded,
                                  color: AppColors.error, size: 20)
                            else if (selected)
                              Icon(Icons.radio_button_checked_rounded,
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                ))
            .toList(),
      );
    }

    // fill_blank → single-line text field
    return _TextAnswerField(ctrl: ctrl, isDisabled: isDisabled);
  }
}

class _TextAnswerField extends StatefulWidget {
  const _TextAnswerField({required this.ctrl, required this.isDisabled});
  final QuizController ctrl;
  final bool isDisabled;

  @override
  State<_TextAnswerField> createState() => _TextAnswerFieldState();
}

class _TextAnswerFieldState extends State<_TextAnswerField> {
  late final TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(text: widget.ctrl.selectedAnswer.value ?? '');
    _tc.addListener(() => widget.ctrl.selectAnswer(_tc.text));
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fb = widget.ctrl.lastAnswer.value;
      return TextField(
        controller: _tc,
        enabled: !widget.isDisabled,
        decoration: InputDecoration(
          hintText: 'Type your answer…',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: fb != null
              ? Icon(
                  fb.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: fb.isCorrect ? AppColors.success : AppColors.error,
                )
              : null,
        ),
        onChanged: widget.ctrl.selectAnswer,
      );
    });
  }
}

// ─── Translation answer widget ────────────────────────────────────────────────

class _TranslationAnswerWidget extends StatefulWidget {
  const _TranslationAnswerWidget({
    required this.ctrl,
    required this.question,
    required this.isDisabled,
  });
  final QuizController ctrl;
  final QuizQuestion question;
  final bool isDisabled;

  @override
  State<_TranslationAnswerWidget> createState() =>
      _TranslationAnswerWidgetState();
}

class _TranslationAnswerWidgetState
    extends State<_TranslationAnswerWidget> {
  late final TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(
        text: widget.ctrl.selectedAnswer.value ?? '');
    _tc.addListener(() => widget.ctrl.selectAnswer(_tc.text));
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q      = widget.question;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final fb = widget.ctrl.lastAnswer.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Source sentence card ──────────────────────────────
          if (q.sourceSentence != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(
                    alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 5),
                      Text(
                        q.sourceLanguage ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    q.sourceSentence!,
                    style:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              height: 1.55,
                            ),
                  ),
                ],
              ),
            ),

          if (q.sourceSentence != null) const SizedBox(height: 6),

          // ── Direction arrow ───────────────────────────────────
          if (q.sourceSentence != null && q.targetLanguage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_downward_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          q.isTranslationToTarget
                              ? q.targetLanguage!
                              : (q.sourceLanguage ?? ''),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

          // ── Hint ──────────────────────────────────────────────
          if (q.hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 13,
                      color: AppColors.amber.withValues(alpha: 0.8)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Hint: ${q.hint}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.amber.withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Translation text input ────────────────────────────
          TextField(
            controller: _tc,
            enabled: !widget.isDisabled,
            maxLines: 4,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Type your translation…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: fb == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Icon(
                        fb.isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: fb.isCorrect
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
            ),
            onChanged: widget.ctrl.selectAnswer,
          ),
        ],
      );
    });
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.response, required this.isDark});
  final QuizAnswerResponse response;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final correct = response.isCorrect;
    final color = correct ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Result header ─────────────────────────────────────
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),

          // ── Always show the correct answer ────────────────────
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded,
                    size: 14, color: color, ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Correct answer: ${response.correctAnswer}',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Explanation ───────────────────────────────────────
          if (response.explanation != null &&
              response.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              response.explanation!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.ctrl, required this.isDark});
  final QuizController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
      ),
      child: Obx(() {
        final phase = ctrl.phase.value;

        if (phase == QuizPhase.feedback) {
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: ctrl.nextQuestion,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                ctrl.isLastQuestion ? 'See Results' : 'Next Question',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        final canSubmit = ctrl.selectedAnswer.value != null &&
            ctrl.selectedAnswer.value!.isNotEmpty &&
            phase == QuizPhase.question;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: canSubmit ? ctrl.submitAnswer : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: phase == QuizPhase.submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Submit Answer',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      }),
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.ctrl});
  final QuizController ctrl;

  @override
  Widget build(BuildContext context) {
    final r = ctrl.result.value!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = r.scorePercentage;
    final passed = score >= 70;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Score circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightOutline,
                      color: passed ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: passed ? AppColors.success : AppColors.error,
                            ),
                      ),
                      Text(
                        passed ? 'Passed!' : 'Try again',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Level up banner
              if (r.leveledUp)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Level Up!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            if (r.previousLevel != null && r.newLevel != null)
                              Text(
                                '${r.previousLevel} → ${r.newLevel}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _ResultCard(
                    icon: Icons.check_circle_outline_rounded,
                    value: '${r.correctAnswers}',
                    label: 'Correct',
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                  _ResultCard(
                    icon: Icons.cancel_outlined,
                    value: '${r.incorrectAnswers}',
                    label: 'Incorrect',
                    color: AppColors.error,
                    isDark: isDark,
                  ),
                  _ResultCard(
                    icon: Icons.bolt_rounded,
                    value: '+${r.xpEarned}',
                    label: 'XP Earned',
                    color: AppColors.amber,
                    isDark: isDark,
                  ),
                  _ResultCard(
                    icon: Icons.bar_chart_rounded,
                    value: r.newLevel ?? r.previousLevel ?? '—',
                    label: 'Your Level',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ],
              ),

              // Skill breakdown
              if (r.performanceBySkill.isNotEmpty) ...[
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Performance by Skill',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ...r.performanceBySkill.entries.map((e) {
                  final pct =
                      (e.value['percentage'] as num?)?.toDouble() ?? 0.0;
                  final correct = (e.value['correct'] as num?)?.toInt() ?? 0;
                  final total = (e.value['total'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SkillRow(
                      skill: e.key,
                      percentage: pct,
                      label: '$correct/$total',
                      isDark: isDark,
                    ),
                  );
                }),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: ctrl.done,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.skill,
    required this.percentage,
    required this.label,
    required this.isDark,
  });
  final String skill;
  final double percentage;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 70
        ? AppColors.success
        : percentage >= 50
            ? AppColors.amber
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skill[0].toUpperCase() + skill.substring(1),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$label (${percentage.toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 6,
          backgroundColor:
              isDark ? AppColors.darkSurfaceVariant : AppColors.lightOutline,
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
