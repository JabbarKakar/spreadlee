class OtpModel {
  final String? message;
  final String? token;
  final String? otpExpiry;
  final Data? data;

  OtpModel({
    this.message,
    this.token,
    this.otpExpiry,
    this.data,
  });

  factory OtpModel.fromJson(Map<String, dynamic> json) {
    return OtpModel(
      message: json['message'],
      token: json['token'],
      otpExpiry: json['otpExpiry'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }
}

class Data {
  String? id;
  String? email;
  String? role;
  String? customer_country;
  String? commercialName;
  String? publicName;
  String? photoUrl;
  String? subMainAccount;
  String? username;
  // Ensure it's correctly typed

  Data(
      {this.id,
      this.email,
      this.role,
      this.customer_country,
      this.commercialName,
      this.publicName,
      this.photoUrl,
      this.subMainAccount,
      this.username});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? json['_id'];
    email = json['email'];
    role = json['role'];
    customer_country = json['customer_country'];
    commercialName = json['commercialName'];
    publicName = json['publicName'];
    photoUrl = json['photoUrl'];
    subMainAccount = json['subMainAccount'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'role': role,
      'customer_country': customer_country,
      'commercialName': commercialName,
      'publicName': publicName,
      'photoUrl': photoUrl,
      'subMainAccount': subMainAccount,
      'username': username,
    };
  }
}
