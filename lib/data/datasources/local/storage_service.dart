import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants.dart';
import '../../models/user_model.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Tokens (secure) ──────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secure.write(key: AppConstants.keyAccessToken, value: accessToken),
      _secure.write(key: AppConstants.keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _secure.read(key: AppConstants.keyAccessToken);

  Future<String?> getRefreshToken() =>
      _secure.read(key: AppConstants.keyRefreshToken);

  Future<void> clearTokens() async {
    await Future.wait([
      _secure.delete(key: AppConstants.keyAccessToken),
      _secure.delete(key: AppConstants.keyRefreshToken),
    ]);
  }

  // ─── User info (preferences) ──────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(AppConstants.keyUserId, user.id),
      prefs.setString(AppConstants.keyUserEmail, user.email),
      prefs.setString(AppConstants.keyUsername, user.username),
      prefs.setString('cached_user', jsonEncode(user.toJson())),
    ]);
  }

  Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyUserId, id);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyUserId);
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cached_user');
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─── Theme ────────────────────────────────────────────────────────────────

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyThemeMode);
  }

  // ─── Onboarding ───────────────────────────────────────────────────────────

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
  }

  // ─── Quiz pending ─────────────────────────────────────────────────────────

  Future<void> setQuizPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyQuizPending, value);
  }

  Future<bool> isQuizPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyQuizPending) ?? false;
  }

  // ─── Clear all ────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      clearTokens(),
      prefs.clear(),
    ]);
  }
}
