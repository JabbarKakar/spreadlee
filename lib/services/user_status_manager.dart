import 'package:flutter/foundation.dart';
import '../providers/user_status_provider.dart';
import '../services/socket_service.dart';
import '../services/user_presence_service.dart';

/// Clean facade service for managing user online/offline status
/// This service provides a simple interface for the rest of the app
class UserStatusManager {
  static final UserStatusManager _instance = UserStatusManager._internal();
  factory UserStatusManager() => _instance;
  UserStatusManager._internal();

  final UserStatusProvider _statusProvider = UserStatusProvider();
  final SocketService _socketService = SocketService();
  final UserPresenceService _presenceService = UserPresenceService();

  bool _isInitialized = false;

  /// Initialize the manager
  void initialize() {
    if (_isInitialized) return;

    _statusProvider.initialize();
    _isInitialized = true;

    if (kDebugMode) {
      print('UserStatusManager: Initialized successfully');
    }
  }

  /// Connect to real-time services
  void connect(String userId, String token) {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('UserStatusManager: Not initialized, initializing first');
      }
      initialize();
    }

    _statusProvider.connect(userId, token);

    if (kDebugMode) {
      print('UserStatusManager: Connected with userId: $userId');
    }
  }

  /// Disconnect from real-time services
  void disconnect() {
    _statusProvider.disconnect();

    if (kDebugMode) {
      print('UserStatusManager: Disconnected');
    }
  }

  /// Check if a user is online
  bool isUserOnline(String userId) {
    return _statusProvider.isUserOnline(userId);
  }

  /// Get last seen timestamp for a user
  DateTime? getLastSeen(String userId) {
    return _statusProvider.getLastSeen(userId);
  }

  /// Check if a user is typing in a specific chat
  bool isUserTyping(String chatId, String userId) {
    return _statusProvider.isUserTyping(chatId, userId);
  }

  /// Get all typing users in a chat
  List<String> getTypingUsers(String chatId) {
    return _statusProvider.getTypingUsers(chatId);
  }

  /// Start typing indicator
  void startTyping(String chatId) {
    _statusProvider.startTyping(chatId);
  }

  /// Stop typing indicator
  void stopTyping(String chatId) {
    _statusProvider.stopTyping(chatId);
  }

  /// Request user status from server
  void requestUserStatus(String userId) {
    _statusProvider.requestUserStatus(userId);
  }

  /// Update current user status
  void updateCurrentUserStatus(bool isOnline) {
    _statusProvider.updateCurrentUserStatus(isOnline);
  }

  /// Get connection status
  bool get isConnected => _statusProvider.isConnected;

  /// Get user status provider for advanced usage
  UserStatusProvider get statusProvider => _statusProvider;

  /// Get socket service for advanced usage
  SocketService get socketService => _socketService;

  /// Get presence service for advanced usage
  UserPresenceService get presenceService => _presenceService;
}
