import 'dart:async';

import 'package:get/get.dart';

import '../../config/routes.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/conversation_api.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../services/websocket_service.dart';

class ConversationController extends GetxController {
  static ConversationController get to => Get.find();

  final isLoading = false.obs;
  final conversations = <ConversationModel>[].obs;
  final searchQuery = ''.obs;
  final activeTab = 0.obs; // 0=All, 1=Active, 2=Archived

  late final ConversationRepository _repo;
  StreamSubscription<WsCallEvent>? _callSub;

  @override
  void onInit() {
    super.onInit();
    _repo = ConversationRepository(ConversationApi(ApiClient.instance));
    loadConversations();
    _listenForIncomingCalls();
  }

  @override
  void onClose() {
    _callSub?.cancel();
    super.onClose();
  }

  void _listenForIncomingCalls() {
    _callSub = WebSocketService.to.callEventStream.listen((event) {
      if (!event.isIncoming) return;
      final route = event.callType == 'video' ? Routes.videoCall : Routes.audioCall;
      Get.toNamed(route, arguments: {
        'call_type':       event.callType,
        'partner_name':    event.callerName ?? 'Partner',
        'partner_id':      event.callerId,
        'conversation_id': event.conversationId,
        'is_receiver':     true,
        'call_id':         event.callId,
        'call_token':      event.callToken,
        'call_server_url': event.callServerUrl,
      });
    });
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadConversations() async {
    isLoading.value = true;
    try {
      final list = await _repo.getConversations();
      conversations.assignAll(list);
    } catch (_) {
      // Non-fatal
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() => loadConversations();

  // ─── Filtering ────────────────────────────────────────────────────────────

  void setSearch(String q) => searchQuery.value = q;
  void setTab(int t) => activeTab.value = t;

  List<ConversationModel> get filtered {
    var list = conversations.toList();

    // Tab filter
    switch (activeTab.value) {
      case 1:
        list = list.where((c) => c.status == 'active').toList();
      case 2:
        list = list.where((c) => c.status == 'archived').toList();
    }

    // Search filter
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              (c.partner?.name.toLowerCase().contains(q) ?? false) ||
              (c.lastMessage?.content.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return list;
  }

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> archive(int id) async {
    try {
      await _repo.archiveConversation(id);
      final idx = conversations.indexWhere((c) => c.id == id);
      if (idx != -1) {
        // Optimistically update status
        final c = conversations[idx];
        conversations[idx] = ConversationModel(
          id: c.id,
          status: 'archived',
          type: c.type,
          language: c.language,
          partner: c.partner,
          lastMessage: c.lastMessage,
          unreadCount: c.unreadCount,
          messageCount: c.messageCount,
          callCount: c.callCount,
          lastActivityAt: c.lastActivityAt,
          createdAt: c.createdAt,
        );
      }
    } catch (_) {}
  }

  Future<void> delete(int id) async {
    try {
      await _repo.deleteConversation(id);
      conversations.removeWhere((c) => c.id == id);
    } catch (_) {}
  }
}
