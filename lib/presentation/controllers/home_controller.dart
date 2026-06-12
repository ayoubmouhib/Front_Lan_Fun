import 'package:get/get.dart';

import '../../config/routes.dart';
import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/conversation_api.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../widgets/common/language_picker_sheet.dart';
import 'app_controller.dart';
import 'gamification_controller.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // ─── Navigation ───────────────────────────────────────────────────────────
  final tabIndex = 0.obs;

  void setTab(int i) => tabIndex.value = i;
  void goToSearch() => setTab(1);
  void goToMessages() => setTab(2);
  void goToProfile() => setTab(3);
  void goToAchievements() => setTab(4);

  // ─── State ────────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final quizPending = false.obs;
  final user = Rx<UserModel?>(null);
  final conversations = <ConversationModel>[].obs;

  // Derived stats
  int get totalConversations => conversations.length;
  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  // Placeholder gamification stats (populated when gamification API is added)
  final xpPoints = 0.obs;
  final level = 1.obs;
  final streakDays = 0.obs;
  final practiceHours = 0.obs;

  late final ConversationRepository _convRepo;

  @override
  void onInit() {
    super.onInit();
    _convRepo = ConversationRepository(ConversationApi(ApiClient.instance));
    _loadData();
    _syncGamificationStats();
  }

  void _syncGamificationStats() {
    final gc = GamificationController.to;
    // Seed current values (GamificationController may already have loaded data)
    xpPoints.value = gc.xpPoints.value;
    level.value = gc.level;
    streakDays.value = gc.streakDays.value;
    practiceHours.value = gc.practiceHours.value.toInt();
    // Stay reactive as GamificationController updates from the API
    ever(gc.xpPoints, (v) {
      xpPoints.value = v;
      level.value = gc.level;
    });
    ever(gc.streakDays, (v) => streakDays.value = v);
    ever(gc.practiceHours, (v) => practiceHours.value = v.toInt());
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    await Future.wait([
      _loadUser(),
      _loadConversations(),
      _loadQuizPending(),
    ]);
    isLoading.value = false;
  }

  Future<void> _loadQuizPending() async {
    quizPending.value = await StorageService.instance.isQuizPending();
  }

  Future<void> markQuizDone() async {
    await StorageService.instance.setQuizPending(false);
    quizPending.value = false;
  }

  Future<void> _loadUser() async {
    user.value = await StorageService.instance.getCachedUser();
  }

  Future<void> _loadConversations() async {
    try {
      final list = await _convRepo.getConversations();
      conversations.assignAll(list.where((c) => c.isActive).toList());
    } catch (e) {
      // Non-fatal — show empty state
    }
  }

  @override
  Future<void> refresh() => _loadData();

  List<ConversationModel> get recentConversations =>
      conversations.take(5).toList();

  void navigateToConversation(int conversationId) {
    Get.toNamed(Routes.conversationDetail, arguments: {'id': conversationId});
  }

  void toggleTheme() => Get.find<AppController>().toggleTheme();

  void navigateToSettings() => Get.toNamed(Routes.settings);

  void navigateToFindPartner() => Get.toNamed(Routes.searchPartner);

  // ─── Quiz / Games — pick a language first if the user is learning several ──

  Future<void> startQuiz() async {
    final title = quizPending.value ? 'Placement Quiz' : 'Practice Quiz';
    final result = await _startLanguageActivity(Routes.quiz, title);
    // Unlock only if the user actually answered at least one question
    // (QuizController.done() returns true in that case).
    if (quizPending.value && result == true) await markQuizDone();
  }

  Future<void> startGames() async =>
      _startLanguageActivity(Routes.games, 'Play Games');

  Future<dynamic> _startLanguageActivity(
      String route, String pickerTitle) async {
    final learning = user.value?.learningLanguages ?? [];

    // Nothing to choose between — let the screen auto-select / show its own error.
    if (learning.length <= 1) {
      return await Get.toNamed(route);
    }

    final chosen = await Get.bottomSheet<UserLanguageModel>(
      LanguagePickerSheet(title: pickerTitle, languages: learning),
    );
    if (chosen == null) return null;

    return await Get.toNamed(route, arguments: {
      'languageId': chosen.languageId,
      'languageName': chosen.language?.name,
    });
  }
}
