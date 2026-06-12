// Mirrors formatCall() response from conversation.service.ts

class CallModel {
  const CallModel({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.status,
    this.initiator,
    this.receiver,
    this.callToken,
    this.durationSeconds,
    this.wasMissed = false,
    this.canBeRecorded = true,
    this.initiatedAt,
    this.startedAt,
    this.endedAt,
  });

  final int id;
  final int conversationId;
  final String type;    // 'audio' | 'video'
  final String status;  // 'initiated' | 'ringing' | 'accepted' | 'active' | 'ended' | 'missed' | 'rejected'
  final CallParticipant? initiator;
  final CallParticipant? receiver;
  final String? callToken;
  final int? durationSeconds;
  final bool wasMissed;
  final bool canBeRecorded;
  final DateTime? initiatedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get isAudio => type == 'audio';
  bool get isVideo => type == 'video';
  bool get isActive => status == 'active';
  bool get isRinging => status == 'ringing';

  factory CallModel.fromJson(Map<String, dynamic> j) => CallModel(
        id: j['id'] as int,
        conversationId: j['conversation_id'] as int,
        type: j['type'] as String? ?? 'audio',
        status: j['status'] as String? ?? 'initiated',
        initiator: j['initiator'] != null
            ? CallParticipant.fromJson(j['initiator'] as Map<String, dynamic>)
            : null,
        receiver: j['receiver'] != null
            ? CallParticipant.fromJson(j['receiver'] as Map<String, dynamic>)
            : null,
        callToken: j['call_token'] as String?,
        durationSeconds: j['duration_seconds'] as int?,
        wasMissed: j['was_missed'] as bool? ?? false,
        canBeRecorded: j['can_be_recorded'] as bool? ?? true,
        initiatedAt: j['initiated_at'] != null
            ? DateTime.tryParse(j['initiated_at'] as String)
            : null,
        startedAt: j['started_at'] != null
            ? DateTime.tryParse(j['started_at'] as String)
            : null,
        endedAt: j['ended_at'] != null
            ? DateTime.tryParse(j['ended_at'] as String)
            : null,
      );
}

class CallParticipant {
  const CallParticipant({required this.id, required this.name});
  final int id;
  final String name;

  factory CallParticipant.fromJson(Map<String, dynamic> j) => CallParticipant(
        id: j['id'] as int,
        name: j['name'] as String? ?? 'Unknown',
      );
}
