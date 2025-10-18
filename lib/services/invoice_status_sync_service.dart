import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/domain/invoice_update_event.dart';
import 'package:spreadlee/services/invoice_update_service.dart';

/// Service for synchronizing invoice status between frontend and backend
class InvoiceStatusSyncService extends ChangeNotifier {
  static final InvoiceStatusSyncService _instance =
      InvoiceStatusSyncService._internal();
  factory InvoiceStatusSyncService() => _instance;
  InvoiceStatusSyncService._internal();

  final InvoiceUpdateService _invoiceUpdateService = InvoiceUpdateService();

  // Stream controllers for status synchronization
  final StreamController<Map<String, dynamic>> _statusUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Track invoice statuses
  final Map<String, String> _invoiceStatuses = {};
  final Map<String, DateTime> _lastUpdateTimes = {};

  StreamSubscription<InvoiceUpdateEvent>? _updateSubscription;

  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  Stream<Map<String, dynamic>> get statusUpdateStream =>
      _statusUpdateController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Listen for invoice updates
      _updateSubscription = _invoiceUpdateService.invoiceUpdateStream.listen(
        _handleInvoiceUpdate,
        onError: (error) {
          if (kDebugMode) {
            print('InvoiceStatusSyncService: Error in update stream: $error');
          }
        },
      );

      _isInitialized = true;
      notifyListeners();

      if (kDebugMode) {
        print('InvoiceStatusSyncService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceStatusSyncService: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Handle invoice updates and synchronize status
  void _handleInvoiceUpdate(InvoiceUpdateEvent event) {
    try {
      // Get invoice ID from multiple sources (prioritize ObjectId _id and invoiceId)
      String? invoiceId = event.invoiceId.isNotEmpty
          ? event.invoiceId
          : (event.invoice['_id'] ??
                  event.invoice['invoiceId'] ??
                  event.invoice['invoiceId'])
              ?.toString();

      if (invoiceId == null || invoiceId.isEmpty) {
        if (kDebugMode) {
          print('InvoiceStatusSyncService: No valid invoice ID found in event');
        }
        return;
      }

      if (kDebugMode) {
        print(
            'InvoiceStatusSyncService: Processing invoice update for ID: $invoiceId');
        print('Event data: ${event.invoice.keys}');
      }

      // Extract status information
      String? newStatus = _extractStatus(event);
      if (newStatus == null) {
        if (kDebugMode) {
          print('InvoiceStatusSyncService: No status found in event data');
        }
        return;
      }

      // Check if status has changed
      final currentStatus = _invoiceStatuses[invoiceId];
      if (currentStatus == newStatus) {
        if (kDebugMode) {
          print(
              'InvoiceStatusSyncService: Status unchanged for invoice: $invoiceId ($newStatus)');
        }
        return;
      }

      // Update status
      _invoiceStatuses[invoiceId] = newStatus;
      _lastUpdateTimes[invoiceId] = DateTime.now();

      // Create status update data
      final statusUpdate = {
        'invoiceId': invoiceId,
        'status': newStatus,
        'previousStatus': currentStatus,
        'paymentCompleted': event.paymentCompleted,
        'chatId': event.chatId,
        'targetType': event.targetType,
        'timestamp': DateTime.now().toIso8601String(),
        'invoiceData': event.invoice,
      };

      // Emit status update
      _statusUpdateController.add(statusUpdate);

      if (kDebugMode) {
        print(
            'InvoiceStatusSyncService: Status updated for invoice $invoiceId: ${currentStatus ?? 'null'} → $newStatus');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceStatusSyncService: Error handling invoice update: $e');
      }
    }
  }

  /// Extract status from invoice update event
  String? _extractStatus(InvoiceUpdateEvent event) {
    // Priority order for status extraction
    final invoiceData = event.invoice;

    // 1. Check message invoiceData status (frontend format)
    if (invoiceData['status'] != null) {
      return invoiceData['status'].toString().toLowerCase();
    }

    // 2. Check backend invoice_status (backend format)
    if (invoiceData['invoice_status'] != null) {
      final backendStatus = invoiceData['invoice_status'].toString();
      return _mapBackendStatusToFrontend(backendStatus);
    }

    // 3. Check payment status
    if (invoiceData['payment_status'] != null) {
      final paymentStatus = invoiceData['payment_status'].toString();
      return _mapPaymentStatusToFrontend(paymentStatus);
    }

    return null;
  }

  /// Map backend status to frontend status
  String _mapBackendStatusToFrontend(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'paid':
        return 'paid';
      case 'unpaid':
        return 'unpaid';
      case 'expired':
        return 'expired';
      case 'under review':
        return 'pending';
      default:
        return backendStatus.toLowerCase();
    }
  }

  /// Map payment status to frontend status
  String _mapPaymentStatusToFrontend(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'completed':
        return 'paid';
      case 'pending':
        return 'pending';
      case 'failed':
        return 'unpaid';
      default:
        return paymentStatus.toLowerCase();
    }
  }

  /// Get current status for an invoice
  String? getInvoiceStatus(String invoiceId) {
    return _invoiceStatuses[invoiceId];
  }

  /// Get last update time for an invoice
  DateTime? getLastUpdateTime(String invoiceId) {
    return _lastUpdateTimes[invoiceId];
  }

  /// Check if invoice is paid
  bool isInvoicePaid(String invoiceId) {
    final status = _invoiceStatuses[invoiceId];
    return status == 'paid';
  }

  /// Check if invoice is expired
  bool isInvoiceExpired(String invoiceId) {
    final status = _invoiceStatuses[invoiceId];
    return status == 'expired';
  }

  /// Check if invoice is pending
  bool isInvoicePending(String invoiceId) {
    final status = _invoiceStatuses[invoiceId];
    return status == 'pending' || status == 'unpaid';
  }

  /// Get all tracked invoice statuses
  Map<String, String> getAllStatuses() {
    return Map.from(_invoiceStatuses);
  }

  /// Clear status for specific invoice
  void clearInvoiceStatus(String invoiceId) {
    _invoiceStatuses.remove(invoiceId);
    _lastUpdateTimes.remove(invoiceId);
    notifyListeners();
  }

  /// Clear all statuses
  void clearAllStatuses() {
    _invoiceStatuses.clear();
    _lastUpdateTimes.clear();
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _updateSubscription?.cancel();
    _statusUpdateController.close();
    super.dispose();
  }
}
