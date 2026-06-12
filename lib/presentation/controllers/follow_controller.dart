import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/routes.dart';
import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/follows_api.dart';
import '../../data/datasources/remote/user_api.dart';
import '../../data/models/follow_model.dart';
import '../../data/repositories/follows_repository.dart';
import '../../data/repositories/user_repository.dart';

/// Drives the "Find People" flow: searching the user directory, viewing a
/// public profile, and sending/accepting follow requests so two users can
/// connect and message each other through the existing conversation system.
class FollowController extends GetxController {
  static FollowController get to => Get.find();

  late final FollowsRepository _followsRepo;
  late final UserRepository _userRepo;

  // ─── Search ───────────────────────────────────────────────────────────────
  final searchQuery = ''.obs;
  final searchResults = <UserSearchResult>[].obs;
  final isSearching = false.obs;
  final searchError = Rx<String?>(null);
  Timer? _debounce;

  // ─── Public profile ───────────────────────────────────────────────────────
  final viewedProfile = Rx<PublicProfileModel?>(null);
  final isLoadingProfile = false.obs;
  final profileError = Rx<String?>(null);

  // ─── Pending requests (incoming/outgoing) ────────────────────────────────
  final incomingRequests = <FollowRequestModel>[].obs;
  final outgoingRequests = <FollowRequestModel>[].obs;
  final isLoadingRequests = false.obs;

  // ─── My connections (followers/following on the own profile) ─────────────
  final myFollowers = <UserSummary>[].obs;
  final myFollowing = <UserSummary>[].obs;
  final isLoadingConnections = false.obs;

  // Per-action loading flags, keyed by the relevant id (userId or requestId)
  final actionInProgress = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _followsRepo = FollowsRepository(FollowsApi(ApiClient.instance));
    _userRepo = UserRepository(UserApi(ApiClient.instance), StorageService.instance);
    loadMyConnections();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // ─── Search users ─────────────────────────────────────────────────────────

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final term = query.trim();
    if (term.isEmpty) {
      searchResults.clear();
      searchError.value = null;
      return;
    }

    isSearching.value = true;
    searchError.value = null;
    try {
      searchResults.value = await _userRepo.searchUsers(term);
    } catch (e) {
      searchError.value = ApiClient.parseError(e);
    } finally {
      isSearching.value = false;
    }
  }

  // ─── Public profile ───────────────────────────────────────────────────────

  Future<void> openProfile(int userId) async {
    viewedProfile.value = null;
    profileError.value = null;
    isLoadingProfile.value = true;
    Get.toNamed(Routes.userProfile, arguments: {'user_id': userId});
    try {
      viewedProfile.value = await _userRepo.getPublicProfile(userId);
    } catch (e) {
      profileError.value = ApiClient.parseError(e);
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> reloadProfile(int userId) async {
    profileError.value = null;
    try {
      viewedProfile.value = await _userRepo.getPublicProfile(userId);
    } catch (e) {
      profileError.value = ApiClient.parseError(e);
    }
  }

  // ─── Follow actions ───────────────────────────────────────────────────────

  Future<void> sendFollowRequest(int userId) => _runAction(userId, () async {
        final request = await _followsRepo.sendRequest(userId);
        final autoAccepted = request.status == 'accepted';
        _patchRelationship(userId, autoAccepted ? RelationshipStatus.following : RelationshipStatus.requestSent);
        if (autoAccepted) loadMyConnections();
        _toast('Request sent', 'Your follow request was sent.');
      });

  Future<void> cancelOutgoingRequest(int userId, int requestId) =>
      _runAction(userId, () async {
        await _followsRepo.cancelRequest(requestId);
        _patchRelationship(userId, RelationshipStatus.none);
        outgoingRequests.removeWhere((r) => r.requestId == requestId);
        _toast('Request cancelled', 'Your follow request was withdrawn.');
      });

  Future<void> unfollow(int userId) => _runAction(userId, () async {
        await _followsRepo.unfollow(userId);
        _patchRelationship(userId, RelationshipStatus.none);
        myFollowing.removeWhere((u) => u.id == userId);
        _toast('Unfollowed', 'You no longer follow this user.');
      });

  /// Accepts an incoming request and opens the conversation that was
  /// created/reused so the two users can start chatting immediately.
  Future<void> acceptRequest(int requestId, {int? fromUserId, String? partnerName}) =>
      _runAction(requestId, () async {
        final conversationId = await _followsRepo.acceptRequest(requestId);
        incomingRequests.removeWhere((r) => r.requestId == requestId);
        if (fromUserId != null) {
          _patchRelationship(fromUserId, RelationshipStatus.following);
        }
        loadMyConnections();
        _toast('Request accepted', 'You can now message ${partnerName ?? 'each other'}.');
        Get.toNamed(Routes.conversationDetail, arguments: {
          'id': conversationId,
          'partner_name': partnerName ?? 'Partner',
          'partner_id': fromUserId,
        });
      });

  Future<void> declineRequest(int requestId) => _runAction(requestId, () async {
        await _followsRepo.declineRequest(requestId);
        incomingRequests.removeWhere((r) => r.requestId == requestId);
        _toast('Request declined', 'The follow request was declined.');
      });

  // ─── Pending requests lists ───────────────────────────────────────────────

  Future<void> loadRequests() async {
    isLoadingRequests.value = true;
    try {
      final results = await Future.wait([
        _followsRepo.getIncomingRequests(),
        _followsRepo.getOutgoingRequests(),
      ]);
      incomingRequests.value = results[0];
      outgoingRequests.value = results[1];
    } catch (_) {
      // Non-fatal — surfaced lists simply stay empty
    } finally {
      isLoadingRequests.value = false;
    }
  }

  // ─── My connections (followers/following) ────────────────────────────────

  /// Loads the signed-in user's followers and following lists, used to show
  /// counts on the profile header and populate the connections screen.
  Future<void> loadMyConnections() async {
    isLoadingConnections.value = true;
    try {
      final results = await Future.wait([
        _followsRepo.getMyFollowers(),
        _followsRepo.getMyFollowing(),
      ]);
      myFollowers.value = results[0];
      myFollowing.value = results[1];
    } catch (_) {
      // Non-fatal — counts simply stay at their last known values
    } finally {
      isLoadingConnections.value = false;
    }
  }

  // ─── Internals ────────────────────────────────────────────────────────────

  bool isBusy(int id) => actionInProgress.contains(id);

  Future<void> _runAction(int id, Future<void> Function() action) async {
    if (actionInProgress.contains(id)) return;
    actionInProgress.add(id);
    try {
      await action();
    } catch (e) {
      _toast('Something went wrong', ApiClient.parseError(e), isError: true);
    } finally {
      actionInProgress.remove(id);
    }
  }

  void _patchRelationship(int userId, RelationshipStatus status) {
    final profile = viewedProfile.value;
    if (profile != null && profile.id == userId) {
      viewedProfile.value = PublicProfileModel(
        id: profile.id,
        name: profile.name,
        username: profile.username,
        profilePicture: profile.profilePicture,
        age: profile.age,
        nativeLanguage: profile.nativeLanguage,
        interests: profile.interests,
        learningLanguages: profile.learningLanguages,
        followersCount: status == RelationshipStatus.following
            ? profile.followersCount + (profile.relationship == RelationshipStatus.following ? 0 : 1)
            : (profile.relationship == RelationshipStatus.following && status == RelationshipStatus.none
                ? (profile.followersCount - 1).clamp(0, 1 << 30)
                : profile.followersCount),
        followingCount: profile.followingCount,
        score: profile.score,
        rank: profile.rank,
        relationship: status,
        followRequestId: status == RelationshipStatus.none ? null : profile.followRequestId,
      );
    }

    final index = searchResults.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final current = searchResults[index];
      searchResults[index] = UserSearchResult(
        id: current.id,
        name: current.name,
        username: current.username,
        profilePicture: current.profilePicture,
        nativeLanguage: current.nativeLanguage,
        relationshipStatus: status,
      );
    }
  }

  void _toast(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: isError ? null : null,
    );
  }
}
