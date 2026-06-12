import 'package:dio/dio.dart';

import '../../models/follow_model.dart';
import '../../models/quiz_model.dart';
import '../../models/user_model.dart';
import 'api_client.dart';

class UserApi {
  UserApi(this._client);
  final ApiClient _client;

  // GET /user/:id
  Future<UserModel> getUserById(int id) async {
    final res = await _client.get('/user/$id');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  // PATCH /user/:id — update mutable profile fields
  Future<UserModel> updateUser(int id, Map<String, dynamic> fields) async {
    final res = await _client.patch('/user/$id', data: fields);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /user/:id/profile-picture — multipart image upload
  Future<UserModel> uploadProfilePicture(int id, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _client.post('/user/$id/profile-picture', data: formData);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  // PUT /interests/my-interests
  Future<void> updateInterests(List<int> interestIds) async {
    await _client.put('/interests/my-interests', data: {'interest_ids': interestIds});
  }

  // GET /interests/my-interests
  Future<List<Map<String, dynamic>>> getMyInterests() async {
    final res = await _client.get('/interests/my-interests');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  // GET /interests — all available interests
  Future<List<Map<String, dynamic>>> getAllInterests() async {
    final res = await _client.get('/interests');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  // GET /languages
  Future<List<Map<String, dynamic>>> getLanguages() async {
    final res = await _client.get('/languages');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  // POST /user/:id/languages — add a new language to learn
  Future<UserModel> addLanguage(int id, int languageId, String level) async {
    final res = await _client.post('/user/$id/languages', data: {
      'language_id': languageId,
      'level': level,
    });
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  // PUT /auth/change-Password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.put('/auth/change-Password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  // DELETE /user/:id — delete account
  Future<void> deleteAccount(int id) async {
    await _client.delete('/user/$id');
  }

  // GET /user/leaderboard?period=week|month|all&category=xp|streak|conversations
  Future<({List<LeaderboardEntry> entries, int? currentUserRank})> getLeaderboard({
    required String period,
    required String category,
  }) async {
    final res = await _client.get(
      '/user/leaderboard',
      queryParameters: {'period': period, 'category': category},
    );
    final data = res.data as Map<String, dynamic>;
    final entries = (data['entries'] as List<dynamic>)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final rank = (data['currentUserRank'] as num?)?.toInt();
    return (entries: entries, currentUserRank: rank);
  }

  // GET /user/search?q=<query> — find people by username / name
  Future<List<UserSearchResult>> searchUsers(String query) async {
    final res = await _client.get('/user/search', queryParameters: {'q': query});
    return (res.data as List<dynamic>)
        .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /user/:id/public-profile — followers/following, score, rank, relationship
  Future<PublicProfileModel> getPublicProfile(int id) async {
    final res = await _client.get('/user/$id/public-profile');
    return PublicProfileModel.fromJson(res.data as Map<String, dynamic>);
  }
}
