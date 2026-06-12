import 'dart:async';

import 'package:get/get.dart';

import '../../config/routes.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/matching_api.dart';
import '../../data/repositories/matching_repository.dart';

class PracticeSessionController extends GetxController {
  static PracticeSessionController get to => Get.find();

  // ─── Session args (from route) ────────────────────────────────────────────
  late final int sessionId;
  late final int plannedDurationMinutes;
  late final String partnerName;
  late final int partnerId;
  late final String sessionType;

  // ─── Timer state ──────────────────────────────────────────────────────────
  final remainingSeconds = 0.obs;
  final isStarted  = false.obs;
  final isEnding   = false.obs;
  final errorMessage = Rx<String?>(null);

  Timer? _timer;
  late final MatchingRepository _repo;

  @override
  void onInit() {
    super.onInit();
    _repo = MatchingRepository(MatchingApi(ApiClient.instance));

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    sessionId              = args['session_id']              as int?    ?? 0;
    plannedDurationMinutes = args['planned_duration_minutes'] as int?    ?? 5;
    partnerName            = args['partner_name']            as String? ?? 'Partner';
    partnerId              = args['partner_id']              as int?    ?? 0;
    sessionType            = args['session_type']            as String? ?? 'text';

    remainingSeconds.value = plannedDurationMinutes * 60;
    _startSession();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // ─── Start session via API ────────────────────────────────────────────────

  Future<void> _startSession() async {
    try {
      final result = await _repo.startSession(
        sessionId,
        plannedDurationMinutes: plannedDurationMinutes,
      );
      // If already active, sync remaining time from server's started_at
      if (result['status'] == 'active' && result['started_at'] != null) {
        final startedAt = DateTime.tryParse(result['started_at'] as String);
        if (startedAt != null) {
          final elapsed = DateTime.now().difference(startedAt).inSeconds;
          final total   = (result['planned_duration_minutes'] as int? ?? plannedDurationMinutes) * 60;
          remainingSeconds.value = (total - elapsed).clamp(0, total);
        }
      }
      isStarted.value = true;
      _startCountdown();
    } catch (_) {
      // Even if the API call fails, run the timer locally so UX isn't blocked
      isStarted.value = true;
      _startCountdown();
    }
  }

  // ─── Countdown ────────────────────────────────────────────────────────────

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value <= 0) {
        _timer?.cancel();
        _onTimerExpired();
      } else {
        remainingSeconds.value--;
      }
    });
  }

  Future<void> _onTimerExpired() => _endSession();

  // ─── End session ──────────────────────────────────────────────────────────

  Future<void> endEarly() async {
    _timer?.cancel();
    await _endSession();
  }

  Future<void> _endSession() async {
    if (isEnding.value) return;
    isEnding.value = true;
    errorMessage.value = null;

    try {
      final result = await _repo.endSession(sessionId);
      final xpEarned        = result['xp_earned']       as int? ?? 0;
      final durationMinutes = result['duration_minutes'] as int? ?? plannedDurationMinutes;

      Get.offNamed(Routes.callRating, arguments: {
        'session_id':    sessionId,
        'partner_name':  partnerName,
        'call_duration': durationMinutes * 60,
        'call_type':     sessionType,
        'xp_earned':     xpEarned,
      });
    } catch (e) {
      isEnding.value = false;
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── Display helpers ──────────────────────────────────────────────────────

  String get timerLabel {
    final m = remainingSeconds.value ~/ 60;
    final s = remainingSeconds.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get progress {
    final total = plannedDurationMinutes * 60;
    if (total == 0) return 0;
    return remainingSeconds.value / total;
  }

  String get sessionTypeLabel {
    switch (sessionType) {
      case 'audio': return 'Audio Session';
      case 'video': return 'Video Session';
      default:      return 'Text Session';
    }
  }
}
