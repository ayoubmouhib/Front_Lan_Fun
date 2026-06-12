// ─── Active-search response ───────────────────────────────────────────────────
// POST /matching/request/active-search
// Returns either an instant match or a "searching" ticket.

class SearchResponse {
  const SearchResponse({
    required this.status,
    this.requestId,
    this.sessionId,
    this.matchedUser,
    this.matchedLanguageId,
    this.compatibilityScore,
    this.message,
    this.estimatedWait,
    this.searchTimeoutIn,
    this.canStartMessaging = false,
  });

  final String status; // 'matched' | 'searching'
  final int? requestId;
  final int? sessionId;
  final MatchedUser? matchedUser;
  final int? matchedLanguageId;
  final double? compatibilityScore;
  final String? message;
  final String? estimatedWait;
  final int? searchTimeoutIn; // seconds remaining
  final bool canStartMessaging;

  bool get isMatched => status == 'matched';
  bool get isSearching => status == 'searching';

  factory SearchResponse.fromJson(Map<String, dynamic> j) => SearchResponse(
        status: j['status'] as String? ?? 'searching',
        requestId: j['request_id'] as int?,
        sessionId: j['session_id'] as int?,
        matchedUser: j['matched_user'] != null
            ? MatchedUser.fromJson(j['matched_user'] as Map<String, dynamic>)
            : null,
        matchedLanguageId: j['matched_language_id'] as int?,
        compatibilityScore: double.tryParse(j['compatibility_score']?.toString() ?? ''),
        message: j['message'] as String?,
        estimatedWait: j['estimated_wait'] as String?,
        searchTimeoutIn: j['search_timeout_in'] as int?,
        canStartMessaging: j['can_start_messaging'] as bool? ?? false,
      );
}

// ─── Poll status response ─────────────────────────────────────────────────────
// GET /matching/search-status/:requestId

class SearchStatus {
  const SearchStatus({
    required this.status,
    required this.requestId,
    this.sessionId,
    this.matchedUser,
    this.message,
    this.searchTimeoutIn,
    this.canStartMessaging = false,
  });

  final String status; // 'searching' | 'matched' | 'expired'
  final int requestId;
  final int? sessionId;
  final MatchedUser? matchedUser;
  final String? message;
  final int? searchTimeoutIn;
  final bool canStartMessaging;

  bool get isMatched => status == 'matched';
  bool get isExpired => status == 'expired';
  bool get isSearching => status == 'searching';

  factory SearchStatus.fromJson(Map<String, dynamic> j) => SearchStatus(
        status: j['status'] as String? ?? 'searching',
        requestId: j['request_id'] as int? ?? 0,
        sessionId: j['session_id'] as int?,
        matchedUser: j['matched_user'] != null
            ? MatchedUser.fromJson(j['matched_user'] as Map<String, dynamic>)
            : null,
        message: j['message'] as String?,
        searchTimeoutIn: j['search_timeout_in'] as int?,
        canStartMessaging: j['can_start_messaging'] as bool? ?? false,
      );
}

// ─── Matched user (minimal — name + id from backend) ─────────────────────────

class MatchedUser {
  const MatchedUser({required this.id, required this.name, this.avatar});

  final int id;
  final String name;
  final String? avatar;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory MatchedUser.fromJson(Map<String, dynamic> j) => MatchedUser(
        id: j['id'] as int,
        name: j['name'] as String? ?? 'Unknown',
        avatar: j['avatar'] as String?,
      );
}

// ─── Pending request (for Discover / match cards) ─────────────────────────────

class MatchRequest {
  const MatchRequest({
    required this.requestId,
    required this.requester,
    this.compatibilityScore,
    this.requesterLanguageName,
    this.matchedLanguageName,
    this.isSender = false,
  });

  final int requestId;
  final MatchedUser requester;
  final double? compatibilityScore;
  final String? requesterLanguageName;
  final String? matchedLanguageName;
  // true = I sent this request and am waiting; false = someone sent this to me
  final bool isSender;

  factory MatchRequest.fromJson(Map<String, dynamic> j) => MatchRequest(
        requestId: j['request_id'] as int,
        requester: MatchedUser.fromJson(
          j['requester'] as Map<String, dynamic>? ?? {'id': 0, 'name': '?'},
        ),
        compatibilityScore: double.tryParse(j['compatibility_score']?.toString() ?? ''),
        requesterLanguageName: j['requester_language'] as String? ?? j['language'] as String?,
        matchedLanguageName: j['matched_language'] as String?,
        isSender: j['is_sender'] as bool? ?? false,
      );
}
