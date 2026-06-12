import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/game_model.dart';
import '../../controllers/games_controller.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_widget.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GamesController>();

    return Obx(() {
      switch (ctrl.phase.value) {
        case GamePhase.idle:
        case GamePhase.loading:
          return const _ScaffoldShell(child: LoadingWidget());

        case GamePhase.starting:
          return const _ScaffoldShell(child: _MessageLoader(message: 'Preparing your game…'));

        case GamePhase.hub:
          return _HubView(ctrl: ctrl);

        case GamePhase.playing:
        case GamePhase.submitting:
        case GamePhase.feedback:
          return _PlayView(ctrl: ctrl);

        case GamePhase.completing:
          return const _ScaffoldShell(child: _MessageLoader(message: 'Tallying your score…'));

        case GamePhase.results:
          return _ResultView(ctrl: ctrl);

        case GamePhase.error:
          return _ErrorView(ctrl: ctrl);
      }
    });
  }
}

// ─── Shared shell / loaders ───────────────────────────────────────────────────

class _ScaffoldShell extends StatelessWidget {
  const _ScaffoldShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: child,
    );
  }
}

class _MessageLoader extends StatelessWidget {
  const _MessageLoader({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.ctrl});
  final GamesController ctrl;

  @override
  Widget build(BuildContext context) {
    return _ScaffoldShell(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_esports_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                ctrl.errorMessage.value ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: ctrl.loadAvailableGames,
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

// ─── Hub ──────────────────────────────────────────────────────────────────────

class _HubView extends StatelessWidget {
  const _HubView({required this.ctrl});
  final GamesController ctrl;

  @override
  Widget build(BuildContext context) {
    final data = ctrl.availableGames.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _ScaffoldShell(
      child: data == null
          ? const EmptyState(
              icon: Icons.sports_esports_outlined,
              title: 'No games available',
              subtitle: 'Check back once vocabulary has been added for this language.',
            )
          : RefreshIndicator(
              onRefresh: ctrl.loadAvailableGames,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    'Practice ${ctrl.languageName.isEmpty ? 'your language' : ctrl.languageName} with quick games',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 16),
                  for (final game in data.games) ...[
                    _GameCard(game: game, isDark: isDark, onTap: () => ctrl.startGame(game.gameType)),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.isDark, required this.onTap});
  final GameInfo game;
  final bool isDark;
  final VoidCallback onTap;

  IconData get _icon => game.isWordMatch ? Icons.join_inner_rounded : Icons.shuffle_on_rounded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: game.playable ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(icon: Icons.bolt_rounded, label: '+${game.xpPerCorrect} XP / correct'),
                        const SizedBox(width: 8),
                        _Chip(icon: Icons.workspace_premium_rounded, label: '+${game.xpPerfectBonus} perfect bonus'),
                      ],
                    ),
                    if (!game.playable) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Not enough vocabulary yet for this language.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: game.playable ? 0.4 : 0.15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ─── Play view ────────────────────────────────────────────────────────────────

class _PlayView extends StatelessWidget {
  const _PlayView({required this.ctrl});
  final GamesController ctrl;

  @override
  Widget build(BuildContext context) {
    final session = ctrl.session.value;
    final round = ctrl.currentRound.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (session == null || round == null) {
      return const _ScaffoldShell(child: LoadingWidget());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: ctrl.backToHub,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ctrl.progressFraction,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => _TimerPill(seconds: ctrl.roundSecondsSpent.value)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Round ${round.roundIndex + 1} of ${session.totalRounds}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 28),
              Text(round.prompt, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 28),
              Expanded(
                child: round.options != null
                    ? _WordMatchBody(ctrl: ctrl, round: round, isDark: isDark)
                    : _WordScrambleBody(ctrl: ctrl, round: round, isDark: isDark),
              ),
              Obx(() {
                final feedback = ctrl.lastAnswer.value;
                if (ctrl.phase.value == GamePhase.feedback && feedback != null) {
                  return _FeedbackBar(ctrl: ctrl, feedback: feedback);
                }
                return SizedBox(
                  width: double.infinity,
                  child: Obx(() => FilledButton(
                        onPressed: ctrl.canSubmit && ctrl.phase.value == GamePhase.playing ? ctrl.submitRound : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: ctrl.phase.value == GamePhase.submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Check Answer', style: TextStyle(fontWeight: FontWeight.w700)),
                      )),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('${seconds}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ─── Word Match round body ────────────────────────────────────────────────────

class _WordMatchBody extends StatelessWidget {
  const _WordMatchBody({required this.ctrl, required this.round, required this.isDark});
  final GamesController ctrl;
  final GameRoundData round;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final options = round.options ?? const [];

    return Obx(() {
      final selected = ctrl.selectedOption.value;
      final feedback = ctrl.lastAnswer.value;
      final showFeedback = ctrl.phase.value == GamePhase.feedback && feedback != null;

      return ListView.separated(
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final option = options[i];
          final isSelected = selected == option;

          Color borderColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
          Color? fillColor;
          IconData? trailingIcon;
          Color? trailingColor;

          if (showFeedback) {
            if (option == feedback.correctAnswer) {
              borderColor = AppColors.success;
              fillColor = AppColors.success.withValues(alpha: 0.1);
              trailingIcon = Icons.check_circle_rounded;
              trailingColor = AppColors.success;
            } else if (isSelected) {
              borderColor = AppColors.error;
              fillColor = AppColors.error.withValues(alpha: 0.1);
              trailingIcon = Icons.cancel_rounded;
              trailingColor = AppColors.error;
            }
          } else if (isSelected) {
            borderColor = AppColors.primary;
            fillColor = AppColors.primary.withValues(alpha: 0.08);
          }

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: ctrl.phase.value == GamePhase.playing ? () => ctrl.selectOption(option) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fillColor ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: isSelected || showFeedback ? 2 : 1),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(option, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                  if (trailingIcon != null) Icon(trailingIcon, color: trailingColor, size: 20),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// ─── Word Scramble round body ─────────────────────────────────────────────────

class _WordScrambleBody extends StatefulWidget {
  const _WordScrambleBody({required this.ctrl, required this.round, required this.isDark});
  final GamesController ctrl;
  final GameRoundData round;
  final bool isDark;

  @override
  State<_WordScrambleBody> createState() => _WordScrambleBodyState();
}

class _WordScrambleBodyState extends State<_WordScrambleBody> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.ctrl.typedAnswer.value);
  }

  @override
  void didUpdateWidget(covariant _WordScrambleBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.round.roundIndex != widget.round.roundIndex) {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = (widget.round.scrambled ?? '').split('');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final letter in letters)
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    letter.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
            ],
          ),
          if (widget.round.hint != null && widget.round.hint!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Hint: ${widget.round.hint}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Obx(() => TextField(
                controller: _textController,
                enabled: widget.ctrl.phase.value == GamePhase.playing,
                onChanged: widget.ctrl.updateTypedAnswer,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  hintText: 'Type the unscrambled word…',
                  filled: true,
                  fillColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: widget.isDark ? AppColors.darkOutline : AppColors.lightOutline),
                  ),
                ),
              )),
          Obx(() {
            final feedback = widget.ctrl.lastAnswer.value;
            if (widget.ctrl.phase.value == GamePhase.feedback && feedback != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Correct word: ${feedback.correctAnswer}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

// ─── Feedback bar (shown after answering, before moving on) ──────────────────

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({required this.ctrl, required this.feedback});
  final GamesController ctrl;
  final GameAnswerResponse feedback;

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback.isCorrect;
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect ? 'Correct! Nice work.' : 'Not quite — keep practicing.',
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ),
          FilledButton(
            onPressed: ctrl.nextRound,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(feedback.finished ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }
}

// ─── Result view ──────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.ctrl});
  final GamesController ctrl;

  @override
  Widget build(BuildContext context) {
    final result = ctrl.result.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (result == null) {
      return const _ScaffoldShell(child: LoadingWidget());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${result.title} Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    '${result.scorePercentage.round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                result.isPerfect ? 'Perfect round! 🎉' : 'Game complete',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Correct', value: '${result.correctCount}/${result.totalRounds}', icon: Icons.check_circle_rounded, color: AppColors.success, isDark: isDark)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'XP earned', value: '+${result.xpEarned}', icon: Icons.bolt_rounded, color: AppColors.amber, isDark: isDark)),
              ],
            ),
            if (result.timeTakenSeconds != null) ...[
              const SizedBox(height: 12),
              _StatCard(
                label: 'Time taken',
                value: '${result.timeTakenSeconds}s',
                icon: Icons.timer_outlined,
                color: AppColors.info,
                isDark: isDark,
                fullWidth: true,
              ),
            ],
            const SizedBox(height: 24),
            Text('Round by round', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final round in result.rounds) ...[
              _RoundResultTile(round: round, isDark: isDark),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ctrl.playAgain(result.gameType),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play Again'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: ctrl.backToHub,
              child: const Text('Back to Games'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundResultTile extends StatelessWidget {
  const _RoundResultTile({required this.round, required this.isDark});
  final GameRoundResult round;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isCorrect = round.isCorrect ?? false;
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(round.term, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  'Correct answer: ${round.correctAnswer}'
                  '${round.userAnswer != null && !isCorrect ? ' • You answered: ${round.userAnswer}' : ''}',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
