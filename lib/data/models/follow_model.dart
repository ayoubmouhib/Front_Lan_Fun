import '../../config/constants.dart';
import 'user_model.dart';

/// Relationship between the signed-in user (viewer) and another profile.
enum RelationshipStatus {
  self,
  none,
  requestSent,
  requestReceived,
  following;

  static RelationshipStatus fromJson(String? value) {
    switch (value) {
      case 'self':
        return RelationshipStatus.self;
      case 'request_sent':
        return RelationshipStatus.requestSent;
      case 'request_received':
        return RelationshipStatus.requestReceived;
      case 'following':
        return RelationshipStatus.following;
      default:
        return RelationshipStatus.none;
    }
  }
}

/// Lightweight user reference used across follow lists, requests and search results.
class UserSummary {
  const UserSummary({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
  });

  final int id;
  final String name;
  final String username;
  final String? profilePicture;

  String? get profilePictureUrl => (profilePicture == null || profilePicture!.isEmpty)
      ? null
      : '${AppConstants.apiBaseUrl}/uploads/profile-pictures/$profilePicture';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
        id: j['id'] as int,
        name: (j['name'] as String?)?.trim().isNotEmpty == true
            ? (j['name'] as String).trim()
            : 'Unknown user',
        username: j['username'] as String? ?? '',
        profilePicture: j['profile_picture'] as String?,
      );
}

/// A pending follow request, either incoming or outgoing.
class FollowRequestModel {
  const FollowRequestModel({
    required this.requestId,
    required this.status,
    required this.createdAt,
    this.user,
  });

  final int requestId;
  final String status; // pending | accepted | declined | cancelled
  final DateTime createdAt;
  final UserSummary? user;

  factory FollowRequestModel.fromJson(Map<String, dynamic> j) => FollowRequestModel(
        requestId: j['request_id'] as int,
        status: j['status'] as String? ?? 'pending',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        user: j['user'] != null ? UserSummary.fromJson(j['user'] as Map<String, dynamic>) : null,
      );
}

/// A row in the "search users" results list.
class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.name,
    required this.username,
    required this.relationshipStatus,
    this.profilePicture,
    this.nativeLanguage,
  });

  final int id;
  final String name;
  final String username;
  final String? profilePicture;
  final LanguageModel? nativeLanguage;
  final RelationshipStatus relationshipStatus;

  String? get profilePictureUrl => (profilePicture == null || profilePicture!.isEmpty)
      ? null
      : '${AppConstants.apiBaseUrl}/uploads/profile-pictures/$profilePicture';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserSearchResult.fromJson(Map<String, dynamic> j) => UserSearchResult(
        id: j['id'] as int,
        name: (j['name'] as String?)?.trim().isNotEmpty == true
            ? (j['name'] as String).trim()
            : 'Unknown user',
        username: j['username'] as String? ?? '',
        profilePicture: j['profile_picture'] as String?,
        nativeLanguage: j['native_language'] != null
            ? LanguageModel.fromJson(j['native_language'] as Map<String, dynamic>)
            : null,
        relationshipStatus: RelationshipStatus.fromJson(j['relationship_status'] as String?),
      );
}

/// A learning-language entry shown on a public profile.
class PublicProfileLanguage {
  const PublicProfileLanguage({
    required this.languageId,
    required this.level,
    this.language,
    this.cefrLevel,
    this.xpPoints = 0,
  });

  final int languageId;
  final String level;
  final String? cefrLevel;
  final int xpPoints;
  final LanguageModel? language;

  factory PublicProfileLanguage.fromJson(Map<String, dynamic> j) => PublicProfileLanguage(
        languageId: j['language_id'] as int,
        level: j['level'] as String? ?? 'beginner',
        cefrLevel: j['cefr_level'] as String?,
        xpPoints: (j['xp_points'] as num?)?.toInt() ?? 0,
        language: j['language'] != null
            ? LanguageModel.fromJson(j['language'] as Map<String, dynamic>)
            : null,
      );
}

/// Full public profile shown when tapping a user from search results.
class PublicProfileModel {
  const PublicProfileModel({
    required this.id,
    required this.name,
    required this.username,
    required this.followersCount,
    required this.followingCount,
    required this.score,
    required this.relationship,
    this.profilePicture,
    this.age,
    this.nativeLanguage,
    this.interests = const [],
    this.learningLanguages = const [],
    this.rank,
    this.followRequestId,
  });

  final int id;
  final String name;
  final String username;
  final String? profilePicture;
  final int? age;
  final LanguageModel? nativeLanguage;
  final List<InterestModel> interests;
  final List<PublicProfileLanguage> learningLanguages;
  final int followersCount;
  final int followingCount;
  final int score;
  final int? rank;
  final RelationshipStatus relationship;
  final int? followRequestId;

  String? get profilePictureUrl => (profilePicture == null || profilePicture!.isEmpty)
      ? null
      : '${AppConstants.apiBaseUrl}/uploads/profile-pictures/$profilePicture';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory PublicProfileModel.fromJson(Map<String, dynamic> j) => PublicProfileModel(
        id: j['id'] as int,
        name: (j['name'] as String?)?.trim().isNotEmpty == true
            ? (j['name'] as String).trim()
            : 'Unknown user',
        username: j['username'] as String? ?? '',
        profilePicture: j['profile_picture'] as String?,
        age: j['age'] as int?,
        nativeLanguage: j['native_language'] != null
            ? LanguageModel.fromJson(j['native_language'] as Map<String, dynamic>)
            : null,
        interests: (j['interests'] as List<dynamic>?)
                ?.map((e) => InterestModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        learningLanguages: (j['learning_languages'] as List<dynamic>?)
                ?.map((e) => PublicProfileLanguage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        followersCount: (j['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (j['following_count'] as num?)?.toInt() ?? 0,
        score: (j['score'] as num?)?.toInt() ?? 0,
        rank: (j['rank'] as num?)?.toInt(),
        relationship: RelationshipStatus.fromJson(j['relationship'] as String?),
        followRequestId: (j['follow_request_id'] as num?)?.toInt(),
      );
}
