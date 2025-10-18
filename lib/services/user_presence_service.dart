import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import '../core/constant.dart';

/// Clean and simple service for managing user online/offline status
class UserPresenceService extends ChangeNotifier with WidgetsBindingObserver {
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();

  // Simple status storage
  final Map<String, bool> _userStatus = {}; // userId -> isOnline
  final Map<String, DateTime> _lastSeen = {}; // userId -> lastSeen timestamp

  // Connection state
  bool _isConnected = false;
  Timer? _heartbeatTimer;

  // Getters
  bool get isConnected => _isConnected;
  Map<String, bool> get userStatus => Map.unmodifiable(_userStatus);

  // Initialize the service
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
  }

  /// Check if a user is online
  bool isUserOnline(String userId) {
    return _userStatus[userId] ?? false;
  }

  /// Get last seen timestamp for a user
  DateTime? getLastSeen(String userId) {
    return _lastSeen[userId];
  }

  /// Update user status
  void updateUserStatus(String userId, bool isOnline) {
    final previousStatus = _userStatus[userId];

    if (previousStatus != isOnline) {
      _userStatus[userId] = isOnline;

      if (!isOnline) {
        _lastSeen[userId] = DateTime.now();
      }

      if (kDebugMode) {
        print(
            'UserPresenceService: User $userId is now ${isOnline ? 'online' : 'offline'}');
      }

      notifyListeners();
    }
  }

  /// Update connection status
  void updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;

      if (kDebugMode) {
        print('UserPresenceService: Connection status changed to: $connected');
      }

      notifyListeners();
    }
  }

  /// Handle user activity (heartbeat)
  void onUserActivity(String userId) {
    if (_userStatus[userId] != true) {
      updateUserStatus(userId, true);
    }
  }

  /// Start heartbeat to keep users online
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Reduced from 30 seconds to 5 seconds for faster real-time updates
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isConnected) {
        // Mark current user as active
        final currentUserId = Constants.userId;
        if (currentUserId.isNotEmpty) {
          onUserActivity(currentUserId);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentUserId = Constants.userId;
    if (currentUserId.isEmpty) return;

    switch (state) {
      case AppLifecycleState.resumed:
        updateUserStatus(currentUserId, true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        updateUserStatus(currentUserId, false);
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
