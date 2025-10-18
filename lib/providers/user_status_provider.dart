import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';
import '../services/connection_monitor_service.dart';
import '../services/offline_status_service.dart';
import '../models/user_presence.dart';
import '../core/constant.dart';

/// Clean and simple provider for managing user online/offline status using socket-based presence
class UserStatusProvider extends ChangeNotifier {
  static final UserStatusProvider _instance = UserStatusProvider._internal();
  factory UserStatusProvider() => _instance;
  UserStatusProvider._internal();

  final SocketService _socketService = SocketService();
  final ConnectionMonitorService _connectionMonitor =
      ConnectionMonitorService();
  final OfflineStatusService _offlineService = OfflineStatusService();

  // Presence storage using the new UserPresence model
  final Map<String, UserPresence> _userPresences = {};

  // Typing indicators
  final Map<String, Set<String>> _typingUsers =
      {}; // chatId -> Set of typing userIds

  // Connection state
  bool _isConnected = false;
  bool _isInitialized = false;

  // Rate limiting for presence requests
  DateTime? _lastRefreshRequest;
  static const Duration _refreshCooldown = Duration(seconds: 2);

  // Getters
  bool get isConnected => _isConnected;
  Map<String, UserPresence> get userPresences =>
      Map.unmodifiable(_userPresences);
  Map<String, bool> get userStatus => Map.fromEntries(
      _userPresences.entries.map((e) => MapEntry(e.key, e.value.isOnline)));

  // Expose socket service for lifecycle management
  SocketService get socketService => _socketService;

  /// Initialize the provider
  void initialize() {
    if (_isInitialized) return;

    if (kDebugMode) {
      print('UserStatusProvider: Initializing...');
    }

    _setupSocketListeners();
    _connectionMonitor.initialize(this, _socketService);

    _isInitialized = true;

    if (kDebugMode) {
      print('UserStatusProvider: Initialized successfully');
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Listen to presence changes
    _socketService.onPresenceChange((data) {
      _handlePresenceUpdate(data);
    });

    // Listen to typing events
    _socketService.onUserStartedTyping((data) {
      _handleTypingStarted(data);
    });

    _socketService.onUserStoppedTyping((data) {
      _handleTypingStopped(data);
    });

    // Listen to socket connection changes
    _socketService.addListener(() {
      final newConnectionStatus = _socketService.isConnected;
      if (_isConnected != newConnectionStatus) {
        _isConnected = newConnectionStatus;
        notifyListeners();
      }
    });
  }

  /// Handle presence updates from socket
  void _handlePresenceUpdate(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('UserStatusProvider: Received presence update: $data');
    }

    final type = data['type'];

    if (type == 'presence_change') {
      _handleSinglePresenceChange(data);
    } else if (type == 'presence_bulk_update') {
      _handleBulkPresenceUpdate(data);
    }
  }

  /// Handle single presence change
  void _handleSinglePresenceChange(Map<String, dynamic> data) {
    final userId = data['userId'];
    final status = data['status'];
    final lastSeen = data['lastSeen'];
    final lastActive = data['lastActive'];

    if (userId != null && status != null) {
      final presence = UserPresence(
        userId: userId,
        status: status,
        lastSeen: lastSeen != null ? DateTime.tryParse(lastSeen) : null,
        lastActive: lastActive != null ? DateTime.tryParse(lastActive) : null,
      );

      _userPresences[userId] = presence;
      notifyListeners();

      if (kDebugMode) {
        print('UserStatusProvider: Updated presence for user $userId: $status');
      }
    }
  }

  /// Handle bulk presence update
  void _handleBulkPresenceUpdate(Map<String, dynamic> data) {
    final presences = data['presences'] as Map<String, dynamic>?;

    if (presences != null) {
      for (final entry in presences.entries) {
        final userId = entry.key;
        final presenceData = entry.value as Map<String, dynamic>;

        if (presenceData['status'] != null) {
          final presence = UserPresence(
            userId: userId,
            status: presenceData['status'],
            lastSeen: presenceData['lastSeen'] != null
                ? DateTime.tryParse(presenceData['lastSeen'])
                : null,
            lastActive: presenceData['lastActive'] != null
                ? DateTime.tryParse(presenceData['lastActive'])
                : null,
          );

          _userPresences[userId] = presence;
        }
      }

      notifyListeners();

      if (kDebugMode) {
        print(
            'UserStatusProvider: Bulk updated presence for ${_userPresences.length} users');
      }
    }
  }

  /// Handle typing started events
  void _handleTypingStarted(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final userId = data['userId'];

    if (chatId != null && userId != null) {
      _typingUsers.putIfAbsent(chatId, () => <String>{});
      _typingUsers[chatId]!.add(userId);
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserStatusProvider: User $userId started typing in chat $chatId');
      }
    }
  }

  /// Handle typing stopped events
  void _handleTypingStopped(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final userId = data['userId'];

    if (chatId != null && userId != null) {
      _typingUsers[chatId]?.remove(userId);
      if (_typingUsers[chatId]?.isEmpty == true) {
        _typingUsers.remove(chatId);
      }
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserStatusProvider: User $userId stopped typing in chat $chatId');
      }
    }
  }

  /// Check if a user is online
  bool isUserOnline(String userId) {
    final presence = _userPresences[userId];
    return presence?.isOnline ?? false;
  }

  /// Get user presence data
  UserPresence? getUserPresence(String userId) {
    return _userPresences[userId];
  }

  /// Get last seen timestamp for a user
  DateTime? getLastSeen(String userId) {
    final presence = _userPresences[userId];
    return presence?.lastSeen;
  }

  /// Check if a user is typing in a specific chat
  bool isUserTyping(String chatId, String userId) {
    return _typingUsers[chatId]?.contains(userId) ?? false;
  }

  /// Get all typing users in a chat
  List<String> getTypingUsers(String chatId) {
    return _typingUsers[chatId]?.toList() ?? [];
  }

  /// Connect to socket
  void connect(String userId, String token) {
    _socketService.connect(userId, token);
    _connectionMonitor.startMonitoring();
  }

  /// Disconnect from socket
  void disconnect() {
    _socketService.disconnect();
    _connectionMonitor.stopMonitoring();
  }

  /// Start typing indicator
  void startTyping(String chatId) {
    _socketService.startTyping(chatId);
  }

  /// Stop typing indicator
  void stopTyping(String chatId) {
    _socketService.stopTyping(chatId);
  }

  /// Request presence data for a specific user
  void requestUserStatus(String userId) {
    if (_isConnected) {
      if (kDebugMode) {
        print('UserStatusProvider: Requesting status for user: $userId');
      }
      _socketService.requestUserStatus(userId);
    } else {
      if (kDebugMode) {
        print(
            'UserStatusProvider: Not connected, cannot request status for user: $userId');
      }
    }
  }

  /// Request presence data for multiple users
  void requestPresenceData(List<String> userIds) {
    // Rate limiting: prevent too many rapid requests
    final now = DateTime.now();
    if (_lastRefreshRequest != null &&
        now.difference(_lastRefreshRequest!) < _refreshCooldown) {
      if (kDebugMode) {
        print(
            'UserStatusProvider: Rate limiting presence data request - too soon since last request');
      }
      return;
    }
    _lastRefreshRequest = now;

    if (_isConnected) {
      if (kDebugMode) {
        print(
            'UserStatusProvider: Requesting presence data for users: $userIds');
      }
      _socketService.requestPresenceData(userIds);
    } else {
      if (kDebugMode) {
        print(
            'UserStatusProvider: Not connected, cannot request presence data');
      }
    }
  }

  /// Update current user status
  void updateCurrentUserStatus(bool isOnline, {bool emitToBackend = true}) {
    final currentUserId = Constants.userId;
    if (currentUserId.isNotEmpty) {
      final status = isOnline ? 'online' : 'offline';
      final presence = UserPresence(
        userId: currentUserId,
        status: status,
        lastActive: DateTime.now(),
      );

      _userPresences[currentUserId] = presence;
      notifyListeners();

      // If going offline and emission is enabled, force emit to backend immediately
      if (!isOnline && emitToBackend) {
        _socketService.forceEmitUserOffline(reason: 'status_update');
        // Also try HTTP as backup
        _offlineService.forceEmitCurrentUserOffline(reason: 'status_update');
      }
    }
  }

  /// Initialize user status (for new users)
  void initializeUserStatus(String userId, {bool isDeleted = false}) {
    if (_userPresences.containsKey(userId)) {
      if (kDebugMode) {
        print(
            'UserStatusProvider: User $userId already tracked, skipping initialization');
      }
      return;
    }

    final status = isDeleted ? 'offline' : 'offline';
    final presence = UserPresence(
      userId: userId,
      status: status,
      lastSeen: DateTime.now(),
    );

    _userPresences[userId] = presence;

    if (kDebugMode) {
      print('UserStatusProvider: Initialized user $userId as $status');
    }
  }

  /// Add user to tracking
  void addUserToTracking(String userId, {bool isOnline = false}) {
    if (_userPresences.containsKey(userId)) {
      if (kDebugMode) {
        print('UserStatusProvider: User $userId already tracked, skipping add');
      }
      return;
    }

    final status = isOnline ? 'online' : 'offline';
    final presence = UserPresence(
      userId: userId,
      status: status,
      lastActive: DateTime.now(),
    );

    _userPresences[userId] = presence;

    if (kDebugMode) {
      print(
          'UserStatusProvider: Added user $userId to tracking with status: $status');
    }
  }

  /// Request and track user status
  void requestAndTrackUserStatus(String userId, {String? chatId}) {
    // Add user to tracking if not already tracked
    if (!_userPresences.containsKey(userId)) {
      initializeUserStatus(userId);
    }

    // Request fresh status
    requestUserStatus(userId);
  }

  /// Request status for multiple users
  void requestMultipleUserStatuses(List<String> userIds) {
    if (kDebugMode) {
      print('UserStatusProvider: Requesting status for users: $userIds');
    }

    // Request presence data for all users at once
    requestPresenceData(userIds);

    // Add users to tracking if not already tracked
    for (final userId in userIds) {
      if (!_userPresences.containsKey(userId)) {
        initializeUserStatus(userId);
      }
    }
  }

  /// Refresh all user statuses
  void refreshAllUserStatuses() {
    // Rate limiting: prevent too many rapid refresh requests
    final now = DateTime.now();
    if (_lastRefreshRequest != null &&
        now.difference(_lastRefreshRequest!) < _refreshCooldown) {
      if (kDebugMode) {
        print(
            'UserStatusProvider: Rate limiting refresh request - too soon since last refresh');
      }
      return;
    }
    _lastRefreshRequest = now;

    if (kDebugMode) {
      print('UserStatusProvider: Refreshing all user statuses');
      print(
          'UserStatusProvider: Tracked users: ${_userPresences.keys.toList()}');
    }

    // Request fresh presence data for all tracked users
    if (_userPresences.isNotEmpty) {
      requestPresenceData(_userPresences.keys.toList());
    }
  }

  // Compatibility methods for existing code
  void forceUIUpdate() {
    notifyListeners();
  }

  // Legacy getters for compatibility
  Map<String, bool> get globalOnlineUsers => userStatus;
  Map<String, bool> get onlineUsers => userStatus;

  // Legacy method for compatibility
  bool isUserOnlineGlobally(String userId) {
    return isUserOnline(userId);
  }

  // Legacy methods for compatibility (now handled by socket service)
  void maintainUserStatusAcrossAppLifecycle() {}
  void persistUserStatus() {}
  void restoreUserStatus() {}
  void ensureUserStatusPersistence() {}
  void requestUserStatusForChat(String chatId, String userId) {
    requestUserStatus(userId);
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'userPresences': _userPresences.map((k, v) => MapEntry(k, v.toJson())),
      'typingUsers': _typingUsers,
      'isConnected': _isConnected,
      'isInitialized': _isInitialized,
    };
  }

  List<String> getAllTrackedUsers() {
    return _userPresences.keys.toList();
  }

  @override
  void dispose() {
    _socketService.removeListener(() {});
    _connectionMonitor.dispose();
    _offlineService.dispose();
    super.dispose();
  }
}
