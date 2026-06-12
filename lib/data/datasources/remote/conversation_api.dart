import '../../models/conversation_model.dart';
import 'api_client.dart';

class ConversationApi {
  ConversationApi(this._client);
  final ApiClient _client;

  // GET /conversations
  Future<List<ConversationModel>> getUserConversations() async {
    final res = await _client.get('/conversations');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /conversations/:id
  Future<ConversationModel> getConversation(int id) async {
    final res = await _client.get('/conversations/$id');
    return ConversationModel.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /conversations/:id/messages
  // Backend uses offset (not page) and sort_asc flag.
  Future<MessagesPage> getMessages(
    int conversationId, {
    int offset = 0,
    int limit = 50,
    bool sortAsc = true,
  }) async {
    final res = await _client.get(
      '/conversations/$conversationId/messages',
      queryParameters: {
        'offset': offset,
        'limit': limit,
        'sort_asc': sortAsc,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final list = (data['messages'] as List<dynamic>?) ?? [];
    return MessagesPage(
      total: data['total'] as int? ?? 0,
      messages: list
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // POST /conversations/:id/messages
  Future<MessageModel> sendMessage(
    int conversationId,
    String content, {
    String type = 'text',
    int? replyToMessageId,
  }) async {
    final res = await _client.post(
      '/conversations/$conversationId/messages',
      data: {
        'content': content,
        'type': type,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      },
    );
    return MessageModel.fromJson(res.data as Map<String, dynamic>);
  }

  // PUT /conversations/:id/messages/:messageId (edit)
  Future<MessageModel> editMessage(
    int conversationId,
    int messageId,
    String newContent,
  ) async {
    final res = await _client.put(
      '/conversations/$conversationId/messages/$messageId',
      data: {'content': newContent},
    );
    return MessageModel.fromJson(res.data as Map<String, dynamic>);
  }

  // DELETE /conversations/:id/messages/:messageId
  Future<void> deleteMessage(int conversationId, int messageId) async {
    await _client.delete('/conversations/$conversationId/messages/$messageId');
  }

  // POST /conversations/:id/messages/:messageId/react
  // add=true adds the reaction, add=false removes it
  Future<void> reactToMessage(
    int conversationId,
    int messageId,
    String emoji, {
    bool add = true,
  }) async {
    await _client.post(
      '/conversations/$conversationId/messages/$messageId/react',
      data: {'emoji': emoji, 'add': add},
    );
  }

  // POST /conversations/:id/messages/:messageId/pin
  Future<void> pinMessage(int conversationId, int messageId, {bool pin = true}) async {
    await _client.post(
      '/conversations/$conversationId/messages/$messageId/pin',
      data: {'pin': pin},
    );
  }

  // ─── Call endpoints ────────────────────────────────────────────────────────

  // POST /conversations/:id/calls/initiate
  Future<Map<String, dynamic>> initiateCall(
    int conversationId, {
    required String type, // 'audio' | 'video'
  }) async {
    final res = await _client.post(
      '/conversations/$conversationId/calls/initiate',
      data: {'type': type},
    );
    return res.data as Map<String, dynamic>;
  }

  // POST /conversations/calls/:callId/accept
  Future<Map<String, dynamic>> acceptCall(int callId) async {
    final res = await _client.post('/conversations/calls/$callId/accept',
        data: <String, dynamic>{});
    return res.data as Map<String, dynamic>;
  }

  // POST /conversations/calls/:callId/reject
  Future<void> rejectCall(int callId) async {
    await _client.post('/conversations/calls/$callId/reject');
  }

  // POST /conversations/calls/:callId/end
  Future<Map<String, dynamic>> endCall(
    int callId, {
    required int durationSeconds,
  }) async {
    final res = await _client.post(
      '/conversations/calls/$callId/end',
      data: {'duration_seconds': durationSeconds},
    );
    return res.data as Map<String, dynamic>;
  }

  // GET /conversations/:id/calls
  Future<List<Map<String, dynamic>>> getCallHistory(int conversationId) async {
    final res = await _client.get('/conversations/$conversationId/calls');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  // PUT /conversations/calls/:callId/quality
  Future<void> updateCallQuality(
    int callId, {
    int? bitrate,
    int? latency,
    int? packetLoss,
  }) async {
    final body = <String, dynamic>{};
    if (bitrate != null) body['bitrate'] = bitrate;
    if (latency != null) body['latency'] = latency;
    if (packetLoss != null) body['packet_loss'] = packetLoss;
    await _client.put('/conversations/calls/$callId/quality', data: body);
  }

  // GET /conversations/:conversationId/messages/pinned
  Future<List<Map<String, dynamic>>> getPinnedMessages(
      int conversationId) async {
    final res = await _client
        .get('/conversations/$conversationId/messages/pinned');
    final data = res.data;
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map) {
      return List<Map<String, dynamic>>.from(
          data['messages'] as List? ?? []);
    }
    return [];
  }

  // PUT /conversations/:id/archive
  Future<void> archiveConversation(int id) async {
    await _client.put('/conversations/$id/archive');
  }

  // DELETE /conversations/:id
  Future<void> deleteConversation(int id) async {
    await _client.delete('/conversations/$id');
  }
}

class MessagesPage {
  const MessagesPage({required this.total, required this.messages});
  final int total;
  final List<MessageModel> messages;
}
