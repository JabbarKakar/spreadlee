// API Response Models
class ClientRequestResponse {
  final String? message;
  final List<ClientRequestData>? data;

  ClientRequestResponse({
    this.message,
    this.data,
  });

  factory ClientRequestResponse.fromJson(Map<String, dynamic> json) {
    return ClientRequestResponse(
      message: json['message'] as String?,
      data: json['data'] != null
          ? List<ClientRequestData>.from(
              (json['data'] as List).map((x) => ClientRequestData.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data?.map((x) => x.toJson()).toList(),
    };
  }
}

class ClientRequestData {
  final Company? company;
  final String id;
  final int? statusCode;
  final Client? client;
  final bool? accepted;
  final String? createdTime;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  ClientRequestData({
    this.company,
    required this.id,
    this.statusCode,
    this.client,
    this.accepted,
    this.createdTime,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory ClientRequestData.fromJson(Map<String, dynamic> json) {
    return ClientRequestData(
      company:
          json['company'] != null ? Company.fromJson(json['company']) : null,
      id: json['_id'] as String,
      statusCode: json['status_code'] as int?,
      client: json['client'] != null ? Client.fromJson(json['client']) : null,
      accepted: json['accepted'] as bool?,
      createdTime: json['created_time'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      version: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company?.toJson(),
      '_id': id,
      'status_code': statusCode,
      'client': client?.toJson(),
      'accepted': accepted,
      'created_time': createdTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
    };
  }
}

class Client {
  final String id;
  final String? companyName;
  final String? commercialName;
  final dynamic commercialNumber;
  final int? vatNumber;

  Client({
    required this.id,
    this.companyName,
    this.commercialName,
    this.commercialNumber,
    this.vatNumber,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] as String,
      companyName: json['companyName'] as String?,
      commercialName: json['commercialName'] as String?,
      commercialNumber: json['commercialNumber'],
      vatNumber: json['vATNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'companyName': companyName,
      'commercialName': commercialName,
      'commercialNumber': commercialNumber,
      'vATNumber': vatNumber,
    };
  }
}

class Company {
  final String? customerId;
  final CustomerCompany? customerCompany;

  Company({
    this.customerId,
    this.customerCompany,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      customerId: json['customerId'] as String?,
      customerCompany: json['customer_companyId'] != null
          ? CustomerCompany.fromJson(json['customer_companyId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customer_companyId': customerCompany?.toJson(),
    };
  }
}

class CustomerCompany {
  final String id;
  final String? customerId;
  final String? countryName;
  final String? companyName;
  final String? commercialName;
  final dynamic commercialNumber;
  final int? vatNumber;
  final String? vatCertificate;
  final String? comRegForm;
  final String? brief;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  CustomerCompany({
    required this.id,
    this.customerId,
    this.countryName,
    this.companyName,
    this.commercialName,
    this.commercialNumber,
    this.vatNumber,
    this.vatCertificate,
    this.comRegForm,
    this.brief,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory CustomerCompany.fromJson(Map<String, dynamic> json) {
    return CustomerCompany(
      id: json['_id'] as String,
      customerId: json['customerId'] as String?,
      countryName: json['countryName'] as String?,
      companyName: json['companyName'] as String?,
      commercialName: json['commercialName'] as String?,
      commercialNumber: json['commercialNumber'],
      vatNumber: json['vATNumber'] as int?,
      vatCertificate: json['vATCertificate'] as String?,
      comRegForm: json['comRegForm'] as String?,
      brief: json['brief'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      version: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customerId': customerId,
      'countryName': countryName,
      'companyName': companyName,
      'commercialName': commercialName,
      'commercialNumber': commercialNumber,
      'vATNumber': vatNumber,
      'vATCertificate': vatCertificate,
      'comRegForm': comRegForm,
      'brief': brief,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
    };
  }
}

// Extension to convert API models to domain models
extension ClientRequestDataExtension on ClientRequestData {
  ClientRequestModel toDomainModel() {
    return ClientRequestModel(
      id: id,
      companyName: company?.customerCompany?.companyName ?? '',
      companyId: company?.customerCompany?.id ?? '',
      customerId: company?.customerId ?? '',
      createdAt:
          createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
      statusCode: statusCode ?? 0,
      isAccepted: accepted ?? false,
      countryName: company?.customerCompany?.countryName,
      commercialName: company?.customerCompany?.commercialName,
      commercialNumber: company?.customerCompany?.commercialNumber,
      brief: company?.customerCompany?.brief,
      vatNumber: company?.customerCompany?.vatNumber,
      clientCompanyName: client?.companyName,
      clientCommercialName: client?.commercialName,
      clientCommercialNumber: client?.commercialNumber,
      clientVatNumber: client?.vatNumber,
    );
  }
}

// Domain model for use in the UI
class ClientRequestModel {
  final String id;
  final String companyName;
  final String companyId;
  final String customerId;
  final DateTime createdAt;
  final int statusCode;
  final bool isAccepted;
  final String? rejectionReason;
  final String? additionalInfo;
  final String? countryName;
  final String? commercialName;
  final dynamic commercialNumber;
  final String? brief;
  final int? vatNumber;
  final String? clientCompanyName;
  final String? clientCommercialName;
  final String? clientCommercialNumber;
  final int? clientVatNumber;

  ClientRequestModel({
    required this.id,
    required this.companyName,
    required this.companyId,
    required this.customerId,
    required this.createdAt,
    this.statusCode = 0,
    this.isAccepted = false,
    this.rejectionReason,
    this.additionalInfo,
    this.countryName,
    this.commercialName,
    this.commercialNumber,
    this.brief,
    this.vatNumber,
    this.clientCompanyName,
    this.clientCommercialName,
    this.clientCommercialNumber,
    this.clientVatNumber,
  });

  ClientRequestModel copyWith({
    String? id,
    String? companyName,
    String? companyId,
    String? customerId,
    DateTime? createdAt,
    int? statusCode,
    bool? isAccepted,
    String? rejectionReason,
    String? additionalInfo,
    String? countryName,
    String? commercialName,
    dynamic commercialNumber,
    String? brief,
    int? vatNumber,
    String? clientCompanyName,
    String? clientCommercialName,
    String? clientCommercialNumber,
    int? clientVatNumber,
  }) {
    return ClientRequestModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      statusCode: statusCode ?? this.statusCode,
      isAccepted: isAccepted ?? this.isAccepted,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      countryName: countryName ?? this.countryName,
      commercialName: commercialName ?? this.commercialName,
      commercialNumber: commercialNumber ?? this.commercialNumber,
      brief: brief ?? this.brief,
      vatNumber: vatNumber ?? this.vatNumber,
      clientCompanyName: clientCompanyName ?? this.clientCompanyName,
      clientCommercialName: clientCommercialName ?? this.clientCommercialName,
      clientCommercialNumber:
          clientCommercialNumber ?? this.clientCommercialNumber,
      clientVatNumber: clientVatNumber ?? this.clientVatNumber,
    );
  }
}
