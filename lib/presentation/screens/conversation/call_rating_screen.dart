import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../controllers/call_rating_controller.dart';
import '../../widgets/buttons/primary_button.dart';

class CallRatingScreen extends StatelessWidget {
  const CallRatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CallRatingController());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Rate Your Call'),
        centerTitle: true,
      ),
      body: Obx(() => ctrl.isSubmitted.value
          ? _SuccessView(ctrl: ctrl)
          : _RatingForm(ctrl: ctrl)),
    );
  }
}

// ─── Rating form ──────────────────────────────────────────────────────────────

class _RatingForm extends StatelessWidget {
  const _RatingForm({required this.ctrl});
  final CallRatingController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Call summary card ────────────────────────────────
          _SummaryCard(ctrl: ctrl),

          const SizedBox(height: 28),

          Text(
            'How was your call with ${ctrl.partnerName}?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 24),

          // ── Overall rating ───────────────────────────────────
          _RatingCategory(
            label: 'Overall Experience',
            icon: Icons.star_rounded,
            color: AppColors.amber,
            value: ctrl.overallRating,
            onChange: ctrl.setOverall,
          ),

          const SizedBox(height: 20),

          // ── Communication ────────────────────────────────────
          _RatingCategory(
            label: 'Communication Quality',
            icon: Icons.record_voice_over_rounded,
            color: AppColors.primary,
            value: ctrl.communicationRating,
            onChange: ctrl.setCommunication,
          ),

          const SizedBox(height: 20),

          // ── Helpfulness ──────────────────────────────────────
          _RatingCategory(
            label: 'Helpfulness',
            icon: Icons.lightbulb_rounded,
            color: AppColors.secondary,
            value: ctrl.helpfulnessRating,
            onChange: ctrl.setHelpfulness,
          ),

          const SizedBox(height: 20),

          // ── Patience ─────────────────────────────────────────
          _RatingCategory(
            label: 'Patience',
            icon: Icons.favorite_rounded,
            color: AppColors.purple,
            value: ctrl.patienceRating,
            onChange: ctrl.setPatience,
          ),

          const SizedBox(height: 28),

          // ── Comment ──────────────────────────────────────────
          Text(
            'Comment (Optional)',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextFormField(
            maxLines: 3,
            maxLength: 300,
            onChanged: ctrl.setComment,
            decoration: const InputDecoration(
              hintText: 'Share your experience…',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 28),

          // ── Submit ───────────────────────────────────────────
          Obx(() => PrimaryButton(
                label: 'Submit Rating',
                icon: Icons.check_circle_outline_rounded,
                onPressed: ctrl.submit,
                isLoading: ctrl.isSubmitting.value,
              )),

          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: ctrl.goHome,
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.ctrl});
  final CallRatingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(ctrl.callTypeIcon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.partnerName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ctrl.callType == 'video' ? 'Video' : 'Audio'} Call  •  ${ctrl.durationLabel}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Just now',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
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

// ─── Rating category row ─────────────────────────────────────────────────────

class _RatingCategory extends StatelessWidget {
  const _RatingCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChange,
  });

  final String label;
  final IconData icon;
  final Color color;
  final RxInt value;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Obx(() => _StarRow(
                      current: value.value,
                      color: color,
                      onChange: onChange,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Interactive star row ─────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.current,
    required this.color,
    required this.onChange,
  });

  final int current;
  final Color color;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < current;
        return GestureDetector(
          onTap: () => onChange(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(filled),
                color: filled ? color : Theme.of(context).colorScheme.outline,
                size: 28,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatefulWidget {
  const _SuccessView({required this.ctrl});
  final CallRatingController ctrl;

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _fade  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: const Interval(0, 0.5)));
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated checkmark
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
              ),
            ),

            const SizedBox(height: 24),

            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Text(
                    'Rating Submitted!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  // XP earned badge
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '+${widget.ctrl.xpEarned.value} XP',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 12),
                  Text(
                    'Thanks for helping our community improve!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  PrimaryButton(
                    label: 'Back to Home',
                    icon: Icons.home_rounded,
                    onPressed: widget.ctrl.goHome,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
