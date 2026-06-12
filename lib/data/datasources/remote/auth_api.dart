import '../../../data/models/user_model.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  // POST /auth/login
  // Body: { email?, username?, password }
  // Response: { accessToken, refreshToken, userId }
  Future<AuthResponse> login({
    String? email,
    String? username,
    required String password,
  }) async {
    final body = <String, dynamic>{'password': password};
    if (email != null) body['email'] = email;
    if (username != null) body['username'] = username;
    final res = await _client.post('/auth/login', data: body);
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /auth/signup
  Future<AuthResponse> signup(Map<String, dynamic> body) async {
    final res = await _client.post('/auth/signup', data: body);
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /auth/google — idToken from google_sign_in
  Future<AuthResponse> googleLogin(String idToken) async {
    final res = await _client.post('/auth/google', data: {'idToken': idToken});
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /auth/forgot-password
  Future<String> forgotPassword(String email) async {
    final res = await _client.post('/auth/forgot-password', data: {'email': email});
    return (res.data['message'] as String?) ?? 'Reset email sent';
  }

  // PUT /auth/reset-password
  Future<String> resetPassword({
    required String newPassword,
    required String code,
  }) async {
    final res = await _client.put('/auth/reset-password', data: {
      'newPassword': newPassword,
      'codenumber': int.tryParse(code) ?? code,
    });
    return (res.data['message'] as String?) ?? 'Password reset successfully';
  }

  // POST /auth/refresh
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final res = await _client.post('/auth/refresh', data: {'token': refreshToken});
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /user/:id  — fetch full user object after login
  Future<UserModel> getUserById(int id) async {
    final res = await _client.get('/user/$id');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /interests  — for signup step 6
  Future<List<Map<String, dynamic>>> getInterests() async {
    final res = await _client.get('/interests');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  // GET /languages  — for signup steps 4 & 5
  Future<List<Map<String, dynamic>>> getLanguages() async {
    final res = await _client.get('/languages');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  // POST /auth/resend-verification
  Future<void> resendVerification(String email) async {
    await _client.post('/auth/resend-verification', data: {'email': email});
  }

  // GET /auth/check-verification-status
  Future<bool> checkVerificationStatus(String email) async {
    final res = await _client.get('/auth/check-verification-status',
        queryParameters: {'email': email});
    return (res.data['email_verified'] as bool?) ?? false;
  }
}
