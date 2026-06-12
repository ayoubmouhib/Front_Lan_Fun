import '../datasources/remote/conversation_api.dart';
import '../models/conversation_model.dart';

class ConversationRepository {
  ConversationRepository(this._api);
  final ConversationApi _api;

  // ─── Conversations ────────────────────────────────────────────────────────

  /// GET /conversations
  Future<List<ConversationModel>> getConversations() =>
      _api.getUserConversations();

  /// GET /conversations/:id
  Future<ConversationModel> getConversation(int id) =>
      _api.getConversation(id);

  /// PUT /conversations/:id/archive
  Future<void> archiveConversation(int id) =>
      _api.archiveConversation(id);

  /// DELETE /conversations/:id
  Future<void> deleteConversation(int id) =>
      _api.deleteConversation(id);

  // ─── Messages ─────────────────────────────────────────────────────────────

  /// GET /conversations/:id/messages
  Future<MessagesPage> getMessages(
    int conversationId, {
    int offset = 0,
    int limit = 50,
    bool sortAsc = true,
  }) =>
      _api.getMessages(
        conversationId,
        offset: offset,
        limit: limit,
        sortAsc: sortAsc,
      );

  /// POST /conversations/:id/messages
  Future<MessageModel> sendMessage(int conversationId, String content,
          {String type = 'text', int? replyToMessageId}) =>
      _api.sendMessage(conversationId, content,
          type: type, replyToMessageId: replyToMessageId);

  /// PUT /conversations/:id/messages/:messageId
  Future<MessageModel> editMessage(
          int conversationId, int messageId, String newContent) =>
      _api.editMessage(conversationId, messageId, newContent);

  /// DELETE /conversations/:id/messages/:messageId
  Future<void> deleteMessage(int conversationId, int messageId) =>
      _api.deleteMessage(conversationId, messageId);

  /// POST /conversations/:id/messages/:messageId/react
  Future<void> reactToMessage(
          int conversationId, int messageId, String emoji) =>
      _api.reactToMessage(conversationId, messageId, emoji);

  /// POST /conversations/:id/messages/:messageId/pin
  Future<void> pinMessage(int conversationId, int messageId, {bool pin = true}) =>
      _api.pinMessage(conversationId, messageId, pin: pin);

  /// GET /conversations/:id/messages/pinned
  Future<List<Map<String, dynamic>>> getPinnedMessages(int conversationId) =>
      _api.getPinnedMessages(conversationId);

  // ─── Calls ────────────────────────────────────────────────────────────────

  /// POST /conversations/:id/calls/initiate
  Future<Map<String, dynamic>> initiateCall(
    int conversationId, {
    required String type, // 'audio' | 'video'
  }) =>
      _api.initiateCall(conversationId, type: type);

  /// POST /conversations/calls/:callId/accept
  Future<Map<String, dynamic>> acceptCall(int callId) =>
      _api.acceptCall(callId);

  /// POST /conversations/calls/:callId/reject
  Future<void> rejectCall(int callId) => _api.rejectCall(callId);

  /// POST /conversations/calls/:callId/end
  Future<Map<String, dynamic>> endCall(int callId,
          {required int durationSeconds}) =>
      _api.endCall(callId, durationSeconds: durationSeconds);

  /// GET /conversations/:id/calls
  Future<List<Map<String, dynamic>>> getCallHistory(int conversationId) =>
      _api.getCallHistory(conversationId);

  /// PUT /conversations/calls/:callId/quality
  Future<void> updateCallQuality(
    int callId, {
    int? bitrate,
    int? latency,
    int? packetLoss,
  }) =>
      _api.updateCallQuality(
        callId,
        bitrate: bitrate,
        latency: latency,
        packetLoss: packetLoss,
      );
}
