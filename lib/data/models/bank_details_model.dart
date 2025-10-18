class BankDetailsResponse {
  final bool status;
  final String message;
  final BankDetailsData data;

  BankDetailsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BankDetailsResponse.fromJson(Map<String, dynamic> json) {
    return BankDetailsResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: BankDetailsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class BankUpdation {
  final bool updated;
  final String updateTime;
  final bool adminUpdated;
  final bool accepted;
  final bool rejected;
  final String rejectedInfo;

  BankUpdation({
    required this.updated,
    required this.updateTime,
    required this.adminUpdated,
    required this.accepted,
    required this.rejected,
    required this.rejectedInfo,
  });

  factory BankUpdation.fromJson(Map<String, dynamic> json) {
    return BankUpdation(
      updated: json['updated'] as bool? ?? false,
      updateTime: json['update_time'] as String? ?? '',
      adminUpdated: json['admin_updated'] as bool? ?? false,
      accepted: json['accepted'] as bool? ?? false,
      rejected: json['rejected'] as bool? ?? false,
      rejectedInfo: json['rejected_info'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updated': updated,
      'update_time': updateTime,
      'admin_updated': adminUpdated,
      'accepted': accepted,
      'rejected': rejected,
      'rejected_info': rejectedInfo,
    };
  }
}

class BankDetailsData {
  final int bankBranchCode;
  final String bankCountry;
  final String bankName;
  final String bankHolderName;
  final int bankAccountNumber;
  final String bankIBANNumber;
  final String bankBranchName;
  final String bankSwiftCode;
  final BankUpdation updation;

  BankDetailsData({
    required this.bankBranchCode,
    required this.bankCountry,
    required this.bankName,
    required this.bankHolderName,
    required this.bankAccountNumber,
    required this.bankIBANNumber,
    required this.bankBranchName,
    required this.bankSwiftCode,
    required this.updation,
  });

  factory BankDetailsData.fromJson(Map<String, dynamic> json) {
    return BankDetailsData(
      bankBranchCode: json['bankBranchCode'] as int,
      bankCountry: json['bankCountry'] as String,
      bankName: json['bankName'] as String,
      bankHolderName: json['bankHolderName'] as String,
      bankAccountNumber: json['bankAccountNumber'] as int,
      bankIBANNumber: json['bankIBANNumber'] as String,
      bankBranchName: json['bankBranchName'] as String,
      bankSwiftCode: json['bankSwiftCode'] as String,
      updation: BankUpdation.fromJson(
          json['updation'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankBranchCode': bankBranchCode,
      'bankCountry': bankCountry,
      'bankName': bankName,
      'bankHolderName': bankHolderName,
      'bankAccountNumber': bankAccountNumber,
      'bankIBANNumber': bankIBANNumber,
      'bankBranchName': bankBranchName,
      'bankSwiftCode': bankSwiftCode,
      'updation': updation.toJson(),
    };
  }

  // Helper getters for backward compatibility
  bool get isRejected => updation.rejected;
  String? get rejectionReason =>
      updation.rejectedInfo.isEmpty ? null : updation.rejectedInfo;
}
