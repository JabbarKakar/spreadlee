class TaxInvoiceResponse {
  final bool? status;
  final String? message;
  final List<TaxInvoiceData>? data;

  TaxInvoiceResponse({
    this.status,
    this.message,
    this.data,
  });

  factory TaxInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return TaxInvoiceResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? List<TaxInvoiceData>.from(
              json['data'].map((x) => TaxInvoiceData.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data?.map((x) => x.toJson()).toList(),
      };
}

class TaxInvoiceData {
  final String? id;
  final int? invoice_id;
  final String? invoice_creation_date;
  final String? invoice_description;
  final int? quantity;
  final double? invoice_amount;
  final int? invoice_vat1;
  final double? invoice_total;
  final double? original_invoice_amount;
  final double? service_fee_percentage;
  final double? vat_on_service_fee;
  final String? tax_invoice_pdf;
  final Seller? seller;
  final Buyer? buyer;

  TaxInvoiceData({
    this.id,
    this.invoice_id,
    this.invoice_creation_date,
    this.invoice_description,
    this.quantity,
    this.invoice_amount,
    this.invoice_vat1,
    this.invoice_total,
    this.original_invoice_amount,
    this.service_fee_percentage,
    this.vat_on_service_fee,
    this.tax_invoice_pdf,
    this.seller,
    this.buyer,
  });

  factory TaxInvoiceData.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double values
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return TaxInvoiceData(
      id: json['_id'] as String?,
      invoice_id: json['invoice_id'] as int?,
      invoice_creation_date: json['invoice_creation_date'] as String?,
      invoice_description: json['invoice_description'] as String?,
      quantity: json['Quantity'] as int?,
      invoice_amount: parseDouble(json['invoice_amount']),
      invoice_vat1: json['invoice_vat1'] as int?,
      invoice_total: parseDouble(json['invoice_total']),
      original_invoice_amount: parseDouble(json['original_invoice_amount']),
      service_fee_percentage: parseDouble(json['service_fee_percentage']),
      vat_on_service_fee: parseDouble(json['vat_on_service_fee']),
      tax_invoice_pdf: json['tax_invoice_pdf'] as String?,
      seller: json['seller'] != null ? Seller.fromJson(json['seller']) : null,
      buyer: json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'invoice_id': invoice_id,
      'invoice_creation_date': invoice_creation_date,
      'invoice_description': invoice_description,
      'Quantity': quantity,
      'invoice_amount': invoice_amount,
      'invoice_vat1': invoice_vat1,
      'invoice_total': invoice_total,
      'original_invoice_amount': original_invoice_amount,
      'service_fee_percentage': service_fee_percentage,
      'vat_on_service_fee': vat_on_service_fee,
      'tax_invoice_pdf': tax_invoice_pdf,
      'seller': seller?.toJson(),
      'buyer': buyer?.toJson(),
    };
  }

  // Helper getters for formatted values
  String get formattedInvoiceAmount =>
      invoice_amount?.toStringAsFixed(2) ?? '0.00';
  String get formattedInvoiceTotal =>
      invoice_total?.toStringAsFixed(2) ?? '0.00';
  String get formattedVatOnServiceFee =>
      vat_on_service_fee?.toStringAsFixed(2) ?? '0.00';
  String get formattedOriginalInvoiceAmount =>
      original_invoice_amount?.toStringAsFixed(2) ?? '0.00';
  String get formattedServiceFeePercentage => '${service_fee_percentage ?? 0}%';
  String get formattedVatPercentage => '${invoice_vat1 ?? 0}%';
}

class Seller {
  final String? companyName;
  final String? address;
  final dynamic commercialNumber;
  final String? vatNumber;

  Seller({
    this.companyName,
    this.address,
    this.commercialNumber,
    this.vatNumber,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      companyName: json['companyName'],
      address: json['address'],
      commercialNumber: json['commercialNumber'],
      vatNumber: json['vATNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'address': address,
        'commercialNumber': commercialNumber,
        'vATNumber': vatNumber,
      };
}

class Buyer {
  final String? companyName;
  final String? address;
  final dynamic commercialNumber;
  final int? vatNumber;

  Buyer({
    this.companyName,
    this.address,
    this.commercialNumber,
    this.vatNumber,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      companyName: json['companyName'],
      address: json['address'],
      commercialNumber: json['commercialNumber'],
      vatNumber: json['vATNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'address': address,
        'commercialNumber': commercialNumber,
        'vATNumber': vatNumber,
      };
}
