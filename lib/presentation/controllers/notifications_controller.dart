import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/routes.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/conversation_api.dart';
import '../../data/datasources/remote/matching_api.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/matching_repository.dart';

class NotificationsController extends GetxController {
  static NotificationsController get to => Get.find();

  final notifications = <NotificationModel>[].obs;
  final isLoading     = false.obs;
  final activeFilter  = Rx<NotificationType?>(null); // null = All

  late final MatchingRepository     _matchingRepo;
  late final ConversationRepository _convRepo;

  // ─── Computed ─────────────────────────────────────────────────────────────

  List<NotificationModel> get filtered {
    final f = activeFilter.value;
    if (f == null) return notifications.toList();
    return notifications.where((n) => n.type == f).toList();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  // ─── Init ─────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _matchingRepo = MatchingRepository(MatchingApi(ApiClient.instance));
    _convRepo     = ConversationRepository(ConversationApi(ApiClient.instance));
    loadNotifications();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadNotifications() async {
    isLoading.value = true;
    final built = <NotificationModel>[];

    // 1. Pending match requests → match notifications
    try {
      final requests = await _matchingRepo.getPendingRequests();
      for (final r in requests) {
        final name = r.requester.name.isNotEmpty ? r.requester.name : 'Someone';
        final lang = r.requesterLanguageName ?? 'a language';
        built.add(NotificationModel(
          id:        'match_${r.requestId}',
          type:      NotificationType.match,
          title:     'New Match Request',
          body:      '$name wants to practice $lang with you',
          createdAt: DateTime.now(),
          routePath: Routes.searchPartner,
        ));
      }
    } catch (_) {}

    // 2. Unread conversations → message notifications
    try {
      final convos = await _convRepo.getConversations();
      for (final c in convos.where((c) => c.unreadCount > 0)) {
        final partner = c.partner?.name ?? 'Someone';
        final count   = c.unreadCount;
        built.add(NotificationModel(
          id:        'msg_${c.id}',
          type:      NotificationType.message,
          title:     'New Message${count > 1 ? 's' : ''}',
          body:      '$partner sent you ${count > 1 ? '$count messages' : 'a message'}',
          createdAt: c.lastActivityAt ?? c.createdAt ?? DateTime.now(),
          routePath: Routes.conversationDetail,
          routeArgs: {'id': c.id},
        ));
      }
    } catch (_) {}

    // 3. Restore read state from SharedPreferences
    final prefs  = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('notif_read_ids') ?? [];
    for (final n in built) {
      if (readIds.contains(n.id)) n.isRead = true;
    }

    // Sort newest first
    built.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifications.assignAll(built);
    isLoading.value = false;
  }

  // ─── Mark read ─────────────────────────────────────────────────────────────

  Future<void> markRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || notifications[idx].isRead) return;

    notifications[idx].isRead = true;
    notifications.refresh();

    final prefs   = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('notif_read_ids') ?? [];
    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setStringList('notif_read_ids', readIds);
    }
  }

  Future<void> markAllRead() async {
    for (final n in notifications) {
      n.isRead = true;
    }
    notifications.refresh();

    final prefs = await SharedPreferences.getInstance();
    final allIds = notifications.map((n) => n.id).toList();
    await prefs.setStringList('notif_read_ids', allIds);
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);

    // Also remove from read list
    final prefs   = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('notif_read_ids') ?? [];
    readIds.remove(id);
    await prefs.setStringList('notif_read_ids', readIds);
  }

  Future<void> clearAll() async {
    notifications.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notif_read_ids');
  }

  // ─── Filter ────────────────────────────────────────────────────────────────

  void setFilter(NotificationType? type) => activeFilter.value = type;

  // ─── Navigate on tap ──────────────────────────────────────────────────────

  void onTap(NotificationModel n) {
    markRead(n.id);
    if (n.routePath != null) {
      Get.toNamed(n.routePath!, arguments: n.routeArgs);
    }
  }
}
