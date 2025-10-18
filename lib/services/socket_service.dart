import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constant.dart';

/// Clean and simple socket service for managing real-time connections
class SocketService extends ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _currentUserId;
  bool _isConnected = false;

  // Event streams for presence management
  final StreamController<Map<String, dynamic>> _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Event callbacks
  Function(Map<String, dynamic>)? _onUserStatusChange;
  Function(Map<String, dynamic>)? _onUserStartedTyping;
  Function(Map<String, dynamic>)? _onUserStoppedTyping;
  Function(Map<String, dynamic>)? _onPresenceChange;

  // Presence management
  final Map<String, Map<String, dynamic>> _userPresences = {};
  Timer? _heartbeatTimer;
  Timer? _activityTimer;

  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Map<String, Map<String, dynamic>> get userPresences =>
      Map.unmodifiable(_userPresences);

  /// Connect to socket server
  void connect(String userId, String token) {
    if (_isConnected) return;

    _currentUserId = userId;

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
      print('=== SocketService Socket URL Debug ===');
      print('Constants.socketBaseUrl: ${Constants.socketBaseUrl}');
      print('Parsed URI: $uri');
      print('URI scheme: ${uri.scheme}');
      print('URI host: ${uri.host}');
      print('URI port: ${uri.port}');
      print('Final socket URL: $socketUrl');
      print('Expected: ws://localhost:4000');
      print('Is correct: ${socketUrl == 'ws://localhost:4000'}');
      print('=====================================');
    }

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token, 'userId': userId},
      // FIX: Add buffer size configuration for large video files
      'maxHttpBufferSize': 50 * 1024 * 1024, // 50MB buffer
      'forceNew': true,
      'timeout': 20000,
    });

    _setupEventListeners();
  }

  /// Setup socket event listeners
  void _setupEventListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      _emitUserOnline();
      _startPresenceManagement();
      notifyListeners();

      if (kDebugMode) {
        print('SocketService: Connected successfully');
      }
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      _emitUserOffline();
      _stopPresenceManagement();
      notifyListeners();

      if (kDebugMode) {
        print('SocketService: Disconnected');
      }
    });

    _socket?.onError((error) {
      if (kDebugMode) {
        print('SocketService: Error: $error');
      }
    });

    // Authentication success
    _socket?.on('authenticated', (data) {
      if (kDebugMode) {
        print('SocketService: Authenticated successfully');
      }
    });

    // Presence events (following backend specification)
    _socket?.on('user_presence_change', (data) {
      _handlePresenceChange(data);
    });

    _socket?.on('presence_data_response', (data) {
      _handlePresenceDataResponse(data);
    });

    // Heartbeat events (following backend specification)
    _socket?.on('heartbeat_ping', (data) {
      _handleHeartbeatPing();
    });

    _socket?.on('heartbeat_ack', (data) {
      if (kDebugMode) {
        print('SocketService: Heartbeat acknowledged');
      }
    });

    // Legacy events for backward compatibility
    _socket?.on('user_status_change', (data) {
      _handleUserStatusChange(data);
    });

    // Typing events
    _socket?.on('user_started_typing', (data) {
      _handleTypingEvent(data, true);
    });

    _socket?.on('user_stopped_typing', (data) {
      _handleTypingEvent(data, false);
    });
  }

  /// Start presence management
  void _startPresenceManagement() {
    // Send heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _socket?.emit('heartbeat', {
          'userId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    // Send user activity every 5 minutes
    _activityTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isConnected) {
        _socket?.emit('user_activity', {
          'userId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Stop presence management
  void _stopPresenceManagement() {
    _heartbeatTimer?.cancel();
    _activityTimer?.cancel();
  }

  /// Handle presence change events (new backend event)
  void _handlePresenceChange(dynamic data) {
    try {
      final actualData = data is List ? data[0] : data;
      if (actualData is Map<String, dynamic>) {
        final userId = actualData['userId'];
        final status = actualData['status'];
        final lastSeen = actualData['lastSeen'];
        final lastActive = actualData['lastActive'];

        if (userId != null && status != null) {
          // Update local presence data
          _userPresences[userId] = {
            'status': status,
            'lastSeen': lastSeen,
            'lastActive': lastActive,
            'timestamp': DateTime.now().toIso8601String(),
          };

          // Create event data for listeners
          final eventData = {
            'type': 'presence_change',
            'userId': userId,
            'status': status,
            'isOnline': status == 'online',
            'lastSeen': lastSeen,
            'lastActive': lastActive,
            'timestamp': DateTime.now().toIso8601String(),
          };

          // Notify presence listeners
          _presenceController.add(eventData);
          _onPresenceChange?.call(eventData);

          if (kDebugMode) {
            print('SocketService: Presence change: $userId is now $status');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SocketService: Error handling presence change: $e');
      }
    }
  }

  /// Handle presence data response (new backend event)
  void _handlePresenceDataResponse(dynamic data) {
    try {
      final actualData = data is List ? data[0] : data;
      if (actualData is Map<String, dynamic>) {
        final presences = actualData['presences'] as List?;

        if (presences != null) {
          for (final presence in presences) {
            if (presence is Map<String, dynamic>) {
              final userId = presence['userId'];
              final status = presence['status'];
              final lastSeen = presence['lastSeen'];
              final lastActive = presence['lastActive'];

              if (userId != null && status != null) {
                _userPresences[userId] = {
                  'status': status,
                  'lastSeen': lastSeen,
                  'lastActive': lastActive,
                  'timestamp': DateTime.now().toIso8601String(),
                };
              }
            }
          }

          // Notify listeners of bulk presence update
          _presenceController.add({
            'type': 'presence_bulk_update',
            'presences': Map.from(_userPresences),
            'timestamp': DateTime.now().toIso8601String(),
          });

          if (kDebugMode) {
            print(
                'SocketService: Received presence data for ${_userPresences.length} users');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SocketService: Error handling presence data response: $e');
      }
    }
  }

  /// Handle heartbeat ping from server
  void _handleHeartbeatPing() {
    if (_socket?.connected == true) {
      _socket?.emit('heartbeat_ack', {
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('SocketService: Responded to heartbeat ping');
      }
    }
  }

  /// Handle user status change events (legacy)
  void _handleUserStatusChange(dynamic data) {
    try {
      final actualData = data is List ? data[0] : data;
      if (actualData is Map<String, dynamic>) {
        final eventData = {
          'type': 'status_change',
          'chatId': actualData['chatId'],
          'userId': actualData['userId'],
          'isOnline': actualData['isOnline'] ?? false,
          'timestamp':
              actualData['timestamp'] ?? DateTime.now().toIso8601String(),
        };

        _presenceController.add(eventData);
        _onUserStatusChange?.call(eventData);

        if (kDebugMode) {
          print('SocketService: User status change: $eventData');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SocketService: Error handling user status change: $e');
      }
    }
  }

  /// Handle typing events
  void _handleTypingEvent(dynamic data, bool isTyping) {
    try {
      final actualData = data is List ? data[0] : data;
      if (actualData is Map<String, dynamic>) {
        final eventData = {
          'type': isTyping ? 'typing_started' : 'typing_stopped',
          'chatId': actualData['chatId'],
          'userId': actualData['userId'],
          'timestamp':
              actualData['timestamp'] ?? DateTime.now().toIso8601String(),
        };

        _typingController.add(eventData);

        if (isTyping) {
          _onUserStartedTyping?.call(eventData);
        } else {
          _onUserStoppedTyping?.call(eventData);
        }

        if (kDebugMode) {
          print('SocketService: Typing event: $eventData');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SocketService: Error handling typing event: $e');
      }
    }
  }

  /// Emit user online status
  void _emitUserOnline() {
    if (_socket?.connected == true && _currentUserId != null) {
      _socket?.emit('user_online', {
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('SocketService: Emitted user_online');
      }
    }
  }

  /// Emit user offline status
  void _emitUserOffline() {
    if (_socket?.connected == true && _currentUserId != null) {
      _socket?.emit('user_offline', {
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('SocketService: Emitted user_offline');
      }
    }
  }

  /// Set user status change callback
  void onUserStatusChange(Function(Map<String, dynamic>) callback) {
    _onUserStatusChange = callback;
  }

  /// Set typing started callback
  void onUserStartedTyping(Function(Map<String, dynamic>) callback) {
    _onUserStartedTyping = callback;
  }

  /// Set typing stopped callback
  void onUserStoppedTyping(Function(Map<String, dynamic>) callback) {
    _onUserStoppedTyping = callback;
  }

  /// Set presence change callback
  void onPresenceChange(Function(Map<String, dynamic>) callback) {
    _onPresenceChange = callback;
  }

  /// Emit typing start
  void startTyping(String chatId) {
    if (_socket?.connected == true) {
      _socket?.emit('start_typing', {'chatId': chatId});

      if (kDebugMode) {
        print('SocketService: Emitted start_typing for chat: $chatId');
      }
    }
  }

  /// Emit typing stop
  void stopTyping(String chatId) {
    if (_socket?.connected == true) {
      _socket?.emit('stop_typing', {'chatId': chatId});

      if (kDebugMode) {
        print('SocketService: Emitted stop_typing for chat: $chatId');
      }
    }
  }

  /// Request user status
  void requestUserStatus(String userId) {
    if (_socket?.connected == true) {
      _socket?.emit('request_user_status', {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('SocketService: Requested status for user: $userId');
      }
    }
  }

  /// Request presence data for multiple users
  void requestPresenceData(List<String> userIds) {
    if (_socket?.connected == true) {
      final safeUserIds = List<String>.from(userIds);

      final data = {
        'userIds': safeUserIds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'presence_request',
        'version': '2.0',
        'count': safeUserIds.length,
      };

      _socket?.emit('request_presence_data', data);

      if (kDebugMode) {
        print('SocketService: Emitted data structure: $data');
      }
    }
  }

  /// Get user presence data
  Map<String, dynamic>? getUserPresence(String userId) {
    return _userPresences[userId];
  }

  /// Check if user is online based on presence data
  bool isUserOnline(String userId) {
    final presence = _userPresences[userId];
    if (presence != null) {
      return presence['status'] == 'online';
    }
    return false;
  }

  /// Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _emitUserOffline();
      _stopPresenceManagement();
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _currentUserId = null;
      notifyListeners();

      if (kDebugMode) {
        print('SocketService: Disconnected and disposed');
      }
    }
  }

  /// Force reconnect with fresh socket (useful for testing URL fixes)
  Future<void> forceReconnect() async {
    if (kDebugMode) {
      print('SocketService: Force reconnecting with fresh socket...');
    }

    // Disconnect current socket
    disconnect();

    // Wait a moment
    await Future.delayed(const Duration(milliseconds: 500));

    // Note: Cannot reconnect without userId and token
    // This method is mainly for clearing the old socket instance
    if (kDebugMode) {
      print(
          'SocketService: Socket cleared. Call connect() with userId and token to reconnect.');
    }
  }

  /// Initialize popup service (required by other services)
  void initializePopupService(dynamic context) {
    if (kDebugMode) {
      print('SocketService: Popup service initialized');
    }
    // This method is required by other services but doesn't need implementation
    // as popup management is handled by other services
  }

  /// Resume socket connection (alias for connect but requires existing credentials)
  void resume() {
    if (_currentUserId != null && _socket != null) {
      if (!_isConnected) {
        // Reconnect using existing socket
        _socket?.connect();
        if (kDebugMode) {
          print('SocketService: Resumed connection');
        }
      } else {
        if (kDebugMode) {
          print('SocketService: Already connected, no need to resume');
        }
      }
    } else {
      if (kDebugMode) {
        print('SocketService: Cannot resume - no active connection or user ID');
      }
    }
  }

  /// Suspend socket connection (temporarily disconnect)
  void suspend() {
    if (_socket != null && _isConnected) {
      _emitUserOffline();
      _stopPresenceManagement();
      _socket?.disconnect();
      _isConnected = false;
      notifyListeners();

      if (kDebugMode) {
        print('SocketService: Connection suspended');
      }
    }
  }

  /// Force emit user offline status with custom reason
  void forceEmitUserOffline({String reason = 'manual'}) {
    if (_socket?.connected == true && _currentUserId != null) {
      _socket?.emit('user_offline', {
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason,
        'forced': true,
      });

      if (kDebugMode) {
        print('SocketService: Force emitted user_offline with reason: $reason');
      }
    }
  }

  /// Stop reconnection attempts (placeholder for compatibility)
  void stopReconnectionAttempts() {
    if (kDebugMode) {
      print('SocketService: Stop reconnection attempts requested');
    }
    // This method is called by other services but the current implementation
    // doesn't have automatic reconnection logic, so this is a no-op
  }

  /// Reset connection state (placeholder for compatibility)
  void resetConnectionState() {
    _isConnected = false;
    _stopPresenceManagement();
    notifyListeners();

    if (kDebugMode) {
      print('SocketService: Connection state reset');
    }
  }

  @override
  void dispose() {
    disconnect();
    _presenceController.close();
    _typingController.close();
    super.dispose();
  }
}
