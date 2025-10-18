class RejectedRequestModel {
  bool? status;
  String? message;
  List<RejectedRequestData>? data;

  RejectedRequestModel({this.status, this.message, this.data});

  RejectedRequestModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <RejectedRequestData>[];
      json['data'].forEach((v) {
        data!.add(RejectedRequestData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RejectedRequestData {
  Company? company;
  RejectedData? rejectedData;
  String? sId;
  int? statusCode;
  Client? client;
  String? clientId;
  bool? accepted;
  String? createdTime;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? rejectionReason;

  RejectedRequestData({
    this.company,
    this.rejectedData,
    this.sId,
    this.statusCode,
    this.client,
    this.clientId,
    this.accepted,
    this.createdTime,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.rejectionReason,
  });

  RejectedRequestData.fromJson(Map<String, dynamic> json) {
    company =
        json['company'] != null ? Company.fromJson(json['company']) : null;
    rejectedData = json['rejected_data'] != null
        ? RejectedData.fromJson(json['rejected_data'])
        : null;
    sId = json['_id'];
    statusCode = json['status_code'];
    if (json['client'] != null) {
      if (json['client'] is Map<String, dynamic>) {
        client = Client.fromJson(json['client']);
      } else {
        clientId = json['client'].toString();
      }
    }
    accepted = json['accepted'];
    createdTime = json['created_time'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    rejectionReason = json['rejection_reason'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (company != null) {
      data['company'] = company!.toJson();
    }
    if (rejectedData != null) {
      data['rejected_data'] = rejectedData!.toJson();
    }
    data['_id'] = sId;
    data['status_code'] = statusCode;
    if (client != null) {
      data['client'] = client!.toJson();
    } else if (clientId != null) {
      data['client'] = clientId;
    }
    data['accepted'] = accepted;
    data['created_time'] = createdTime;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['rejection_reason'] = rejectionReason;
    return data;
  }
}

class Company {
  String? customerId;
  String? customerCompanyId;

  Company({this.customerId, this.customerCompanyId});

  Company.fromJson(Map<String, dynamic> json) {
    customerId = json['customerId'];
    customerCompanyId = json['customer_companyId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['customerId'] = customerId;
    data['customer_companyId'] = customerCompanyId;
    return data;
  }
}

class RejectedData {
  bool? read;
  String? reason;
  String? time;

  RejectedData({this.read, this.reason, this.time});

  RejectedData.fromJson(Map<String, dynamic> json) {
    read = json['read'];
    reason = json['reason'];
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['read'] = read;
    data['reason'] = reason;
    data['time'] = time;
    return data;
  }
}

class Client {
  String? sId;
  String? companyName;
  String? commercialName;
  String? photoUrl;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Client({
    this.sId,
    this.companyName,
    this.commercialName,
    this.photoUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  Client.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    companyName = json['companyName'];
    commercialName = json['commercialName'];
    photoUrl = json['photoUrl'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['companyName'] = companyName;
    data['commercialName'] = commercialName;
    data['photoUrl'] = photoUrl;
    data['status'] = status;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
