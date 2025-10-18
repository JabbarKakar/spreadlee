class InvoiceUpdateEvent {
  final Map<String, dynamic> invoice;
  final String chatId;
  final String invoiceId;
  final bool paymentCompleted;
  final String? targetType;
  final String? status;
  final String? invoiceStatus;

  InvoiceUpdateEvent({
    required this.invoice,
    required this.chatId,
    required this.invoiceId,
    required this.paymentCompleted,
    this.targetType,
    this.status,
    this.invoiceStatus,
  });

  factory InvoiceUpdateEvent.fromJson(Map<String, dynamic> json) {
    final invoiceData = json['invoice'] ?? {};

    return InvoiceUpdateEvent(
      invoice: invoiceData,
      chatId: json['chatId'] ?? '',
      invoiceId: json['invoiceId'] ??
          invoiceData['_id']?.toString() ??
          invoiceData['invoiceId']?.toString() ??
          '',
      paymentCompleted: json['paymentCompleted'] ?? false,
      targetType: json['targetType'],
      status: invoiceData['status']?.toString(),
      invoiceStatus: invoiceData['invoice_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice': invoice,
      'chatId': chatId,
      'invoiceId': invoiceId,
      'paymentCompleted': paymentCompleted,
      'targetType': targetType,
      'status': status,
      'invoiceStatus': invoiceStatus,
    };
  }

  @override
  String toString() {
    return 'InvoiceUpdateEvent(chatId: $chatId, invoiceId: $invoiceId, paymentCompleted: $paymentCompleted, targetType: $targetType, status: $status, invoiceStatus: $invoiceStatus)';
  }
}
