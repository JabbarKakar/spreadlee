class ContactInfoResponse {
  final bool status;
  final String message;
  final ContactInfoData data;

  ContactInfoResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ContactInfoResponse.fromJson(Map<String, dynamic> json) {
    return ContactInfoResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: ContactInfoData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class ContactInfoData {
  final String email;
  final String phoneNumber;
  final String priceTag;

  ContactInfoData({
    required this.email,
    required this.phoneNumber,
    this.priceTag = '',
  });

  factory ContactInfoData.fromJson(Map<String, dynamic> json) {
    return ContactInfoData(
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      priceTag: json['price_tag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone_number': phoneNumber,
      'price_tag': priceTag,
    };
  }
}
