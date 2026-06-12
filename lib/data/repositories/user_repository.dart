import '../datasources/local/storage_service.dart';
import '../datasources/remote/user_api.dart';
import '../models/follow_model.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository(this._api, this._storage);

  final UserApi _api;
  final StorageService _storage;

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<UserModel> getProfile(int userId) => _api.getUserById(userId);

  Future<UserModel> updateProfile(int userId, Map<String, dynamic> fields) async {
    final updated = await _api.updateUser(userId, fields);
    await _storage.saveUser(updated);
    return updated;
  }

  Future<UserModel> uploadProfilePicture(int userId, String filePath) async {
    final updated = await _api.uploadProfilePicture(userId, filePath);
    await _storage.saveUser(updated);
    return updated;
  }

  // ─── Interests ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllInterests() =>
      _api.getAllInterests();

  Future<List<Map<String, dynamic>>> getMyInterests() =>
      _api.getMyInterests();

  Future<void> updateInterests(List<int> interestIds) =>
      _api.updateInterests(interestIds);

  // ─── Languages ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLanguages() =>
      _api.getLanguages();

  Future<UserModel> addLanguage(int userId, int languageId, String level) async {
    final updated = await _api.addLanguage(userId, languageId, level);
    await _storage.saveUser(updated);
    return updated;
  }

  // ─── Password ─────────────────────────────────────────────────────────────

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _api.changePassword(oldPassword: oldPassword, newPassword: newPassword);

  // ─── Account ──────────────────────────────────────────────────────────────

  Future<void> deleteAccount(int userId) async {
    await _api.deleteAccount(userId);
    await _storage.clearAll();
  }

  // ─── Find people ──────────────────────────────────────────────────────────

  Future<List<UserSearchResult>> searchUsers(String query) => _api.searchUsers(query);

  Future<PublicProfileModel> getPublicProfile(int userId) => _api.getPublicProfile(userId);
}
