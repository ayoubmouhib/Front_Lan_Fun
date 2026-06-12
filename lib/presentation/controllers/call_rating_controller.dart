import 'package:get/get.dart';

import '../../config/routes.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/matching_api.dart';
import '../../data/repositories/matching_repository.dart';

class CallRatingController extends GetxController {
  static CallRatingController get to => Get.find();

  // ─── Route args ───────────────────────────────────────────────────────────
  late final String partnerName;
  int? sessionId;
  late final int callDuration; // seconds
  late final String callType;

  // ─── Rating values (1–5) ─────────────────────────────────────────────────
  final overallRating        = 5.obs;
  final communicationRating  = 5.obs;
  final helpfulnessRating    = 5.obs;
  final patienceRating       = 5.obs;
  final commentText          = ''.obs;

  // ─── Submit state ─────────────────────────────────────────────────────────
  final isSubmitting = false.obs;
  final isSubmitted  = false.obs;
  late final int _conversationXp;
  final xpEarned = 0.obs; // conversation XP now; bumped by the rating bonus on submit

  late final MatchingRepository _repo;

  @override
  void onInit() {
    super.onInit();
    _repo = MatchingRepository(MatchingApi(ApiClient.instance));

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    partnerName  = args['partner_name'] as String? ?? 'Partner';
    sessionId    = args['session_id']   as int?;
    callDuration = args['call_duration'] as int? ?? 0;
    callType     = args['call_type']    as String? ?? 'audio';

    _conversationXp = args['xp_earned'] as int? ?? 0;
    xpEarned.value  = _conversationXp;
  }

  // ─── Setters ──────────────────────────────────────────────────────────────

  void setOverall(int v)       => overallRating.value       = v;
  void setCommunication(int v) => communicationRating.value = v;
  void setHelpfulness(int v)   => helpfulnessRating.value   = v;
  void setPatience(int v)      => patienceRating.value      = v;
  void setComment(String v)    => commentText.value         = v;

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> submit() async {
    isSubmitting.value = true;

    final sid = sessionId;
    if (sid != null) {
      try {
        final result = await _repo.rateSession(
          sid,
          overallScore:       overallRating.value,
          communicationScore: communicationRating.value,
          helpfulnessScore:   helpfulnessRating.value,
          patienceScore:      patienceRating.value,
          comment: commentText.value.trim().isEmpty
              ? null
              : commentText.value.trim(),
        );
        final bonus = result['xp_earned'] as int? ?? 0;
        xpEarned.value = _conversationXp + bonus;
      } catch (_) {
        // Non-fatal — show success anyway, with conversation XP only
      }
    }

    isSubmitting.value = false;
    isSubmitted.value  = true;
  }

  void goHome() => Get.offAllNamed(Routes.home);

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get durationLabel {
    final m = callDuration ~/ 60;
    final s = callDuration % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  String get callTypeIcon => callType == 'video' ? '📹' : '📞';
}
