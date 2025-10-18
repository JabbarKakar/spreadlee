class ChatResponse {
  final bool? status;
  final ChatData? data;

  ChatResponse({this.status, this.data});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      status: json['status'],
      data: json['data'] != null ? ChatData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data?.toJson(),
    };
  }
}

class ChatData {
  final List<ChatMessageResponse>? messages;
  final int? totalCount;
  final bool? hasMore;

  ChatData({this.messages, this.totalCount, this.hasMore});

  factory ChatData.fromJson(Map<String, dynamic> json) {
    return ChatData(
      messages: json['messages'] != null
          ? List<ChatMessageResponse>.from(
              json['messages'].map((x) => ChatMessageResponse.fromJson(x)))
          : null,
      totalCount: json['totalCount'],
      hasMore: json['hasMore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages?.map((x) => x.toJson()).toList(),
      'totalCount': totalCount,
      'hasMore': hasMore,
    };
  }
}

class ChatMessageResponse {
  final String? id;
  final List<String>? messagePhotos;
  final String? messageText;
  final String? messageDate;
  final MessageCreator? messageCreator;
  final String? messageCreatorRole;
  final List<String>? messageDocs;
  final String? messageId;
  final String? chatId;
  final bool? isSameDayWithPreviousMessage;
  final bool? isSeen;
  final bool? isReceived;
  final String? userId;
  final String? messageDateString;
  final List<ReadBy>? readBy;
  final bool? isDeleted;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final int? version;
  final dynamic messageLocation;
  final dynamic messageInvoiceRef;

  ChatMessageResponse({
    this.id,
    this.messagePhotos,
    this.messageText,
    this.messageDate,
    this.messageCreator,
    this.messageCreatorRole,
    this.messageDocs,
    this.messageId,
    this.chatId,
    this.isSameDayWithPreviousMessage,
    this.isSeen,
    this.isReceived,
    this.userId,
    this.messageDateString,
    this.readBy,
    this.isDeleted,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.version,
    this.messageLocation,
    this.messageInvoiceRef,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      id: json['_id'],
      messagePhotos: json['messagePhotos'] != null
          ? List<String>.from(json['messagePhotos'])
          : null,
      messageText: json['messageText'],
      messageDate: json['messageDate'],
      messageCreator: json['messageCreator'] != null
          ? MessageCreator.fromJson(json['messageCreator'])
          : null,
      messageCreatorRole: json['messageCreatorRole'],
      messageDocs: json['messageDocs'] != null
          ? List<String>.from(json['messageDocs'])
          : null,
      messageId: json['message_id'],
      chatId: json['chat_id'],
      isSameDayWithPreviousMessage: json['isSameDayWithPreviousMessage'],
      isSeen: json['isSeen'],
      isReceived: json['isReceived'],
      userId: json['user_id'],
      messageDateString: json['messageDateString'],
      readBy: json['readBy'] != null
          ? List<ReadBy>.from(json['readBy'].map((x) => ReadBy.fromJson(x)))
          : null,
      isDeleted: json['isDeleted'],
      deletedAt: json['deletedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      version: json['__v'],
      messageLocation: json['messageLocation'],
      messageInvoiceRef: json['messageInvoiceRef'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'messagePhotos': messagePhotos,
      'messageText': messageText,
      'messageDate': messageDate,
      'messageCreator': messageCreator?.toJson(),
      'messageCreatorRole': messageCreatorRole,
      'messageDocs': messageDocs,
      'message_id': messageId,
      'chat_id': chatId,
      'isSameDayWithPreviousMessage': isSameDayWithPreviousMessage,
      'isSeen': isSeen,
      'isReceived': isReceived,
      'user_id': userId,
      'messageDateString': messageDateString,
      'readBy': readBy?.map((x) => x.toJson()).toList(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
      'messageLocation': messageLocation,
      'messageInvoiceRef': messageInvoiceRef,
    };
  }
}

class MessageCreator {
  final String? id;
  final String? role;
  final String? username;
  final String? photoUrl;

  MessageCreator({this.id, this.role, this.username, this.photoUrl});

  factory MessageCreator.fromJson(Map<String, dynamic> json) {
    return MessageCreator(
      id: json['_id'],
      role: json['role'],
      username: json['username'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'role': role,
      'username': username,
      'photoUrl': photoUrl,
    };
  }
}

class ReadBy {
  final String? userId;
  final String? readAt;
  final String? id;

  ReadBy({this.userId, this.readAt, this.id});

  factory ReadBy.fromJson(Map<String, dynamic> json) {
    return ReadBy(
      userId: json['userId'],
      readAt: json['readAt'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'readAt': readAt,
      '_id': id,
    };
  }
}
