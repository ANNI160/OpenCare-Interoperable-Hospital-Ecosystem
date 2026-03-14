class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String receiverId;
  final String receiverName;
  final String patientId;
  final String patientName;
  final String content;
  final String type;
  final DateTime sentAt;
  final bool isDelivered;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? attachmentUrl;
  final String? voiceNotePath;
  final int? voiceDurationSeconds;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.receiverId,
    required this.receiverName,
    required this.patientId,
    required this.patientName,
    required this.content,
    this.type = 'text',
    required this.sentAt,
    this.isDelivered = false,
    this.isRead = false,
    this.deliveredAt,
    this.readAt,
    this.attachmentUrl,
    this.voiceNotePath,
    this.voiceDurationSeconds,
  });

  bool get isTextMessage => type == 'text';
  bool get isVoiceMessage => type == 'voice';
  bool get isImageMessage => type == 'image';

  String get statusLabel {
    if (isRead) return 'Read';
    if (isDelivered) return 'Delivered';
    return 'Sent';
  }

  String get voiceDurationLabel {
    if (voiceDurationSeconds == null) return '0:00';
    final minutes = voiceDurationSeconds! ~/ 60;
    final seconds = voiceDurationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderRole: json['sender_role'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      sentAt: DateTime.parse(json['sent_at'] ?? DateTime.now().toIso8601String()),
      isDelivered: json['is_delivered'] ?? false,
      isRead: json['is_read'] ?? false,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      attachmentUrl: json['attachment_url'],
      voiceNotePath: json['voice_note_path'],
      voiceDurationSeconds: json['voice_duration_seconds'],
    );
  }

  Map<String, dynamic> toJson() => {
    'receiver_id': receiverId,
    'receiver_name': receiverName,
    'patient_id': patientId,
    'patient_name': patientName,
    'content': content,
    'type': type,
    'voice_note_path': voiceNotePath,
    'voice_duration_seconds': voiceDurationSeconds,
  };
}
