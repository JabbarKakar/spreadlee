import 'package:flutter/foundation.dart';
import '../providers/user_status_provider.dart';
import '../services/socket_service.dart';
import '../services/app_lifecycle_manager.dart';
import '../services/connection_monitor_service.dart';
import '../core/constant.dart';

/// Central coordinator for all user status management
/// Provides a unified interface for managing user online/offline status across all scenarios
class UserStatusCoordinator {
  static final UserStatusCoordinator _instance =
      UserStatusCoordinator._internal();
  factory UserStatusCoordinator() => _instance;
  UserStatusCoordinator._internal();

  UserStatusProvider? _userStatusProvider;
  SocketService? _socketService;
  AppLifecycleManager? _lifecycleManager;
  ConnectionMonitorService? _connectionMonitor;

  bool _isInitialized = false;

  /// Initialize the coordinator with all required services
  void initialize() {
    if (_isInitialized) return;

    _userStatusProvider = UserStatusProvider();
    _socketService = SocketService();
    _lifecycleManager = AppLifecycleManager();
    _connectionMonitor = ConnectionMonitorService();

    // Initialize all services
    _userStatusProvider!.initialize();
    _lifecycleManager!.initialize(_userStatusProvider!);
    _connectionMonitor!.initialize(_userStatusProvider!, _socketService!);

    _isInitialized = true;

    if (kDebugMode) {
      print('UserStatusCoordinator: Initialized with all services');
    }
  }

  /// Connect user to real-time services
  void connectUser(String userId, String token) {
    if (!_isInitialized) {
      initialize();
    }

    if (kDebugMode) {
      print('UserStatusCoordinator: Connecting user $userId');
    }

    _userStatusProvider!.connect(userId, token);
  }

  /// Disconnect user from real-time services
  void disconnectUser() {
    if (kDebugMode) {
      print('UserStatusCoordinator: Disconnecting user');
    }

    _userStatusProvider?.disconnect();
  }

  /// Mark user as offline (for emergency situations)
  void markUserOffline() {
    if (kDebugMode) {
      print('UserStatusCoordinator: Force marking user offline');
    }

    _userStatusProvider?.updateCurrentUserStatus(false, emitToBackend: true);
    _socketService?.disconnect();
  }

  /// Mark user as online (for emergency situations)
  void markUserOnline() {
    if (kDebugMode) {
      print('UserStatusCoordinator: Force marking user online');
    }

    if (Constants.userId.isNotEmpty && Constants.token.isNotEmpty) {
      _userStatusProvider?.connect(Constants.userId, Constants.token);
      _userStatusProvider?.updateCurrentUserStatus(true, emitToBackend: true);
    }
  }

  /// Get current connection status
  bool get isConnected => _socketService?.isConnected ?? false;

  /// Get current user online status
  bool get isUserOnline {
    if (Constants.userId.isEmpty) return false;
    return _userStatusProvider?.isUserOnline(Constants.userId) ?? false;
  }

  /// Check if another user is online
  bool isOtherUserOnline(String userId) {
    return _userStatusProvider?.isUserOnline(userId) ?? false;
  }

  /// Get user presence data
  dynamic getUserPresence(String userId) {
    return _userStatusProvider?.getUserPresence(userId);
  }

  /// Get last seen timestamp for a user
  DateTime? getLastSeen(String userId) {
    return _userStatusProvider?.getLastSeen(userId);
  }

  /// Start typing indicator
  void startTyping(String chatId) {
    _userStatusProvider?.startTyping(chatId);
  }

  /// Stop typing indicator
  void stopTyping(String chatId) {
    _userStatusProvider?.stopTyping(chatId);
  }

  /// Check if a user is typing in a chat
  bool isUserTyping(String chatId, String userId) {
    return _userStatusProvider?.isUserTyping(chatId, userId) ?? false;
  }

  /// Get all typing users in a chat
  List<String> getTypingUsers(String chatId) {
    return _userStatusProvider?.getTypingUsers(chatId) ?? [];
  }

  /// Request user status from server
  void requestUserStatus(String userId) {
    _userStatusProvider?.requestUserStatus(userId);
  }

  /// Request presence data for multiple users
  void requestPresenceData(List<String> userIds) {
    _userStatusProvider?.requestPresenceData(userIds);
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isConnected': isConnected,
      'isUserOnline': isUserOnline,
      'userStatusProvider': _userStatusProvider?.getDebugInfo(),
      'lifecycleManager': {
        'isInitialized': _lifecycleManager?.isInitialized ?? false,
        'isInBackground': _lifecycleManager?.isInBackground ?? false,
        'isAppInactive': _lifecycleManager?.isAppInactive ?? false,
        'timeInBackground': _lifecycleManager?.timeInBackground?.inSeconds,
        'timeInactive': _lifecycleManager?.timeInactive?.inSeconds,
      },
      'connectionMonitor': {
        'isMonitoring': _connectionMonitor?.isMonitoring ?? false,
        'lastKnownConnectivity':
            _connectionMonitor?.lastKnownConnectivity ?? false,
        'timeSinceLastPing': _connectionMonitor?.timeSinceLastPing?.inSeconds,
        'consecutiveFailures': _connectionMonitor?.consecutiveFailures ?? 0,
      },
    };
  }

  /// Force reconnection (for testing)
  void forceReconnection() {
    if (kDebugMode) {
      print('UserStatusCoordinator: Force reconnection');
    }

    if (Constants.userId.isNotEmpty && Constants.token.isNotEmpty) {
      _socketService?.forceReconnect();
      connectUser(Constants.userId, Constants.token);
    }
  }

  /// Dispose all resources
  void dispose() {
    if (kDebugMode) {
      print('UserStatusCoordinator: Disposing all resources');
    }

    _userStatusProvider?.disconnect();
    _lifecycleManager?.dispose();
    _connectionMonitor?.dispose();

    _userStatusProvider = null;
    _socketService = null;
    _lifecycleManager = null;
    _connectionMonitor = null;
    _isInitialized = false;
  }
}
