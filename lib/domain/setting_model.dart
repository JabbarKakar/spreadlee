class SettingResponse {
  final bool status;
  final String message;
  final dynamic data;

  const SettingResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SettingResponse.fromJson(Map<String, dynamic> json) {
    return SettingResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }
}

class SettingData {
  final String pricingDetails;

  const SettingData({
    required this.pricingDetails,
  });

  factory SettingData.fromJson(dynamic json) {
    if (json is String) {
      return SettingData(pricingDetails: json);
    } else if (json is Map<String, dynamic>) {
      return SettingData(
        pricingDetails: json['pricingDetails'] as String,
      );
    }
    throw Exception('Invalid data format');
  }

  Map<String, dynamic> toJson() {
    return {
      'pricingDetails': pricingDetails,
    };
  }
}


class SettingDataPhoto {
  final String photoUrl;

  const SettingDataPhoto({
    required this.photoUrl,
  });

  factory SettingDataPhoto.fromJson(dynamic json) {
    if (json is String) {
      return SettingDataPhoto(photoUrl: json);
    } else if (json is Map<String, dynamic>) {
      return SettingDataPhoto(
        photoUrl: json['photoUrl'] as String,
      );
    }
    throw Exception('Invalid data format');
  }

  Map<String, dynamic> toJson() {
    return {
      'photoUrl': photoUrl,
    };
  }
}