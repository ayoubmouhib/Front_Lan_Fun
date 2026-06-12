import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/auth_api.dart';
import '../../data/models/user_model.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final StorageService _storage;

  Future<UserModel> login({
    required String identifier, // email or username
    required String password,
  }) async {
    final isEmail = identifier.contains('@');
    final auth = await _api.login(
      email: isEmail ? identifier : null,
      username: isEmail ? null : identifier,
      password: password,
    );
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await _storage.saveUserId(auth.userId);
    final user = await _api.getUserById(auth.userId);
    await _storage.saveUser(user);
    return user;
  }

  Future<UserModel> signup(Map<String, dynamic> body) async {
    final auth = await _api.signup(body);
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await _storage.saveUserId(auth.userId);
    // Signup may return user inline; if not, fetch it
    final user = auth.user ?? await _api.getUserById(auth.userId);
    await _storage.saveUser(user);
    return user;
  }

  Future<UserModel> googleLogin(String idToken) async {
    final auth = await _api.googleLogin(idToken);
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await _storage.saveUserId(auth.userId);
    final user = auth.user ?? await _api.getUserById(auth.userId);
    await _storage.saveUser(user);
    return user;
  }

  Future<void> logout() => _storage.clearAll();

  Future<String> forgotPassword(String email) => _api.forgotPassword(email);

  Future<String> resetPassword({
    required String newPassword,
    required String code,
  }) =>
      _api.resetPassword(newPassword: newPassword, code: code);

  Future<List<Map<String, dynamic>>> getLanguages() => _api.getLanguages();

  Future<List<Map<String, dynamic>>> getInterests() => _api.getInterests();

  Future<bool> checkVerificationStatus(String email) =>
      _api.checkVerificationStatus(email);

  Future<void> resendVerificationEmail(String email) =>
      _api.resendVerification(email);
}
