import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../controllers/call_controller.dart';
import '../../widgets/common/avatar_widget.dart';

class AudioCallScreen extends StatelessWidget {
  const AudioCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CallController());
    return Scaffold(
      body: Obx(() => switch (ctrl.callState.value) {
            CallState.connecting => _ConnectingView(ctrl: ctrl),
            CallState.ringing    => _RingingView(ctrl: ctrl),
            CallState.active     => _ActiveAudioView(ctrl: ctrl),
            CallState.ended      => _EndedView(label: 'Call ended'),
            CallState.declined   => _EndedView(label: 'Call declined'),
            _                    => _EndedView(label: 'Call failed'),
          }),
    );
  }
}

// ─── Connecting ───────────────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({required this.ctrl});
  final CallController ctrl;

  @override
  Widget build(BuildContext context) {
    return _CallBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarWidget(initials: ctrl.partnerName, radius: 56),
          const SizedBox(height: 24),
          Text(ctrl.partnerName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Connecting…', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 32),
          const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
        ],
      ),
    );
  }
}

// ─── Ringing ──────────────────────────────────────────────────────────────────

class _RingingView extends StatelessWidget {
  const _RingingView({required this.ctrl});
  final CallController ctrl;

  @override
  Widget build(BuildContext context) {
    return _CallBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulsingAvatar(name: ctrl.partnerName),
          const SizedBox(height: 24),
          Text(ctrl.partnerName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Ringing…', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 80),
          // Decline button
          _RoundButton(
            icon: Icons.call_end_rounded,
            color: AppColors.error,
            size: 72,
            label: 'Decline',
            onTap: ctrl.decline,
          ),
        ],
      ),
    );
  }
}

// ─── Active call ──────────────────────────────────────────────────────────────

class _ActiveAudioView extends StatelessWidget {
  const _ActiveAudioView({required this.ctrl});
  final CallController ctrl;

  @override
  Widget build(BuildContext context) {
    return _CallBackground(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Partner info
            AvatarWidget(initials: ctrl.partnerName, radius: 56),
            const SizedBox(height: 20),
            Text(ctrl.partnerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Connected', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 15)),

            const SizedBox(height: 20),

            // Timer
            Obx(() => Text(
                  ctrl.durationLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w300, letterSpacing: 2),
                )),

            const Spacer(),

            // Sound wave
            const _SoundWave(),

            const Spacer(),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        icon: ctrl.isMuted.value ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: ctrl.isMuted.value ? 'Unmute' : 'Mute',
                        active: ctrl.isMuted.value,
                        onTap: ctrl.toggleMute,
                      ),
                      _RoundButton(
                        icon: Icons.call_end_rounded,
                        color: AppColors.error,
                        size: 72,
                        label: 'End',
                        onTap: ctrl.endCall,
                      ),
                      _ControlButton(
                        icon: ctrl.isSpeakerOn.value ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: ctrl.isSpeakerOn.value ? 'Earpiece' : 'Speaker',
                        active: ctrl.isSpeakerOn.value,
                        onTap: ctrl.toggleSpeaker,
                      ),
                    ],
                  )),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─── Ended / declined ────────────────────────────────────────────────────────

class _EndedView extends StatelessWidget {
  const _EndedView({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return _CallBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_end_rounded, color: Colors.white, size: 56),
            const SizedBox(height: 20),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _CallBackground extends StatelessWidget {
  const _CallBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
      child: child,
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  const _PulsingAvatar({required this.name});
  final String name;

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.08).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 4),
        ),
        child: AvatarWidget(initials: widget.name, radius: 56),
      ),
    );
  }
}

class _SoundWave extends StatefulWidget {
  const _SoundWave();
  @override
  State<_SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<_SoundWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(7, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              final phase = (_ctrl.value + i * 0.14) % 1.0;
              final h = 8.0 + (phase < 0.5 ? phase : 1 - phase) * 44;
              return Container(
                width: 5,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.color, required this.size, required this.label, required this.onTap});
  final IconData icon;
  final Color color;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: active ? AppColors.primary : Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
