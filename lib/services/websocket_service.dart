import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/constants.dart';
import '../data/datasources/local/storage_service.dart';

// ─── Event models ─────────────────────────────────────────────────────────────

class WsMessage {
  const WsMessage({
    required this.conversationId,
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.eventType,
    required this.at,
    this.senderName,
    this.isEdited = false,
    this.isDeleted = false,
  });

  final int conversationId;
  final int messageId;
  final int senderId;
  final String content;
  final String messageType; // text | image | audio | file
  final String eventType;   // new | edited | deleted
  final DateTime at;
  final String? senderName;
  final bool isEdited;
  final bool isDeleted;

  bool get isNew     => eventType == 'new';
  bool get wasEdited => eventType == 'edited';
  bool get wasDeleted => eventType == 'deleted';

  factory WsMessage.fromJson(Map<String, dynamic> j) => WsMessage(
        conversationId: j['conversation_id'] as int? ?? 0,
        messageId:      j['id'] as int? ?? (j['message_id'] as int? ?? 0),
        senderId:       j['sender_id'] as int? ??
            (j['sender'] as Map<String, dynamic>?)?['id'] as int? ?? 0,
        senderName:     (j['sender'] as Map<String, dynamic>?)?['name'] as String?,
        content:        j['content'] as String? ?? '',
        messageType:    j['type'] as String? ?? 'text',
        eventType:      j['event_type'] as String? ?? 'new',
        at:             DateTime.tryParse(j['created_at'] as String? ?? '') ??
                        DateTime.now(),
        isEdited:       j['is_edited'] as bool? ?? false,
        isDeleted:      j['is_deleted'] as bool? ?? false,
      );
}

class WsTyping {
  const WsTyping({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  final int conversationId;
  final int userId;
  final bool isTyping;

  factory WsTyping.fromJson(Map<String, dynamic> j) => WsTyping(
        conversationId: j['conversation_id'] as int? ?? 0,
        userId:         j['user_id'] as int? ?? 0,
        isTyping:       j['is_typing'] as bool? ?? false,
      );
}

class WsReadReceipt {
  const WsReadReceipt({
    required this.conversationId,
    required this.messageId,
    required this.readBy,
    required this.at,
  });

  final int conversationId;
  final int messageId;
  final int readBy;
  final DateTime at;

  factory WsReadReceipt.fromJson(Map<String, dynamic> j) => WsReadReceipt(
        conversationId: j['conversation_id'] as int? ?? 0,
        messageId:      j['message_id'] as int? ?? 0,
        readBy:         j['read_by'] as int? ?? 0,
        at:             DateTime.tryParse(j['at'] as String? ?? '') ??
                        DateTime.now(),
      );
}

class WsOnlineStatus {
  const WsOnlineStatus({
    required this.userId,
    required this.isOnline,
  });

  final int userId;
  final bool isOnline;

  factory WsOnlineStatus.fromJson(Map<String, dynamic> j, String event) =>
      WsOnlineStatus(
        userId:   j['user_id'] as int? ?? 0,
        isOnline: j['is_online'] as bool? ?? (event == 'user_online'),
      );
}

class WsCallEvent {
  const WsCallEvent({
    required this.callId,
    required this.eventType,
    required this.callType,
    this.callerName,
    this.callerId,
    this.conversationId,
    this.callToken,
    this.callServerUrl,
  });

  final int callId;
  final String eventType; // incoming_call | call_accepted | call_rejected | call_ended
  final String callType;  // audio | video
  final String? callerName;
  final int? callerId;
  final int? conversationId;
  final String? callToken;     // LiveKit JWT for the receiver
  final String? callServerUrl; // LiveKit server URL

  bool get isIncoming  => eventType == 'incoming_call';
  bool get isAccepted  => eventType == 'call_accepted';
  bool get isRejected  => eventType == 'call_rejected';
  bool get isEnded     => eventType == 'call_ended';

  factory WsCallEvent.fromJson(Map<String, dynamic> j, String event) =>
      WsCallEvent(
        callId:         j['call_id'] as int? ?? 0,
        eventType:      event,
        callType:       j['type'] as String? ?? 'audio',
        callerName:     (j['caller'] as Map<String, dynamic>?)?['name'] as String?,
        callerId:       (j['caller'] as Map<String, dynamic>?)?['id'] as int?,
        conversationId: j['conversation_id'] as int?,
        callToken:      j['call_token'] as String?,
        callServerUrl:  j['call_server_url'] as String?,
      );
}

class WsMatchEvent {
  const WsMatchEvent({
    required this.eventType,
    required this.userId,
    required this.userName,
    this.requestId,
  });

  final String eventType; // match_found | match_request
  final int userId;
  final String userName;
  final int? requestId;

  factory WsMatchEvent.fromJson(Map<String, dynamic> j, String event) =>
      WsMatchEvent(
        eventType: event,
        userId:    j['user_id'] as int? ?? (j['id'] as int? ?? 0),
        userName:  j['name'] as String? ?? 'Unknown',
        requestId: j['request_id'] as int?,
      );
}

class WsSessionEvent {
  const WsSessionEvent({
    required this.sessionId,
    required this.eventType,
    this.plannedDurationMinutes,
    this.partnerName,
    this.partnerId,
    this.sessionType,
  });

  final int sessionId;
  final String eventType; // session_accepted
  final int? plannedDurationMinutes;
  final String? partnerName;
  final int? partnerId;
  final String? sessionType;

  factory WsSessionEvent.fromJson(Map<String, dynamic> j, String event) =>
      WsSessionEvent(
        sessionId:               j['session_id'] as int? ?? 0,
        eventType:               event,
        plannedDurationMinutes:  j['planned_duration_minutes'] as int?,
        partnerName:             (j['partner'] as Map<String, dynamic>?)?['name'] as String?,
        partnerId:               (j['partner'] as Map<String, dynamic>?)?['id'] as int?,
        sessionType:             j['session_type'] as String?,
      );
}

// ─── WebSocketService ─────────────────────────────────────────────────────────

class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();

  // ─── Connection state ──────────────────────────────────────────────────────
  final isConnected     = false.obs;
  final connectionState = WsConnectionState.disconnected.obs;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;
  String? _token;

  static const Duration _pingInterval      = Duration(seconds: 25);
  static const int      _maxReconnects     = 8;
  static const List<int> _backoffSeconds   = [1, 2, 4, 8, 16, 30, 30, 30];

  // ─── Event stream controllers ──────────────────────────────────────────────
  final _msgCtrl     = StreamController<WsMessage>.broadcast();
  final _typingCtrl  = StreamController<WsTyping>.broadcast();
  final _readCtrl    = StreamController<WsReadReceipt>.broadcast();
  final _onlineCtrl  = StreamController<WsOnlineStatus>.broadcast();
  final _callCtrl    = StreamController<WsCallEvent>.broadcast();
  final _matchCtrl   = StreamController<WsMatchEvent>.broadcast();
  final _sessionCtrl = StreamController<WsSessionEvent>.broadcast();

  Stream<WsMessage>      get messageStream      => _msgCtrl.stream;
  Stream<WsTyping>       get typingStream       => _typingCtrl.stream;
  Stream<WsReadReceipt>  get readReceiptStream  => _readCtrl.stream;
  Stream<WsOnlineStatus> get onlineStatusStream => _onlineCtrl.stream;
  Stream<WsCallEvent>    get callEventStream    => _callCtrl.stream;
  Stream<WsMatchEvent>   get matchEventStream   => _matchCtrl.stream;
  Stream<WsSessionEvent> get sessionEventStream => _sessionCtrl.stream;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _connectFromStorage();
  }

  @override
  void onClose() {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channelSub?.cancel();
    _channel?.sink.close();
    _msgCtrl.close();
    _typingCtrl.close();
    _readCtrl.close();
    _onlineCtrl.close();
    _callCtrl.close();
    _matchCtrl.close();
    _sessionCtrl.close();
    super.onClose();
  }

  // ─── Connect ───────────────────────────────────────────────────────────────

  Future<void> _connectFromStorage() async {
    final token = await StorageService.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      await connect(token);
    }
  }

  Future<void> connect(String token) async {
    _token                 = token;
    _intentionalDisconnect = false;
    _reconnectAttempts     = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_intentionalDisconnect) return;

    connectionState.value = WsConnectionState.connecting;

    try {
      final uri = Uri.parse(
          '${AppConstants.wsBaseUrl}?token=${Uri.encodeComponent(_token ?? '')}');
      _channel = WebSocketChannel.connect(uri);

      // `ready` completes on successful handshake or throws on failure.
      await _channel!.ready;

      _reconnectAttempts    = 0;
      isConnected.value     = true;
      connectionState.value = WsConnectionState.connected;

      _startPing();

      _channelSub = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone:  _onDone,
        cancelOnError: false,
      );
    } catch (_) {
      isConnected.value     = false;
      connectionState.value = WsConnectionState.reconnecting;
      _scheduleReconnect();
    }
  }

  // ─── Disconnect ────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    connectionState.value  = WsConnectionState.disconnected;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channelSub?.cancel();
    _channelSub = null;
    await _channel?.sink.close();
    _channel        = null;
    isConnected.value = false;
  }

  // ─── Event dispatching ─────────────────────────────────────────────────────

  void _onData(dynamic raw) {
    if (raw is! String) return;
    try {
      final json    = jsonDecode(raw) as Map<String, dynamic>;
      final event   = json['event'] as String?;
      final data    = json['data'] as Map<String, dynamic>?;

      if (event == null) return;
      if (data == null && event != 'pong') return;

      final payload = data ?? <String, dynamic>{};

      switch (event) {
        // ── Messages ──────────────────────────────────────────────────────
        case 'new_message':
          _msgCtrl.add(WsMessage.fromJson({...payload, 'event_type': 'new'}));

        case 'message_edited':
          _msgCtrl.add(WsMessage.fromJson({...payload, 'event_type': 'edited'}));

        case 'message_deleted':
          _msgCtrl.add(WsMessage.fromJson({...payload, 'event_type': 'deleted'}));

        // ── Typing ────────────────────────────────────────────────────────
        case 'typing':
          _typingCtrl.add(WsTyping.fromJson(payload));

        // ── Read receipts ─────────────────────────────────────────────────
        case 'message_read':
          _readCtrl.add(WsReadReceipt.fromJson(payload));

        // ── Online status ─────────────────────────────────────────────────
        case 'user_online' || 'user_offline':
          _onlineCtrl.add(WsOnlineStatus.fromJson(payload, event));

        // ── Calls ─────────────────────────────────────────────────────────
        case 'incoming_call' ||
              'call_accepted' ||
              'call_rejected' ||
              'call_ended':
          _callCtrl.add(WsCallEvent.fromJson(payload, event));

        // ── Matching ──────────────────────────────────────────────────────
        case 'match_found' || 'match_request':
          _matchCtrl.add(WsMatchEvent.fromJson(payload, event));

        // ── Session ───────────────────────────────────────────────────────
        case 'session_accepted':
          _sessionCtrl.add(WsSessionEvent.fromJson(payload, event));

        // ── Keep-alive ────────────────────────────────────────────────────
        case 'pong':
          break;
      }
    } catch (_) {
      // Malformed frame — ignore silently
    }
  }

  void _onError(dynamic _) {
    isConnected.value     = false;
    connectionState.value = WsConnectionState.reconnecting;
    _pingTimer?.cancel();
    if (!_intentionalDisconnect) _scheduleReconnect();
  }

  void _onDone() {
    isConnected.value     = false;
    connectionState.value = WsConnectionState.reconnecting;
    _pingTimer?.cancel();
    if (!_intentionalDisconnect) _scheduleReconnect();
  }

  // ─── Auto-reconnect ────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    if (_reconnectAttempts >= _maxReconnects) {
      connectionState.value = WsConnectionState.disconnected;
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(
        seconds: _backoffSeconds[_reconnectAttempts.clamp(0, _backoffSeconds.length - 1)]);
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, _doConnect);
  }

  // ─── Ping ──────────────────────────────────────────────────────────────────

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _emit('ping', const {});
    });
  }

  // ─── Emit helpers ──────────────────────────────────────────────────────────

  void _emit(String event, Map<String, dynamic> data) {
    if (!isConnected.value || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'event': event, 'data': data}));
    } catch (_) {}
  }

  // ─── Public send methods ───────────────────────────────────────────────────

  /// Subscribe the client to events for a specific conversation room.
  void joinConversation(int conversationId) =>
      _emit('join_conversation', {'conversation_id': conversationId});

  /// Unsubscribe from a conversation room.
  void leaveConversation(int conversationId) =>
      _emit('leave_conversation', {'conversation_id': conversationId});

  /// Send a chat message.
  void sendMessage(int conversationId, String content,
          {String type = 'text'}) =>
      _emit('send_message', {
        'conversation_id': conversationId,
        'content': content,
        'type': type,
      });

  /// Emit or cancel a typing indicator.
  void setTyping(int conversationId, {required bool isTyping}) =>
      _emit('typing', {
        'conversation_id': conversationId,
        'is_typing': isTyping,
      });

  /// Mark all messages up to [messageId] as read by the current user.
  void markAsRead(int conversationId, int messageId) =>
      _emit('mark_read', {
        'conversation_id': conversationId,
        'message_id': messageId,
      });

  /// Broadcast the current user's online / offline status.
  void updateOnlineStatus({required bool isOnline}) =>
      _emit('online_status', {'is_online': isOnline});

  /// Accept or decline an incoming call.
  void respondToCall(int callId, {required bool accepted}) =>
      _emit('call_response', {'call_id': callId, 'accepted': accepted});
}

// ─── Connection state enum ────────────────────────────────────────────────────

enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}
