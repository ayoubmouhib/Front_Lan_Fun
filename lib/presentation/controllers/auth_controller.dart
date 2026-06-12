import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/routes.dart';
import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/auth_api.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // ─── Observables ──────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final errorMessage = Rx<String?>(null);
  final currentUser = Rx<UserModel?>(null);

  // ─── Signup form state (shared across steps) ──────────────────────────────
  final signupData = <String, dynamic>{}.obs;
  final signupStep = 0.obs;

  // Remote data for signup dropdowns
  final languages = <Map<String, dynamic>>[].obs;
  final interests = <Map<String, dynamic>>[].obs;

  late final AuthRepository _repo;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void onInit() {
    super.onInit();
    _repo = AuthRepository(
      AuthApi(ApiClient.instance),
      StorageService.instance,
    );
    _loadRemoteData();
  }

  Future<void> _loadRemoteData() async {
    try {
      final results = await Future.wait([
        _repo.getLanguages(),
        _repo.getInterests(),
      ]);
      languages.assignAll(results[0]);
      interests.assignAll(results[1]);
    } catch (_) {
      // Non-fatal — falls back to AppConstants lists
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final user = await _repo.login(identifier: identifier, password: password);
      currentUser.value = user;
      Get.offAllNamed(Routes.home);
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Google Login ─────────────────────────────────────────────────────────

  Future<void> loginWithGoogle() async {
    isGoogleLoading.value = true;
    errorMessage.value = null;
    try {
      await _googleSignIn.signOut(); // ensure fresh picker
      final account = await _googleSignIn.signIn();
      if (account == null) return; // user cancelled

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google sign-in failed: no ID token');

      final user = await _repo.googleLogin(idToken);
      currentUser.value = user;
      Get.offAllNamed(Routes.home);
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // ─── Signup (multi-step) ──────────────────────────────────────────────────

  void updateSignupData(Map<String, dynamic> data) =>
      signupData.addAll(data);

  void nextSignupStep() => signupStep.value++;
  void prevSignupStep() {
    if (signupStep.value > 0) signupStep.value--;
  }

  Future<void> submitSignup() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final user = await _repo.signup(Map<String, dynamic>.from(signupData));
      currentUser.value = user;
      await StorageService.instance.setQuizPending(true);
      Get.offAllNamed(
        Routes.verifyEmail,
        arguments: {'email': user.email},
      );
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Email verification ───────────────────────────────────────────────────

  Future<bool> checkVerificationStatus(String email) =>
      _repo.checkVerificationStatus(email);

  Future<void> resendVerificationEmail(String email) =>
      _repo.resendVerificationEmail(email);

  // ─── Forgot password ──────────────────────────────────────────────────────

  Future<bool> forgotPassword(String email) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repo.forgotPassword(email);
      return true;
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String code,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repo.resetPassword(newPassword: newPassword, code: code);
      return true;
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await Future.wait([
      _repo.logout(),
      _googleSignIn.signOut(),
    ]);
    currentUser.value = null;
    Get.offAllNamed(Routes.login);
  }
}
