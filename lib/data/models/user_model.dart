import '../../config/constants.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.age,
    this.profilePicture,
    this.preferredLanguageId,
    this.emailVerified = false,
    this.isActive = true,
    this.createdAt,
    this.interests = const [],
    this.languages = const [],
  });

  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final int? age;
  final String? profilePicture;
  final int? preferredLanguageId;
  final bool emailVerified;
  final bool isActive;
  final DateTime? createdAt;
  final List<InterestModel> interests;
  final List<UserLanguageModel> languages;

  String get fullName => '$firstName $lastName';

  /// Absolute URL for the uploaded profile picture, or null if none is set.
  String? get profilePictureUrl => (profilePicture == null || profilePicture!.isEmpty)
      ? null
      : '${AppConstants.apiBaseUrl}/uploads/profile-pictures/$profilePicture';

  List<UserLanguageModel> get learningLanguages =>
      languages.where((l) => l.userType == 'learning').toList();

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as int,
        firstName: j['first_name'] as String? ?? '',
        lastName: j['last_name'] as String? ?? '',
        username: j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        age: j['age'] as int?,
        profilePicture: j['profile_picture'] as String?,
        preferredLanguageId: j['preferred_language_id'] as int?,
        emailVerified: j['email_verified'] as bool? ?? false,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        interests: (j['interests'] as List<dynamic>?)
                ?.map((e) => InterestModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        languages: (() {
          final old = j['userLanguages'] as List<dynamic>?;
          if (old != null && old.isNotEmpty) {
            return old
                .map((e) => UserLanguageModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          // Fall back to the newer languageProgress table
          final progress = j['languageProgress'] as List<dynamic>?;
          return progress
                  ?.map((e) => UserLanguageModel.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
        })(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'age': age,
        'profile_picture': profilePicture,
        'preferred_language_id': preferredLanguageId,
        'email_verified': emailVerified,
        'is_active': isActive,
        // Store under 'languageProgress' so fromJson can re-parse them from cache
        'languageProgress': languages.map((l) => l.toJson()).toList(),
        'interests': interests.map((i) => i.toJson()).toList(),
      };
}

class InterestModel {
  const InterestModel({required this.id, required this.name, this.icon});
  final int id;
  final String name;
  final String? icon;

  factory InterestModel.fromJson(Map<String, dynamic> j) => InterestModel(
        id: j['id'] as int,
        name: j['name'] as String,
        icon: j['icon'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
      };
}

class UserLanguageModel {
  const UserLanguageModel({
    required this.id,
    required this.languageId,
    required this.level,
    this.userType = 'learning',
    this.language,
  });

  final int id;
  final int languageId;
  final String level;    // 'beginner' | 'intermediate' | 'advanced'
  final String userType; // 'learning' | 'native' | 'fluent'
  final LanguageModel? language;

  factory UserLanguageModel.fromJson(Map<String, dynamic> j) =>
      UserLanguageModel(
        id: j['id'] as int,
        languageId: j['language_id'] as int,
        // userLanguages uses 'proficiency_level'; languageProgress uses 'initial_level'
        level: (j['proficiency_level'] ?? j['initial_level']) as String? ?? 'beginner',
        userType: j['user_type'] as String? ?? 'learning',
        language: j['language'] != null
            ? LanguageModel.fromJson(j['language'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'language_id': languageId,
        'initial_level': level,
        'user_type': userType,
        if (language != null) 'language': language!.toJson(),
      };
}

class LanguageModel {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.isoCode,
    this.nativeName,
  });

  final int id;
  final String name;
  final String isoCode;
  final String? nativeName;

  factory LanguageModel.fromJson(Map<String, dynamic> j) => LanguageModel(
        id: j['id'] as int,
        name: j['name'] as String,
        isoCode: j['iso_code'] as String,
        nativeName: j['native_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iso_code': isoCode,
        'native_name': nativeName,
      };
}

// ─── Auth response ───────────────────────────────────────────────────────────

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int userId;
  final UserModel? user;

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        accessToken: j['accessToken'] as String? ?? j['access_token'] as String? ?? '',
        refreshToken: j['refreshToken'] as String? ?? j['refresh_token'] as String? ?? '',
        userId: (j['userId'] ?? j['user']?['id'] ?? 0) as int,
        user: j['user'] != null
            ? UserModel.fromJson(j['user'] as Map<String, dynamic>)
            : null,
      );
}
