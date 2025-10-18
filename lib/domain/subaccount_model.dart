class SubaccountModel {
  bool? status;
  String? message;
  List<Data>? data;

  SubaccountModel({this.status, this.message, this.data});

  SubaccountModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
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

class Data {
  String? id;
  String? username;
  String? phoneNumber;
  String? passwordGen;
  String? role;
  bool? isSubaccount;
  String? subMainAccount;

  Data(
      {this.id,
      this.username,
      this.phoneNumber,
      this.passwordGen,
      this.role,
      this.isSubaccount,
      this.subMainAccount});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    phoneNumber = json['phoneNumber'];
    passwordGen = json['passwordGen'];
    role = json['role'];
    isSubaccount = json['isSubaccount'];
    subMainAccount = json['subMainAccount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['phoneNumber'] = phoneNumber;
    data['passwordGen'] = passwordGen;
    data['role'] = role;
    data['isSubaccount'] = isSubaccount;
    data['subMainAccount'] = subMainAccount;
    return data;
  }
}
