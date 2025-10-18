import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/core/constant.dart';

/// Callback types for socket events
typedef SocketMessageCallback = void Function(Map<String, dynamic> data);
typedef SocketConnectionCallback = void Function(bool isConnected);
typedef SocketErrorCallback = void Function(String error);

/// Clean and focused chat socket service
class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  // Socket instance
  IO.Socket? _socket;

  // Configuration
  String? _baseUrl;
  String? _token;

  // Connection state
  bool _isConnected = false;
  bool _isInitializing = false;
  bool _isDisposed = false;

  // Reconnection settings
  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  // Event callbacks
  final Map<String, List<SocketMessageCallback>> _eventCallbacks = {};
  SocketConnectionCallback? _onConnectionChanged;
  SocketErrorCallback? _onError;

  // Getters
  bool get isConnected => _isConnected && _socket?.connected == true;
  IO.Socket? get socket => _socket;

  /// Initialize socket with configuration
  Future<void> initialize({
    required String baseUrl,
    required String token,
    SocketConnectionCallback? onConnectionChanged,
    SocketErrorCallback? onError,
  }) async {
    if (_isInitializing || _isDisposed) return;

    _baseUrl = baseUrl;
    _token = token;
    _onConnectionChanged = onConnectionChanged;
    _onError = onError;

    await _initializeSocket();
  }

  /// Initialize socket connection
  Future<void> _initializeSocket() async {
    if (_isInitializing || _isDisposed) return;

    _isInitializing = true;

    try {
      // FIX: Use the same URL construction logic as ChatService to prevent port 0 issue
      final uri = Uri.parse(Constants.socketBaseUrl);

      // FIX: Use proper WebSocket protocol and exclude default ports
      // Uri.parse() returns default ports: 443 for HTTPS, 80 for HTTP
      // We only include non-default ports explicitly set in the URL
      String socketUrl;
      if (uri.scheme == 'https') {
        // For HTTPS, use WSS protocol (WebSocket Secure)
        // Only include port if it's NOT the default HTTPS port (443)
        socketUrl = (uri.hasPort && uri.port != 443)
            ? 'wss://${uri.host}:${uri.port}'
            : 'wss://${uri.host}';
      } else if (uri.scheme == 'http') {
        // For HTTP, use WS protocol
        // Only include port if it's NOT the default HTTP port (80)
        socketUrl = (uri.hasPort && uri.port != 80)
            ? 'ws://${uri.host}:${uri.port}'
            : 'ws://${uri.host}';
      } else {
        // Fallback: assume HTTPS and use WSS
        socketUrl = (uri.hasPort && uri.port != 443)
            ? 'wss://${uri.host}:${uri.port}'
            : 'wss://${uri.host}';
      }

      // Debug: Log the exact socket URL being used
      if (kDebugMode) {
        print('=== ChatSocketService Socket URL Debug ===');
        print('Constants.socketBaseUrl: ${Constants.socketBaseUrl}');
        print('Parsed URI: $uri');
        print('URI scheme: ${uri.scheme}');
        print('URI host: ${uri.host}');
        print('URI port: ${uri.port}');
        print('Final socket URL: $socketUrl');
        print('Expected: ws://localhost:4000');
        print('Is correct: ${socketUrl == 'ws://localhost:4000'}');
        print('=========================================');
      }

      if (kDebugMode) {
        print('ChatSocketService: Initializing socket at $socketUrl');
      }

      // Create socket with configuration
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $_token'})
            .setQuery({'token': _token})
            .enableForceNew()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(_reconnectDelay.inMilliseconds)
            .setReconnectionDelayMax(10000)
            .setTimeout(30000)
            .disableAutoConnect()
            .build(),
      );

      // Set up event listeners
      _setupEventListeners();

      // Connect to socket
      _socket!.connect();
    } catch (e) {
      _isInitializing = false;
      _onError?.call('Failed to initialize socket: $e');
      if (kDebugMode) {
        print('ChatSocketService: Socket initialization failed: $e');
      }
    }
  }

  /// Set up socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) => _handleConnect());
    _socket!.onDisconnect((reason) => _handleDisconnect(reason));
    _socket!.onConnectError((error) => _handleConnectError(error));
    _socket!.onError((error) => _handleError(error));
    _socket!.onReconnect((_) => _handleReconnect());
    _socket!.onReconnectAttempt((attempt) => _handleReconnectAttempt(attempt));
    _socket!.onReconnectError((error) => _handleReconnectError(error));

    // Chat events
    _socket!.on('new_message', (data) => _handleEvent('new_message', data));
    _socket!.on('message_seen_update',
        (data) => _handleEvent('message_seen_update', data));
    _socket!.on(
        'message_received', (data) => _handleEvent('message_received', data));
    _socket!.on('messages_delivered',
        (data) => _handleEvent('messages_delivered', data));
    _socket!.on('messages_read', (data) => _handleEvent('messages_read', data));
    _socket!.on('user_status_change',
        (data) => _handleEvent('user_status_change', data));
    _socket!.on('user_started_typing',
        (data) => _handleEvent('user_started_typing', data));
    _socket!.on('user_stopped_typing',
        (data) => _handleEvent('user_stopped_typing', data));
    _socket!
        .on('invoice_updated', (data) => _handleEvent('invoice_updated', data));
    _socket!.on('force_logout', (data) => _handleEvent('force_logout', data));

    // Handle reconnection failure from backend
    _socket!.on('reconnection_failed', (data) {
      if (kDebugMode) {
        print(
            'ChatSocketService: Backend rejected reconnection - max attempts reached');
      }

      // Stop reconnection attempts
      _reconnectAttempts = _maxReconnectAttempts;

      // Notify error
      _onError?.call(
          'Connection failed after multiple attempts. Please check your internet connection and try again.');
    });

    // Handle successful reconnection from backend
    _socket!.on('reconnected', (data) {
      if (kDebugMode) {
        print('ChatSocketService: Successfully reconnected to server');
      }

      // Reset reconnection attempts
      _reconnectAttempts = 0;
      _isConnected = true;
      _isInitializing = false;

      // Notify connection restored
      _onConnectionChanged?.call(true);
    });

    // Handle reconnection error from backend
    _socket!.on('reconnection_error', (data) {
      if (kDebugMode) {
        print('ChatSocketService: Reconnection error from backend: $data');
      }

      // Continue with next attempt or show error if max reached
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _onError?.call(
            'Failed to reconnect. Please check your internet connection and try again.');
      }
    });
  }

  /// Handle connection established
  void _handleConnect() {
    _isConnected = true;
    _isInitializing = false;
    _reconnectAttempts = 0;

    if (kDebugMode) {
      print('ChatSocketService: Socket connected with ID: ${_socket?.id}');
    }

    _onConnectionChanged?.call(true);
  }

  /// Handle connection lost
  void _handleDisconnect(String? reason) {
    _isConnected = false;
    _isInitializing = false;

    if (kDebugMode) {
      print('ChatSocketService: Socket disconnected. Reason: $reason');
    }

    _onConnectionChanged?.call(false);

    // Attempt reconnection if not manually disconnected
    if (reason != 'io client disconnect' && !_isDisposed) {
      _scheduleReconnect();
    }
  }

  /// Handle connection error
  void _handleConnectError(dynamic error) {
    _isConnected = false;
    _isInitializing = false;

    if (kDebugMode) {
      print('ChatSocketService: Connection error: $error');
    }

    _onError?.call('Connection failed: $error');

    if (!_isDisposed) {
      _scheduleReconnect();
    }
  }

  /// Handle socket error
  void _handleError(dynamic error) {
    if (kDebugMode) {
      print('ChatSocketService: Socket error: $error');
    }

    _onError?.call('Socket error: $error');
  }

  /// Handle reconnection
  void _handleReconnect() {
    _isConnected = true;
    _reconnectAttempts = 0;

    if (kDebugMode) {
      print('ChatSocketService: Socket reconnected');
    }

    _onConnectionChanged?.call(true);
  }

  /// Handle reconnection attempt
  void _handleReconnectAttempt(int attempt) {
    if (kDebugMode) {
      print('ChatSocketService: Reconnection attempt $attempt');
    }
  }

  /// Handle reconnection error
  void _handleReconnectError(dynamic error) {
    if (kDebugMode) {
      print('ChatSocketService: Reconnection error: $error');
    }

    _onError?.call('Reconnection failed: $error');
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isDisposed) {
      if (kDebugMode) {
        print('ChatSocketService: Max reconnection attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    final delay =
        Duration(seconds: _reconnectDelay.inSeconds * _reconnectAttempts);

    if (kDebugMode) {
      print(
          'ChatSocketService: Scheduling reconnection in ${delay.inSeconds}s');
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed && !_isConnected) {
        _initializeSocket();
      }
    });
  }

  /// Handle incoming socket events
  void _handleEvent(String eventName, dynamic data) {
    if (_isDisposed) return;

    try {
      // Handle case where data is a List with the actual data at index 0
      final actualData = data is List ? data[0] : data;

      if (actualData is Map<String, dynamic>) {
        if (kDebugMode) {
          print('ChatSocketService: Received $eventName event: $actualData');
        }

        // Notify all registered callbacks for this event
        final callbacks = _eventCallbacks[eventName];
        if (callbacks != null) {
          for (final callback in callbacks) {
            try {
              callback(actualData);
            } catch (e) {
              if (kDebugMode) {
                print('ChatSocketService: Error in event callback: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatSocketService: Error processing $eventName event: $e');
      }
    }
  }

  /// Add event listener
  void addEventListener(String eventName, SocketMessageCallback callback) {
    _eventCallbacks.putIfAbsent(eventName, () => []).add(callback);
  }

  /// Remove event listener
  void removeEventListener(String eventName, SocketMessageCallback callback) {
    final callbacks = _eventCallbacks[eventName];
    if (callbacks != null) {
      callbacks.remove(callback);
      if (callbacks.isEmpty) {
        _eventCallbacks.remove(eventName);
      }
    }
  }

  /// Emit event to server
  void emit(String eventName, Map<String, dynamic> data) {
    if (_isConnected && _socket != null) {
      if (kDebugMode) {
        print('ChatSocketService: Emitting $eventName: $data');
      }
      _socket!.emit(eventName, data);
    } else {
      if (kDebugMode) {
        print(
            'ChatSocketService: Cannot emit $eventName - socket not connected');
      }
    }
  }

  /// Send message
  void sendMessage({
    required String chatId,
    required String messageText,
    required String messageCreator,
    required String messageCreatorRole,
    required String userId,
    List<Map<String, dynamic>>? files,
    Map<String, dynamic>? location,
    String? messageInvoiceRef,
    String? clientMessageId,
  }) {
    final data = {
      'chatId': chatId,
      'messageText': messageText,
      'messageCreator': messageCreator,
      'messageCreatorRole': messageCreatorRole,
      'userId': userId,
      if (files != null) 'files': files,
      if (location != null) 'location': location,
      if (messageInvoiceRef != null) 'messageInvoiceRef': messageInvoiceRef,
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    };

    // Debug logging to check what's being sent
    if (kDebugMode) {
      print('SocketService: Sending message with data:');
      print('  messageCreatorRole: "${data['messageCreatorRole']}"');
      print('  messageCreator: "${data['messageCreator']}"');
      print('  userId: "${data['userId']}"');
      print('  chatId: "${data['chatId']}"');
    }

    emit('send_message', data);
  }

  /// Mark messages as read
  void markMessagesAsRead(String chatId, List<String> messageIds) {
    final data = {
      'chatId': chatId,
      'messageIds': messageIds,
    };

    emit('mark_messages_read', data);
  }

  /// Mark messages as delivered
  void markMessagesAsDelivered(String chatId, List<String> messageIds) {
    final data = {
      'chatId': chatId,
      'messageIds': messageIds,
    };

    emit('mark_messages_delivered', data);
  }

  /// Update user status
  void updateUserStatus({required bool isOnline, DateTime? lastSeen}) {
    final data = {
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': lastSeen.toIso8601String(),
    };

    emit('update_user_status', data);
  }

  /// Start typing indicator
  void startTyping(String chatId) {
    final data = {'chatId': chatId};
    emit('start_typing', data);
  }

  /// Stop typing indicator
  void stopTyping(String chatId) {
    final data = {'chatId': chatId};
    emit('stop_typing', data);
  }

  /// Disconnect socket
  void disconnect() {
    if (kDebugMode) {
      print('ChatSocketService: Disconnecting socket');
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
    _isInitializing = false;
  }

  /// Stop reconnection attempts (when user closes reconnecting popup)
  void stopReconnectionAttempts() {
    if (kDebugMode) {
      print('ChatSocketService: Stopping reconnection attempts');
    }

    _reconnectAttempts = _maxReconnectAttempts;
  }

  /// Dispose service
  void dispose() {
    if (kDebugMode) {
      print('ChatSocketService: Disposing service');
    }

    _isDisposed = true;
    disconnect();

    // Clear all callbacks
    _eventCallbacks.clear();
    _onConnectionChanged = null;
    _onError = null;
  }
}
