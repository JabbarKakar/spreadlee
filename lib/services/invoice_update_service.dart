import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/domain/invoice_update_event.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/services/chat_socket_service.dart';

/// Service for handling real-time invoice updates via WebSocket
class InvoiceUpdateService extends ChangeNotifier {
  static final InvoiceUpdateService _instance =
      InvoiceUpdateService._internal();
  factory InvoiceUpdateService() => _instance;
  InvoiceUpdateService._internal();

  final ChatSocketService _socketService = ChatSocketService();

  // Stream controllers for different types of updates
  final StreamController<InvoiceUpdateEvent> _invoiceUpdateController =
      StreamController<InvoiceUpdateEvent>.broadcast();

  final StreamController<InvoiceModel> _invoiceStatusChangedController =
      StreamController<InvoiceModel>.broadcast();

  final StreamController<InvoiceModel> _paymentCompletedController =
      StreamController<InvoiceModel>.broadcast();

  // Track active listeners
  final Map<String, List<Function(InvoiceUpdateEvent)>> _chatListeners = {};
  final Map<String, List<Function(InvoiceModel)>> _invoiceListeners = {};

  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  Stream<InvoiceUpdateEvent> get invoiceUpdateStream =>
      _invoiceUpdateController.stream;
  Stream<InvoiceModel> get invoiceStatusChangedStream =>
      _invoiceStatusChangedController.stream;
  Stream<InvoiceModel> get paymentCompletedStream =>
      _paymentCompletedController.stream;

  /// Initialize the service with socket connection
  Future<void> initialize({
    required String baseUrl,
    required String token,
    required String userId,
    required String userRole,
  }) async {
    if (_isInitialized) return;

    if (kDebugMode) {
      print('=== InvoiceUpdateService: Initializing ===');
      print('Base URL: $baseUrl');
      print(
          'Token: ${token.isNotEmpty ? '***${token.substring(token.length - 4)}' : 'EMPTY'}');
      print('User ID: $userId');
      print('User Role: $userRole');
    }

    try {
      // Validate required parameters
      if (baseUrl.isEmpty) {
        throw Exception('Base URL cannot be empty');
      }
      if (token.isEmpty) {
        throw Exception('Token cannot be empty');
      }
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      if (userRole.isEmpty) {
        throw Exception('User role cannot be empty');
      }

      await _socketService.initialize(
        baseUrl: baseUrl,
        token: token,
        onConnectionChanged: _handleSocketConnectionChanged,
        onError: _handleSocketError,
      );

      _setupEventListeners();
      _joinRoleBasedRooms(userId, userRole);
      _isInitialized = true;
      notifyListeners();

      if (kDebugMode) {
        print('InvoiceUpdateService: Successfully initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Initialization failed: $e');
        print('Please check your configuration:');
        print('- Base URL: $baseUrl');
        print('- Token: ${token.isNotEmpty ? 'Valid' : 'Empty'}');
        print('- User ID: $userId');
        print('- User Role: $userRole');
      }
      rethrow;
    }
  }

  /// Set up WebSocket event listeners
  void _setupEventListeners() {
    // Listen for invoice updates (primary event from backend)
    _socketService.addEventListener('invoice_updated', _handleInvoiceUpdate);

    // Listen for other relevant events
    _socketService.addEventListener(
        'payment_completed', _handlePaymentCompleted);
    _socketService.addEventListener(
        'invoice_status_changed', _handleInvoiceStatusChanged);

    // Listen for message updates that might contain invoice data
    _socketService.addEventListener('message_sent', _handleMessageSent);
    _socketService.addEventListener('new_message', _handleNewMessage);
  }

  /// Handle invoice update events
  void _handleInvoiceUpdate(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('=== INVOICE UPDATE EVENT RECEIVED ===');
        print('Event data keys: ${data.keys}');
        print('Full event data: $data');
      }

      final event = InvoiceUpdateEvent.fromJson(data);

      if (kDebugMode) {
        print('=== CREATED INVOICE UPDATE EVENT ===');
        print('Event invoiceId: ${event.invoiceId}');
        print('Event invoice data: ${event.invoice}');
        print('Event chatId: ${event.chatId}');
      }

      // Emit to general stream
      _invoiceUpdateController.add(event);

      // Notify chat-specific listeners
      _notifyChatListeners(event);

      // Notify invoice-specific listeners
      _notifyInvoiceListeners(event);

      // Handle payment completion
      if (event.paymentCompleted) {
        _handlePaymentCompleted(data);
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error handling invoice update: $e');
      }
    }
  }

  /// Handle payment completed events
  void _handlePaymentCompleted(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('InvoiceUpdateService: Payment completed event: $data');
      }

      final invoiceData = data['invoice'];
      if (invoiceData != null) {
        final invoice = InvoiceModel.fromJson(invoiceData);
        _paymentCompletedController.add(invoice);

        if (kDebugMode) {
          print(
              'InvoiceUpdateService: Payment completed for invoice: ${invoice.invoiceId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error handling payment completed: $e');
      }
    }
  }

  /// Handle invoice status change events
  void _handleInvoiceStatusChanged(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('InvoiceUpdateService: Invoice status changed event: $data');
      }

      final invoiceData = data['invoice'];
      if (invoiceData != null) {
        final invoice = InvoiceModel.fromJson(invoiceData);
        _invoiceStatusChangedController.add(invoice);

        if (kDebugMode) {
          print(
              'InvoiceUpdateService: Status changed for invoice: ${invoice.invoiceId} to ${invoice.invoiceStatus}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error handling status change: $e');
      }
    }
  }

  /// Handle message_sent events that might contain updated invoice data
  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print(
            'InvoiceUpdateService: Received message_sent event: ${data.keys}');
      }

      // Check if this message contains invoice data
      if (data.containsKey('invoiceData') && data['invoiceData'] != null) {
        final invoiceData = data['invoiceData'] as Map<String, dynamic>;
        final invoiceId = invoiceData['_id']?.toString() ??
            invoiceData['invoiceId']?.toString() ??
            invoiceData['invoiceId']?.toString();

        if (invoiceId != null) {
          if (kDebugMode) {
            print(
                'InvoiceUpdateService: Message contains invoice data for invoice: $invoiceId');
          }

          // Create an invoice update event for this message
          final event = InvoiceUpdateEvent(
            invoice: invoiceData,
            chatId: data['chat_id']?.toString() ?? '',
            invoiceId: invoiceId,
            paymentCompleted: invoiceData['status'] == 'paid',
            targetType: 'message_update',
          );

          // Emit to general stream
          _invoiceUpdateController.add(event);

          // Notify listeners
          _notifyChatListeners(event);
          _notifyInvoiceListeners(event);

          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error handling message_sent: $e');
      }
    }
  }

  /// Handle new_message events that might contain invoice data
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('InvoiceUpdateService: Received new_message event: ${data.keys}');
      }

      // Check if this message contains invoice data
      if (data.containsKey('invoiceData') && data['invoiceData'] != null) {
        final invoiceData = data['invoiceData'] as Map<String, dynamic>;
        final invoiceId = invoiceData['_id']?.toString() ??
            invoiceData['invoiceId']?.toString() ??
            invoiceData['invoiceId']?.toString();

        if (invoiceId != null) {
          if (kDebugMode) {
            print(
                'InvoiceUpdateService: New message contains invoice data for invoice: $invoiceId');
          }

          // Create an invoice update event for this message
          final event = InvoiceUpdateEvent(
            invoice: invoiceData,
            chatId: data['chat_id']?.toString() ?? '',
            invoiceId: invoiceId,
            paymentCompleted: invoiceData['status'] == 'paid',
            targetType: 'new_message',
          );

          // Emit to general stream
          _invoiceUpdateController.add(event);

          // Notify listeners
          _notifyChatListeners(event);
          _notifyInvoiceListeners(event);

          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error handling new_message: $e');
      }
    }
  }

  /// Join rooms based on user role
  void _joinRoleBasedRooms(String userId, String userRole) {
    try {
      switch (userRole.toLowerCase()) {
        case 'company':
        case 'influencer':
          _joinCompanyRoom(userId);
          break;
        case 'customer':
          // Customer rooms are joined when they enter specific chats
          break;
        case 'subaccount':
          _joinCompanyRoom(userId);
          break;
        case 'admin':
          _joinAdminRoom();
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error joining role-based rooms: $e');
      }
    }
  }

  /// Join company room
  void _joinCompanyRoom(String companyId) {
    try {
      _socketService.socket?.emit('join_company', {'companyId': companyId});
      if (kDebugMode) {
        print('InvoiceUpdateService: Joined company room: $companyId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error joining company room: $e');
      }
    }
  }

  /// Join admin room
  void _joinAdminRoom() {
    try {
      _socketService.socket?.emit('join_admin', {});
      if (kDebugMode) {
        print('InvoiceUpdateService: Joined admin room');
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error joining admin room: $e');
      }
    }
  }

  /// Join chat room for invoice updates
  void joinChatRoom(String chatId) {
    try {
      _socketService.socket?.emit('join_chat', {'chatId': chatId});
      if (kDebugMode) {
        print('InvoiceUpdateService: Joined chat room: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error joining chat room: $e');
      }
    }
  }

  /// Leave chat room
  void leaveChatRoom(String chatId) {
    try {
      _socketService.socket?.emit('leave_chat', {'chatId': chatId});
      if (kDebugMode) {
        print('InvoiceUpdateService: Left chat room: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error leaving chat room: $e');
      }
    }
  }

  /// Add listener for specific chat updates
  void addChatListener(String chatId, Function(InvoiceUpdateEvent) listener) {
    _chatListeners.putIfAbsent(chatId, () => []).add(listener);
  }

  /// Remove listener for specific chat
  void removeChatListener(
      String chatId, Function(InvoiceUpdateEvent) listener) {
    _chatListeners[chatId]?.remove(listener);
    if (_chatListeners[chatId]?.isEmpty == true) {
      _chatListeners.remove(chatId);
    }
  }

  /// Add listener for specific invoice updates
  void addInvoiceListener(String invoiceId, Function(InvoiceModel) listener) {
    _invoiceListeners.putIfAbsent(invoiceId, () => []).add(listener);
  }

  /// Remove listener for specific invoice
  void removeInvoiceListener(
      String invoiceId, Function(InvoiceModel) listener) {
    _invoiceListeners[invoiceId]?.remove(listener);
    if (_invoiceListeners[invoiceId]?.isEmpty == true) {
      _invoiceListeners.remove(invoiceId);
    }
  }

  /// Notify chat-specific listeners
  void _notifyChatListeners(InvoiceUpdateEvent event) {
    final listeners = _chatListeners[event.chatId];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(event);
        } catch (e) {
          if (kDebugMode) {
            print('InvoiceUpdateService: Error in chat listener: $e');
          }
        }
      }
    }
  }

  /// Notify invoice-specific listeners
  void _notifyInvoiceListeners(InvoiceUpdateEvent event) {
    final listeners = _invoiceListeners[event.invoiceId];
    if (listeners != null) {
      try {
        final invoice = InvoiceModel.fromJson(event.invoice);
        for (final listener in listeners) {
          try {
            listener(invoice);
          } catch (e) {
            if (kDebugMode) {
              print('InvoiceUpdateService: Error in invoice listener: $e');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('InvoiceUpdateService: Error creating invoice model: $e');
        }
      }
    }
  }

  /// Handle socket connection changes
  void _handleSocketConnectionChanged(bool isConnected) {
    if (kDebugMode) {
      print('InvoiceUpdateService: Socket connection changed: $isConnected');
    }
    notifyListeners();
  }

  /// Handle socket errors
  void _handleSocketError(String error) {
    if (kDebugMode) {
      print('InvoiceUpdateService: Socket error: $error');
    }
    notifyListeners();
  }

  /// Disconnect and cleanup
  void disconnect() {
    try {
      _socketService.disconnect();
      _isInitialized = false;
      notifyListeners();

      if (kDebugMode) {
        print('InvoiceUpdateService: Disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('InvoiceUpdateService: Error disconnecting: $e');
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    _invoiceUpdateController.close();
    _invoiceStatusChangedController.close();
    _paymentCompletedController.close();
    super.dispose();
  }
}
