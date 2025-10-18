import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/domain/invoice_update_event.dart';
import '../../view/chat_screen.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'dart:convert';
import 'dart:async';
import 'package:spreadlee/services/invoice_pdf_service.dart';
import 'package:spreadlee/services/invoice_update_service.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/customer/chat_bloc/chat_cubit.dart';

class MessageInvoiceCustomerWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final Function(String)? onInvoiceTap;
  final Function(String)? onDownloadTap;
  final Function(InvoiceModel)? onViewTap;
  final bool isLoading;
  final String? chatId;
  final String? currentUserId;
  final VoidCallback? onMessageVisible;

  const MessageInvoiceCustomerWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    this.onInvoiceTap,
    this.onDownloadTap,
    this.onViewTap,
    this.isLoading = false,
    this.chatId,
    this.currentUserId,
    this.onMessageVisible,
  }) : super(key: key);

  @override
  State<MessageInvoiceCustomerWidget> createState() =>
      _MessageInvoiceCustomerWidgetState();
}

class _MessageInvoiceCustomerWidgetState
    extends State<MessageInvoiceCustomerWidget>
    with AutomaticKeepAliveClientMixin {
  final StopWatchTimer _timer = StopWatchTimer();
  String _timerDisplay = '';
  InvoiceModel? _invoiceData;
  static const int _countdownHours = 48;
  Timer? _countdownTimer;
  bool _isLoading = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const List<int> _retryDelays = [1, 2, 5, 10, 30]; // seconds

  // Invoice update service
  final InvoiceUpdateService _invoiceUpdateService = InvoiceUpdateService();
  StreamSubscription<InvoiceUpdateEvent>? _invoiceUpdateSubscription;
  StreamSubscription<InvoiceModel>? _invoiceStatusSubscription;
  StreamSubscription<InvoiceModel>? _paymentCompletedSubscription;

  @override
  void initState() {
    super.initState();

    // Test invoice parsing first
    _testInvoiceParsing();

    // Initialize invoice update service
    _initializeInvoiceUpdateService();

    // Check if we already have invoice data in invoiceData
    if (widget.message.invoiceData is Map) {
      print('=== Found Invoice Data in invoiceData during initState ===');
      print('Processing invoice data immediately...');
      // Force immediate processing of Map data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parseInvoiceDataAsync();
      });
    }

    print('About to call _parseInvoiceDataAsync...');
    _parseInvoiceDataAsync();
    print('_parseInvoiceDataAsync called from initState');

    // Debug current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugInvoiceState();
    });
  }

  /// Test invoice parsing with sample data
  void _testInvoiceParsing() {
    try {
      print('=== Testing Invoice Parsing ===');

      // Sample invoice data structure
      final sampleInvoice = {
        '_id': 'test_id_123',
        'invoice_id': '123',
        'invoice_status': 'Unpaid',
        'invoice_amount': 100.0,
        'invoice_description': 'Test invoice',
        'currency': 'SAR',
        'invoice_company_ref': {
          '_id': 'company_123',
          'companyName': 'Test Company',
          'commercialName': 'Test Commercial',
          'commercialNumber': '123456',
          'vATNumber': '123456789',
        },
        'invoice_customer_company_ref': {
          '_id': 'customer_123',
          'companyName': 'Test Customer',
          'commercialName': 'Test Customer Commercial',
          'commercialNumber': '654321',
          'vATNumber': '987654321',
        },
      };

      print('Sample invoice data: ${jsonEncode(sampleInvoice)}');

      final parsedInvoice = InvoiceModel.fromJson(sampleInvoice);
      print('✅ Invoice parsing test successful!');
      print('Parsed invoice ID: ${parsedInvoice.invoiceId}');
      print('Parsed status: ${parsedInvoice.invoiceStatus}');
    } catch (e, stackTrace) {
      print('❌ Invoice parsing test failed!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Initialize the invoice update service for real-time updates
  Future<void> _initializeInvoiceUpdateService() async {
    try {
      if (kDebugMode) {
        print('=== Initializing Invoice Update Service ===');
        print('User ID: ${Constants.userId}');
        print('User Role: ${Constants.role}');
        print('Chat ID: ${widget.chatId}');
        print('Socket Base URL: ${Constants.socketBaseUrl}');
      }

      await _invoiceUpdateService.initialize(
        baseUrl: Constants.socketBaseUrl,
        token: Constants.token,
        userId: Constants.userId,
        userRole: Constants.role,
      );

      // Set up listeners for real-time updates
      _setupInvoiceUpdateListeners();

      // Join multiple rooms for comprehensive coverage
      _joinAllRelevantRooms();

      if (kDebugMode) {
        print('InvoiceUpdateService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize InvoiceUpdateService: $e');
      }
    }
  }

  /// Join all relevant rooms for comprehensive invoice updates
  void _joinAllRelevantRooms() {
    if (kDebugMode) {
      print('=== Joining Relevant Rooms ===');
    }

    // 1. Join chat room (for chat-specific updates)
    if (widget.chatId != null) {
      _invoiceUpdateService.joinChatRoom(widget.chatId!);
      if (kDebugMode) {
        print('✅ Joined chat room: ${widget.chatId}');
      }
    }

    // 2. Join additional chat rooms for better coverage
    // This helps when the same user is in multiple chats
    if (Constants.role == 'customer') {
      // For customers, also join a general customer room
      _invoiceUpdateService.joinChatRoom('customer_${Constants.userId}');
      if (kDebugMode) {
        print('✅ Joined customer general room: customer_${Constants.userId}');
      }
    } else if (Constants.role == 'company' || Constants.role == 'influencer') {
      // For companies, also join a general company room
      _invoiceUpdateService.joinChatRoom('company_${Constants.userId}');
      if (kDebugMode) {
        print('✅ Joined company general room: company_${Constants.userId}');
      }
    }

    if (kDebugMode) {
      print('=== Room Joining Complete ===');
    }
  }

  /// Set up listeners for real-time invoice updates
  void _setupInvoiceUpdateListeners() {
    // Listen for general invoice updates
    _invoiceUpdateSubscription =
        _invoiceUpdateService.invoiceUpdateStream.listen(
      (event) {
        _handleInvoiceUpdate(event);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to invoice updates: $error');
        }
      },
    );

    // Listen for invoice status changes
    _invoiceStatusSubscription =
        _invoiceUpdateService.invoiceStatusChangedStream.listen(
      (invoice) {
        _handleInvoiceStatusChange(invoice);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to invoice status changes: $error');
        }
      },
    );

    // Listen for payment completion
    _paymentCompletedSubscription =
        _invoiceUpdateService.paymentCompletedStream.listen(
      (invoice) {
        _handlePaymentCompleted(invoice);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to payment completion: $error');
        }
      },
    );

    // Add specific listener for this invoice if we have an invoice ID from invoiceData
    // Try to derive an invoice id from multiple possible locations and formats
    String? messageInvoiceId;
    try {
      if (widget.message.invoiceData is Map) {
        final invoiceData = widget.message.invoiceData as Map;
        messageInvoiceId = invoiceData['invoiceId']?.toString() ??
            invoiceData['invoice_id']?.toString() ??
            invoiceData['_id']?.toString();
      } else if (widget.message.invoiceData is String) {
        messageInvoiceId = widget.message.invoiceData as String;
      } else if (widget.message.invoice is Map) {
        final invoiceData = widget.message.invoice as Map;
        messageInvoiceId = invoiceData['invoiceId']?.toString() ??
            invoiceData['invoice_id']?.toString() ??
            invoiceData['_id']?.toString();
      }
    } catch (e) {
      if (kDebugMode) print('Error deriving message invoice id: $e');
    }

    if (messageInvoiceId != null && messageInvoiceId.isNotEmpty) {
      if (kDebugMode)
        print('🔗 Adding specific listener for invoice: $messageInvoiceId');

      _invoiceUpdateService.addInvoiceListener(
        messageInvoiceId,
        (updatedInvoice) {
          if (kDebugMode) {
            print(
                '✅ Direct invoice update received for: ${updatedInvoice.invoiceId}');
            print('New status: ${updatedInvoice.invoiceStatus}');
          }

          setState(() {
            _invoiceData = updatedInvoice;
          });

          // Show notification if status changed
          // Compare with previous status before we overwrote it. We store previous locally.
          // (simple approach: no notification if equal)
          // _showStatusChangeNotification(updatedInvoice.invoiceStatus);

          // Reinitialize timer
          _initializeTimer();
        },
      );
    }
  }

  /// Handle real-time invoice updates
  void _handleInvoiceUpdate(InvoiceUpdateEvent event) {
    if (kDebugMode) {
      print('=== Received Invoice Update Event ===');
      print('Chat ID: ${event.chatId}');
      print('Invoice ID: ${event.invoiceId}');
      print('Payment Completed: ${event.paymentCompleted}');
      print('Target Type: ${event.targetType}');
      print('Event Invoice Data: ${event.invoice}');
    }

    // Debug current state before processing
    _debugInvoiceState();

    // Check if this update is relevant to our widget
    if (_isRelevantUpdate(event)) {
      _updateInvoiceData(event.invoice);
    } else {
      // Fallback: check if the invoice data itself matches our current invoice
      if (_invoiceData != null) {
        final eventInvoiceId =
            event.invoice['invoiceId'] ?? event.invoice['_id'];
        final currentInvoiceId = _invoiceData!.invoiceId;

        if (kDebugMode) {
          print('=== Fallback Check ===');
          print('Event Invoice ID: $eventInvoiceId');
          print('Current Invoice ID: $currentInvoiceId');
        }

        if (eventInvoiceId == currentInvoiceId) {
          if (kDebugMode) print('✅ Fallback match found, updating invoice');
          _updateInvoiceData(event.invoice);
        }
      } else {
        // If we don't have invoice data yet, check if this event is for our invoice
        if (widget.message.invoiceData is Map) {
          final invoiceData = widget.message.invoiceData as Map;
          final messageInvoiceId = invoiceData['invoiceId']?.toString() ??
              invoiceData['invoiceId']?.toString() ??
              invoiceData['_id']?.toString();
          final eventInvoiceId =
              event.invoice['invoiceId'] ?? event.invoice['_id'];

          if (kDebugMode) {
            print('=== No Invoice Data Yet - Checking Message Reference ===');
            print('Message Invoice ID: $messageInvoiceId');
            print('Event Invoice ID: $eventInvoiceId');
          }

          if (messageInvoiceId != null && eventInvoiceId == messageInvoiceId) {
            if (kDebugMode)
              print('✅ Event matches message reference, updating invoice');
            _updateInvoiceData(event.invoice);
          }
        }
      }
    }

    // Enhanced check for bank transfer receipt uploads
    _handleBankTransferReceiptUpdate(event);

    // Debug state after processing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugInvoiceState();
    });
  }

  /// Handle invoice status changes
  void _handleInvoiceStatusChange(InvoiceModel updatedInvoice) {
    if (kDebugMode) {
      print('=== Invoice Status Changed ===');
      print('Invoice ID: ${updatedInvoice.invoiceId}');
      print('New Status: ${updatedInvoice.invoiceStatus}');
    }

    // Check if this is our invoice
    if (_invoiceData?.invoiceId == updatedInvoice.invoiceId) {
      setState(() {
        _invoiceData = updatedInvoice;
      });

      // Show status change notification
      // _showStatusChangeNotification(updatedInvoice.invoiceStatus);

      // Reinitialize timer if needed
      _initializeTimer();
    }
  }

  /// Handle payment completion
  void _handlePaymentCompleted(InvoiceModel paidInvoice) {
    if (kDebugMode) {
      print('=== Payment Completed ===');
      print('Invoice ID: ${paidInvoice.invoiceId}');
      print('Status: ${paidInvoice.invoiceStatus}');
    }

    // Check if this is our invoice
    if (_invoiceData?.invoiceId == paidInvoice.invoiceId) {
      setState(() {
        _invoiceData = paidInvoice;
      });

      // // Show payment success notification
      // _showPaymentSuccessNotification(paidInvoice);

      // Reinitialize timer
      _initializeTimer();
    }
  }

  /// Check if an update is relevant to this widget
  bool _isRelevantUpdate(InvoiceUpdateEvent event) {
    if (kDebugMode) {
      print('=== Checking Update Relevance ===');
      print('Widget Chat ID: ${widget.chatId}');
      print('Event Chat ID: ${event.chatId}');
      print('Widget Invoice ID: ${_invoiceData?.invoiceId}');
      print('Event Invoice ID: ${event.invoiceId}');
      print('Event Invoice Data: ${event.invoice}');
    }

    // First check chatId: if widget.chatId is set and differs from event.chatId,
    // don't immediately reject — invoiceId match should still be allowed.
    if (widget.chatId != null && event.chatId != widget.chatId) {
      if (kDebugMode)
        print(
            '⚠️ Event chatId differs from widget chatId, will still check invoiceId for relevance');
      // continue to invoice id checks below instead of short-circuit returning false
    }

    // Get current invoice ID from widget
    String? currentInvoiceId;
    if (_invoiceData != null) {
      currentInvoiceId = _invoiceData!.invoiceId;
    } else if (widget.message.invoiceData is Map) {
      final invoiceData = widget.message.invoiceData as Map;
      currentInvoiceId = invoiceData['invoiceId']?.toString() ??
          invoiceData['invoiceId']?.toString() ??
          invoiceData['_id']?.toString();
    }

    if (currentInvoiceId == null) {
      if (kDebugMode) print('❌ No current invoice ID found');
      return false;
    }

    // Get event invoice ID
    final eventInvoiceId = event.invoiceId.isNotEmpty
        ? event.invoiceId
        : event.invoice['invoiceId']?.toString() ??
            event.invoice['_id']?.toString() ??
            '';

    if (eventInvoiceId.isEmpty) {
      if (kDebugMode) print('❌ No event invoice ID found');
      return false;
    }

    // Check if invoice IDs match — if they do, consider the event relevant even
    // if chatIds didn't match. This handles server-side updates that broadcast
    // invoice changes without chat scoping.
    if (currentInvoiceId == eventInvoiceId) {
      if (kDebugMode) print('✅ Match by Invoice ID');
      return true;
    }

    if (kDebugMode) print('❌ No match found');
    return false;
  }

  /// Update invoice data from real-time update
  void _updateInvoiceData(Map<String, dynamic> invoiceData) {
    try {
      if (kDebugMode) {
        print('=== Updating Invoice Data ===');
        print('Raw invoice data: ${jsonEncode(invoiceData)}');
        print('Current invoice status: ${_invoiceData?.invoiceStatus}');
      }

      final updatedInvoice = InvoiceModel.fromJson(invoiceData);

      if (kDebugMode) {
        print('✅ Invoice parsed successfully');
        print('New invoice status: ${updatedInvoice.invoiceStatus}');
        print('New invoice amount: ${updatedInvoice.invoiceAmount}');
        print('New invoice ID: ${updatedInvoice.invoiceId}');
      }

      setState(() {
        _invoiceData = updatedInvoice;
      });

      // Show status change notification if status changed
      if (_invoiceData?.invoiceStatus != updatedInvoice.invoiceStatus) {
        // _showStatusChangeNotification(updatedInvoice.invoiceStatus);
      }

      // Reinitialize timer
      _initializeTimer();

      if (kDebugMode) {
        print('✅ Invoice data updated successfully via WebSocket');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error updating invoice data: $e');
        print('Stack trace: $stackTrace');
        print('Raw data that failed: ${jsonEncode(invoiceData)}');
      }

      // Fallback: try to refresh from API if parsing fails
      _refreshInvoiceDataFromApi();
    }
  }

  /// Fallback method to refresh invoice data from API
  void _refreshInvoiceDataFromApi() {
    if (_invoiceData?.invoiceId != null) {
      if (kDebugMode) {
        print('🔄 Attempting to refresh invoice data from API...');
      }
      _fetchInvoiceData(_invoiceData!.invoiceId);
    }
  }

  /// Debug method to show current invoice state
  void _debugInvoiceState() {
    if (kDebugMode) {
      print('=== Current Invoice Widget State ===');
      print('Has Invoice Data: ${_invoiceData != null}');
      if (_invoiceData != null) {
        print('Invoice ID: ${_invoiceData!.invoiceId}');
        print('Invoice _id: ${_invoiceData!.id}');
        print('Invoice Status: ${_invoiceData!.invoiceStatus}');
        print('Invoice Amount: ${_invoiceData!.invoiceAmount}');
        print('Chat ID: ${widget.chatId}');
      }
      print('Is Loading: $_isLoading');
      print('Has Invoice Data: ${widget.message.invoiceData != null}');
    }
  }

  // /// Show status change notification
  // void _showStatusChangeNotification(String newStatus) {
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Invoice status updated to: $newStatus'),
  //         backgroundColor: Colors.blue,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   }
  // }

  // /// Show payment success notification
  // void _showPaymentSuccessNotification(InvoiceModel invoice) {
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Payment completed for invoice #${invoice.invoiceId}'),
  //         backgroundColor: Colors.green,
  //         duration: const Duration(seconds: 5),
  //       ),
  //     );
  //   }
  // }

  void _parseInvoiceDataAsync() {
    _parseInvoiceData();
  }

  @override
  void didUpdateWidget(covariant MessageInvoiceCustomerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we need to re-parse invoice data
    bool shouldReparse = false;

    // 1. Check if message ID changed
    if (widget.message.id != oldWidget.message.id) {
      print('Message ID changed, re-parsing...');
      shouldReparse = true;
    }

    // 2. Check if invoice data changed
    if (widget.message.invoiceData != oldWidget.message.invoiceData) {
      print('Invoice data changed, re-parsing...');
      shouldReparse = true;
    }

    // 3. Check if we have invoice data but no parsed data (new message case)
    if (widget.message.invoiceData != null && _invoiceData == null) {
      print('New message with invoice data but no parsed data, re-parsing...');
      shouldReparse = true;
    }

    if (shouldReparse) {
      print('Re-parsing invoice data...');
      _parseInvoiceDataAsync();
    } else {
      print('No changes detected, skipping _parseInvoiceDataAsync');
    }
  }

  Future<void> _fetchInvoiceData(String invoiceId) async {
    if (_isLoading) return;

    // Validate invoice ID
    if (invoiceId.isEmpty) {
      print('=== Invalid Invoice ID ===');
      print('Invoice ID is empty, cannot fetch data');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Add timeout to prevent infinite loading
    late Timer timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice loading timed out. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });

    try {
      print('=== Fetching Invoice Data ===');
      print('Invoice ID: $invoiceId');
      print('API Endpoint: ${Constants.invoiceById}/$invoiceId');

      // Fetch invoice data from API using the correct endpoint
      final response = await DioHelper.getData(
        endPoint: '${Constants.invoiceById}/$invoiceId',
      );

      print('=== API Response Details ===');
      print('Response: $response');
      print('Response data: ${response?.data}');
      print('Response status code: ${response?.statusCode}');

      if (response != null && response.data != null) {
        print('=== Invoice API Response ===');
        print('Response data: ${response.data}');

        // Handle response data - the invoiceById endpoint returns a single invoice object
        Map<String, dynamic>? invoiceData;
        if (response.data is Map) {
          // Check if response has a 'data' field (wrapped response)
          if (response.data['data'] is Map) {
            invoiceData = Map<String, dynamic>.from(response.data['data']);
          } else {
            // Direct invoice object
            invoiceData = Map<String, dynamic>.from(response.data);
          }
        }

        if (invoiceData != null) {
          print('=== Found Invoice in Response ===');
          print('Found invoice: ${jsonEncode(invoiceData)}');

          try {
            // Parse the invoice data with better error handling
            final parsedInvoice = InvoiceModel.fromJson(invoiceData);

            setState(() {
              _invoiceData = parsedInvoice;
              _isLoading = false;
              _retryCount = 0; // Reset retry count on success
            });

            // Initialize timer after invoice data is set
            _initializeTimer();

            print('=== Invoice Parsed Successfully ===');
            print('Invoice ID: ${parsedInvoice.invoiceId}');
            print('Status: ${parsedInvoice.invoiceStatus}');
            print('Amount: ${parsedInvoice.invoiceAmount}');
          } catch (parseError, parseStackTrace) {
            print('=== Error Parsing Invoice Data ===');
            print('Parse Error: $parseError');
            print('Parse Stack Trace: $parseStackTrace');
            print(
                'Raw invoice data that failed to parse: ${jsonEncode(invoiceData)}');

            setState(() {
              _isLoading = false;
            });

            // Show error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error loading invoice data'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } else {
          print('=== Invoice Not Found in Response ===');
          print('Searched for invoice ID: $invoiceId');
          print('Response data: ${response.data}');

          setState(() {
            _isLoading = false;
          });

          // Try delayed retry if we haven't exceeded max retries
          if (_retryCount < _maxRetries) {
            _scheduleRetry(invoiceId);
          } else {
            // Show final error to user with retry option
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Invoice not found after multiple attempts. It may not be available yet or you may not have permission to view it.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      _retryCount = 0;
                      _fetchInvoiceData(invoiceId);
                    },
                  ),
                ),
              );
            }
          }
        }
      } else {
        print('=== No Invoice Data Received ===');
        print('Response was null or had no data');
        print('Response: $response');

        setState(() {
          _isLoading = false;
        });

        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No invoice data received from server'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('=== Error Fetching Invoice ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('Invoice ID that failed: $invoiceId');

      setState(() {
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to fetch invoice'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _fetchInvoiceData(invoiceId),
            ),
          ),
        );
      }
    } finally {
      // Cancel timeout timer
      timeoutTimer.cancel();
    }
  }

  /// Schedule a delayed retry with exponential backoff
  void _scheduleRetry(String invoiceId) {
    if (_retryCount >= _maxRetries) return;

    final delay = _retryDelays[_retryCount];
    _retryCount++;

    print('=== Scheduling Retry ===');
    print('Retry count: $_retryCount');
    print('Delay: ${delay}s');
    print('Invoice ID: $invoiceId');

    Timer(Duration(seconds: delay), () {
      if (mounted && _invoiceData == null) {
        print('=== Executing Retry ===');
        print('Retry count: $_retryCount');
        _fetchInvoiceData(invoiceId);
      }
    });
  }

  Future<void> _parseInvoiceData() async {
    try {
      print('=== Invoice Data Parsing ===');
      final rawMessage = widget.message.toJson();
      print('Raw message data: ${jsonEncode(rawMessage)}');

      Map<String, dynamic>? invoiceData;

      // Handle your three response formats:
      // 1. Direct invoiceData field (all three responses have invoiceData)
      if (widget.message.invoiceData is Map) {
        print('=== Found Invoice Data in invoiceData field ===');
        print('Invoice data: ${jsonEncode(widget.message.invoiceData)}');
        invoiceData = Map<String, dynamic>.from(widget.message.invoiceData!);
      }
      // 2. Fallback to invoice if it's a Map (legacy support)
      else if (widget.message.invoice is Map) {
        print('=== Found Invoice Data in invoice field ===');
        print('Invoice data: ${jsonEncode(widget.message.invoice)}');
        invoiceData = Map<String, dynamic>.from(widget.message.invoice as Map);
      }

      if (invoiceData != null) {
        print('=== Found Invoice Data ===');
        print('Invoice data: ${jsonEncode(invoiceData)}');

        // The InvoiceModel.fromJson now handles all three response formats
        // No need for complex data transformation
        setState(() {
          _invoiceData = InvoiceModel.fromJson(invoiceData!);
          _retryCount = 0; // Reset retry count on success
        });

        // Initialize timer after invoice data is set
        _initializeTimer();

        print('=== Invoice Parsed Successfully ===');
        print('Invoice ID: ${_invoiceData?.invoiceId}');
        print('Status: ${_invoiceData?.invoiceStatus}');
        print('Amount: ${_invoiceData?.invoiceAmount}');
      } else {
        print('No invoice data found in message');
      }
    } catch (e, stackTrace) {
      print('=== Error Parsing Invoice Data ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('Raw message: ${jsonEncode(widget.message.toJson())}');
    }
  }

  void _initializeTimer() {
    print('=== Initializing Timer ===');
    if (_invoiceData != null) {
      print('Invoice data is available');
      final DateTime creationDate = _invoiceData!.invoiceCreationDate;
      print('Creation date: $creationDate');
      final DateTime endDate =
          creationDate.add(const Duration(hours: _countdownHours));
      print('End date: $endDate');
      final DateTime now = DateTime.now();
      print('Current time: $now');

      if (now.isAfter(endDate)) {
        // If we're past the 48-hour mark, show 0.0.0
        print('Past 48-hour mark, showing 0.0.0');
        setState(() {
          _timerDisplay = '0.0.0';
        });
      } else {
        // Start the countdown timer
        print('Starting countdown timer');
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final DateTime currentTime = DateTime.now();
          if (currentTime.isAfter(endDate)) {
            setState(() {
              _timerDisplay = '0.0.0';
            });
            timer.cancel();
          } else {
            final Duration remaining = endDate.difference(currentTime);
            setState(() {
              final hours = remaining.inHours.toString().padLeft(2, '0');
              final minutes =
                  (remaining.inMinutes % 60).toString().padLeft(2, '0');
              final seconds =
                  (remaining.inSeconds % 60).toString().padLeft(2, '0');
              _timerDisplay = '$hours.$minutes.$seconds';
            });
          }
        });
      }
    } else {
      print('Invoice data is null, cannot initialize timer');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timer.dispose();
    _invoiceUpdateSubscription?.cancel();
    _invoiceStatusSubscription?.cancel();
    _paymentCompletedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Determine sender role - prioritize messageCreatorRole over messageCreator.role
    // This handles cases where messageCreator object might be incorrect but messageCreatorRole is correct
    final senderRole = widget.message.messageCreatorRole?.toLowerCase() ??
        (widget.message.messageCreator?.role.toLowerCase() ?? '');
    Color bubbleColor;
    if (senderRole == 'customer') {
      bubbleColor = ColorManager.blueLight800;
    } else if (senderRole == 'company' || senderRole == 'influencer') {
      bubbleColor = ColorManager.gray500;
    } else if (senderRole == 'subaccount') {
      bubbleColor = ColorManager.primaryGreen;
    } else {
      bubbleColor = ColorManager.primaryGreen;
    }

    // Get status from provider instead of directly from message
    Map<String, dynamic>? currentStatus;
    try {
      final provider = ChatProviderInherited.of(context);
      currentStatus = provider.getMessageStatus(widget.message.id);
    } catch (e) {
      // ChatProviderInherited not available in this context, use message status only
      if (kDebugMode) {
        print(
            'MessageInvoiceCustomerWidget: ChatProviderInherited not available: $e');
      }
      currentStatus = null;
    }

    // Get status values from message object first, then fall back to provider status
    // This ensures UI reflects the most up-to-date message data from the cubit
    final isSeen = widget.message.isSeen ?? currentStatus?['isSeen'] ?? false;
    final isReceived =
        widget.message.isReceived ?? currentStatus?['isReceived'] ?? false;
    final isRead = widget.message.isRead ?? currentStatus?['isRead'] ?? false;
    final isDelivered =
        widget.message.isDelivered ?? currentStatus?['isDelivered'] ?? false;

    // For sender's own messages, show proper status progression
    // For received messages, don't show status icons
    final shouldShowStatus = widget.isFromUser;

    // Determine message status based on proper progression: sent → delivered → read
    // Consider recipient's online status for accurate delivery status
    String? messageStatus;
    if (shouldShowStatus) {
      if (isRead || isSeen) {
        messageStatus = 'read'; // Blue double check - message has been read
      } else if (isReceived && isDelivered) {
        messageStatus =
            'delivered'; // Gray double check - message delivered but not read
      } else if (isReceived) {
        messageStatus =
            'sent'; // Gray single check - message sent to server (regardless of recipient online status)
      } else {
        messageStatus =
            'pending'; // No check - message pending (not yet received by server)
      }
    }

    bool hasInvoiceData = false;
    if (widget.message.invoiceData is Map) {
      hasInvoiceData = true;
    } else if (widget.message.invoice is Map) {
      hasInvoiceData = true;
    }

    if (!hasInvoiceData) {
      return const SizedBox.shrink();
    }

    // Don't show loading or error states - just return empty widget if no invoice data
    if (_invoiceData == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment:
          widget.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: widget.isFromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRoleDisplay(widget.message.messageCreatorRole ?? ''),
                  style: getRegularStyle(
                    fontSize: 10,
                    color: ColorManager.warning,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: ColorManager.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Invoice ID: ${_invoiceData?.invoice_id ?? ''}',
                      style: getRegularStyle(
                        fontSize: 12,
                        color: ColorManager.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 228,
                  height: 94,
                  decoration: BoxDecoration(
                    color: ColorManager.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Timer or placeholder to maintain layout
                            if (_invoiceData != null &&
                                _normalizeStatus(_invoiceData!.invoiceStatus) !=
                                    'paid' &&
                                _normalizeStatus(_invoiceData!.invoiceStatus) !=
                                    'under_review' &&
                                _timerDisplay != '0.0.0')
                              Text(
                                _timerDisplay,
                                style: getRegularStyle(
                                  fontSize: 12,
                                  color: ColorManager.gray900,
                                ),
                              )
                            else
                              const SizedBox(
                                  width:
                                      1), // Invisible placeholder to maintain layout
                            _buildStatusWidget(),
                          ],
                        ),
                        const SizedBox(height: 19),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionButton('View', onPressed: () async {
                              // Get the invoice ID from the current invoice data
                              final invoiceId =
                                  _invoiceData?.invoiceId ?? _invoiceData?.id;

                              if (invoiceId == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invoice ID not found'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                                return;
                              }

                              // Show loading indicator
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Loading invoice details...'),
                                    backgroundColor: Colors.blue,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }

                              try {
                                // Fetch full invoice data using ChatCubit
                                final chatCubit =
                                    context.read<ChatCustomerCubit>();
                                final fullInvoiceData = await chatCubit
                                    .fetchInvoiceDataById(invoiceId.toString());

                                if (fullInvoiceData != null && mounted) {
                                  // Check if the user is a customer
                                  final isCustomer =
                                      Constants.role == 'customer';
                                  print(
                                      'User role: ${Constants.role}, isCustomer: $isCustomer');

                                  if (isCustomer) {
                                    if (fullInvoiceData.payment_method ==
                                        "Bank Transfer") {
                                      print(
                                          'Navigating to bank transfer route');
                                      Navigator.pushNamed(
                                        context,
                                        Routes.invoiceDetailsBankTransfer,
                                        arguments: {'invoice': fullInvoiceData},
                                      );
                                    } else {
                                      print(
                                          'Navigating to regular invoice route');
                                      Navigator.pushNamed(
                                        context,
                                        Routes.invoiceDetails,
                                        arguments: {'invoice': fullInvoiceData},
                                      );
                                    }
                                  } else {
                                    if (fullInvoiceData.payment_method ==
                                        "Bank Transfer") {
                                      print(
                                          'Navigating to business bank transfer route');
                                      Navigator.pushNamed(
                                        context,
                                        Routes
                                            .invoiceDetailsBankTransferBusinessRoute,
                                        arguments: {'invoice': fullInvoiceData},
                                      );
                                    } else {
                                      print(
                                          'Navigating to business invoice route');
                                      Navigator.pushNamed(
                                        context,
                                        Routes.invoiceDetailsBusinessRoute,
                                        arguments: {'invoice': fullInvoiceData},
                                      );
                                    }
                                  }
                                } else {
                                  // Show error if invoice not found
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Invoice not found or access denied'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print('Error fetching invoice data: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error loading invoice'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            }),
                            _buildActionButton(
                              'Download',
                              onPressed: () async {
                                if (_invoiceData != null) {
                                  final result = await InvoicePdfService
                                      .generateAndDownloadInvoice(
                                    _invoiceData!,
                                    'Invoice_${_invoiceData!.invoiceId}',
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result,
                                          style: getRegularStyle(
                                            fontSize: 14,
                                            color: ColorManager.white,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 4000),
                                        backgroundColor:
                                            result == 'Error downloading file'
                                                ? ColorManager.error
                                                : ColorManager.success,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: widget.isFromUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  _formatMessageTime(widget.message.messageDate),
                  style: getRegularStyle(
                    fontSize: 12,
                    color: widget.isFromUser
                        ? ColorManager.black.withOpacity(0.7)
                        : ColorManager.black,
                  ),
                ),
                if (shouldShowStatus && messageStatus != 'pending' ||
                    widget.message.isTemp == true)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      messageStatus == 'read' ||
                              messageStatus == 'delivered' ||
                              widget.message.isDelivered == true ||
                              widget.message.isRead == true
                          ? Icons.done_all // Double check for delivered/read
                          : Icons.check, // Single check for sent
                      size: 16,
                      color: messageStatus == 'read' ||
                              widget.message.isSeen == true ||
                              widget.message.isRead == true
                          ? ColorManager.black
                            .withOpacity(0.7)
                          : ColorManager.black
                              .withOpacity(0.7), // Gray for sent/delivered
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Normalize status strings to handle different formats
  String _normalizeStatus(String? status) {
    if (status == null) return 'unknown';

    final normalized = status.toLowerCase().trim();
    switch (normalized) {
      case 'under review':
      case 'under_review':
        return 'under_review';
      case 'paid':
        return 'paid';
      case 'unpaid':
        return 'unpaid';
      case 'expired':
        return 'expired';
      default:
        return normalized;
    }
  }

  String _getStatusMessage(String status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'paid':
        return 'paid';
      case 'unpaid':
        return 'unpaid';
      case 'expired':
        return 'expired';
      case 'under_review':
        return 'under review';
      default:
        return 'Invoice status: $status';
    }
  }

  Widget _buildStatusWidget() {
    final status = _invoiceData?.invoiceStatus ?? 'Unknown';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getStatusMessage(status),
        style: getRegularStyle(
          fontSize: 10,
          color: ColorManager.white,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, {required VoidCallback onPressed}) {
    // Determine sender role - prioritize messageCreatorRole over messageCreator.role
    // This handles cases where messageCreator object might be incorrect but messageCreatorRole is correct
    final senderRole = widget.message.messageCreatorRole?.toLowerCase() ??
        (widget.message.messageCreator?.role.toLowerCase() ?? '');
    Color buttonColor;
    if (senderRole == 'customer') {
      buttonColor = ColorManager.blueLight800;
    } else if (senderRole == 'company' || senderRole == 'influencer') {
      buttonColor = ColorManager.gray500;
    } else if (senderRole == 'subaccount') {
      buttonColor = ColorManager.primaryGreen;
    } else {
      buttonColor = ColorManager.primaryGreen;
    }

    return SizedBox(
      width: 93.5,
      height: 26,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: getMediumStyle(
            fontSize: 12,
            color: ColorManager.white,
          ),
        ),
      ),
    );
  }

  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'company':
      case 'influencer':
        return 'Manager';
      case 'subaccount':
        return 'Employee';
      default:
        return 'Employee';
    }
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'unpaid':
        return Colors.red; // Red
      case 'expired':
        return ColorManager.lightGrey; // Grey
      case 'under_review':
        return ColorManager.primaryunderreview; // Blue
      default:
        return ColorManager.lightGrey;
    }
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'moments ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24 &&
        now.day == dateTime.day &&
        now.month == dateTime.month &&
        now.year == dateTime.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  bool get wantKeepAlive => true;

  /// Handle bank transfer receipt uploads specifically
  void _handleBankTransferReceiptUpdate(InvoiceUpdateEvent event) {
    final invoiceData = event.invoice;
    final normalizedStatus =
        _normalizeStatus(invoiceData['invoice_status']?.toString());
    final isBankTransferReceipt = normalizedStatus == 'under_review' &&
        invoiceData['bankTransferReceiptUploadedURL'] != null;

    if (!isBankTransferReceipt) return;

    if (kDebugMode) {
      print('🔄 Bank transfer receipt detected!');
      try {
        print(
            'Invoice ID: ${invoiceData['invoiceId'] ?? invoiceData['invoice_id'] ?? invoiceData['_id']}');
      } catch (_) {}
      print('Status: ${invoiceData['invoice_status']}');
      print('Receipt URL: ${invoiceData['bankTransferReceiptUploadedURL']}');
    }

    // Derive event invoice id flexibly
    final eventInvoiceId = event.invoiceId.isNotEmpty
        ? event.invoiceId
        : (invoiceData['invoiceId']?.toString() ??
            invoiceData['invoice_id']?.toString() ??
            invoiceData['_id']?.toString() ??
            '');

    // Derive current invoice id from widget or parsed data
    String? currentInvoiceId;
    if (_invoiceData != null) {
      currentInvoiceId = _invoiceData!.invoiceId;
    } else {
      try {
        if (widget.message.invoiceData is Map) {
          final messageInvoiceData = widget.message.invoiceData as Map;
          currentInvoiceId = messageInvoiceData['invoiceId']?.toString() ??
              messageInvoiceData['invoice_id']?.toString() ??
              messageInvoiceData['_id']?.toString();
        } else if (widget.message.invoice is Map) {
          final messageInvoiceData = widget.message.invoice as Map;
          currentInvoiceId = messageInvoiceData['invoiceId']?.toString() ??
              messageInvoiceData['invoice_id']?.toString() ??
              messageInvoiceData['_id']?.toString();
        }
      } catch (e) {
        if (kDebugMode) print('Error deriving current invoice id: $e');
      }
    }

    if (currentInvoiceId != null && currentInvoiceId == eventInvoiceId) {
      if (kDebugMode)
        print('✅ This is our invoice (bank transfer) — updating immediately');
      _updateInvoiceData(invoiceData);
    } else {
      if (kDebugMode) print('❌ Not our invoice, skipping unnecessary API call');
    }
  }
}
