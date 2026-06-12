import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../config/theme.dart';
import '../../controllers/call_controller.dart';
import '../../widgets/common/avatar_widget.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CallController());
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() => switch (ctrl.callState.value) {
            CallState.ringing  => _VideoRingingView(ctrl: ctrl),
            CallState.active   => _ActiveVideoView(ctrl: ctrl),
            CallState.ended    => _VideoEndedView(label: 'Call ended'),
            CallState.declined => _VideoEndedView(label: 'Call declined'),
            _                  => _VideoConnectingView(ctrl: ctrl),
          }),
    );
  }
}

// ─── Connecting ───────────────────────────────────────────────────────────────

class _VideoConnectingView extends StatelessWidget {
  const _VideoConnectingView({required this.ctrl});
  final CallController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarWidget(initials: ctrl.partnerName, radius: 60),
            const SizedBox(height: 20),
            Text(ctrl.partnerName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Connecting video…', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 28),
            const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Ringing ──────────────────────────────────────────────────────────────────

class _VideoRingingView extends StatelessWidget {
  const _VideoRingingView({required this.ctrl});
  final CallController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text('Video Call from…', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 4),
              ),
              child: AvatarWidget(initials: ctrl.partnerName, radius: 60),
            ),
            const SizedBox(height: 16),
            Text(ctrl.partnerName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Ringing…', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const Spacer(),
            // Camera/mic pre-join toggles
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _VideoToggle(
                      icon: ctrl.isMuted.value ? Icons.mic_off_rounded : Icons.mic_rounded,
                      active: !ctrl.isMuted.value,
                      onTap: ctrl.toggleMute,
                      label: 'Mic',
                    ),
                    const SizedBox(width: 24),
                    _VideoToggle(
                      icon: ctrl.isCameraOn.value ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      active: ctrl.isCameraOn.value,
                      onTap: ctrl.toggleCamera,
                      label: 'Camera',
                    ),
                  ],
                )),
            const SizedBox(height: 32),
            // Accept / Decline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallActionButton(icon: Icons.call_end_rounded, color: AppColors.error, label: 'Decline', onTap: ctrl.decline),
                _CallActionButton(icon: Icons.videocam_rounded, color: AppColors.success, label: 'Accept', onTap: () {}),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─── Active video ─────────────────────────────────────────────────────────────

class _ActiveVideoView extends StatelessWidget {
  const _ActiveVideoView({required this.ctrl});
  final CallController ctrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Partner video (full screen) ────────────────────────
        Positioned.fill(
          child: Obx(() {
            final track = ctrl.remoteVideoTrack.value;
            if (track != null) {
              return VideoTrackRenderer(track);
            }
            // Fallback: partner camera off or not yet streaming
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvatarWidget(initials: ctrl.partnerName, radius: 64),
                    const SizedBox(height: 16),
                    Text(ctrl.partnerName,
                        style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            );
          }),
        ),

        // ── Top gradient overlay ───────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
          ),
        ),

        // ── Timer top-center ──────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Center(
              child: Obx(() => Text(
                    ctrl.durationLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  )),
            ),
          ),
        ),

        // ── PiP (own video) ────────────────────────────────────
        Obx(() {
          final pip = Positioned(
            right: 16,
            bottom: 140,
            child: GestureDetector(
              onTap: ctrl.togglePiPSwap,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF2d2d2d),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Obx(() {
                  final track = ctrl.localVideoTrack.value;
                  if (ctrl.isCameraOn.value && track != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: VideoTrackRenderer(track),
                    );
                  }
                  return Center(
                    child: Icon(
                      ctrl.isCameraOn.value
                          ? Icons.person_rounded
                          : Icons.videocam_off_rounded,
                      color: Colors.white38,
                      size: 36,
                    ),
                  );
                }),
              ),
            ),
          );
          return pip;
        }),

        // ── Bottom controls ────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
              ),
            ),
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _VideoControlBtn(
                      icon: ctrl.isMuted.value ? Icons.mic_off_rounded : Icons.mic_rounded,
                      active: !ctrl.isMuted.value,
                      label: 'Mute',
                      onTap: ctrl.toggleMute,
                    ),
                    _VideoControlBtn(
                      icon: ctrl.isCameraOn.value ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      active: ctrl.isCameraOn.value,
                      label: 'Camera',
                      onTap: ctrl.toggleCamera,
                    ),
                    // End call
                    GestureDetector(
                      onTap: ctrl.endCall,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 6),
                          const Text('End', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    _VideoControlBtn(
                      icon: Icons.flip_camera_ios_rounded,
                      active: false,
                      label: 'Flip',
                      onTap: ctrl.flipCamera,
                    ),
                    _VideoControlBtn(
                      icon: ctrl.isSpeakerOn.value ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      active: ctrl.isSpeakerOn.value,
                      label: 'Speaker',
                      onTap: ctrl.toggleSpeaker,
                    ),
                  ],
                )),
          ),
        ),
      ],
    );
  }
}

// ─── Ended ────────────────────────────────────────────────────────────────────

class _VideoEndedView extends StatelessWidget {
  const _VideoEndedView({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_end_rounded, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _VideoControlBtn extends StatelessWidget {
  const _VideoControlBtn({required this.icon, required this.active, required this.label, required this.onTap});
  final IconData icon;
  final bool active;
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: active ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: active ? Colors.white.withValues(alpha: 0.4) : Colors.transparent, width: 1),
            ),
            child: Icon(icon, color: active ? Colors.white : Colors.white54, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}

class _VideoToggle extends StatelessWidget {
  const _VideoToggle({required this.icon, required this.active, required this.onTap, required this.label});
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: active ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({required this.icon, required this.color, required this.label, required this.onTap});
  final IconData icon;
  final Color color;
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
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
