class TicketsResponse {
  bool? status;
  List<TicketData>? data;

  TicketsResponse({this.status, this.data});

  TicketsResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <TicketData>[];
      json['data'].forEach((v) {
        data!.add(TicketData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TicketData {
  TicketCreator? creator;
  TicketAssignedTo? assignedTo;
  String? sId;
  String? title;
  String? description;
  String? status;
  bool? isChatActive;
  ChatData? chatId;
  String? createdAt;
  String? updatedAt;
  int? iV;
  int? ticketNumber;

  TicketData({
    this.creator,
    this.assignedTo,
    this.sId,
    this.title,
    this.description,
    this.status,
    this.isChatActive,
    this.chatId,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.ticketNumber,
  });

  TicketData.fromJson(Map<String, dynamic> json) {
    creator = json['creator'] != null
        ? TicketCreator.fromJson(json['creator'])
        : null;
    assignedTo = json['assignedTo'] != null
        ? TicketAssignedTo.fromJson(json['assignedTo'])
        : null;
    sId = json['_id'];
    title = json['title'];
    description = json['description'];
    status = json['status'];
    isChatActive = json['isChatActive'];
    chatId = json['chatId'] != null ? ChatData.fromJson(json['chatId']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    ticketNumber = json['ticketNumber'] != null
        ? int.parse(json['ticketNumber'].toString())
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (creator != null) {
      data['creator'] = creator!.toJson();
    }
    if (assignedTo != null) {
      data['assignedTo'] = assignedTo!.toJson();
    }
    data['_id'] = sId;
    data['title'] = title;
    data['description'] = description;
    data['status'] = status;
    data['isChatActive'] = isChatActive;
    if (chatId != null) {
      data['chatId'] = chatId!.toJson();
    }
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['ticketNumber'] = ticketNumber;
    return data;
  }
}

class ChatData {
  ChatUsers? chatUsers;
  TicketRef? ticketRef;
  String? sId;
  String? chatLastMessage;
  int? chatNotSeenMessages;
  String? chatCompanyName;
  String? chatCustomerCompanyName;
  String? chatCustomerCommercialName;
  bool? isDeleted;
  bool? isClosed;
  bool? isTicketChat;
  bool? isActive;
  bool? isAdminJoined;
  List<ChatParticipant>? participants;
  String? createdAt;
  String? updatedAt;
  int? iV;

  ChatData({
    this.chatUsers,
    this.ticketRef,
    this.sId,
    this.chatLastMessage,
    this.chatNotSeenMessages,
    this.chatCompanyName,
    this.chatCustomerCompanyName,
    this.chatCustomerCommercialName,
    this.isDeleted,
    this.isClosed,
    this.isTicketChat,
    this.isActive,
    this.isAdminJoined,
    this.participants,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  ChatData.fromJson(Map<String, dynamic> json) {
    chatUsers = json['chat_users'] != null
        ? ChatUsers.fromJson(json['chat_users'])
        : null;
    ticketRef = json['ticket_ref'] != null
        ? TicketRef.fromJson(json['ticket_ref'])
        : null;
    sId = json['_id'];
    chatLastMessage = json['chat_last_message'];
    chatNotSeenMessages = json['chat_not_seen_messages'];
    chatCompanyName = json['chat_company_name'];
    chatCustomerCompanyName = json['chat_customer_company_name'];
    chatCustomerCommercialName = json['chat_customer_commercial_name'];
    isDeleted = json['isDeleted'];
    isClosed = json['isClosed'];
    isTicketChat = json['isTicketChat'];
    isActive = json['isActive'];
    isAdminJoined = json['isAdminJoined'];
    if (json['participants'] != null) {
      participants = <ChatParticipant>[];
      json['participants'].forEach((v) {
        participants!.add(ChatParticipant.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (chatUsers != null) {
      data['chat_users'] = chatUsers!.toJson();
    }
    if (ticketRef != null) {
      data['ticket_ref'] = ticketRef!.toJson();
    }
    data['_id'] = sId;
    data['chat_last_message'] = chatLastMessage;
    data['chat_not_seen_messages'] = chatNotSeenMessages;
    data['chat_company_name'] = chatCompanyName;
    data['chat_customer_company_name'] = chatCustomerCompanyName;
    data['chat_customer_commercial_name'] = chatCustomerCommercialName;
    data['isDeleted'] = isDeleted;
    data['isClosed'] = isClosed;
    data['isTicketChat'] = isTicketChat;
    data['isActive'] = isActive;
    data['isAdminJoined'] = isAdminJoined;
    if (participants != null) {
      data['participants'] = participants!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class ChatUsers {
  String? customerId;
  String? companyId;

  ChatUsers({this.customerId, this.companyId});

  ChatUsers.fromJson(Map<String, dynamic> json) {
    customerId = json['customerId'];
    companyId = json['companyId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['customerId'] = customerId;
    data['companyId'] = companyId;
    return data;
  }
}

class TicketRef {
  String? ticketId;

  TicketRef({this.ticketId});

  TicketRef.fromJson(Map<String, dynamic> json) {
    ticketId = json['ticketId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ticketId'] = ticketId;
    return data;
  }
}

class ChatParticipant {
  String? userId;
  String? role;
  String? joinedAt;
  String? sId;

  ChatParticipant({this.userId, this.role, this.joinedAt, this.sId});

  ChatParticipant.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    role = json['role'];
    joinedAt = json['joinedAt'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['role'] = role;
    data['joinedAt'] = joinedAt;
    data['_id'] = sId;
    return data;
  }
}

class TicketAssignedTo {
  String? userId;
  String? name;
  String? role;

  TicketAssignedTo({this.userId, this.name, this.role});

  TicketAssignedTo.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    name = json['name'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['name'] = name;
    data['role'] = role;
    return data;
  }
}

class TicketCreator {
  String? userId;
  String? userType;

  TicketCreator({this.userId, this.userType});

  TicketCreator.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userType = json['userType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userType'] = userType;
    return data;
  }
}
