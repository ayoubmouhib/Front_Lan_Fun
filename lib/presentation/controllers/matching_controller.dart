import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/matching_api.dart';
import '../../data/models/match_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/matching_repository.dart';
import '../../services/websocket_service.dart';

// Search UI states
enum SearchState { idle, searching, matched, expired, error }

class MatchingController extends GetxController {
  static MatchingController get to => Get.find();

  // ─── State ────────────────────────────────────────────────────────────────
  final searchState = SearchState.idle.obs;
  final isLoading = false.obs;

  // Language selection for the search
  final selectedLanguageId = Rx<int?>(null);
  final selectedLanguageName = ''.obs;
  // Languages the user is learning — only these are offered in the picker
  final myLanguages = <UserLanguageModel>[].obs;

  // Active search ticket
  int? _activeRequestId;
  int? _matchedSessionId;
  final matchedUser = Rx<MatchedUser?>(null);
  final compatibilityScore = Rx<double?>(null);

  // Polling timer & elapsed
  Timer? _pollTimer;
  final elapsedSeconds = 0.obs;
  Timer? _elapsedTimer;
  final searchTimeoutIn = Rx<int?>(null);

  // Pending requests (for Discover)
  final pendingRequests = <MatchRequest>[].obs;

  // Error message
  final errorMessage = Rx<String?>(null);

  late final MatchingRepository _repo;
  StreamSubscription<WsSessionEvent>? _sessionSub;

  @override
  void onInit() {
    super.onInit();
    _repo = MatchingRepository(MatchingApi(ApiClient.instance));
    _loadInitialLanguage();
    _loadPendingRequests();
    _subscribeToSessionEvents();
  }

  void _subscribeToSessionEvents() {
    try {
      _sessionSub = WebSocketService.to.sessionEventStream.listen((event) {
        if (event.eventType == 'session_accepted') {
          _navigateToPracticeSession(
            sessionId: event.sessionId,
            plannedDurationMinutes: event.plannedDurationMinutes ?? 10,
            partnerName: event.partnerName ?? 'Partner',
            partnerId: event.partnerId ?? 0,
            sessionType: event.sessionType ?? 'text',
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _loadInitialLanguage() async {
    final user = await StorageService.instance.getCachedUser();
    if (user == null) return;
    // Only offer the languages the user is actually learning
    final candidates = user.learningLanguages.isNotEmpty
        ? user.learningLanguages
        : user.languages;
    myLanguages.value = candidates;
    if (selectedLanguageId.value != null || candidates.isEmpty) return;
    final lang = candidates.first;
    selectedLanguageId.value = lang.languageId;
    selectedLanguageName.value =
        lang.language?.name ?? 'Language ${lang.languageId}';
  }

  @override
  void onClose() {
    _sessionSub?.cancel();
    _stopPolling();
    super.onClose();
  }

  // ─── Language selection ───────────────────────────────────────────────────

  void selectLanguage(int id, String name) {
    selectedLanguageId.value = id;
    selectedLanguageName.value = name;
    errorMessage.value = null;
  }

  // ─── CASE 0 — Start active search ────────────────────────────────────────

  Future<void> startActiveSearch() async {
    final langId = selectedLanguageId.value;
    if (langId == null) {
      errorMessage.value = 'Please select the language you want to practice';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _repo.initiateActiveSearch(
        languageId: langId,
        timeoutSeconds: AppConstants.activeSearchTimeout.inSeconds,
      );

      if (response.isMatched) {
        // Instant match!
        _handleMatch(
          sessionId: response.sessionId,
          user: response.matchedUser,
          score: response.compatibilityScore,
        );
      } else {
        // Entered search pool — start polling
        _activeRequestId = response.requestId;
        searchTimeoutIn.value = response.searchTimeoutIn;
        searchState.value = SearchState.searching;
        _startElapsedTimer();
        _startPolling();
      }
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
      searchState.value = SearchState.error;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Polling ─────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    final reqId = _activeRequestId;
    if (reqId == null) return;

    try {
      final status = await _repo.getSearchStatus(reqId);

      if (status.isMatched) {
        _handleMatch(
          sessionId: status.sessionId,
          user: status.matchedUser,
          score: null,
        );
      } else if (status.isExpired) {
        _stopPolling();
        searchState.value = SearchState.expired;
        errorMessage.value = status.message ?? 'Search timed out. Please try again.';
      } else {
        searchTimeoutIn.value = status.searchTimeoutIn;
      }
    } catch (_) {
      // Non-fatal — retry on next tick
    }
  }

  void _handleMatch({
    int? sessionId,
    MatchedUser? user,
    double? score,
  }) {
    _stopPolling();
    _matchedSessionId = sessionId;
    matchedUser.value = user;
    compatibilityScore.value = score;
    searchState.value = SearchState.matched;
  }

  void _startElapsedTimer() {
    elapsedSeconds.value = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  // ─── Cancel search ────────────────────────────────────────────────────────

  Future<void> cancelSearch() async {
    _stopPolling();
    final reqId = _activeRequestId;
    if (reqId != null) {
      try {
        await _repo.cancelSearch(reqId);
      } catch (_) {}
    }
    _reset();
  }

  void _reset() {
    _activeRequestId = null;
    matchedUser.value = null;
    compatibilityScore.value = null;
    elapsedSeconds.value = 0;
    searchTimeoutIn.value = null;
    searchState.value = SearchState.idle;
    errorMessage.value = null;
  }

  // ─── Navigate to practice session after match ─────────────────────────────

  Future<void> startChatting() async {
    final duration = await _showDurationPicker();
    if (duration == null) return;

    final sessionId = _matchedSessionId;
    final user = matchedUser.value;
    _reset();

    if (sessionId != null) {
      _navigateToPracticeSession(
        sessionId: sessionId,
        plannedDurationMinutes: duration,
        partnerName: user?.name ?? 'Partner',
        partnerId: user?.id ?? 0,
        sessionType: 'text',
      );
    } else {
      Get.toNamed(Routes.conversationsList);
    }
  }

  void viewMatchedProfile() {
    final user = matchedUser.value;
    if (user == null) return;
    Get.toNamed(Routes.partnerProfile, arguments: {
      'user_id': user.id,
      'user_name': user.name,
    });
  }

  void dismissMatch() => _reset();

  // ─── Discover — pending requests ─────────────────────────────────────────

  Future<void> _loadPendingRequests() => refreshPendingRequests();

  Future<void> refreshPendingRequests() async {
    try {
      final list = await _repo.getPendingRequests();
      pendingRequests.assignAll(list);
    } catch (_) {}
  }

  Future<void> acceptPendingRequest(int requestId) async {
    final duration = await _showDurationPicker();
    if (duration == null) return;

    MatchRequest? request;
    try {
      request = pendingRequests.firstWhere((r) => r.requestId == requestId);
    } catch (_) {}

    try {
      final result = await _repo.acceptRequest(
        requestId,
        plannedDurationMinutes: duration,
      );
      pendingRequests.removeWhere((r) => r.requestId == requestId);

      final sessionId = result['session_id'] as int?;
      if (sessionId != null) {
        Get.back(); // close the pending-requests sheet
        _navigateToPracticeSession(
          sessionId: sessionId,
          plannedDurationMinutes: duration,
          partnerName: request?.requester.name ?? 'Partner',
          partnerId: request?.requester.id ?? 0,
          sessionType: 'text',
        );
      }
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  Future<void> rejectPendingRequest(int requestId) async {
    try {
      await _repo.rejectRequest(requestId);
      pendingRequests.removeWhere((r) => r.requestId == requestId);
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  Future<void> cancelSentRequest(int requestId) async {
    try {
      await _repo.cancelRequest(requestId);
      pendingRequests.removeWhere((r) => r.requestId == requestId);
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    }
  }

  // ─── Duration picker ──────────────────────────────────────────────────────

  Future<int?> _showDurationPicker() async {
    int? selected;
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'How long to practice?',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 20, 30].map((min) {
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: Text(
                '$min minutes',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () {
                selected = min;
                Get.back();
              },
            );
          }).toList(),
        ),
      ),
      barrierDismissible: true,
    );
    return selected;
  }

  void _navigateToPracticeSession({
    required int sessionId,
    required int plannedDurationMinutes,
    required String partnerName,
    required int partnerId,
    required String sessionType,
  }) {
    Get.toNamed(Routes.practiceSession, arguments: {
      'session_id':              sessionId,
      'planned_duration_minutes': plannedDurationMinutes,
      'partner_name':             partnerName,
      'partner_id':               partnerId,
      'session_type':             sessionType,
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get elapsedLabel {
    final s = elapsedSeconds.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String get timeoutLabel {
    final t = searchTimeoutIn.value;
    if (t == null) return '';
    final m = t ~/ 60;
    final s = t % 60;
    return '${m}m ${s}s remaining';
  }
}
