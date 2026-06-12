import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/conversation_api.dart';
import '../../data/models/conversation_model.dart';
import '../../services/websocket_service.dart';

class ConversationDetailController extends GetxController {
  static ConversationDetailController get to => Get.find();

  // Route args
  late final int conversationId;
  late final String partnerName;
  int? partnerId;

  // ─── State ────────────────────────────────────────────────────────────────
  final messages       = <MessageModel>[].obs;
  final isLoading      = false.obs;
  final isSending      = false.obs;
  final isLoadingMore  = false.obs;
  final hasMore        = true.obs;
  final partnerIsOnline = false.obs;
  final isPartnerTyping = false.obs;
  final errorMessage   = Rx<String?>(null);

  /// Message currently being replied to (shown as a preview above the input bar).
  final activeReply = Rx<MessageModel?>(null);

  // Text input
  final textController  = TextEditingController();
  final hasText         = false.obs;

  // Scroll
  final scrollController = ScrollController();

  // ─── Internal ─────────────────────────────────────────────────────────────
  Timer? _pollTimer;
  Timer? _typingDebounce;
  int    _lastMessageId = 0;
  int    _myUserId      = 0;
  bool   _usingWebSocket = false;

  // WebSocket stream subscriptions (null when using polling)
  StreamSubscription<WsMessage>?      _wsMsgSub;
  StreamSubscription<WsTyping>?       _wsTypingSub;
  StreamSubscription<WsReadReceipt>?  _wsReadSub;
  StreamSubscription<WsOnlineStatus>? _wsOnlineSub;
  StreamSubscription<bool>?           _wsConnSub;

  late final ConversationApi _api;

  // ─── Init / close ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _api = ConversationApi(ApiClient.instance);

    final args     = Get.arguments as Map<String, dynamic>? ?? {};
    conversationId = args['id'] as int? ?? 0;
    partnerName    = args['partner_name'] as String? ?? 'Partner';
    partnerId      = args['partner_id'] as int?;

    textController.addListener(_onTextChanged);
    _init();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    _wsMsgSub?.cancel();
    _wsTypingSub?.cancel();
    _wsReadSub?.cancel();
    _wsOnlineSub?.cancel();
    _wsConnSub?.cancel();
    textController.dispose();
    scrollController.dispose();

    // Leave the conversation room if WS is active
    if (_usingWebSocket && Get.isRegistered<WebSocketService>()) {
      try {
        WebSocketService.to.leaveConversation(conversationId);
        WebSocketService.to.updateOnlineStatus(isOnline: false);
      } catch (_) {}
    }

    super.onClose();
  }

  // ─── Setup ────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    _myUserId = (await StorageService.instance.getUserId()) ?? 0;
    await loadMessages();
    _startRealtimeTransport();
  }

  /// Try WebSocket first; fall back to polling if unavailable or disconnected.
  void _startRealtimeTransport() {
    if (Get.isRegistered<WebSocketService>()) {
      final ws = WebSocketService.to;
      if (ws.isConnected.value) {
        _activateWebSocket(ws);
      } else {
        // WS registered but not yet connected — watch the connection state
        _wsConnSub = ws.isConnected.listen((connected) {
          if (connected && !_usingWebSocket) {
            _deactivatePolling();
            _activateWebSocket(ws);
          } else if (!connected && _usingWebSocket) {
            _deactivateWebSocket();
            _startPolling();
          }
        });
        // Use polling in the meantime
        _startPolling();
      }
    } else {
      // WebSocketService not registered — polling only
      _startPolling();
    }
  }

  // ─── WebSocket transport ──────────────────────────────────────────────────

  void _activateWebSocket(WebSocketService ws) {
    _usingWebSocket = true;

    ws.joinConversation(conversationId);
    ws.updateOnlineStatus(isOnline: true);

    // New / edited / deleted messages
    _wsMsgSub = ws.messageStream
        .where((m) => m.conversationId == conversationId)
        .listen(_handleWsMessage);

    // Typing indicators
    _wsTypingSub = ws.typingStream
        .where((t) => t.conversationId == conversationId && t.userId != _myUserId)
        .listen((t) {
          isPartnerTyping.value = t.isTyping;
          if (t.isTyping) {
            _typingDebounce?.cancel();
            _typingDebounce = Timer(const Duration(seconds: 4), () {
              isPartnerTyping.value = false;
            });
          }
        });

    // Read receipts
    _wsReadSub = ws.readReceiptStream
        .where((r) => r.conversationId == conversationId)
        .listen(_handleReadReceipt);

    // Partner online status
    if (partnerId != null) {
      _wsOnlineSub = ws.onlineStatusStream
          .where((s) => s.userId == partnerId)
          .listen((s) => partnerIsOnline.value = s.isOnline);
    }
  }

  void _deactivateWebSocket() {
    _usingWebSocket = false;
    _wsMsgSub?.cancel();
    _wsTypingSub?.cancel();
    _wsReadSub?.cancel();
    _wsOnlineSub?.cancel();
    _wsMsgSub    = null;
    _wsTypingSub = null;
    _wsReadSub   = null;
    _wsOnlineSub = null;
  }

  void _handleWsMessage(WsMessage m) {
    if (m.isNew) {
      final msg = MessageModel(
        id:             m.messageId,
        conversationId: m.conversationId,
        content:        m.content,
        type:           m.messageType,
        status:         'delivered',
        createdAt:      m.at,
        senderId:       m.senderId,
        senderName:     m.senderName,
      );
      // Avoid duplicates (may arrive via both WS and REST send response)
      if (messages.every((e) => e.id != msg.id)) {
        messages.add(msg);
        _lastMessageId = msg.id;
        _scrollToBottom();
      }
    } else if (m.wasDeleted) {
      messages.removeWhere((e) => e.id == m.messageId);
    } else if (m.wasEdited) {
      final idx = messages.indexWhere((e) => e.id == m.messageId);
      if (idx != -1) {
        final old = messages[idx];
        messages[idx] = MessageModel(
          id:             old.id,
          conversationId: old.conversationId,
          content:        m.content,
          type:           old.type,
          status:         old.status,
          createdAt:      old.createdAt,
          senderId:       old.senderId,
          senderName:     old.senderName,
          isEdited:       true,
          editedAt:       m.at,
        );
      }
    }
  }

  void _handleReadReceipt(WsReadReceipt r) {
    final idx = messages.indexWhere((m) => m.id == r.messageId);
    if (idx == -1) return;
    final old = messages[idx];
    messages[idx] = MessageModel(
      id:             old.id,
      conversationId: old.conversationId,
      content:        old.content,
      type:           old.type,
      status:         'read',
      createdAt:      old.createdAt,
      senderId:       old.senderId,
      senderName:     old.senderName,
      isEdited:       old.isEdited,
      editedAt:       old.editedAt,
      readAt:         r.at,
    );
  }

  // ─── Polling transport (fallback) ─────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _pollOnce());
  }

  void _deactivatePolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    try {
      final page = await _api.getMessages(
        conversationId,
        offset: 0,
        limit:  50,
        sortAsc: true,
      );
      final newMsgs =
          page.messages.where((m) => m.id > _lastMessageId).toList();
      if (newMsgs.isNotEmpty) {
        messages.addAll(newMsgs);
        _lastMessageId = newMsgs.last.id;
        _scrollToBottom();
      }
    } catch (_) {}
  }

  // ─── Load messages (initial + pagination) ────────────────────────────────

  Future<void> loadMessages({bool loadMore = false}) async {
    if (loadMore && (!hasMore.value || isLoadingMore.value)) return;

    if (loadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      final offset = loadMore ? messages.length : 0;
      final page   = await _api.getMessages(
        conversationId,
        offset:  offset,
        limit:   50,
        sortAsc: true,
      );

      if (loadMore) {
        messages.insertAll(0, page.messages);
      } else {
        messages.assignAll(page.messages);
        if (page.messages.isNotEmpty) {
          _lastMessageId = page.messages.last.id;
        }
        _scrollToBottom();
      }

      hasMore.value = (offset + page.messages.length) < page.total;
    } catch (e) {
      if (!loadMore) errorMessage.value = ApiClient.parseError(e);
    } finally {
      isLoading.value      = false;
      isLoadingMore.value  = false;
    }
  }

  // ─── Send message ─────────────────────────────────────────────────────────

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final replyToId = activeReply.value?.id;

    textController.clear();
    hasText.value = false;
    _emitTyping(false);
    clearReply();

    isSending.value = true;
    try {
      // Send via REST (authoritative — gives us the real message ID)
      final msg = await _api.sendMessage(
        conversationId,
        text,
        replyToMessageId: replyToId,
      );
      if (messages.every((m) => m.id != msg.id)) {
        messages.add(msg);
        _lastMessageId = msg.id;
      }
      _scrollToBottom();

      // Mark WS-acknowledged if connected
      if (_usingWebSocket && Get.isRegistered<WebSocketService>()) {
        WebSocketService.to.markAsRead(conversationId, msg.id);
      }
    } catch (e) {
      Get.snackbar(
        'Send Failed',
        ApiClient.parseError(e),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSending.value = false;
    }
  }

  // ─── Reply ────────────────────────────────────────────────────────────────

  void setReplyTarget(MessageModel msg) => activeReply.value = msg;

  void clearReply() => activeReply.value = null;

  // ─── Pin / unpin ──────────────────────────────────────────────────────────

  Future<void> togglePin(MessageModel msg) async {
    final pin = !msg.isPinned;
    try {
      await _api.pinMessage(conversationId, msg.id, pin: pin);
      final idx = messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        messages[idx] = MessageModel(
          id:             msg.id,
          conversationId: msg.conversationId,
          content:        msg.content,
          type:           msg.type,
          status:         msg.status,
          createdAt:      msg.createdAt,
          senderId:       msg.senderId,
          senderName:     msg.senderName,
          isEdited:       msg.isEdited,
          isDeleted:      msg.isDeleted,
          isPinned:       pin,
          reactions:      msg.reactions,
          replyTo:        msg.replyTo,
          readAt:         msg.readAt,
          editedAt:       msg.editedAt,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Action Failed',
        ApiClient.parseError(e),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ─── React / delete ───────────────────────────────────────────────────────

  Future<void> react(int messageId, String emoji) async {
    try {
      await _api.reactToMessage(conversationId, messageId, emoji);
      await _pollOnce();
    } catch (_) {}
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _api.deleteMessage(conversationId, messageId);
      messages.removeWhere((m) => m.id == messageId);
    } catch (_) {}
  }

  // ─── Typing indicator ─────────────────────────────────────────────────────

  void _onTextChanged() {
    final typing = textController.text.trim().isNotEmpty;
    hasText.value = typing;
    _emitTyping(typing);
  }

  bool _lastTypingState = false;

  void _emitTyping(bool typing) {
    if (typing == _lastTypingState) return;
    _lastTypingState = typing;

    if (_usingWebSocket && Get.isRegistered<WebSocketService>()) {
      try {
        WebSocketService.to.setTyping(conversationId, isTyping: typing);
      } catch (_) {}
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool isMyMessage(MessageModel msg) => msg.senderId == _myUserId;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
