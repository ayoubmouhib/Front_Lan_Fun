import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/routes.dart';
import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/user_api.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  // ─── State ────────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isSaving  = false.obs;
  final isUploadingAvatar = false.obs;
  final isAddingLanguage = false.obs;
  final errorMessage = Rx<String?>(null);

  final user = Rx<UserModel?>(null);

  // All interests from API (for edit screen)
  final allInterests = <Map<String, dynamic>>[].obs;
  // User's selected interest IDs
  final selectedInterestIds = <int>{}.obs;

  // All languages from API (for "add a language to learn")
  final allLanguages = <LanguageModel>[].obs;

  // Local-only profile fields (stored in SharedPreferences until backend adds them)
  final bio       = ''.obs;
  final location  = ''.obs;

  late final UserRepository _repo;

  @override
  void onInit() {
    super.onInit();
    _repo = UserRepository(UserApi(ApiClient.instance), StorageService.instance);
    _loadProfile();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    isLoading.value = true;
    try {
      // 1. Load cached user first for instant display
      user.value = await StorageService.instance.getCachedUser();

      // 2. Fetch fresh data from API
      final userId = await StorageService.instance.getUserId();
      if (userId != null) {
        final fresh = await _repo.getProfile(userId);
        user.value = fresh;
        await StorageService.instance.saveUser(fresh);
      }

      // 3. Load all interests for edit screen
      final interests = await _repo.getAllInterests();
      allInterests.assignAll(interests);

      // 4. Build selected IDs from user's interests
      selectedInterestIds.assignAll(
        (user.value?.interests ?? []).map((i) => i.id).toSet(),
      );

      // 5. Load all languages (for "add a language to learn")
      final languages = await _repo.getLanguages();
      allLanguages.assignAll(languages.map(LanguageModel.fromJson));

      // 6. Load local prefs
      await _loadLocalPrefs();
    } catch (_) {
      // Non-fatal — cached data is sufficient
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    bio.value      = prefs.getString('profile_bio')      ?? '';
    location.value = prefs.getString('profile_location') ?? '';
  }

  @override
  Future<void> refresh() => _loadProfile();

  // ─── Save profile ─────────────────────────────────────────────────────────

  Future<bool> saveProfile({
    required String firstName,
    required String lastName,
    int? age,
    String? bioText,
    String? locationText,
    List<int>? interestIds,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;

    try {
      final userId = user.value?.id;
      if (userId == null) throw Exception('User not found');

      // Update API fields that are available
      final body = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
      };
      if (age != null) body['age'] = age;
      final updated = await _repo.updateProfile(userId, body);
      user.value = updated;
      await StorageService.instance.saveUser(updated);

      // Update interests if changed
      if (interestIds != null) {
        await _repo.updateInterests(interestIds);
        selectedInterestIds.assignAll(interestIds.toSet());
      }

      // Save local-only fields to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (bioText != null) {
        await prefs.setString('profile_bio', bioText);
        bio.value = bioText;
      }
      if (locationText != null) {
        await prefs.setString('profile_location', locationText);
        location.value = locationText;
      }

      return true;
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Avatar upload ────────────────────────────────────────────────────────

  Future<void> pickAndUploadAvatar() async {
    final userId = user.value?.id;
    if (userId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    isUploadingAvatar.value = true;
    errorMessage.value = null;
    try {
      final updated = await _repo.uploadProfilePicture(userId, picked.path);
      user.value = updated;
      Get.snackbar(
        'Success',
        'Profile picture updated',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Upload failed',
        ApiClient.parseError(e),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  // ─── Languages ────────────────────────────────────────────────────────────

  /// Languages the user is not yet learning — candidates for "Add a language".
  List<LanguageModel> get languagesAvailableToAdd {
    final learningIds = (user.value?.languages ?? []).map((l) => l.languageId).toSet();
    return allLanguages.where((l) => !learningIds.contains(l.id)).toList();
  }

  Future<bool> addLanguage(int languageId, String level) async {
    final userId = user.value?.id;
    if (userId == null) return false;

    isAddingLanguage.value = true;
    try {
      final updated = await _repo.addLanguage(userId, languageId, level);
      user.value = updated;
      return true;
    } catch (e) {
      Get.snackbar(
        'Could not add language',
        ApiClient.parseError(e),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isAddingLanguage.value = false;
    }
  }

  // ─── Change password ──────────────────────────────────────────────────────

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    try {
      await _repo.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Interests toggle (for edit screen) ────────────────────────────────────

  void toggleInterest(int id) {
    if (selectedInterestIds.contains(id)) {
      selectedInterestIds.remove(id);
    } else {
      selectedInterestIds.add(id);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String get fullName => user.value?.fullName ?? '';
  String get email    => user.value?.email ?? '';
  String get username => user.value?.username ?? '';
  int?   get age      => user.value?.age;

  String languageLevelLabel(String level) => switch (level) {
        'beginner'     => 'Beginner',
        'intermediate' => 'Intermediate',
        'advanced'     => 'Advanced',
        _              => level,
      };

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await Get.find<AuthController>().logout();
    } catch (_) {
      await StorageService.instance.clearAll();
      Get.offAllNamed(Routes.login);
    }
  }

  // ─── Delete account ───────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    final userId = user.value?.id;
    if (userId == null) return;
    try {
      await _repo.deleteAccount(userId); // also clears storage internally
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        ApiClient.parseError(e),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
