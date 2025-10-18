class LoginModel {
  String? otpExpiry;
  bool? status;
  String? message;
  Data? data;

  LoginModel({this.otpExpiry, this.status, this.message, this.data});

  LoginModel.fromJson(Map<String, dynamic> json) {
    otpExpiry = json['otpExpiry'];
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['otpExpiry'] = otpExpiry;
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? phoneNumber;
  String? email;
  String? identifier; // The actual field returned by the API

  Data({this.phoneNumber, this.email, this.identifier});

  Data.fromJson(Map<String, dynamic> json) {
    phoneNumber = json['phoneNumber'];
    email = json['email'];
    identifier = json['identifier']; // Parse the identifier field
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phoneNumber'] = phoneNumber;
    data['email'] = email;
    data['identifier'] = identifier; // Include identifier in toJson
    return data;
  }
}
