import 'package:get/get.dart';

import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/verify_email_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/home/search_partner_screen.dart';
import '../presentation/screens/home/partner_profile_screen.dart';
import '../presentation/screens/home/discover_screen.dart';
import '../presentation/screens/home/user_search_screen.dart';
import '../presentation/screens/home/user_profile_screen.dart';
import '../presentation/screens/profile/my_connections_screen.dart';
import '../presentation/screens/profile/vocabulary_screen.dart';
import '../presentation/screens/conversation/conversations_list_screen.dart';
import '../presentation/screens/conversation/conversation_detail_screen.dart';
import '../presentation/screens/conversation/audio_call_screen.dart';
import '../presentation/screens/conversation/video_call_screen.dart';
import '../presentation/screens/conversation/call_rating_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/settings_screen.dart';
import '../presentation/screens/profile/blocked_users_screen.dart';
import '../presentation/screens/gamification/achievements_screen.dart';
import '../presentation/screens/gamification/leaderboard_screen.dart';
import '../presentation/screens/gamification/daily_challenge_screen.dart';
import '../presentation/screens/notifications_screen.dart';
import '../presentation/screens/user_reviews_screen.dart';
import '../presentation/screens/quiz/quiz_screen.dart';
import '../presentation/screens/games/games_screen.dart';
import '../presentation/screens/practice/practice_session_screen.dart';
import '../presentation/bindings/auth_binding.dart';
import '../presentation/bindings/home_binding.dart';
import '../presentation/bindings/conversation_binding.dart';

class Routes {
  Routes._();

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String splash          = '/';
  static const String onboarding      = '/onboarding';
  static const String login           = '/login';
  static const String signup          = '/signup';
  static const String forgotPassword  = '/forgot-password';
  static const String verifyEmail     = '/verify-email';

  // ─── Home ─────────────────────────────────────────────────────────────────
  static const String home            = '/home';
  static const String searchPartner   = '/search-partner';
  static const String partnerProfile  = '/partner-profile';
  static const String discover        = '/discover';
  static const String userSearch      = '/find-people';
  static const String userProfile     = '/find-people/profile';
  static const String myConnections   = '/profile/connections';
  static const String vocabulary      = '/profile/vocabulary';

  // ─── Conversations ────────────────────────────────────────────────────────
  static const String conversationsList   = '/conversations';
  static const String conversationDetail  = '/conversations/detail';
  static const String audioCall           = '/call/audio';
  static const String videoCall           = '/call/video';
  static const String callRating          = '/call/rating';

  // ─── Profile ──────────────────────────────────────────────────────────────
  static const String profile     = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings    = '/settings';
  static const String blockedUsers = '/settings/blocked-users';

  // ─── Gamification ─────────────────────────────────────────────────────────
  static const String achievements    = '/achievements';
  static const String leaderboard     = '/leaderboard';
  static const String dailyChallenge  = '/daily-challenge';

  // ─── Quiz ─────────────────────────────────────────────────────────────────
  static const String quiz = '/quiz';

  // ─── Games ────────────────────────────────────────────────────────────────
  static const String games = '/games';

  // ─── Practice session ─────────────────────────────────────────────────────
  static const String practiceSession = '/practice-session';

  // ─── Remaining ────────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String userReviews   = '/reviews';

  // ─── GetPages ─────────────────────────────────────────────────────────────

  static final List<GetPage> pages = [
    // Auth
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: AuthBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: signup,
      page: () => const SignupScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: verifyEmail,
      page: () => const VerifyEmailScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Home
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: searchPartner,
      page: () => const SearchPartnerScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: partnerProfile,
      page: () => const PartnerProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: discover,
      page: () => const DiscoverScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: userSearch,
      page: () => const UserSearchScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: userProfile,
      page: () => const UserProfileScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: myConnections,
      page: () => const MyConnectionsScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: vocabulary,
      page: () => const VocabularyScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Conversations
    GetPage(
      name: conversationsList,
      page: () => const ConversationsListScreen(),
      binding: ConversationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: conversationDetail,
      page: () => const ConversationDetailScreen(),
      binding: ConversationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: audioCall,
      page: () => const AudioCallScreen(),
      transition: Transition.upToDown,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: videoCall,
      page: () => const VideoCallScreen(),
      transition: Transition.upToDown,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: callRating,
      page: () => const CallRatingScreen(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // Profile
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: blockedUsers,
      page: () => const BlockedUsersScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Gamification
    GetPage(
      name: achievements,
      page: () => const AchievementsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: leaderboard,
      page: () => const LeaderboardScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: dailyChallenge,
      page: () => const DailyChallengeScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Remaining
    GetPage(
      name: notifications,
      page: () => const NotificationsScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: userReviews,
      page: () => const UserReviewsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Quiz
    GetPage(
      name: quiz,
      page: () => const QuizScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Games
    GetPage(
      name: games,
      page: () => const GamesScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Practice session
    GetPage(
      name: practiceSession,
      page: () => const PracticeSessionScreen(),
      transition: Transition.upToDown,
      transitionDuration: const Duration(milliseconds: 400),
    ),
  ];
}
