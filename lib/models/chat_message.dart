// Re-export the ChatMessage and MessageCreator classes from domain
export '../../domain/chat_model.dart' show ChatMessage, MessageCreator;

// This file is kept for backward compatibility but now uses the domain model
// All new code should import directly from domain/chat_model.dart

class ChatMessage {
  final String id;
  final String messageText;
  final DateTime? messageDate;
  final String messageCreator;
  final String? messageCreatorRole;
  final bool isSeen;
  final String chatId;
  final String? tempId; // ✅ ADDED: Temporary ID for real-time messages
  final List<String>? messagePhotos;
  final List<String>? messageDocs;
  final Map<String, dynamic>? messageLocation;
  final dynamic messageInvoiceRef;
  final List<String> readBy;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? companyName;
  final String? companyCommercialName;
  final String? companyId;
  final String? senderDisplayRole;
  final bool isTemp;
  final String? messageAudio;
  final String? messageVideo;
  final double? messageAudioDuration;

  ChatMessage({
    required this.id,
    required this.messageText,
    this.messageDate,
    required this.messageCreator,
    this.messageCreatorRole,
    this.isSeen = false,
    required this.chatId,
    this.tempId, // ✅ ADDED: Temporary ID parameter
    this.messagePhotos,
    this.messageDocs,
    this.messageLocation,
    this.messageInvoiceRef,
    this.readBy = const [],
    this.isDeleted = false,
    this.deletedAt,
    this.companyName,
    this.companyCommercialName,
    this.companyId,
    this.senderDisplayRole,
    this.isTemp = false,
    this.messageAudio,
    this.messageVideo,
    this.messageAudioDuration,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['message_id'],
      messageText: json['messageText'],
      messageDate: json['messageDate'] != null
          ? DateTime.parse(json['messageDate'])
          : null,
      messageCreator: json['messageCreator'],
      messageCreatorRole: json['messageCreatorRole'],
      isSeen: json['isSeen'] ?? false,
      chatId: json['chat_id'],
      tempId: json['tempId'], // ✅ ADDED: Parse tempId from JSON
      messagePhotos: json['messagePhotos'] != null
          ? List<String>.from(json['messagePhotos'])
          : null,
      messageDocs: json['messageDocs'] != null
          ? List<String>.from(json['messageDocs'])
          : null,
      messageLocation: json['messageLocation'],
      messageInvoiceRef: json['messageInvoiceRef'],
      readBy: json['readBy'] != null ? List<String>.from(json['readBy']) : [],
      isDeleted: json['isDeleted'] ?? false,
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      companyName: json['company_name'],
      companyCommercialName: json['company_commercial_name'],
      companyId: json['companyId'],
      senderDisplayRole: json['senderDisplayRole'],
      isTemp: json['isTemp'] ?? false,
      messageAudio: json['messageAudio'],
      messageVideo: json['messageVideo'],
      messageAudioDuration: json['messageAudioDuration']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'messageText': messageText,
      'messageDate': messageDate?.toIso8601String(),
      'messageCreator': messageCreator,
      'messageCreatorRole': messageCreatorRole,
      'isSeen': isSeen,
      'chat_id': chatId,
      'tempId': tempId, // ✅ ADDED: Include tempId in JSON
      'messagePhotos': messagePhotos,
      'messageDocs': messageDocs,
      'messageLocation': messageLocation,
      'messageInvoiceRef': messageInvoiceRef,
      'readBy': readBy,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'company_name': companyName,
      'company_commercial_name': companyCommercialName,
      'companyId': companyId,
      'senderDisplayRole': senderDisplayRole,
      'isTemp': isTemp,
      'messageAudio': messageAudio,
      'messageVideo': messageVideo,
      'messageAudioDuration': messageAudioDuration,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? messageText,
    DateTime? messageDate,
    String? messageCreator,
    String? messageCreatorRole,
    bool? isSeen,
    String? chatId,
    String? tempId, // ✅ ADDED: tempId parameter
    List<String>? messagePhotos,
    List<String>? messageDocs,
    Map<String, dynamic>? messageLocation,
    dynamic messageInvoiceRef,
    List<String>? readBy,
    bool? isDeleted,
    DateTime? deletedAt,
    String? companyName,
    String? companyCommercialName,
    String? companyId,
    String? senderDisplayRole,
    bool? isTemp,
    String? messageAudio,
    String? messageVideo,
    double? messageAudioDuration,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      messageText: messageText ?? this.messageText,
      messageDate: messageDate ?? this.messageDate,
      messageCreator: messageCreator ?? this.messageCreator,
      messageCreatorRole: messageCreatorRole ?? this.messageCreatorRole,
      isSeen: isSeen ?? this.isSeen,
      chatId: chatId ?? this.chatId,
      tempId: tempId ?? this.tempId, // ✅ ADDED: tempId assignment
      messagePhotos: messagePhotos ?? this.messagePhotos,
      messageDocs: messageDocs ?? this.messageDocs,
      messageLocation: messageLocation ?? this.messageLocation,
      messageInvoiceRef: messageInvoiceRef ?? this.messageInvoiceRef,
      readBy: readBy ?? this.readBy,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      companyName: companyName ?? this.companyName,
      companyCommercialName:
          companyCommercialName ?? this.companyCommercialName,
      companyId: companyId ?? this.companyId,
      senderDisplayRole: senderDisplayRole ?? this.senderDisplayRole,
      isTemp: isTemp ?? this.isTemp,
      messageAudio: messageAudio ?? this.messageAudio,
      messageVideo: messageVideo ?? this.messageVideo,
      messageAudioDuration: messageAudioDuration ?? this.messageAudioDuration,
    );
  }

  DateTime? get createdAt => messageDate;

  /// Helper to get invoiceId as String regardless of type
  String? get invoiceId {
    if (messageInvoiceRef is String) {
      return messageInvoiceRef as String;
    } else if (messageInvoiceRef is Map) {
      return messageInvoiceRef['_id']?.toString();
    }
    return null;
  }
}
