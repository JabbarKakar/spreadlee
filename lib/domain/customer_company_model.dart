class CustomerCompanyModel {
  bool? status;
  String? message;
  List<CustomerCompanyDataModel>? data;

  CustomerCompanyModel({this.status, this.message, this.data});

  factory CustomerCompanyModel.fromJson(Map<String, dynamic> json) {
    return CustomerCompanyModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] is List
          ? (json['data'] as List)
              .map((item) => CustomerCompanyDataModel.fromJson(item))
              .toList()
          : json['data'] != null
              ? [CustomerCompanyDataModel.fromJson(json['data'])]
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "data": data?.map((item) => item.toJson()).toList(),
    };
  }
}

class CustomerCompanyDataModel {
  String? sId;
  String? countryName;
  String? companyName;
  String? commercialName;
  dynamic commercialNumber;
  int? vATNumber;
  String? vATCertificate;
  String? comRegForm;
  String? brief;
  String? createdAt;
  String? updatedAt;
  int? iV;

  CustomerCompanyDataModel(
      {this.sId,
      this.countryName,
      this.companyName,
      this.commercialName,
      this.commercialNumber,
      this.vATNumber,
      this.vATCertificate,
      this.comRegForm,
      this.brief,
      this.createdAt,
      this.updatedAt,
      this.iV});

  CustomerCompanyDataModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    countryName = json['countryName'];
    companyName = json['companyName'];
    commercialName = json['commercialName'];
    commercialNumber = json['commercialNumber'];
    vATNumber = json['vATNumber'];
    vATCertificate = json['vATCertificate'];
    comRegForm = json['comRegForm'];
    brief = json['brief'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['countryName'] = countryName;
    data['companyName'] = companyName;
    data['commercialName'] = commercialName;
    data['commercialNumber'] = commercialNumber;
    data['vATNumber'] = vATNumber;
    data['vATCertificate'] = vATCertificate;
    data['comRegForm'] = comRegForm;
    data['brief'] = brief;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
