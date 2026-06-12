import 'package:get/get.dart';

import '../../services/websocket_service.dart';
import '../controllers/app_controller.dart';
import '../controllers/conversation_controller.dart';
import '../controllers/follow_controller.dart';
import '../controllers/games_controller.dart';
import '../controllers/gamification_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/matching_controller.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/vocabulary_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppController(), permanent: true);
    // WebSocket service — connects automatically on init using stored token.
    // Registered before other controllers so they can reference it.
    Get.put(WebSocketService(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<MatchingController>(() => MatchingController(), fenix: true);
    Get.lazyPut<FollowController>(() => FollowController(), fenix: true);
    Get.lazyPut<ConversationController>(() => ConversationController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    Get.lazyPut<GamificationController>(() => GamificationController(), fenix: true);
    Get.lazyPut<NotificationsController>(() => NotificationsController(), fenix: true);
    Get.lazyPut<QuizController>(() => QuizController(), fenix: true);
    Get.lazyPut<GamesController>(() => GamesController(), fenix: true);
    Get.lazyPut<VocabularyController>(() => VocabularyController(), fenix: true);
  }
}
