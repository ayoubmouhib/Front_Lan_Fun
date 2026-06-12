import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../config/routes.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/conversation_api.dart';
import '../../services/websocket_service.dart';

export 'package:livekit_client/livekit_client.dart' show VideoTrack, LocalVideoTrack;

enum CallState { idle, connecting, ringing, active, ended, declined, failed }

class CallController extends GetxController {
  static CallController get to => Get.find();

  // ─── Route args ───────────────────────────────────────────────────────────
  late final String callType;       // 'audio' | 'video'
  late final String partnerName;
  int? partnerId;
  int? conversationId;
  int? sessionId;

  // ─── State ────────────────────────────────────────────────────────────────
  final callState = CallState.connecting.obs;

  // Controls (mirrored to LiveKit tracks in setters)
  final isMuted     = false.obs;
  final isSpeakerOn = false.obs;
  final isCameraOn  = true.obs;
  final isFrontCam  = true.obs;
  final isOnHold    = false.obs;

  // Video tracks exposed to the UI
  final remoteVideoTrack = Rx<VideoTrack?>(null);
  final localVideoTrack  = Rx<LocalVideoTrack?>(null);

  // PiP swap
  final isPiPSwapped = false.obs;

  // Duration
  final elapsedSeconds = 0.obs;
  Timer? _durationTimer;

  // Internal call ID from API
  int? _callId;

  // LiveKit
  Room? _room;
  EventsListener<RoomEvent>? _roomListener;

  late final ConversationApi _api;
  StreamSubscription<WsCallEvent>? _wsSub;

  @override
  void onInit() {
    super.onInit();
    _api = ConversationApi(ApiClient.instance);

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    callType       = args['call_type'] as String? ?? 'audio';
    partnerName    = args['partner_name'] as String? ?? 'Partner';
    partnerId      = args['partner_id'] as int?;
    conversationId = args['conversation_id'] as int?;
    sessionId      = args['session_id'] as int?;

    final isReceiver   = args['is_receiver'] as bool? ?? false;
    final callToken    = args['call_token'] as String?;
    final callServerUrl = args['call_server_url'] as String?;
    _callId            = args['call_id'] as int?;

    if (isReceiver && callToken != null && callServerUrl != null) {
      connectAsReceiver(callToken, callServerUrl);
    } else {
      _startCall();
    }
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _wsSub?.cancel();
    _roomListener?.dispose();
    _room?.disconnect();
    _room?.dispose();
    super.onClose();
  }

  // ─── Call lifecycle ───────────────────────────────────────────────────────

  Future<void> _startCall() async {
    callState.value = CallState.connecting;
    final convId = conversationId;

    if (convId == null) {
      // No conversation ID — fallback ringing UI only
      callState.value = CallState.ringing;
      return;
    }

    try {
      final res = await _api.initiateCall(convId, type: callType);
      _callId = res['id'] as int?;
      final callToken    = res['call_token']      as String?;
      final callServerUrl = res['call_server_url'] as String?;

      callState.value = CallState.ringing;

      if (callToken != null && callServerUrl != null) {
        // Listen for the receiver accepting via WebSocket
        _wsSub = WebSocketService.to.callEventStream.listen((event) {
          if (event.callId != _callId) return;
          if (event.isAccepted) {
            _wsSub?.cancel();
            _connectToRoom(callToken, callServerUrl);
          }
          if (event.isRejected || event.isEnded) {
            _wsSub?.cancel();
            callState.value = CallState.declined;
            Future.delayed(const Duration(milliseconds: 600), Get.back);
          }
        });
      } else {
        // Token missing — backend not yet configured; show ringing only
        callState.value = CallState.ringing;
      }
    } catch (e) {
      callState.value = CallState.failed;
      _showError(ApiClient.parseError(e));
    }
  }

  // Called by the RECEIVER when they tap Accept (navigated to call screen via WS)
  Future<void> connectAsReceiver(String callToken, String callServerUrl) async {
    callState.value = CallState.connecting;
    await _connectToRoom(callToken, callServerUrl);
  }

  Future<void> _connectToRoom(String token, String serverUrl) async {
    try {
      _room = Room(
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
      _roomListener = _room!.createListener();

      _roomListener!
        ..on<TrackSubscribedEvent>(_onTrackSubscribed)
        ..on<TrackUnsubscribedEvent>(_onTrackUnsubscribed)
        ..on<RoomDisconnectedEvent>((_) {
          if (callState.value == CallState.active) endCall();
        });

      await _room!.connect(serverUrl, token);

      // Publish local tracks
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      if (callType == 'video') {
        await _room!.localParticipant?.setCameraEnabled(true);
        final pub = _room!.localParticipant?.videoTrackPublications
            .where((p) => p.track != null)
            .firstOrNull;
        if (pub?.track is LocalVideoTrack) {
          localVideoTrack.value = pub!.track as LocalVideoTrack;
        }
      }

      _onCallConnected();
    } catch (e) {
      callState.value = CallState.failed;
      _showError('Could not connect to call: ${ApiClient.parseError(e)}');
    }
  }

  void _onTrackSubscribed(TrackSubscribedEvent event) {
    if (event.track is VideoTrack) {
      remoteVideoTrack.value = event.track as VideoTrack;
    }
  }

  void _onTrackUnsubscribed(TrackUnsubscribedEvent event) {
    if (event.track is VideoTrack) {
      remoteVideoTrack.value = null;
    }
  }

  void _onCallConnected() {
    callState.value = CallState.active;
    _startDurationTimer();
  }

  void _startDurationTimer() {
    elapsedSeconds.value = 0;
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => elapsedSeconds.value++,
    );
  }

  // ─── Controls ─────────────────────────────────────────────────────────────

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _room?.localParticipant?.setMicrophoneEnabled(!isMuted.value);
  }

  void toggleCamera() {
    isCameraOn.value = !isCameraOn.value;
    _room?.localParticipant?.setCameraEnabled(isCameraOn.value);
  }

  Future<void> flipCamera() async {
    isFrontCam.value = !isFrontCam.value;
    // Toggle the camera by cycling enabled state so LiveKit re-opens the other lens
    final participant = _room?.localParticipant;
    if (participant == null) return;
    await participant.setCameraEnabled(false);
    await participant.setCameraEnabled(true);
  }

  void toggleSpeaker()  => isSpeakerOn.value = !isSpeakerOn.value;
  void togglePiPSwap()  => isPiPSwapped.value = !isPiPSwapped.value;

  // ─── End call ─────────────────────────────────────────────────────────────

  Future<void> endCall() async {
    _durationTimer?.cancel();
    final duration = elapsedSeconds.value;
    callState.value = CallState.ended;

    await _room?.disconnect();

    final callId = _callId;
    if (callId != null) {
      try { await _api.endCall(callId, durationSeconds: duration); } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 800));
    _navigateToRating(duration);
  }

  Future<void> decline() async {
    _durationTimer?.cancel();
    callState.value = CallState.declined;

    await _room?.disconnect();

    final callId = _callId;
    if (callId != null) {
      try { await _api.rejectCall(callId); } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 600));
    Get.back();
  }

  void _navigateToRating(int duration) {
    Get.offNamed(Routes.callRating, arguments: {
      'partner_name': partnerName,
      'partner_id':   partnerId,
      'call_duration': duration,
      'call_type':    callType,
      'session_id':   sessionId,
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get durationLabel {
    final m = elapsedSeconds.value ~/ 60;
    final s = elapsedSeconds.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showError(String msg) {
    Get.snackbar(
      'Call Failed',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
    Future.delayed(
      const Duration(seconds: 2),
      () { if (!isClosed) Get.back(); },
    );
  }
}
