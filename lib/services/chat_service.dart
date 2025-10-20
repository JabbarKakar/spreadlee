import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:spreadlee/domain/chat_model.dart';

// Define progress callback type
typedef ProgressCallback = void Function(double progress, String status);

// Define callback types for new features
typedef UserStatusCallback = void Function(Map<String, dynamic> data);
typedef TypingStatusCallback = void Function(Map<String, dynamic> data);
typedef MessageReadCallback = void Function(Map<String, dynamic> data);
typedef ForceLogoutCallback = void Function(Map<String, dynamic> data);

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService({String? baseUrl, String? token}) {
    if (baseUrl != null) _instance.baseUrl = baseUrl;
    if (token != null) _instance.token = token;
    return _instance;
  }
  ChatService._internal();

  late IO.Socket socket;
  late String baseUrl;
  late String token;
  Function(Map<String, dynamic>)? _onNewMessageCallback;
  Function(Map<String, dynamic>)? _onMessageErrorCallback;
  Function(Map<String, dynamic>)? _onMessagesReadCallback;

  // New callback handlers
  UserStatusCallback? _onUserStatusChangeCallback;
  TypingStatusCallback? _onUserStartedTypingCallback;
  TypingStatusCallback? _onUserStoppedTypingCallback;
  MessageReadCallback? _onMessageSeenUpdateCallback;
  MessageReadCallback? _onMessageReceivedCallback;
  MessageReadCallback? _onMessagesDeliveredCallback;
  MessageReadCallback? _onMessageSentCallback;
  MessageReadCallback? _onMessagesUpdatedCallback;
  ForceLogoutCallback? _onForceLogoutCallback;
  Function(Map<String, dynamic>)? _onInvoiceUpdatedCallback;

  bool _isConnected = false;
  final List<Function(dynamic)> _temporaryListeners = [];

  // Add connection state tracking
  bool _isInitializing = false;
  // When suspended is true, initialization requests are ignored. Use suspend()
  // during logout to prevent any part of the app from recreating the socket.
  bool _suspended = false;
  DateTime? _lastConnectionAttempt;
  int _connectionAttempts = 0;
  static const int _maxConnectionAttempts = 5;

  // Add deduplication tracking for messages_read events
  final Set<String> _processedEventIds = {};
  final Map<String, DateTime> _lastEventTimestamps = {};

  // Add getter for connection status
  bool get isConnected => _isConnected && socket.connected;

  // Add getter for socket instance
  IO.Socket get socketInstance => socket;

  // Track joined chat rooms
  final Set<String> _joinedChatRooms = {};

  // Track currently open chat for auto-marking messages as read
  String? _currentOpenChatId;

  // Flag to prevent multiple ACCESS_DENIED handling
  bool _isHandlingAccessDenied = false;

  /// Set the currently open chat ID for auto-marking messages as read
  void setCurrentOpenChat(String? chatId) {
    _currentOpenChatId = chatId;
    if (kDebugMode) {
      print('ChatService: Current open chat set to: $chatId');
    }
  }

  /// Clear the currently open chat ID
  void clearCurrentOpenChat() {
    if (kDebugMode) {
      print('ChatService: Clearing current open chat (was: $_currentOpenChatId)');
    }
    _currentOpenChatId = null;
  }

  // Move _initializeSocket logic to be called only once, or when baseUrl/token changes
  void initializeSocket() {
    // Respect suspend flag to prevent re-initialization after logout
    if (_suspended) {
      if (kDebugMode) {
        print(
            'ChatService: Initialization suppressed because service is suspended');
      }
      return;
    }
    // Prevent multiple simultaneous initialization attempts
    if (_isInitializing) {
      if (kDebugMode) {
        print('ChatService: Socket initialization already in progress');
      }
      return;
    }

    // Check if we need to reinitialize
    if (_isConnected && socket.connected) {
      if (kDebugMode) {
        print(
            'ChatService: Socket already connected, skipping re-initialization');
      }
      return;
    }

    _isInitializing = true;
    _connectionAttempts++;

    try {
      // Only re-initialize if baseUrl or token changed, or socket is not connected
      if (_isConnected && socket.connected) {
        if (kDebugMode) {
          print(
              'ChatService: Socket already connected, skipping re-initialization');
        }
        _isInitializing = false;
        return;
      }

      // Convert base URL to socket URL format
      final uri = Uri.parse(baseUrl);
      // Uri.parse() returns default ports: 443 for HTTPS, 80 for HTTP
      // Only include port if it's NOT the default port for the scheme
      final protocol = uri.scheme == 'https' ? 'wss' : 'ws';
      final defaultPort = uri.scheme == 'https' ? 443 : 80;
      final socketUrl = (uri.hasPort && uri.port != defaultPort)
          ? '$protocol://${uri.host}:${uri.port}'
          : '$protocol://${uri.host}';

      if (kDebugMode) {
        print('=== Initializing Socket ===');
        print('Base URL: $baseUrl');
        print('Socket URL: $socketUrl');
        print('Token: ${token.substring(0, min(10, token.length))}...');
        print('Connection attempt: $_connectionAttempts');
      }

      socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setQuery({'token': token})
            .enableForceNew()
            .setReconnectionAttempts(0) // Disable auto reconnection
            .setReconnectionDelay(0)
            .setReconnectionDelayMax(0)
            .setTimeout(30000)
            .disableAutoConnect()
            .build(),
      );

      // Add connection event handlers
      socket.onConnect((_) {
        if (kDebugMode) {
          print('=== Socket Connected ===');
          print('Socket ID: ${socket.id}');
          print('Connected at: ${DateTime.now()}');
        }
        _isConnected = true;
        _isInitializing = false;
        _connectionAttempts =
            0; // Reset connection attempts on successful connection
        _lastConnectionAttempt = DateTime.now();

        // Join all user's chats automatically for real-time message updates
        _joinAllUserChats();
      });

      socket.onConnectError((data) {
        if (kDebugMode) {
          print('=== Socket Connection Error ===');
          print('Error data: $data');
          print('Error at: ${DateTime.now()}');
          print('Connection attempt: $_connectionAttempts');
        }
        _isConnected = false;
        _isInitializing = false;

        // No auto reconnection - let the manual popup handle it
        if (kDebugMode) {
          print('Connection failed - manual reconnection required');
        }
      });

      socket.onDisconnect((reason) {
        if (kDebugMode) {
          print('=== Socket Disconnected ===');
          print('Reason: ${reason ?? "unknown"}');
          print('Disconnected at: ${DateTime.now()}');
        }
        _isConnected = false;
        _isInitializing = false;

        // No auto reconnection - let the manual popup handle it
        if (kDebugMode) {
          print('Socket disconnected - manual reconnection required');
        }
      });

      socket.onError((error) {
        if (kDebugMode) {
          print('=== Socket Error ===');
          print('Error: $error');
          print('Error at: ${DateTime.now()}');
        }
        _isInitializing = false;
      });

      socket.on('error', (data) {
        if (kDebugMode) {
          print('=== Socket Event Error ===');
          print('Error data: $data');
          print('Error at: ${DateTime.now()}');
        }
        _isInitializing = false;
      });

      // Handle delivery_error events
      socket.on('delivery_error', (data) {
        if (kDebugMode) {
          print('=== Socket Event: delivery_error ===');
          print('Error data: $data');
        }
        try {
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            // Check for ACCESS_DENIED error
            if (actualData['code'] == 'ACCESS_DENIED' ||
                actualData['error']?.toString().contains('Access denied') ==
                    true) {
              print(
                  '=== ACCESS_DENIED in delivery_error - Reinitializing socket ===');
              print('Error data: $actualData');
              _handleAccessDenied();
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing delivery_error event: $e');
          }
        }
      });

      // Handle read_error events
      socket.on('read_error', (data) {
        if (kDebugMode) {
          print('=== Socket Event: read_error ===');
          print('Error data: $data');
        }
        try {
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            // Check for ACCESS_DENIED error
            if (actualData['code'] == 'ACCESS_DENIED' ||
                actualData['error']?.toString().contains('Access denied') ==
                    true) {
              print(
                  '=== ACCESS_DENIED in read_error - Reinitializing socket ===');
              print('Error data: $actualData');
              _handleAccessDenied();
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing read_error event: $e');
          }
        }
      });

      // Auto reconnection disabled - manual popup handles reconnection

      // Add new event listeners for online/offline status, typing, and message read status
      socket.on('user_status_change', (data) {
        if (kDebugMode) {
          print('=== User Status Change Event ===');
          print('Data: $data');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onUserStatusChangeCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing user_status_change: $e');
          }
        }
      });

      socket.on('user_status_response', (data) {
        if (kDebugMode) {
          print('=== User Status Response Event ===');
          print('Data: $data');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onUserStatusChangeCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing user_status_response: $e');
          }
        }
      });

      socket.on('user_started_typing', (data) {
        if (kDebugMode) {
          print('=== User Started Typing Event ===');
          print('Data: $data');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onUserStartedTypingCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing user_started_typing: $e');
          }
        }
      });

      socket.on('user_stopped_typing', (data) {
        if (kDebugMode) {
          print('=== User Stopped Typing Event ===');
          print('Data: $data');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onUserStoppedTypingCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing user_stopped_typing: $e');
          }
        }
      });

      socket.on('message_seen_update', (data) {
        if (kDebugMode) {
          print('=== Message Seen Update Event ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (kDebugMode) {
            print('Actual data: $actualData');
            print('Actual data type: ${actualData.runtimeType}');
          }
          if (actualData is Map<String, dynamic>) {
            if (kDebugMode) {
              print('Calling message_seen_update callback with: $actualData');
            }
            _onMessageSeenUpdateCallback?.call(actualData);
          } else {
            if (kDebugMode) {
              print('Actual data is not a Map<String, dynamic>');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing message_seen_update: $e');
            print('Data structure: $data');
          }
        }
      });

      socket.on('message_received', (data) {
        if (kDebugMode) {
          print('=== Message Received Event ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (kDebugMode) {
            print('Actual data: $actualData');
            print('Actual data type: ${actualData.runtimeType}');
          }
          if (actualData is Map<String, dynamic>) {
            if (kDebugMode) {
              print('Calling message_received callback with: $actualData');
            }
            _onMessageReceivedCallback?.call(actualData);
          } else {
            if (kDebugMode) {
              print('Actual data is not a Map<String, dynamic>');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing message_received: $e');
            print('Data structure: $data');
          }
        }
      });

      socket.on('messages_delivered', (data) {
        if (kDebugMode) {
          print('=== Messages Delivered Event ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (kDebugMode) {
            print('Actual data: $actualData');
            print('Actual data type: ${actualData.runtimeType}');
          }
          if (actualData is Map<String, dynamic>) {
            if (kDebugMode) {
              print('Calling messages_delivered callback with: $actualData');
            }
            _onMessagesDeliveredCallback?.call(actualData);
          } else {
            if (kDebugMode) {
              print('Actual data is not a Map<String, dynamic>');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing messages_delivered: $e');
            print('Data structure: $data');
          }
        }
      });

      // Alternative event names that might be used by the backend
      socket.on('message_delivered', (data) {
        if (kDebugMode) {
          print('=== Message Delivered Event (Alternative) ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Received at: ${DateTime.now()}');
        }
        try {
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onMessagesDeliveredCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing message_delivered: $e');
          }
        }
      });

      socket.on('message_seen', (data) {
        if (kDebugMode) {
          print('=== Message Seen Event (Alternative) ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Received at: ${DateTime.now()}');
        }
        try {
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onMessageSeenUpdateCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing message_seen: $e');
          }
        }
      });

      socket.on('message_read', (data) {
        if (kDebugMode) {
          print('=== Message Read Event (Alternative) ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Received at: ${DateTime.now()}');
        }
        try {
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onMessageSeenUpdateCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing message_read: $e');
          }
        }
      });

      socket.on('force_logout', (data) {
        if (kDebugMode) {
          print('=== Force Logout Event ===');
          print('Data: $data');
          print('Received at: ${DateTime.now()}');
        }
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onForceLogoutCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing force_logout: $e');
          }
        }
      });

      // Add main new_message event listener
      socket.on('new_message', (data) {
        if (kDebugMode) {
          print('=== New Message Event ===');
          print('Data: $data');
          print('Received at: ${DateTime.now()}');
        }

        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;

          if (actualData is Map<String, dynamic>) {
            // Forward to all registered listeners
            for (var listener in _onNewMessageListeners) {
              try {
                listener(actualData);
              } catch (e) {
                if (kDebugMode) {
                  print('Error in new message listener: $e');
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing new_message event: $e');
          }
        }
      });

      // Add message_sent event listener
      if (kDebugMode) {
        print('ChatService: Setting up message_sent socket listener');
        print(
            'ChatService: Callback is null: ${_onMessageSentCallback == null}');
      }
      socket.on('message_sent', (data) {
        if (kDebugMode) {
          print('=== Received Message Sent Event ===');
          print('Raw data: $data');
          print('Data type: ${data.runtimeType}');
          print('Received at: ${DateTime.now()}');
        }

        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            // Auto-mark message as read if it's from the currently open chat
            final chatId = actualData['chat_id']?.toString();
            final messageId = actualData['_id']?.toString() ?? "";

            // Only mark as read if:
            // 1. This chat is currently open
            // 2. Message has valid IDs
            if (chatId != null && messageId.isNotEmpty && chatId == _currentOpenChatId) {
              if (kDebugMode) {
                print('=== Auto-marking message as read (chat is open) ===');
                print('Chat ID: $chatId');
                print('Message ID: $messageId');
              }

              // Mark this message as read immediately
              markMessagesAsRead(chatId, [messageId]);

            } else {
              if (kDebugMode && chatId != null && messageId.isNotEmpty && chatId != _currentOpenChatId) {
                print('=== Message NOT auto-marked as read (chat not open) ===');
                print('Message chat: $chatId');
                print('Current open chat: $_currentOpenChatId');
              }
            }

            if (kDebugMode) {
              print('ChatService: Calling message_sent callback');
              print(
                  'ChatService: Callback is null: ${_onMessageSentCallback == null}');
            }
            _onMessageSentCallback?.call(actualData);
            if (kDebugMode) {
              print('ChatService: message_sent callback called successfully');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing message_sent event: $e');
          }
        }
      });

      // Add messages_updated event listener
      socket.on('messages_updated', (data) {
        try {
          // Handle case where data is a List with the actual data at index 0
          final actualData = data is List ? data[0] : data;
          if (actualData is Map<String, dynamic>) {
            _onMessagesUpdatedCallback?.call(actualData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing messages_updated event: $e');
          }
        }
      });

      // Add a general event listener to see all events
      socket.onAny((eventName, data) {
        if (kDebugMode) {
          print('=== Socket Event Received ===');
          print('Event: $eventName');
          print('Data: $data');
          print('Received at: ${DateTime.now()}');
        }
      });

      // Connect the socket
      if (kDebugMode) {
        print('Attempting to connect socket...');
      }
      socket.connect();
    } catch (e) {
      if (kDebugMode) {
        print('=== Socket Initialization Error ===');
        print('Error: $e');
        print('Error at: ${DateTime.now()}');
      }
      _isConnected = false;
      _isInitializing = false;
    }
  }

  Future<Uint8List?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize image if it's too large
      var resized = image;
      if (image.width > 800 || image.height > 800) {
        resized = img.copyResize(
          image,
          width: min(800, image.width),
          height: min(800, image.height),
        );
      }

      // Encode with quality 70
      final compressed = img.encodeJpg(resized, quality: 70);
      print(
          'Original size: ${bytes.length}, Compressed size: ${compressed.length}');
      return Uint8List.fromList(compressed);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<bool> _sendMessageWithRetry(Map<String, dynamic> messageData) async {
    int attempt = 1;
    bool lastAttemptSuccess = false;
    final messageId = messageData['message_id'];

    // Create a completer that will be completed by either the ack or the socket event
    final completer = Completer<bool>();
    Timer? timeoutTimer;

    // Set up a listener for the new_message event that will complete the completer
    void messageListener(dynamic data) {
      print('Received new_message event: $data');
      if (data is List && data.isNotEmpty && data[0] is Map) {
        final message = data[0];
        print('Checking message_id: ${message['message_id']} vs $messageId');
        if (message != null && message['message_id'] == messageId) {
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      }
    }

    // Add temporary listener for this specific message
    socket.on('new_message', messageListener);

    // Set timeout
    timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        // Don't complete with false, just let it wait for the socket event
        if (kDebugMode) {
          print('Message send timeout, waiting for socket event...');
        }
      }
    });

    try {
      // ✅ ADDED: Debug logging to see what's being sent
      if (kDebugMode) {
        print('🧾 SENDING MESSAGE TO BACKEND:');
        print('  - messageType: ${messageData['messageType']}');
        print('  - messageInvoiceRef: ${messageData['messageInvoiceRef']}');
        print('  - hasInvoiceData: ${messageData.containsKey('invoiceData')}');
        print('  - invoiceData: ${messageData['invoiceData']}');
        print('  - Full messageData: ${jsonEncode(messageData)}');
      }

      socket.emitWithAck('send_message', messageData, ack: (data) {
        if (data == null) {
          if (kDebugMode) {
            print('Warning: Received null acknowledgment');
          }
          // Don't complete here, wait for socket event
          return;
        }

        if (data is Map && data.containsKey('error')) {
          if (kDebugMode) {
            print('Error in message acknowledgment: ${data['error']}');
          }
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          return;
        }

        if (kDebugMode) {
          print('Message sent successfully - ACK received: $data');
        }
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      // Wait for either the ack or the socket event
      lastAttemptSuccess = await completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('Error during send attempt: $e');
      }
      lastAttemptSuccess = false;
    } finally {
      timeoutTimer.cancel();
      socket.off('new_message', messageListener);
    }

    return lastAttemptSuccess;
  }

  /// Upload a file using the backend's upload_file event (unused - kept for reference)
  Future<String?> _uploadFileToServerOld(
      File file, String fileType, String mimeType, String chatId) async {
    print('=== Starting file upload ===');
    final completer = Completer<String?>();
    Timer? timeoutTimer;

    try {
      // Read file bytes
      Uint8List? fileBytes;
      if (fileType == 'image') {
        fileBytes = await _compressImage(file);
        if (fileBytes == null) {
          print('Failed to compress image, using original');
          fileBytes = await file.readAsBytes();
        }
      } else {
        fileBytes = await file.readAsBytes();
      }

      final base64String = base64Encode(fileBytes);
      print('File size after compression: ${fileBytes.length} bytes');
      print('Base64 size: ${base64String.length} bytes');

      // Prepare file data in the exact format the backend expects
      final fileData = {
        'chat_id': chatId,
        'fileName': path.basename(file.path),
        'fileType': mimeType,
        'fileSize': fileBytes.length,
        'fileData': base64String,
        'messageType': fileType,
      };

      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (!completer.isCompleted) {
          print('File upload timeout');
          completer.complete(null);
        }
      });

      // Use the exact event name and structure the backend expects
      socket.emitWithAck('upload_file', fileData, ack: (data) {
        timeoutTimer?.cancel();
        print('Received upload_file acknowledgment: $data');

        if (data == null) {
          print('Warning: Received null acknowledgment for file upload');
          completer.complete(null);
          return;
        }

        if (data is Map && data.containsKey('error')) {
          print('Error in file upload: ${data['error']}');
          completer.complete(null);
          return;
        }

        // Handle the backend response format
        String? fileUrl;
        if (data is Map) {
          if (data['success'] == true && data['data'] != null) {
            // Backend returns: { success: true, data: { url: "..." }, message: "..." }
            fileUrl = data['data']['url'];
          } else {
            // Try alternative response formats
            fileUrl = data['url'] ??
                data['file_id'] ??
                data['id'] ??
                data['path'] ??
                data['fileUrl'];
          }
        } else if (data is String) {
          fileUrl = data;
        }

        if (fileUrl != null) {
          print('File uploaded successfully: $fileUrl');
          completer.complete(fileUrl);
        } else {
          print('Unexpected file upload response format: $data');
          completer.complete(null);
        }
      });
    } catch (e) {
      print('Error during file upload: $e');
      completer.complete(null);
    }

    return completer.future;
  }

  /// Upload video in chunks for large files
  Future<String?> _uploadVideoInChunks(File videoFile, String mimeType) async {
    try {
      if (!await videoFile.exists()) {
        print('❌ ERROR: Video file not found: ${videoFile.path}');
        return null;
      }

      // Read the video file
      final videoBytes = await videoFile.readAsBytes();
      const chunkSize = 750 *
          1024; // 750KB chunks to stay under 1MB when base64 encoded (~1MB)
      final totalChunks = (videoBytes.length / chunkSize).ceil();

      // Generate a unique upload ID for this video
      final uploadId =
          'video_${DateTime.now().millisecondsSinceEpoch}_${videoBytes.length}';

      // Upload each chunk
      List<String> chunkUrls = [];
      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize).clamp(0, videoBytes.length);
        final chunkBytes = videoBytes.sublist(start, end);
        final chunkBase64 = base64Encode(chunkBytes);

        print(
            'Uploading chunk ${i + 1}/$totalChunks (${chunkBytes.length} bytes)');

        // Create chunk data with proper metadata for reassembly
        final chunkData = {
          'fileType': mimeType,
          'fileSize': chunkBytes.length,
          'fileData': chunkBase64,
          'messageType': 'video',
          'filename': path.basename(videoFile.path),
          'metadata': {
            'originalPath': videoFile.path,
            'type': 'video',
            'uploadId': uploadId,
            'chunkIndex': i,
            'totalChunks': totalChunks,
            'originalSize': videoBytes.length,
            'isChunked': true,
          }
        };

        // Upload chunk using socket
        final chunkUrl = await _uploadChunkViaSocket(chunkData);
        if (chunkUrl != null) {
          chunkUrls.add(chunkUrl);
          print('✅ Chunk ${i + 1} uploaded successfully: $chunkUrl');
        } else {
          print('❌ ERROR: Failed to upload chunk ${i + 1}');
          return null;
        }
      }

      // All chunks uploaded successfully
      if (chunkUrls.isNotEmpty) {
        // Return the first chunk URL - the backend should handle reassembly
        // based on the uploadId and chunk metadata
        return chunkUrls.first;
      }

      return null;
    } catch (e) {
      print('Error during chunked video upload: $e');
      return null;
    }
  }

  /// Upload a single chunk via socket
  Future<String?> _uploadChunkViaSocket(Map<String, dynamic> chunkData) async {
    try {
      final completer = Completer<String?>();
      Timer? timeoutTimer;

      // Set timeout for chunk upload
      timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          print('Chunk upload timeout');
          completer.complete(null);
        }
      });

      // Use the upload_file event as specified by backend requirements
      socket.emitWithAck('upload_file', chunkData, ack: (data) {
        timeoutTimer?.cancel();
        print('Received upload_file acknowledgment for chunk: $data');

        if (data == null) {
          print('Warning: Received null acknowledgment for chunk upload');
          completer.complete(null);
          return;
        }

        if (data is Map && data.containsKey('error')) {
          print('Error in chunk upload: ${data['error']}');
          completer.complete(null);
          return;
        }

        // Try different possible response formats
        String? fileUrl;
        if (data is Map) {
          fileUrl = data['file_id'] ??
              data['id'] ??
              data['url'] ??
              data['path'] ??
              data['videoUrl'] ??
              data['video_url'] ??
              data['fileUrl'];
        } else if (data is String) {
          fileUrl = data;
        }

        if (fileUrl != null) {
          print('Chunk uploaded successfully: $fileUrl');
          completer.complete(fileUrl);
        } else {
          print('Unexpected chunk upload response format: $data');
          completer.complete(null);
        }
      });

      return completer.future;
    } catch (e) {
      print('Error during chunk upload: $e');
      return null;
    }
  }

  /// Upload video using the backend's upload_file event (automatically creates message)
  Future<String?> uploadVideoMessage(File file, String chatId,
      {ProgressCallback? onProgress, String? userRole, String? tempId}) async {
    try {
      onProgress?.call(0.1, 'Preparing video for upload...');

      // Ensure socket is connected
      if (!socket.connected) {
        onProgress?.call(0.0, 'Connecting to server...');
        socket.connect();
        await Future.delayed(const Duration(seconds: 2));
        if (!socket.connected) {
          throw Exception('Socket not connected');
        }
      }

      onProgress?.call(0.2, 'Reading video file...');

      // Read video file
      final videoBytes = await file.readAsBytes();
      final base64String = base64Encode(videoBytes);
      final mimeType = _getMimeType(file.path);

      onProgress?.call(0.3, 'Preparing upload data...');

      // Prepare video upload data in the exact format the backend expects
      final videoData = {
        'chat_id': chatId,
        'fileName': path.basename(file.path),
        'fileType': mimeType,
        'fileSize': videoBytes.length,
        'fileData': base64String,
        'messageType': 'video',
        'messageCreatorRole': userRole ?? 'customer', // Pass user role
        'tempId': tempId, // Pass tempId for message matching
      };

      onProgress?.call(0.4, 'Uploading video to server...');

      final completer = Completer<String?>();
      Timer? timeoutTimer;

      // Set longer timeout for video uploads
      timeoutTimer = Timer(const Duration(seconds: 120), () {
        if (!completer.isCompleted) {
          print('Video upload timeout');
          onProgress?.call(0.0, 'Upload timeout');
          completer.complete(null);
        }
      });

      // Use the exact event name and structure the backend expects
      socket.emitWithAck('upload_file', videoData, ack: (data) {
        timeoutTimer?.cancel();
        print('Received upload_file acknowledgment for video: $data');

        if (data == null) {
          print('Warning: Received null acknowledgment for video upload');
          onProgress?.call(0.0, 'Upload failed - no response');
          completer.complete(null);
          return;
        }

        if (data is Map && data.containsKey('error')) {
          print('Error in video upload: ${data['error']}');
          onProgress?.call(0.0, 'Upload failed: ${data['error']}');
          completer.complete(null);
          return;
        }

        // Handle the backend response format
        String? fileUrl;
        if (data is Map) {
          if (data['success'] == true && data['data'] != null) {
            // Backend returns: { success: true, data: { url: "..." }, message: "..." }
            fileUrl = data['data']['url'];
          } else {
            // Try alternative response formats
            fileUrl = data['url'] ??
                data['file_id'] ??
                data['id'] ??
                data['path'] ??
                data['videoUrl'] ??
                data['video_url'];
          }
        } else if (data is String) {
          fileUrl = data;
        }

        if (fileUrl != null) {
          print('Video uploaded successfully: $fileUrl');
          onProgress?.call(1.0, 'Video uploaded successfully');
          completer.complete(fileUrl);
        } else {
          print('Unexpected video upload response format: $data');
          onProgress?.call(0.0, 'Upload failed - unexpected response');
          completer.complete(null);
        }
      });

      return completer.future;
    } catch (e) {
      print('Error during socket video upload: $e');
      return null;
    }
  }

  /// Upload image using the backend's upload_file event (automatically creates message)
  Future<String?> uploadImageMessage(File file, String chatId,
      {ProgressCallback? onProgress, String? userRole, String? tempId}) async {
    try {
      print('=== Starting image upload ===');
      final completer = Completer<String?>();
      Timer? timeoutTimer;

      onProgress?.call(0.1, 'Preparing image for upload...');

      // Check file size (max 10MB for images)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        print('Image file too large: ${fileSize / (1024 * 1024)}MB');
        onProgress?.call(0.0, 'Image file too large (max 10MB)');
        return null;
      }

      onProgress?.call(0.2, 'Reading image file...');

      // Read and compress image file
      final imageBytes =
          await _compressImageForUpload(file) ?? await file.readAsBytes();
      final base64String = base64Encode(imageBytes);
      final mimeType = _getMimeType(file.path);

      onProgress?.call(0.3, 'Preparing upload data...');

      // Prepare image data in the exact format the backend expects
      final imageData = {
        'chat_id': chatId,
        'fileName': path.basename(file.path),
        'fileType': mimeType,
        'fileSize': imageBytes.length,
        'fileData': base64String,
        'messageType': 'image',
        'messageCreatorRole': userRole ?? 'customer', // Pass user role
        'tempId': tempId, // Pass tempId for message matching
      };

      onProgress?.call(0.4, 'Uploading image to server...');

      // Set up timeout
      timeoutTimer = Timer(const Duration(minutes: 2), () {
        if (!completer.isCompleted) {
          print('Image upload timeout');
          onProgress?.call(0.0, 'Upload timeout');
          completer.complete(null);
        }
      });

      // Use the exact event name and structure the backend expects
      socket.emitWithAck('upload_file', imageData, ack: (data) {
        timeoutTimer?.cancel();
        print('Received upload_file acknowledgment for image: $data');

        if (data == null) {
          print('Warning: Received null acknowledgment for image upload');
          onProgress?.call(0.0, 'Upload failed - no response');
          completer.complete(null);
          return;
        }

        String? fileUrl;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            fileUrl = data['data']?['url'] ?? data['url'];
          } else {
            print('Image upload failed: ${data['error']}');
            onProgress?.call(0.0, 'Upload failed: ${data['error']}');
            completer.complete(null);
            return;
          }
        } else if (data is String) {
          fileUrl = data;
        }

        if (fileUrl != null) {
          print('Image uploaded successfully: $fileUrl');
          onProgress?.call(1.0, 'Image uploaded successfully');
          completer.complete(fileUrl);
        } else {
          print('Unexpected image upload response format: $data');
          onProgress?.call(0.0, 'Upload failed - unexpected response');
          completer.complete(null);
        }
      });

      return completer.future;
    } catch (e) {
      print('Error during socket image upload: $e');
      onProgress?.call(0.0, 'Upload failed: $e');
      return null;
    }
  }

  /// Upload document using the backend's upload_file event (automatically creates message)
  Future<String?> uploadDocumentMessage(File file, String chatId,
      {ProgressCallback? onProgress, String? userRole, String? tempId}) async {
    try {
      print('=== Starting document upload ===');
      final completer = Completer<String?>();
      Timer? timeoutTimer;

      onProgress?.call(0.1, 'Preparing document for upload...');

      // Check file size (max 50MB for documents)
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        print('Document file too large: ${fileSize / (1024 * 1024)}MB');
        onProgress?.call(0.0, 'Document file too large (max 50MB)');
        return null;
      }

      onProgress?.call(0.2, 'Reading document file...');

      // Read document file
      final documentBytes = await file.readAsBytes();
      final base64String = base64Encode(documentBytes);
      final mimeType = _getMimeType(file.path);
      final fileType = _getFileType(file.path);

      onProgress?.call(0.3, 'Preparing upload data...');

      // Prepare document data in the exact format the backend expects
      final documentData = {
        'chat_id': chatId,
        'fileName': path.basename(file.path),
        'fileType': mimeType,
        'fileSize': documentBytes.length,
        'fileData': base64String,
        'messageType': fileType, // 'file' for documents
        'messageCreatorRole': userRole ?? 'customer', // Pass user role
        'tempId': tempId, // Pass tempId for message matching
      };

      onProgress?.call(0.4, 'Uploading document to server...');

      // Set up timeout
      timeoutTimer = Timer(const Duration(minutes: 5), () {
        if (!completer.isCompleted) {
          print('Document upload timeout');
          onProgress?.call(0.0, 'Upload timeout');
          completer.complete(null);
        }
      });

      // Use the exact event name and structure the backend expects
      socket.emitWithAck('upload_file', documentData, ack: (data) {
        timeoutTimer?.cancel();
        print('Received upload_file acknowledgment for document: $data');

        if (data == null) {
          print('Warning: Received null acknowledgment for document upload');
          onProgress?.call(0.0, 'Upload failed - no response');
          completer.complete(null);
          return;
        }

        String? fileUrl;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            fileUrl = data['data']?['url'] ?? data['url'];
          } else {
            print('Document upload failed: ${data['error']}');
            onProgress?.call(0.0, 'Upload failed: ${data['error']}');
            completer.complete(null);
            return;
          }
        } else if (data is String) {
          fileUrl = data;
        }

        if (fileUrl != null) {
          print('Document uploaded successfully: $fileUrl');
          onProgress?.call(1.0, 'Document uploaded successfully');
          completer.complete(fileUrl);
        } else {
          print('Unexpected document upload response format: $data');
          onProgress?.call(0.0, 'Upload failed - unexpected response');
          completer.complete(null);
        }
      });

      return completer.future;
    } catch (e) {
      print('Error during socket document upload: $e');
      onProgress?.call(0.0, 'Upload failed: $e');
      return null;
    }
  }

  Future<Uint8List?> _compressImageForUpload(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Calculate target dimensions while maintaining aspect ratio
      int targetWidth = image.width;
      int targetHeight = image.height;
      const maxDimension = 1200; // Maximum dimension for either width or height
      const maxFileSize = 500 * 1024; // 500KB max file size

      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          targetWidth = maxDimension;
          targetHeight = (image.height * maxDimension / image.width).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (image.width * maxDimension / image.height).round();
        }
      }

      // Resize image
      var resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );

      // Start with quality 85 and reduce if needed
      int quality = 85;
      var compressed = img.encodeJpg(resized, quality: quality);

      // If still too large, reduce quality until we hit the size limit or minimum quality
      while (compressed.length > maxFileSize && quality > 30) {
        quality -= 5;
        compressed = img.encodeJpg(resized, quality: quality);
      }

      print(
          'Image compression: Original: ${bytes.length} bytes, Compressed: ${compressed.length} bytes, Quality: $quality');
      return Uint8List.fromList(compressed);
    } catch (e) {
      print('Error compressing image for upload: $e');
      return null;
    }
  }

  Future<String?> _uploadImageToServer(
      Uint8List imageBytes, String fileName, String mimeType) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['fileUrl'] ??
            jsonResponse['url'] ??
            jsonResponse['path'];
      } else {
        print('Upload failed with status: ${response.statusCode}');
        print('Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> _uploadFileToServerOld2(File file, String chatId) async {
    try {
      final fileType = _getFileType(file.path);
      final mimeType = _getMimeType(file.path);

      // Read and compress file if needed
      Uint8List fileBytes;
      if (fileType == 'image') {
        final compressedBytes = await _compressImageForUpload(file);
        fileBytes = compressedBytes ?? await file.readAsBytes();
      } else {
        fileBytes = await file.readAsBytes();
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['chatId'] = chatId
        ..fields['fileType'] = fileType
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: path.basename(file.path),
            contentType: MediaType.parse(mimeType),
          ),
        );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final fileUrl = jsonResponse['url'] ?? jsonResponse['fileUrl'];
        if (fileUrl != null) {
          print('File uploaded successfully. URL: $fileUrl');
          return fileUrl;
        } else {
          print('Upload response missing URL: ${response.body}');
          return null;
        }
      } else {
        print('File upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<Uint8List?> _compressFileForUpload(File file, String fileType) async {
    try {
      if (fileType == 'image') {
        return await _compressImageForUpload(file);
      } else if (fileType == 'video') {
        // Video compression is not available (package removed)
        // Return the original file bytes
        return await file.readAsBytes();
      } else if (fileType == 'audio') {
        // For now, we'll use the original audio file
        // TODO: Implement audio compression if needed
        return await file.readAsBytes();
      } else {
        // For documents, just read the file
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error compressing file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _prepareFileForSocket(File file) async {
    final fileName = path.basename(file.path);
    String fileType = _getFileType(file.path);
    String mimeType = _getMimeType(file.path);

    // Check file size before processing
    final fileSize = await file.length();
    const maxFileSize = 75 * 1024 * 1024; // 75MB limit to match backend

    if (fileSize > maxFileSize) {
      final sizeInMB = fileSize / (1024 * 1024);
      const maxSizeInMB = maxFileSize / (1024 * 1024);
      throw Exception(
          'File size (${sizeInMB.toStringAsFixed(1)} MB) exceeds maximum allowed size ($maxSizeInMB MB). Please choose a smaller file.');
    }

    // For video files, check if they need chunking
    if (fileType == 'video') {
      // Check if video is too large for direct socket transmission
      // Base64 encoding increases size by ~33%, so we need to account for that
      final estimatedBase64Size = fileSize * 1.33;
      const socketMessageLimit = 1024 * 1024; // 1MB socket limit

      if (estimatedBase64Size > socketMessageLimit) {
        // Upload video in chunks and return a reference
        final videoUrl = await _uploadVideoInChunks(file, mimeType);
        if (videoUrl != null) {
          // Return a special format indicating this is a chunked video
          return {
            'fieldname': 'files',
            'originalname': fileName,
            'mimetype': mimeType,
            'buffer': null, // No buffer for chunked videos
            'size': fileSize,
            'metadata': {
              'type': 'video',
              'originalPath': file.path,
              'isChunked': true,
              'videoUrl': videoUrl,
            }
          };
        } else {
          throw Exception('Failed to upload video in chunks');
        }
      } else {
        print('Video file is small enough for direct socket transmission');
      }
    }

    // Read and compress file if needed (for non-chunked files)
    Uint8List fileBytes;
    final compressedBytes = await _compressFileForUpload(file, fileType);
    File? processedFile = file;
    if (compressedBytes == null) {
      print('Failed to compress file, using original');
      fileBytes = await file.readAsBytes();
    } else {
      fileBytes = compressedBytes;
      // If video, ensure extension is .mp4 and mimetype is video/mp4
      if (fileType == 'video') {
        String ext = path.extension(file.path).toLowerCase();
        if (ext != '.mp4') {
          // Save compressedBytes as a temp .mp4 file
          final tempDir = await getTemporaryDirectory();
          final mp4Path = path.join(
              tempDir.path, '${path.basenameWithoutExtension(file.path)}.mp4');
          final mp4File = await File(mp4Path).writeAsBytes(fileBytes);
          processedFile = mp4File;
          mimeType = 'video/mp4';
          print('Converted video to mp4: $mp4Path');
          fileBytes = await mp4File.readAsBytes();
        } else {
          mimeType = 'video/mp4';
        }
      }
    }

    // Add file type specific metadata
    Map<String, dynamic> metadata = {};
    metadata['originalPath'] =
        file.path; // Store original file path for compression
    if (fileType == 'image') {
      try {
        final image = img.decodeImage(fileBytes);
        if (image != null) {
          metadata['width'] = image.width;
          metadata['height'] = image.height;
        }
      } catch (e) {
        print('Error getting image dimensions: $e');
      }
    } else if (fileType == 'video') {
      metadata['type'] = 'video';
    } else if (fileType == 'audio') {
      metadata['type'] = 'audio';
    } else {
      metadata['type'] = 'document';
    }

    print('File size: ${fileBytes.length} bytes');
    if (metadata.isNotEmpty) {
      print('File metadata: $metadata');
    }

    print(
        'Final file sent: ${path.basename(processedFile.path)}, mimetype: $mimeType, size: ${fileBytes.length}');

    // Format file data to match backend expectations
    return {
      'fieldname': 'files', // Required by backend
      'originalname': path.basename(processedFile.path),
      'mimetype': mimeType,
      'buffer': fileBytes, // Send raw bytes
      'size': fileBytes.length,
      'metadata': metadata
    };
  }

  /// Determine the appropriate message type based on content
  String _determineMessageType(
    Map<String, dynamic>? location,
    String? messageInvoiceRef,
    List<File>? files,
  ) {
    if (messageInvoiceRef != null) {
      return 'invoice';
    } else if (location != null) {
      return 'location';
    } else if (files != null && files.isNotEmpty) {
      // Check file types to determine appropriate message type
      bool hasVideos = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm']
            .contains(extension);
      });

      bool hasImages = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
      });

      bool hasAudio = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.mp3', '.wav', '.ogg', '.m4a', '.aac'].contains(extension);
      });

      bool hasDocuments = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return [
          '.pdf',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.ppt',
          '.pptx',
          '.txt',
          '.rtf'
        ].contains(extension);
      });

      // Return specific message type based on file content
      if (hasVideos) {
        return 'video';
      } else if (hasImages) {
        return 'image';
      } else if (hasAudio) {
        return 'audio';
      } else if (hasDocuments) {
        return 'document';
      } else {
        // Fallback for unknown file types
        return 'document';
      }
    } else {
      return 'text';
    }
  }

  /// Prepare the appropriate message text based on content type
  String _prepareMessageText(
      String messageText, List<File>? files, String? messageInvoiceRef) {
    if (messageText.isEmpty && files != null) {
      // Check file types to determine appropriate message text
      bool hasVideos = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm']
            .contains(extension);
      });

      bool hasImages = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
      });

      bool hasAudio = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.mp3', '.wav', '.ogg', '.m4a', '.aac'].contains(extension);
      });

      bool hasDocuments = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return [
          '.pdf',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.ppt',
          '.pptx',
          '.txt',
          '.rtf'
        ].contains(extension);
      });

      // Return appropriate message text based on file content
      if (hasVideos) {
        return '[VIDEO]';
      } else if (hasImages) {
        return '[IMAGE]';
      } else if (hasAudio) {
        return '[AUDIO]';
      } else if (hasDocuments) {
        return '[DOCUMENT]';
      } else {
        // Fallback for unknown file types
        return '[DOCUMENT]';
      }
    } else {
      return messageText;
    }
  }

  Future<ChatMessage?> sendMessage({
    required String chatId,
    required String messageText,
    required String messageCreator,
    required String messageCreatorRole,
    required String userId,
    required String messageType,
    List<File>? files,
    Map<String, dynamic>? location,
    dynamic messageInvoiceRef, // ✅ Allow both String and Map<String, dynamic>
    double? audioDuration,
    ProgressCallback? onProgress,
    String? clientMessageId,
  }) async {
    if (kDebugMode) {
      print('=== Starting sendMessage ===');
      print('Socket connected: ${socket.connected}');
      print('Socket ID: ${socket.id}');
      print('Message text: $messageText');
      print('clientMessageId: $clientMessageId');
    }

    // ✅ ADD: Ensure socket is connected and user is in the room
    await ensureSocketReadyForChat(chatId);

    onProgress?.call(0.1, 'Preparing message...');

    // Use provided clientMessageId or generate a new one
    final String actualClientMessageId = clientMessageId ??
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    final messageId = actualClientMessageId;

    // Prepare base message data
    final messageData = <String, dynamic>{
      'chat_id': chatId,
      'message_id': messageId,
      'client_message_id': actualClientMessageId,
      'messageText': _prepareMessageText(messageText, files, null),
      'messageCreator': messageCreator,
      'messageCreatorRole': messageCreatorRole,
      'user_id': userId,
      'messageDate': DateTime.now().toIso8601String(),
      'messageType': messageType, // Use the passed message type
    };

    // Handle files if present
    if (files != null && files.isNotEmpty) {
      onProgress?.call(0.2, 'Processing ${files.length} file(s)...');
      print('=== Processing files ===');
      print('Number of files: ${files.length}');

      // Check if any files are videos
      List<File> videoFiles = [];
      List<File> otherFiles = [];

      for (var file in files) {
        final extension = path.extension(file.path).toLowerCase();
        if (['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm']
            .contains(extension)) {
          videoFiles.add(file);
        } else {
          otherFiles.add(file);
        }
      }

      // Handle video files using the new upload method
      if (videoFiles.isNotEmpty) {
        print(
            'Found ${videoFiles.length} video file(s), using direct upload...');
        for (var videoFile in videoFiles) {
          try {
            onProgress?.call(
                0.3, 'Uploading video: ${path.basename(videoFile.path)}...');
            final videoUrl = await uploadVideoMessage(videoFile, chatId,
                onProgress: (progress, message) {
              onProgress?.call(0.3 + (0.4 * progress), 'Video: $message');
            });

            if (videoUrl != null) {
              print('Video uploaded successfully: $videoUrl');
              // The backend automatically creates a message with this video
              // Return early since the message is already created
              onProgress?.call(1.0, 'Video message sent successfully');
              return null; // Message already created by backend
            } else {
              print('Video upload failed for: ${videoFile.path}');
            }
          } catch (e) {
            print('Error uploading video ${videoFile.path}: $e');
            // Continue with other files or throw if this was the only file
            if (files.length == 1) {
              throw Exception('Failed to upload video: $e');
            }
          }
        }
      }

      // Handle non-video files using the traditional approach
      if (otherFiles.isNotEmpty) {
        print('Processing ${otherFiles.length} non-video file(s)...');
        List<Map<String, dynamic>> fileData = [];

        for (var i = 0; i < otherFiles.length; i++) {
          var file = otherFiles[i];
          print('Processing file: ${file.path}');
          onProgress?.call(0.2 + (0.4 * (i / otherFiles.length)),
              'Processing file ${i + 1}/${otherFiles.length}...');

          if (!await file.exists()) {
            print('File does not exist, skipping: ${file.path}');
            continue;
          }

          try {
            final fileInfo = await _prepareFileForSocket(file);
            fileData.add(fileInfo);
            print(
                'File processed: ${fileInfo['originalname']} (${fileInfo['size']} bytes)');
          } catch (e) {
            print('Error processing file ${file.path}: $e');
            // If it's a file size error, throw it to stop the entire process
            if (e.toString().contains('exceeds maximum allowed size')) {
              throw Exception('File size error: ${e.toString()}');
            }
            continue;
          }
        }

        if (fileData.isNotEmpty) {
          messageData['files'] = fileData;
          print('Total files added to message: ${fileData.length}');
        } else {
          print('No non-video files were successfully processed');
          // If we had video files that were uploaded successfully, don't throw error
          if (videoFiles.isEmpty) {
            throw Exception('Failed to process files');
          }
        }
      } else if (videoFiles.isEmpty) {
        // No files were processed at all
        throw Exception('Failed to process files');
      }
    }

    // Add optional fields
    if (location != null) {
      // Send location data in the exact format the backend expects
      messageData['messageLocation'] = location;

      // Also add alternative field names for maximum compatibility
      messageData['location'] = location;
      messageData['message_location'] = location;

      // Add individual location fields as well
      messageData['latitude'] = location['latitude'];
      messageData['longitude'] = location['longitude'];
      messageData['address'] = location['address'];

      // Also add as strings for some backends
      messageData['lat'] = location['latitude'].toString();
      messageData['lng'] = location['longitude'].toString();
      messageData['location_address'] = location['address'];

      // Add location data as JSON string for maximum compatibility
      messageData['locationJson'] = json.encode(location);
      messageData['messageLocationJson'] = json.encode(location);

      // Add a flag to indicate this is a location message
      messageData['isLocationMessage'] = true;
      messageData['hasLocation'] = true;
    }
    if (messageInvoiceRef != null) {
      // ✅ CRITICAL: Set messageType to 'invoice' for invoice messages
      messageData['messageType'] = 'invoice';

      // ✅ CRITICAL: Check if messageInvoiceRef is a Map (full invoice data) or String (just ID)
      if (messageInvoiceRef is Map<String, dynamic>) {
        // Full invoice data provided - extract ID and send complete data
        final invoiceId =
            messageInvoiceRef['_id'] ?? messageInvoiceRef['invoiceId'];
        final invoiceData = Map<String, dynamic>.from(messageInvoiceRef as Map);

        messageData['messageInvoiceRef'] = invoiceId;
        messageData['messageInvoiceRefString'] = invoiceId;
        messageData['invoiceData'] =
            invoiceData; // ✅ CRITICAL: Send full invoice data

        if (kDebugMode) {
          print('🧾 Full invoice data provided:');
          print('  - invoiceId: $invoiceId');
          print('  - invoiceData keys: ${invoiceData.keys.toList()}');
          print('  - invoice_amount: ${invoiceData['invoice_amount']}');
          print('  - invoice_status: ${invoiceData['invoice_status']}');
        }
      } else {
        // Just invoice ID provided - send as before
        messageData['messageInvoiceRef'] = messageInvoiceRef;
        messageData['messageInvoiceRefString'] = messageInvoiceRef;

        if (kDebugMode) {
          print('🧾 Invoice ID only provided: $messageInvoiceRef');
        }
      }

      // Also try alternative field names that the backend might expect
      // ✅ FIXED: Only assign string IDs to these fields, not the full map
      if (messageInvoiceRef is Map<String, dynamic>) {
        final invoiceId =
            messageInvoiceRef['_id'] ?? messageInvoiceRef['invoiceId'];
        messageData['invoiceRef'] = invoiceId;
        messageData['invoiceId'] = invoiceId;
        messageData['invoiceId'] = invoiceId;
      } else {
        messageData['invoiceRef'] =
            messageInvoiceRef is String ? messageInvoiceRef : null;
        messageData['invoiceId'] =
            messageInvoiceRef is String ? messageInvoiceRef : null;
        messageData['invoiceId'] =
            messageInvoiceRef is String ? messageInvoiceRef : null;
      }

      // Try ObjectId format if the backend expects it
      // ✅ FIXED: Only assign string IDs to ObjectId format, not the full map
      if (messageInvoiceRef is Map<String, dynamic>) {
        final invoiceId =
            messageInvoiceRef['_id'] ?? messageInvoiceRef['invoiceId'];
        messageData['messageInvoiceRefObjectId'] = {'\$oid': invoiceId};
        messageData['invoiceRefObjectId'] = {'\$oid': invoiceId};
      } else {
        messageData['messageInvoiceRefObjectId'] =
            messageInvoiceRef is String ? {'\$oid': messageInvoiceRef} : null;
        messageData['invoiceRefObjectId'] =
            messageInvoiceRef is String ? {'\$oid': messageInvoiceRef} : null;
      }

      // ✅ ADDED: Add invoice-specific flags
      messageData['isInvoiceMessage'] = true;
      messageData['hasInvoice'] = true;

      if (kDebugMode) {
        print('🧾 Invoice message data prepared:');
        print('  - messageType: ${messageData['messageType']}');
        print('  - messageInvoiceRef: ${messageData['messageInvoiceRef']}');
        print('  - hasInvoiceData: ${messageData.containsKey('invoiceData')}');
        print('  - isInvoiceMessage: ${messageData['isInvoiceMessage']}');
      }
    }
    if (audioDuration != null) {
      messageData['audioDuration'] = audioDuration;
    }

    onProgress?.call(0.7, 'Sending message...');

    // Debug logging for socket emit

    // Create a completer for tracking message status
    final messageCompleter = Completer<bool>();
    bool messageReceived = false;

    // Add temporary listener for this specific message
    void messageListener(dynamic data) {
      print('Received new_message event: $data');
      if (data is List && data.isNotEmpty && data[0] is Map) {
        final message = data[0];
        print(
            'Checking client_message_id: ${message['client_message_id']} vs $actualClientMessageId');
        if (message != null &&
            message['client_message_id'] == actualClientMessageId) {
          messageReceived = true;
          if (!messageCompleter.isCompleted) {
            messageCompleter.complete(true);
          }
          onProgress?.call(1.0, 'Message sent successfully');
        }
      }
    }

    // Add the temporary listener
    socket.on('new_message', messageListener);

    final success = await _sendMessageWithRetry(messageData);
    if (!success) {
      onProgress?.call(0.0, 'Failed to send message');
      socket.off('new_message', messageListener);
      throw Exception('Failed to send message');
    }

    onProgress?.call(0.9, 'Waiting for server confirmation...');

    // Wait for message confirmation with timeout
    try {
      await messageCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          if (!messageCompleter.isCompleted) {
            messageCompleter.complete(false);
          }
          return false;
        },
      );
    } finally {
      socket.off('new_message', messageListener);
    }

    if (!messageReceived) {
      onProgress?.call(0.95, 'Message sent, waiting for confirmation...');
      print(
          'DEBUG: Message not confirmed by server, but socket event will handle real message');
      // Don't throw exception, just return null
      // The socket event will handle the real message arrival

      // Add a fallback to ensure progress reaches 100% after a short delay
      Timer(const Duration(seconds: 2), () {
        onProgress?.call(1.0, 'Message sent successfully');
      });

      return null;
    }

    // Create and return message object with proper video handling
    final videoFiles = files
        ?.where((f) =>
            path.extension(f.path).toLowerCase() == '.mp4' ||
            path.extension(f.path).toLowerCase() == '.mov')
        .map((f) => f.path)
        .toList();

    // For video messages, ensure we have the proper structure
    String? finalMessageText = messageText;
    String? finalMessageVideo =
        videoFiles?.isNotEmpty == true ? videoFiles!.first : null;

    // If this is a video message, ensure proper format
    if (messageText == '[VIDEO]' && finalMessageVideo != null) {
      finalMessageText = '[VIDEO]';
      // The video URL will be updated when the server response comes back
    }

    return ChatMessage(
      id: messageId,
      messageText: finalMessageText,
      messageDate: DateTime.now(),
      messageCreator: MessageCreator(
        id: messageCreator,
        role: messageCreatorRole,
      ),
      messageCreatorRole: messageCreatorRole,
      isRead: false,
      isDeleted: false,
      messagePhotos: files
          ?.where((f) =>
              path.extension(f.path).toLowerCase() == '.jpg' ||
              path.extension(f.path).toLowerCase() == '.jpeg' ||
              path.extension(f.path).toLowerCase() == '.png')
          .map((f) => f.path)
          .toList(),
      messageVideos: videoFiles,
      messageVideo: finalMessageVideo,
      messageDocument: files
          ?.where((f) =>
              path.extension(f.path).toLowerCase() == '.pdf' ||
              path.extension(f.path).toLowerCase() == '.doc' ||
              path.extension(f.path).toLowerCase() == '.docx')
          .map((f) => f.path)
          .firstOrNull,
      location: location,
      messageInvoice: messageInvoiceRef,
      messageAudio: files
          ?.where((f) =>
              path.extension(f.path).toLowerCase() == '.mp3' ||
              path.extension(f.path).toLowerCase() == '.wav')
          .map((f) => f.path)
          .firstOrNull,
    );
  }

  String _getFileType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return 'image';
    } else if (['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm']
        .contains(extension)) {
      return 'video';
    } else if (['.mp3', '.wav', '.ogg', '.m4a', '.aac'].contains(extension)) {
      return 'audio';
    } else if ([
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.rtf'
    ].contains(extension)) {
      return 'document';
    } else {
      return 'document'; // Default to document for unknown types
    }
  }

  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      // Images
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';

      // Videos
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.webm':
        return 'video/webm';

      // Audio
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';

      // Documents
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';

      default:
        return 'application/octet-stream';
    }
  }

  Future<Uint8List?> _createImagePreview(File file) async {
    try {
      // TODO: Implement image preview creation
      // For now, return null to skip preview
      return null;
    } catch (e) {
      print('Error creating image preview: $e');
      return null;
    }
  }

  final List<void Function(Map<String, dynamic>)> _onNewMessageListeners = [];
  void addOnNewMessageListener(void Function(Map<String, dynamic>) listener) {
    _onNewMessageListeners.add(listener);
  }

  void removeOnNewMessageListener(
      void Function(Map<String, dynamic>) listener) {
    _onNewMessageListeners.remove(listener);
  }

  void onMessageError(Function(Map<String, dynamic>) callback) {
    _onMessageErrorCallback = callback;
    socket.on('message_error', (data) {
      if (kDebugMode) {
        print('Received message_error event: $data');
      }
      try {
        // Handle case where data is a List with the actual data at index 0
        final actualData = data is List ? data[0] : data;
        if (actualData is Map<String, dynamic>) {
          // Check for ACCESS_DENIED error
          if (actualData['code'] == 'ACCESS_DENIED' ||
              actualData['error']?.toString().contains('Access denied') ==
                  true) {
            print(
                '=== ACCESS_DENIED detected in message_error - Reinitializing socket ===');
            print('Error data: $actualData');

            // Prevent multiple simultaneous ACCESS_DENIED handling
            if (!_isHandlingAccessDenied) {
              _isHandlingAccessDenied = true;
              _handleAccessDenied();
              // Reset flag after a delay
              Future.delayed(const Duration(seconds: 5), () {
                _isHandlingAccessDenied = false;
              });
            } else {
              print('=== ACCESS_DENIED already being handled, skipping ===');
            }
          }
          _onMessageErrorCallback?.call(actualData);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing message_error event: $e');
        }
      }
    });
  }

  void onMessagesRead(Function(Map<String, dynamic>) callback) {
    _onMessagesReadCallback = callback;

    socket.on('messages_read', (data) {
      if (kDebugMode) {
        print('=== Received Messages Read Event ===');
        print('Raw data: $data');
        print('Data type: ${data.runtimeType}');
        print(
            '=== IMPORTANT: This event should be received by ALL chat participants ===');
        print(
            '=== Including the sender to show read receipts in real-time ===');
      }

      try {
        // Handle case where data is a List with the actual data at index 0
        final actualData = data is List ? data[0] : data;
        if (kDebugMode) {
          print('Actual data: $actualData');
          print('Actual data type: ${actualData.runtimeType}');
        }

        if (actualData is Map<String, dynamic>) {
          // Create unique event ID for deduplication
          final chatId = actualData['chatId']?.toString() ??
              actualData['chat_id']?.toString() ??
              'unknown';
          final messageIds =
              (actualData['messageIds'] as List?)?.cast<String>() ?? [];
          final userId = actualData['userId']?.toString() ??
              actualData['user_id']?.toString() ??
              'unknown';
          final readAt = actualData['readAt']?.toString() ?? 'unknown';

          final eventId =
              'read_${chatId}_${messageIds.join('_')}_${userId}_$readAt';

          // Check if this exact event was already processed
          if (_processedEventIds.contains(eventId)) {
            if (kDebugMode) {
              print(
                  'ChatService: Duplicate messages_read event ignored: $eventId');
            }
            return;
          }

          // Check if this is a recent duplicate (within 2 seconds)
          final now = DateTime.now();
          final lastTimestamp = _lastEventTimestamps[eventId];
          if (lastTimestamp != null &&
              now.difference(lastTimestamp).inSeconds < 2) {
            if (kDebugMode) {
              print(
                  'ChatService: Recent duplicate messages_read event ignored: $eventId');
            }
            return;
          }

          // Mark as processed
          _processedEventIds.add(eventId);
          _lastEventTimestamps[eventId] = now;

          // Clean up old event IDs to prevent memory leaks
          if (_processedEventIds.length > 100) {
            _processedEventIds.clear();
            _lastEventTimestamps.clear();
          }

          if (kDebugMode) {
            print('Calling messages_read callback with: $actualData');
            print('Event ID: $eventId');
          }
          _onMessagesReadCallback?.call(actualData);
        } else {
          if (kDebugMode) {
            print('Actual data is not a Map<String, dynamic>');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing messages_read event: $e');
          print('Data structure: $data');
        }
      }
    });
  }

  void markMessagesAsRead(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print('=== Marking Messages As Read ===');
      print('Chat ID: $chatId');
      print('Message IDs: $messageIds');
      print('Socket connected: ${socket.connected}');
      print('Socket ID: ${socket.id}');
    }

    // Use the correct field names that the backend expects
    final data = <String, dynamic>{
      'chatId': chatId,
      'messageIds': messageIds,
    };

    // Track if acknowledgment was received
    bool ackReceived = false;
    
    // Set timeout to detect if backend doesn't respond
    Timer(const Duration(seconds: 5), () {
      if (!ackReceived && kDebugMode) {
        print('❌❌❌ CRITICAL ERROR: Backend did not acknowledge mark_messages_read after 5 seconds!');
        print('❌ This means the backend is NOT processing the request!');
        print('❌ Chat ID: $chatId');
        print('❌ Message IDs count: ${messageIds.length}');
        print('❌ ACTION REQUIRED: Check backend logs for errors!');
        print('❌ Backend socket event handler may be missing or encountering errors!');
      }
    });

    socket.emitWithAck('mark_messages_read', data, ack: (response) {
      ackReceived = true;
      if (kDebugMode) {
        print('✅✅✅ Mark Messages Read Acknowledgment RECEIVED! ===');
        print('Response: $response');
        print('Response type: ${response.runtimeType}');
        print('=== Backend successfully processed the request ===');
        print('Server should now broadcast messages_read to all participants');
        print('Sender should receive this event and update message status');
      }
    });
  }

  void markMessagesAsDelivered(String chatId, List<String> messageIds) {
    // Use the correct field names that the backend expects
    final data = <String, dynamic>{
      'chatId': chatId,
      'messageIds': messageIds,
    };

    if (kDebugMode) {
      print('Emitting mark_messages_delivered with data: $data');
    }

    socket.emitWithAck('mark_messages_delivered', data, ack: (response) {
      if (kDebugMode) {
        print('=== Mark Messages Delivered Acknowledgment ===');
        print('Response: $response');
        print('Response type: ${response.runtimeType}');
      }
    });
  }

  void confirmMessageReceived(String messageId, String chatId) {
    if (kDebugMode) {
      print(
          'Confirming message received: messageId=$messageId, chatId=$chatId');
    }
    socket.emit('message_received', {
      'messageId': messageId,
      'chatId': chatId,
    });
  }

  // New methods for online/offline status, typing, and message read status

  // Callback setters for new events
  void onUserStatusChange(UserStatusCallback callback) {
    _onUserStatusChangeCallback = callback;
  }

  void onUserStartedTyping(TypingStatusCallback callback) {
    _onUserStartedTypingCallback = callback;
  }

  void onUserStoppedTyping(TypingStatusCallback callback) {
    _onUserStoppedTypingCallback = callback;
  }

  void onMessageSeenUpdate(MessageReadCallback callback) {
    _onMessageSeenUpdateCallback = callback;
  }

  void onMessageReceived(MessageReadCallback callback) {
    _onMessageReceivedCallback = callback;
  }

  void onMessagesDelivered(MessageReadCallback callback) {
    _onMessagesDeliveredCallback = callback;
  }

  void onMessageSent(MessageReadCallback callback) {
    if (kDebugMode) {
      print('ChatService: onMessageSent callback registered');
      print('ChatService: Socket connected: $_isConnected');
      print('ChatService: Socket initialized: ${socket.connected}');
    }
    _onMessageSentCallback = callback;
  }

  void onMessagesUpdated(MessageReadCallback callback) {
    _onMessagesUpdatedCallback = callback;
  }

  void onForceLogout(ForceLogoutCallback callback) {
    _onForceLogoutCallback = callback;
  }

  void onInvoiceUpdated(Function(Map<String, dynamic>) callback) {
    _onInvoiceUpdatedCallback = callback;
    socket.on('invoice_updated', (data) {
      if (kDebugMode) {
        print('=== Received invoice_updated Event ===');
        print('Data: $data');
      }
      try {
        // Handle case where data is a List with the actual data at index 0
        final actualData = data is List ? data[0] : data;
        if (actualData is Map<String, dynamic>) {
          _onInvoiceUpdatedCallback?.call(actualData);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing invoice_updated event: $e');
        }
      }
    });
  }

  // Socket emit methods for client actions
  void startTyping(String chatId) {
    if (kDebugMode) {
      print('Emitting start_typing: chatId=$chatId');
    }
    socket.emit('start_typing', {'chatId': chatId});
  }

  void stopTyping(String chatId) {
    if (kDebugMode) {
      print('Emitting stop_typing: chatId=$chatId');
    }
    socket.emit('stop_typing', {'chatId': chatId});
  }

  void markMessageAsSeen(String messageId, String chatId) {
    if (kDebugMode) {
      print('Emitting message_seen: messageId=$messageId, chatId=$chatId');
    }
    socket.emit('message_seen', {
      'messageId': messageId,
      'chatId': chatId,
    });
  }

  void updateUserStatus({required bool isOnline, DateTime? lastSeen}) {
    if (kDebugMode) {
      print(
          'Emitting user_status_update: isOnline=$isOnline, lastSeen=$lastSeen');
    }
    socket.emit('user_status_update', {
      'isOnline': isOnline,
      'lastSeen':
          lastSeen?.toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }

  /// @deprecated Use UserStatusProvider.requestUserStatus() instead for consistency
  void requestUserStatus(String userId) {
    if (kDebugMode) {
      print(
          'DEPRECATED: ChatService.requestUserStatus() called. Use UserStatusProvider instead.');
      print('Requesting user status for: $userId');
    }
    socket.emit('request_user_status', {
      'userId': userId,
    });
  }

  void disconnect() {
    _cleanupTemporaryListeners();
    if (kDebugMode) {
      print('Disconnecting socket...');
    }

    // Check if socket is already disconnected
    if (!_isConnected && !socket.connected) {
      if (kDebugMode) {
        print('Socket already disconnected, skipping disconnect');
      }
      return;
    }

    try {
      socket.disconnect();
      socket.dispose();
      _isConnected = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting socket: $e');
      }
    }
  }

  /// Handle ACCESS_DENIED error by reinitializing socket and rejoining chat rooms
  void _handleAccessDenied() {
    // Always log in production for debugging
    print('=== Handling ACCESS_DENIED - Reinitializing socket ===');
    print('Current joined rooms: $_joinedChatRooms');
    print('Socket connected: ${socket.connected}');
    print('Is connected: $_isConnected');

    // Store current joined rooms before disconnecting
    final currentJoinedRooms = Set<String>.from(_joinedChatRooms);

    // Disconnect current socket
    disconnect();

    // Clear connection state
    _isConnected = false;
    _isInitializing = false;
    _connectionAttempts = 0;

    // Wait a moment before reinitializing
    Future.delayed(const Duration(milliseconds: 1000), () {
      print('=== Reinitializing socket after ACCESS_DENIED ===');
      print('Base URL: $baseUrl');
      print('Token available: ${token.isNotEmpty}');

      // Reinitialize socket
      initializeSocket();

      // Wait for socket to be ready, then rejoin all chat rooms
      Future.delayed(const Duration(milliseconds: 2000), () {
        print('=== Rejoining chat rooms after socket reinitialization ===');
        print('Rooms to rejoin: $currentJoinedRooms');
        print('Socket connected after reinit: ${socket.connected}');

        // Rejoin all previously joined chat rooms
        for (final chatId in currentJoinedRooms) {
          print('Rejoining room: $chatId');
          joinChatRoom(chatId);

          // Wait a bit before trying to add user to participants
          Future.delayed(const Duration(milliseconds: 500), () {
            _addUserToParticipants(chatId);
          });
        }

        print('=== ACCESS_DENIED recovery completed ===');
        print('Final joined rooms: $_joinedChatRooms');
      });
    });
  }

  /// Add user to chat participants array to fix ACCESS_DENIED for new users
  void _addUserToParticipants(String chatId) {
    print('=== Attempting to add user to participants for chat: $chatId ===');

    if (!socket.connected) {
      print('=== Socket not connected, cannot emit user_online ===');
      return;
    }

    // For new chats created after approval, we need to refresh the user's chat list
    // by emitting user_online without chatId to trigger joinAllUserChats on backend
    print('=== Emitting user_online without chatId to refresh all chats ===');
    socket.emit('user_online', {});

    // Wait longer for backend to process and join all chats
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (socket.connected) {
        // Now emit with specific chatId to ensure we're in this specific room
        socket.emit('user_online', {
          'chatId': chatId,
        });
        print('=== Second user_online emission for specific chat: $chatId ===');

        // Wait a bit more and emit again to ensure backend has fully processed
        Future.delayed(const Duration(milliseconds: 500), () {
          if (socket.connected) {
            socket.emit('user_online', {
              'chatId': chatId,
            });
            print(
                '=== Third user_online emission for specific chat: $chatId ===');
          }
        });
      }
    });

    print('=== Emitted user_online events to refresh chat access ===');
  }

  Future<Map<String, dynamic>> getMessages({
    required String chatId,
    required int page,
    required int pageSize,
  }) async {
    try {
      // Check if socket is connected - if not, return error
      if (!socket.connected) {
        print('Socket not connected - manual reconnection required');
        return {
          'status': false,
          'error': 'Socket not connected - please reconnect manually',
          'data': {
            'messages': [],
            'totalCount': 0,
            'hasMore': false,
          }
        };
      }

      final completer = Completer<Map<String, dynamic>>();

      print('Emitting get_messages event...');
      socket.emitWithAck('get_messages', {
        'chat_id': chatId,
        'page': page,
        'pageSize': pageSize,
      }, ack: (data) {
        if (kDebugMode) {
          print('Received get_messages acknowledgment: $data');
        }

        if (data == null) {
          print('Received null acknowledgment');
          completer.complete({
            'status': false,
            'error': 'No response from server',
            'data': {
              'messages': [],
              'totalCount': 0,
              'hasMore': false,
            }
          });
          return;
        }

        if (data is Map && data.containsKey('error')) {
          print('Error getting messages: ${data['error']}');
          completer.complete({
            'status': false,
            'error': data['error'],
            'data': {
              'messages': [],
              'totalCount': 0,
              'hasMore': false,
            }
          });
          return;
        }

        try {
          completer.complete(data as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing messages response: $e');
          completer.complete({
            'status': false,
            'error': 'Failed to parse response',
            'data': {
              'messages': [],
              'totalCount': 0,
              'hasMore': false,
            }
          });
        }
      });

      // Set a timeout
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          print('Timeout getting messages after 30 seconds');
          completer.complete({
            'status': false,
            'error': 'Request timed out',
            'data': {
              'messages': [],
              'totalCount': 0,
              'hasMore': false,
            }
          });
        }
      });

      final result = await completer.future;
      print('getMessages result: $result');
      return result;
    } catch (e) {
      print('Error in getMessages: $e');
      return {
        'status': false,
        'error': e.toString(),
        'data': {
          'messages': [],
          'totalCount': 0,
          'hasMore': false,
        }
      };
    }
  }

  // Add a temporary listener that will be removed after use
  void addTemporaryListener(Function(dynamic) listener) {
    _temporaryListeners.add(listener);
    socket.on('new_message', listener);
  }

  /// Join a specific chat room for real-time updates
  void joinChatRoom(String chatId) {
    if (!socket.connected) {
      if (kDebugMode) {
        print('Socket not connected, cannot join room');
      }
      return;
    }

    // ✅ ADD: Wait for socket to be fully ready
    Future.delayed(const Duration(milliseconds: 100), () {
      // Emit user_online event to join the chat room
      socket.emit('user_online', {'chatId': chatId});
      _joinedChatRooms.add(chatId);

      if (kDebugMode) {
        print('Emitted user_online event for chat: $chatId');
        print('Joined rooms: $_joinedChatRooms');
      }

      // Also try to add user to participants for new users (after a small delay)
      // This helps with new chats created after approval
      Future.delayed(const Duration(milliseconds: 300), () {
        _addUserToParticipants(chatId);
      });
    });
  }

  /// Ensure user has joined the chat room before sending messages
  /// This is critical for new chats created after approval
  Future<bool> ensureJoinedChatRoom(String chatId) async {
    print('=== Ensuring user is in chat room: $chatId ===');

    if (!socket.connected) {
      print('=== Socket not connected, cannot ensure room join ===');
      return false;
    }

    // If already joined, verify with a fresh user_online event
    if (_joinedChatRooms.contains(chatId)) {
      print('=== Already in room, emitting fresh user_online ===');
      socket.emit('user_online', {'chatId': chatId});
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    }

    // Not joined yet - join now
    print('=== Not in room yet, joining now ===');
    joinChatRoom(chatId);

    // Wait for join to complete
    await Future.delayed(const Duration(milliseconds: 500));

    return _joinedChatRooms.contains(chatId);
  }

  /// Leave a specific chat room
  void leaveChatRoom(String chatId) {
    if (kDebugMode) {
      print('=== Leaving Chat Room ===');
      print('Chat ID: $chatId');
    }

    if (!socket.connected) {
      if (kDebugMode) {
        print('Socket not connected, cannot leave room');
      }
      return;
    }

    // Emit user_offline event to leave the chat room
    socket.emit('user_offline', {'chatId': chatId});
    _joinedChatRooms.remove(chatId);

    if (kDebugMode) {
      print('Emitted user_offline event for chat: $chatId');
      print('Remaining rooms: $_joinedChatRooms');
    }
  }

  /// Join all user's chats automatically
  void _joinAllUserChats() {
    if (kDebugMode) {
      print('=== Joining All User Chats ===');
      print('Socket connected: ${socket.connected}');
    }

    if (!socket.connected) {
      if (kDebugMode) {
        print('Socket not connected, cannot join chats');
      }
      return;
    }

    // Emit user_online event without specific chatId to join all user's chats
    socket.emit('user_online', {});

    if (kDebugMode) {
      print('Emitted user_online event to join all chats');
    }
  }

  // Remove a temporary listener
  void removeTemporaryListener(Function(dynamic) listener) {
    _temporaryListeners.remove(listener);
    socket.off('new_message', listener);
  }

  // Clean up all temporary listeners
  void _cleanupTemporaryListeners() {
    for (var listener in _temporaryListeners) {
      socket.off('new_message', listener);
    }
    _temporaryListeners.clear();
  }

  // ✅ ADD: Fast method for chat navigation (minimal delays)
  Future<void> ensureSocketReadyForChatNavigation(String chatId) async {
    if (kDebugMode) {
      print('=== Fast socket readiness check for chat navigation: $chatId ===');
    }

    // 1. Ensure socket is connected
    if (!socket.connected) {
      if (kDebugMode) {
        print('Socket not connected, attempting to connect...');
      }
      socket.connect();

      // Wait for connection with timeout
      int attempts = 0;
      while (!socket.connected && attempts < 5) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }

      if (!socket.connected) {
        if (kDebugMode) {
          print('Socket connection failed, proceeding anyway...');
        }
        return;
      }
    }

    // 2. Quick check if already in room
    if (_joinedChatRooms.contains(chatId)) {
      if (kDebugMode) {
        print('Already in chat room, navigation ready');
      }
      return;
    }

    // 3. Quick join attempt
    if (kDebugMode) {
      print('Quick join attempt for chat: $chatId');
    }
    joinChatRoom(chatId);

    // Minimal wait for join
    await Future.delayed(const Duration(milliseconds: 300));

    if (kDebugMode) {
      print('Fast socket readiness check completed for: $chatId');
    }
  }

  // ✅ ADD: New method to ensure socket is ready for chat (for message sending)
  Future<void> ensureSocketReadyForChat(String chatId) async {
    if (kDebugMode) {
      print('=== Ensuring socket is ready for chat: $chatId ===');
    }

    // 1. Ensure socket is connected
    if (!socket.connected) {
      if (kDebugMode) {
        print('Socket not connected, attempting to connect...');
      }
      socket.connect();

      // Wait for connection with timeout
      int attempts = 0;
      while (!socket.connected && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!socket.connected) {
        throw Exception('Failed to connect socket');
      }

      if (kDebugMode) {
        print('Socket connected successfully');
      }
    }

    // 2. For new chats, first refresh all user chats by emitting user_online without chatId
    // This ensures the backend joins the user to all their chats, including newly created ones
    if (kDebugMode) {
      print('Emitting user_online to refresh all chats for new chat access...');
    }
    socket.emit('user_online', {});

    // Wait longer for backend to process joinAllUserChats and ensureSocketInRoom
    await Future.delayed(const Duration(milliseconds: 1500));

    // 3. Ensure user is in the specific chat room
    if (!_joinedChatRooms.contains(chatId)) {
      if (kDebugMode) {
        print('User not in chat room, joining...');
      }
      joinChatRoom(chatId);

      // Wait longer for room join to complete on backend
      await Future.delayed(const Duration(milliseconds: 1500));
    } else {
      // Even if we think we're in the room, emit a fresh user_online event for this specific chat
      if (kDebugMode) {
        print(
            'Already in room, but emitting fresh user_online for specific chat...');
      }
      socket.emit('user_online', {'chatId': chatId});
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 4. Double-check room membership and retry if needed
    if (!_joinedChatRooms.contains(chatId)) {
      if (kDebugMode) {
        print('Failed to join chat room, retrying...');
      }
      joinChatRoom(chatId);
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // 5. Final verification - emit user_online one more time to ensure backend has processed everything
    if (kDebugMode) {
      print('Final user_online emission to ensure backend processing...');
    }
    socket.emit('user_online', {'chatId': chatId});
    await Future.delayed(const Duration(milliseconds: 500));

    if (kDebugMode) {
      print('Socket is ready for chat: $chatId');
      print('Joined rooms: $_joinedChatRooms');
    }
  }

  // ✅ ADD: Method to wait for socket to be ready
  Future<void> waitForSocketReady() async {
    try {
      // If service was suspended (e.g., user just logged out), attempt to
      // resume automatically if we have a valid token. This makes login
      // flows more robust when parts of the app call waitForSocketReady
      // after authentication completes.
      if (_suspended) {
        if (token.isNotEmpty) {
          if (kDebugMode)
            print(
                'ChatService: Service suspended, resuming automatically because token available');
          resume();
        } else {
          if (kDebugMode)
            print(
                'ChatService: Service suspended and no token available - cannot initialize');
          throw Exception('Service suspended');
        }
      }

      // Initialize socket if not already done
      if (!_isConnected) {
        initializeSocket();
      }

      if (socket.connected) return;

      if (kDebugMode) {
        print('Waiting for socket connection...');
      }
      int attempts = 0;
      while (!socket.connected && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 250));
        attempts++;
      }

      if (!socket.connected) {
        throw Exception('Socket connection timeout');
      }

      if (kDebugMode) {
        print('Socket is ready');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatService socket not ready yet: $e');
      }
      // Only attempt to initialize again if we're not suspended
      if (!_suspended) {
        try {
          initializeSocket();
        } catch (_) {}
      }
      throw Exception('Socket initialization failed: $e');
    }
  }

  /// Gracefully notify backend that this user is going offline, remove
  /// listeners and disconnect the socket. This should be called during
  /// user-initiated logout or app-wide cleanup.
  Future<void> shutdown({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      if (kDebugMode) {
        print('ChatService: Shutdown started - sending user_offline');
      }

      // Try to inform backend that user is going offline. Prefer ACK when possible.
      if (socket.connected) {
        final completer = Completer<void>();
        Timer? timer;

        try {
          socket.emitWithAck('user_offline', {}, ack: (data) {
            if (!completer.isCompleted) completer.complete();
          });
        } catch (e) {
          if (kDebugMode) print('Error emitting user_offline ack: $e');
          // If emitWithAck is not available or fails, try a plain emit
          try {
            socket.emit('user_offline', {});
          } catch (_) {
            // ignore
          }
          if (!completer.isCompleted) completer.complete();
        }

        timer = Timer(timeout, () {
          if (!completer.isCompleted) completer.complete();
        });

        await completer.future;
        timer.cancel();
      }

      // Remove temporary listeners and any registered handlers
      _cleanupTemporaryListeners();

      try {
        // Try to remove commonly used listeners to avoid memory leaks
        socket.off('new_message');
        socket.off('message_sent');
        socket.off('messages_updated');
        socket.off('user_status_change');
        socket.off('user_status_response');
        socket.off('user_started_typing');
        socket.off('user_stopped_typing');
        socket.off('message_seen_update');
        socket.off('message_received');
        socket.off('messages_delivered');
        socket.off('message_delivered');
        socket.off('message_seen');
        socket.off('message_read');
        socket.off('force_logout');
        socket.off('invoice_updated');
      } catch (e) {
        if (kDebugMode) {
          print('ChatService: Error clearing listeners during shutdown: $e');
        }
      }

      // Clear joined room tracking
      _joinedChatRooms.clear();

      // Finally disconnect and dispose socket
      // Disconnect but keep service suspended to avoid accidental re-init
      disconnect();
      _suspended = true;

      if (kDebugMode) {
        print('ChatService: Shutdown completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatService: Shutdown error: $e');
      }
      try {
        disconnect();
      } catch (_) {}
    }
  }

  /// Permanently suspend automatic reinitialization after logout.
  /// Call `resume()` only when you want the service to allow reconnection again.
  void suspend() {
    _suspended = true;
    if (kDebugMode) print('ChatService: Service suspended');
  }

  /// Resume socket initialization after a previous suspend().
  void resume() {
    _suspended = false;
    if (kDebugMode) print('ChatService: Service resumed');
  }
}
