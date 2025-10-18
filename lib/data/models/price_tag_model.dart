class PriceTagResponse {
  final bool status;
  final String message;
  final PriceTagData data;

  PriceTagResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PriceTagResponse.fromJson(Map<String, dynamic> json) {
    return PriceTagResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: PriceTagData.fromJson(json['data'] as Map<String, dynamic>),
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

class PriceTagData {
  final String priceTag;

  PriceTagData({
    required this.priceTag,
  });

  factory PriceTagData.fromJson(Map<String, dynamic> json) {
    return PriceTagData(
      priceTag: json['price_tag'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price_tag': priceTag,
    };
  }
}
