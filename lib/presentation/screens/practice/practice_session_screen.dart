import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/practice_session_controller.dart';

class PracticeSessionScreen extends StatelessWidget {
  const PracticeSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PracticeSessionController());

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Obx(() {
            if (!ctrl.isStarted.value) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            return _SessionBody(ctrl: ctrl);
          }),
        ),
      ),
    );
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _SessionBody extends StatelessWidget {
  const _SessionBody({required this.ctrl});
  final PracticeSessionController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(ctrl: ctrl),
        const Spacer(),
        _TimerRing(ctrl: ctrl),
        const SizedBox(height: 40),
        _PartnerCard(ctrl: ctrl),
        const Spacer(),
        _BottomActions(ctrl: ctrl),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.ctrl});
  final PracticeSessionController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  '${ctrl.plannedDurationMinutes} min session',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1DB954).withValues(alpha:0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1DB954),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ctrl.sessionTypeLabel,
                  style: const TextStyle(
                    color: Color(0xFF1DB954),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

// ─── Timer ring ───────────────────────────────────────────────────────────────

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.ctrl});
  final PracticeSessionController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() => SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 220),
                painter: _RingPainter(progress: ctrl.progress),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ctrl.timerLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'remaining',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 6.0;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha:0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Partner card ─────────────────────────────────────────────────────────────

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.ctrl});
  final PracticeSessionController ctrl;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(ctrl.partnerName);
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          ctrl.partnerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Practicing together',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── Bottom actions ───────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.ctrl});
  final PracticeSessionController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              if (ctrl.errorMessage.value != null) ...[
                Text(
                  ctrl.errorMessage.value!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: ctrl.isEnding.value ? null : ctrl.endEarly,
                  child: ctrl.isEnding.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'End Session',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ));
  }
}
