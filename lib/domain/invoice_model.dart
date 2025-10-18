class InvoiceCompanyRef {
  final String id;
  final String companyName;
  final String commercialName;
  final dynamic commercialNumber;
  final String publicName;
  final String? vATNumber;
  final String? photoUrl;
  final String? role;

  InvoiceCompanyRef({
    required this.id,
    required this.companyName,
    required this.commercialName,
    required this.commercialNumber,
    required this.publicName,
    this.photoUrl,
    this.vATNumber,
    this.role,
  });

  factory InvoiceCompanyRef.fromJson(Map<String, dynamic> json) {
    return InvoiceCompanyRef(
      id: json['_id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      publicName: json['publicName']?.toString() ?? '',
      commercialName: json['commercialName']?.toString() ?? '',
      commercialNumber: json['commercialNumber'],
      vATNumber: json['vATNumber']?.toString(),
      role: json['role']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'companyName': companyName,
      'publicName': publicName,
      'commercialName': commercialName,
      'commercialNumber': commercialNumber,
      'vATNumber': vATNumber,
      'role': role,
      'photoUrl': photoUrl,
    };
  }
}

class InvoiceCustomerCompanyRef {
  final String id;
  final String companyName;
  final String commercialName;
  final dynamic commercialNumber;
  final String? vATNumber;

  InvoiceCustomerCompanyRef({
    required this.id,
    required this.companyName,
    required this.commercialName,
    required this.commercialNumber,
    this.vATNumber,
  });

  factory InvoiceCustomerCompanyRef.fromJson(Map<String, dynamic> json) {
    return InvoiceCustomerCompanyRef(
      id: json['_id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      commercialName: json['commercialName']?.toString() ?? '',
      commercialNumber: json['commercialNumber'],
      vATNumber: json['vATNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'companyName': companyName,
      'commercialName': commercialName,
      'commercialNumber': commercialNumber,
      'vATNumber': vATNumber,
    };
  }
}

class InvoiceModel {
  final String id;
  final InvoiceCompanyRef invoiceCompanyRef;
  final InvoiceCustomerCompanyRef invoiceCustomerCompanyRef;
  final double invoiceAmount;
  final String invoiceDescription;
  final double invoiceVat1;
  final double invoiceAppFee;
  final double invoiceVat2;
  final double invoiceTotal;
  final double invoiceGrandTotal;
  final double appFeeAmount;
  final double vat2Amount;
  final double invoice_total_with_app_fee;
  final DateTime invoiceCreationDate;
  final String invoiceCustomerRef;
  final String invoiceStatus;
  final String invoiceSubRef;
  final String bankTransferReceiptStatus;
  final DateTime? claimCreationDate;
  final String? invoicePdf;
  final DateTime? bankTransferReceiptDate;
  final String? bankTransferReceiptUploadedURL;
  final String? taxInvoicePdf;
  final String? invoiceSenderName;
  final String? invoiceBankName;
  final String? invoiceAccountName;
  final String? invoiceAccountNo;
  final String? invoiceAccountIban;
  final String? invoiceSwift;
  final String? taxInvoiceStatus;
  final String? paymentMethod;
  final DateTime? paymentDueDate;
  final String? paymentStatus;
  final String? notes;
  final String? currency;
  final String? createdAt;
  final String? updatedAt;
  final String? claim_status;
  final int? invoice_id;
  final String? vATNumber;
  final String? payment_method;
  // Bank account details
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? iban;

  InvoiceModel({
    required this.id,
    required this.invoiceCompanyRef,
    required this.invoiceCustomerCompanyRef,
    required this.invoiceAmount,
    required this.invoiceDescription,
    required this.invoiceVat1,
    required this.invoiceAppFee,
    required this.invoiceVat2,
    required this.invoiceTotal,
    required this.invoiceGrandTotal,
    required this.vat2Amount,
    required this.appFeeAmount,
    required this.invoice_total_with_app_fee,
    required this.invoiceCreationDate,
    required this.invoiceCustomerRef,
    required this.invoiceStatus,
    required this.invoiceSubRef,
    required this.bankTransferReceiptStatus,
    required this.createdAt,
    required this.updatedAt,
    this.claimCreationDate,
    this.invoicePdf,
    this.bankTransferReceiptDate,
    this.bankTransferReceiptUploadedURL,
    this.taxInvoicePdf,
    this.invoiceSenderName,
    this.taxInvoiceStatus,
    this.paymentMethod,
    this.paymentDueDate,
    this.paymentStatus,
    this.notes,
    this.currency,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.iban,
    this.claim_status,
    this.invoice_id,
    this.vATNumber,
    this.invoiceBankName,
    this.invoiceAccountName,
    this.invoiceAccountNo,
    this.invoiceAccountIban,
    this.invoiceSwift,
    this.payment_method,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    // Handle all three response formats:
    // 1. API response with full invoice data (third response)
    // 2. Socket message with invoiceData field (first response)
    // 3. Socket message with invoiceData nested in message (second response)

    // Extract company reference data
    Map<String, dynamic>? companyRef;
    if (json['invoice_company_ref'] is Map<String, dynamic>) {
      companyRef = json['invoice_company_ref'];
    } else if (json['firstParty'] is Map<String, dynamic>) {
      // Handle firstParty format from socket responses
      companyRef = {
        '_id': json['firstParty']['_id'] ?? '',
        'companyName': json['firstParty']['companyName'] ?? '',
        'commercialName': json['firstParty']['name'] ?? '',
        'commercialNumber': json['firstParty']['commercialNumber'],
        'vATNumber': json['firstParty']['vatNumber']?.toString() ?? '',
      };
    }

    // Extract customer company reference data
    Map<String, dynamic>? customerCompanyRef;
    if (json['invoice_customer_company_ref'] is Map<String, dynamic>) {
      customerCompanyRef = json['invoice_customer_company_ref'];
    } else if (json['secondParty'] is Map<String, dynamic>) {
      // Handle secondParty format from socket responses
      customerCompanyRef = {
        '_id': json['secondParty']['_id'] ?? '',
        'companyName': json['secondParty']['companyName'] ?? '',
        'commercialName': json['secondParty']['name'] ?? '',
        'commercialNumber': json['secondParty']['commercialNumber'],
        'vATNumber': json['secondParty']['vatNumber']?.toString() ?? '',
      };
    }

    return InvoiceModel(
        id: json['_id']?.toString() ?? json['invoiceId']?.toString() ?? '',
        invoiceCompanyRef: companyRef != null
            ? InvoiceCompanyRef.fromJson(companyRef)
            : InvoiceCompanyRef.fromJson({}),
        invoiceCustomerCompanyRef: customerCompanyRef != null
            ? InvoiceCustomerCompanyRef.fromJson(customerCompanyRef)
            : InvoiceCustomerCompanyRef.fromJson({}),
        invoiceAmount:
            (json['invoice_amount'] ?? json['amount'] ?? 0).toDouble(),
        invoiceDescription: json['invoice_description']?.toString() ??
            json['description']?.toString() ??
            '',
        invoiceVat1: (json['invoice_vat1'] ?? json['vat'] ?? 0).toDouble(),
        invoiceAppFee: (json['invoice_app_fee'] ?? 0).toDouble(),
        invoiceVat2: (json['invoice_vat2'] ?? 0).toDouble(),
        invoiceTotal: (json['invoice_total'] ?? json['amount'] ?? 0).toDouble(),
        invoiceGrandTotal:
            (json['invoice_grand_total'] ?? json['grandTotal'] ?? 0).toDouble(),
        vat2Amount: (json['vat2Amount'] ?? 0).toDouble(),
        appFeeAmount: (json['appFeeAmount'] ?? 0).toDouble(),
        invoice_total_with_app_fee: (json['invoice_total_with_app_fee'] ??
                json['invoice_total'] ??
                json['grandTotal'] ??
                0)
            .toDouble(),
        invoiceCreationDate:
            _parseDate(json['invoice_creation_date'] ?? json['createdAt']),
        invoiceCustomerRef: json['invoice_customer_ref']?.toString() ?? '',
        invoiceStatus: json['invoice_status']?.toString() ??
            json['status']?.toString() ??
            'Unpaid',
        invoiceSubRef: json['invoice_sub_ref']?.toString() ?? '',
        bankTransferReceiptStatus:
            json['bankTransferReceiptStatus']?.toString() ?? 'Not Uploaded',
        claimCreationDate: json['claim_creation_date'] != null
            ? _parseDate(json['claim_creation_date'])
            : null,
        invoicePdf: json['invoice_pdf']?.toString(),
        bankTransferReceiptDate: json['bankTransferReceiptDate'] != null
            ? _parseDate(json['bankTransferReceiptDate'])
            : null,
        bankTransferReceiptUploadedURL:
            json['bankTransferReceiptUploadedURL']?.toString(),
        taxInvoicePdf: json['tax_invoice_pdf']?.toString(),
        invoiceSenderName: json['invoice_sender_name']?.toString(),
        taxInvoiceStatus: json['tax_invoice_status']?.toString(),
        paymentMethod: json['payment_method']?.toString(),
        paymentDueDate: json['payment_due_date'] != null
            ? _parseDate(json['payment_due_date'])
            : json['expiresAt'] != null
                ? _parseDate(json['expiresAt'])
                : null,
        paymentStatus: json['payment_status']?.toString(),
        invoiceBankName: json['invoiceBankName']?.toString(),
        invoiceAccountName: json['invoiceAccountName']?.toString(),
        invoiceAccountNo: json['invoiceAccountNo']?.toString(),
        invoiceAccountIban: json['invoiceAccountIban']?.toString(),
        invoiceSwift: json['invoiceSwift']?.toString(),
        notes: json['notes']?.toString(),
        currency: json['currency']?.toString() ?? 'SAR',
        bankName: json['invoiceBankName']?.toString(),
        accountName: json['invoiceAccountName']?.toString(),
        accountNumber: json['invoiceAccountNo']?.toString(),
        iban: json['invoiceAccountIban']?.toString(),
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
        claim_status: json['claim_status']?.toString(),
        invoice_id: json['invoice_id'] is int
            ? json['invoice_id']
            : int.tryParse(json['invoice_id']?.toString() ?? '') ??
                int.tryParse(json['invoiceId']?.toString() ?? ''),
        vATNumber: json['vATNumber']?.toString(),
        payment_method: json['payment_method']?.toString());
  }

  /// Helper method to parse dates with better error handling
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    try {
      if (dateValue is String) {
        // Handle ISO string format
        if (dateValue.contains('T') || dateValue.contains('Z')) {
          return DateTime.parse(dateValue);
        }
        // Handle other string formats
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      } else if (dateValue is Map && dateValue['\$date'] != null) {
        // Handle MongoDB date format
        final dateData = dateValue['\$date'];
        if (dateData is Map && dateData['\$numberLong'] != null) {
          final timestamp = int.parse(dateData['\$numberLong'].toString());
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'invoice_company_ref': invoiceCompanyRef.toJson(),
      'invoice_customer_company_ref': invoiceCustomerCompanyRef.toJson(),
      'invoice_amount': invoiceAmount,
      'invoice_description': invoiceDescription,
      'invoice_vat1': invoiceVat1,
      'invoice_app_fee': invoiceAppFee,
      'invoice_vat2': invoiceVat2,
      'invoice_total': invoiceTotal,
      'invoice_grand_total': invoiceGrandTotal,
      'vat2Amount': vat2Amount,
      'appFeeAmount': appFeeAmount,
      'invoice_total_with_app_fee': invoice_total_with_app_fee,
      'invoice_creation_date': invoiceCreationDate.toIso8601String(),
      'invoice_customer_ref': invoiceCustomerRef,
      'invoice_status': invoiceStatus,
      'invoice_sub_ref': invoiceSubRef,
      'bankTransferReceiptStatus': bankTransferReceiptStatus,
      'claim_creation_date': claimCreationDate?.toIso8601String(),
      'invoice_pdf': invoicePdf,
      'bankTransferReceiptDate': bankTransferReceiptDate?.toIso8601String(),
      'bankTransferReceiptUploadedURL': bankTransferReceiptUploadedURL,
      'tax_invoice_pdf': taxInvoicePdf,
      'invoice_sender_name': invoiceSenderName,
      'tax_invoice_status': taxInvoiceStatus,
      'payment_method': paymentMethod,
      'payment_due_date': paymentDueDate?.toIso8601String(),
      'payment_status': paymentStatus,
      'notes': notes,
      'currency': currency,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'iban': iban,
      'invoiceSwift': invoiceSwift,
      'invoiceBankName': invoiceBankName,
      'invoiceAccountName': invoiceAccountName,
      'invoiceAccountNo': invoiceAccountNo,
      'invoiceAccountIban': invoiceAccountIban,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'claim_status': claim_status,
      'invoice_id': invoice_id,
      'vATNumber': vATNumber,
    };
  }

  // Getter methods for PDF generation
  String get invoiceId => id;
  DateTime get date => invoiceCreationDate;
  String get status => invoiceStatus;

  String get firstPartyName => invoiceCompanyRef.companyName;
  dynamic get firstPartyCommercialNumber => invoiceCompanyRef.commercialNumber;
  String? get firstPartyVatNumber =>
      null; // TODO: Add VAT number to InvoiceCompanyRef if needed

  String get secondPartyName => invoiceCustomerCompanyRef.companyName;
  dynamic get secondPartyCommercialNumber =>
      invoiceCustomerCompanyRef.commercialNumber;
  String? get secondPartyVatNumber => invoiceCustomerCompanyRef.vATNumber;

  // Helper method to safely convert commercial number to string
  String getFirstPartyCommercialNumberAsString() {
    if (invoiceCompanyRef.commercialNumber == null) return 'N/A';
    return invoiceCompanyRef.commercialNumber.toString();
  }

  String getSecondPartyCommercialNumberAsString() {
    if (invoiceCustomerCompanyRef.commercialNumber == null) return 'N/A';
    return invoiceCustomerCompanyRef.commercialNumber.toString();
  }
}
