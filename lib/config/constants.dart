class AppConstants {
  AppConstants._();

  // ─── API ────────────────────────────────────────────────────────────────────
  static const String apiBaseUrl = 'http://localhost:3000';
  static const String wsBaseUrl  = 'ws://localhost:3000';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration activeSearchTimeout = Duration(seconds: 600);
  static const int paginationLimit = 20;

  // ─── Storage keys ───────────────────────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUsername = 'username';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyQuizPending = 'quiz_pending';

  // ─── Limits ─────────────────────────────────────────────────────────────────
  static const int maxFileSizeBytes = 5242880; // 5 MB
  static const int maxInterests = 10;
  static const int minInterests = 3;
  static const int maxLanguages = 10;
  static const int maxBioLength = 500;
  static const int minAge = 12;
  static const int maxAge = 100;

  // ─── App meta ───────────────────────────────────────────────────────────────
  static const String appVersion = '1.0.0';
  static const String appName = 'LinguaConnect';
  static const String appTagline = 'Learn Languages, Make Friends';

  // ─── Languages (mirrors backend seed) ───────────────────────────────────────
  static const List<Map<String, String>> supportedLanguages = [
    {'name': 'English',              'iso': 'en', 'flag': '🇬🇧'},
    {'name': 'French',               'iso': 'fr', 'flag': '🇫🇷'},
    {'name': 'Arabic',               'iso': 'ar', 'flag': '🇸🇦'},
    {'name': 'Spanish',              'iso': 'es', 'flag': '🇪🇸'},
    {'name': 'German',               'iso': 'de', 'flag': '🇩🇪'},
    {'name': 'Italian',              'iso': 'it', 'flag': '🇮🇹'},
    {'name': 'Portuguese',           'iso': 'pt', 'flag': '🇵🇹'},
    {'name': 'Chinese (Simplified)', 'iso': 'zh', 'flag': '🇨🇳'},
    {'name': 'Japanese',             'iso': 'ja', 'flag': '🇯🇵'},
    {'name': 'Korean',               'iso': 'ko', 'flag': '🇰🇷'},
    {'name': 'Russian',              'iso': 'ru', 'flag': '🇷🇺'},
    {'name': 'Turkish',              'iso': 'tr', 'flag': '🇹🇷'},
    {'name': 'Hindi',                'iso': 'hi', 'flag': '🇮🇳'},
  ];

  // ─── Interests (mirrors backend seed) ───────────────────────────────────────
  static const List<Map<String, String>> availableInterests = [
    {'name': 'Travel',       'icon': 'flight'},
    {'name': 'Food',         'icon': 'restaurant'},
    {'name': 'Music',        'icon': 'music_note'},
    {'name': 'Sports',       'icon': 'sports_soccer'},
    {'name': 'Technology',   'icon': 'computer'},
    {'name': 'Art',          'icon': 'palette'},
    {'name': 'Reading',      'icon': 'book'},
    {'name': 'Movies',       'icon': 'movie'},
    {'name': 'Gaming',       'icon': 'sports_esports'},
    {'name': 'Photography',  'icon': 'camera_alt'},
    {'name': 'Cooking',      'icon': 'restaurant_menu'},
    {'name': 'Fitness',      'icon': 'fitness_center'},
    {'name': 'Nature',       'icon': 'nature'},
    {'name': 'Fashion',      'icon': 'checkroom'},
    {'name': 'Science',      'icon': 'science'},
  ];

  // ─── Language proficiency levels ────────────────────────────────────────────
  static const List<String> proficiencyLevels = [
    'A1', 'A2', 'B1', 'B2', 'C1', 'C2',
  ];
}
