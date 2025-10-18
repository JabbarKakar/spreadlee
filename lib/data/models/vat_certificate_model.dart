class VatCertificateResponse {
  final bool status;
  final String message;
  final VatCertificateData data;

  VatCertificateResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory VatCertificateResponse.fromJson(Map<String, dynamic> json) {
    return VatCertificateResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: VatCertificateData.fromJson(json['data'] ?? {}),
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

class VatCertificateData {
  final String vatNumber;
  final String vatCertificate;

  VatCertificateData({
    required this.vatNumber,
    required this.vatCertificate,
  });

  factory VatCertificateData.fromJson(Map<String, dynamic> json) {
    return VatCertificateData(
      vatNumber: json['vATNumber']?.toString() ?? '',
      vatCertificate: json['vATCertificate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vATNumber': vatNumber,
      'vATCertificate': vatCertificate,
    };
  }
}
