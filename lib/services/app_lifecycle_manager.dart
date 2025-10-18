import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/user_status_provider.dart';
import '../services/offline_status_service.dart';
import '../core/constant.dart';

/// Service to manage app lifecycle events and user status
/// Handles background/foreground detection, app switching, and connection management
class AppLifecycleManager {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  UserStatusProvider? _userStatusProvider;
  final OfflineStatusService _offlineService = OfflineStatusService();
  Timer? _backgroundTimer;
  Timer? _inactiveTimer;
  bool _isInBackground = false;
  bool _isAppInactive = false;
  DateTime? _backgroundTime;
  DateTime? _inactiveTime;

  // Configuration - Make both scenarios identical
  static const Duration _backgroundTimeout = Duration(seconds: 5);
  static const Duration _inactiveTimeout = Duration(seconds: 5);

  /// Initialize the lifecycle manager
  void initialize(UserStatusProvider userStatusProvider) {
    _userStatusProvider = userStatusProvider;

    if (kDebugMode) {
      print('AppLifecycleManager: Initialized');
    }
  }

  /// Check if the lifecycle manager is initialized
  bool get isInitialized => _userStatusProvider != null;

  /// Handle app going to background
  void handleAppBackgrounded() {
    if (_isInBackground) return;

    _isInBackground = true;
    _backgroundTime = DateTime.now();

    if (kDebugMode) {
      print('AppLifecycleManager: App backgrounded - marking user offline');
    }

    // Mark user as offline immediately when app goes to background (don't emit - we'll do it manually)
    _userStatusProvider?.updateCurrentUserStatus(false, emitToBackend: false);

    // Force emit offline status to backend immediately
    _forceEmitOfflineStatus(reason: 'app_backgrounded');

    // Start background timer - if app stays in background too long, disconnect
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(_backgroundTimeout, () {
      if (_isInBackground) {
        _handleExtendedBackground();
      }
    });
  }

  /// Handle app coming to foreground
  void handleAppForegrounded() {
    if (!_isInBackground) return;

    _isInBackground = false;
    _backgroundTimer?.cancel();

    if (kDebugMode) {
      print(
          'AppLifecycleManager: App foregrounded - reconnecting and marking user online');
    }

    // Reconnect and mark user as online
    _reconnectAndMarkOnline();
  }

  /// Handle app becoming inactive (system overlay, incoming call, etc.)
  void handleAppInactive() {
    if (_isAppInactive) return;

    _isAppInactive = true;
    _inactiveTime = DateTime.now();

    if (kDebugMode) {
      print('AppLifecycleManager: App inactive - marking user offline');
    }

    // Mark user as offline when app becomes inactive (don't emit - we'll do it manually)
    _userStatusProvider?.updateCurrentUserStatus(false, emitToBackend: false);

    // Force emit offline status to backend immediately
    _forceEmitOfflineStatus(reason: 'app_inactive');

    // Start inactive timer
    _inactiveTimer?.cancel();
    _inactiveTimer = Timer(_inactiveTimeout, () {
      if (_isAppInactive) {
        _handleExtendedInactive();
      }
    });
  }

  /// Handle app becoming active again
  void handleAppActive() {
    if (!_isAppInactive) return;

    _isAppInactive = false;
    _inactiveTimer?.cancel();

    if (kDebugMode) {
      print('AppLifecycleManager: App active - marking user online');
    }

    // Mark user as online when app becomes active
    _userStatusProvider?.updateCurrentUserStatus(true, emitToBackend: true);
  }

  /// Handle app termination
  void handleAppTerminated() {
    if (kDebugMode) {
      print('AppLifecycleManager: App terminated - marking user offline');
    }

    // Clean up timers
    _backgroundTimer?.cancel();
    _inactiveTimer?.cancel();

    // Force emit offline status immediately before disconnecting
    _forceEmitOfflineStatus(reason: 'app_terminated');

    // Mark user as offline (don't emit - we'll do it manually)
    _userStatusProvider?.updateCurrentUserStatus(false, emitToBackend: false);
    _userStatusProvider?.disconnect();

    _isInBackground = false;
    _isAppInactive = false;
  }

  /// Handle extended background state
  void _handleExtendedBackground() {
    if (kDebugMode) {
      print(
          'AppLifecycleManager: App in background for extended period - disconnecting');
    }

    // Add a longer delay to ensure status change has time to propagate to other users
    Timer(const Duration(milliseconds: 2000), () {
      _userStatusProvider?.disconnect();
    });
  }

  /// Handle extended inactive state
  void _handleExtendedInactive() {
    if (kDebugMode) {
      print(
          'AppLifecycleManager: App inactive for extended period - disconnecting');
    }

    // Add a longer delay to ensure status change has time to propagate to other users
    Timer(const Duration(milliseconds: 2000), () {
      _userStatusProvider?.disconnect();
    });
  }

  /// Reconnect and mark user as online
  void _reconnectAndMarkOnline() {
    if (Constants.userId.isNotEmpty && Constants.token.isNotEmpty) {
      _userStatusProvider?.connect(Constants.userId, Constants.token);

      // Wait a bit for connection to establish, then mark as online
      Timer(const Duration(milliseconds: 500), () {
        _userStatusProvider?.updateCurrentUserStatus(true, emitToBackend: true);
      });
    }
  }

  /// Check if app is currently in background
  bool get isInBackground => _isInBackground;

  /// Check if app is currently inactive
  bool get isAppInactive => _isAppInactive;

  /// Get time since app went to background
  Duration? get timeInBackground {
    if (_backgroundTime == null) return null;
    return DateTime.now().difference(_backgroundTime!);
  }

  /// Get time since app became inactive
  Duration? get timeInactive {
    if (_inactiveTime == null) return null;
    return DateTime.now().difference(_inactiveTime!);
  }

  /// Force emit offline status to backend immediately
  void _forceEmitOfflineStatus({String reason = 'app_backgrounded'}) {
    if (kDebugMode) {
      print(
          'AppLifecycleManager: Force emitting offline status to backend with reason: $reason');
      print('AppLifecycleManager: User ID: ${Constants.userId}');
      print(
          'AppLifecycleManager: Socket connected: ${_userStatusProvider?.socketService.isConnected}');
    }

    // Try socket first
    final socketService = _userStatusProvider?.socketService;
    if (socketService != null) {
      socketService.forceEmitUserOffline(reason: reason);
      if (kDebugMode) {
        print(
            'AppLifecycleManager: Socket emission completed for reason: $reason');
      }
    } else {
      if (kDebugMode) {
        print('AppLifecycleManager: Socket service is null!');
      }
    }

    // Also try HTTP as backup
    _offlineService.forceEmitCurrentUserOffline(reason: reason);
    if (kDebugMode) {
      print('AppLifecycleManager: HTTP emission completed for reason: $reason');
    }
  }

  /// Force mark user as offline (for emergency situations)
  void forceMarkOffline() {
    if (kDebugMode) {
      print('AppLifecycleManager: Force marking user offline');
    }

    _userStatusProvider?.updateCurrentUserStatus(false, emitToBackend: false);
    _forceEmitOfflineStatus(reason: 'force_offline');
    _userStatusProvider?.disconnect();
  }

  /// Force mark user as online (for emergency situations)
  void forceMarkOnline() {
    if (kDebugMode) {
      print('AppLifecycleManager: Force marking user online');
    }

    _reconnectAndMarkOnline();
  }

  /// Dispose resources
  void dispose() {
    _backgroundTimer?.cancel();
    _inactiveTimer?.cancel();
    _offlineService.dispose();
    _userStatusProvider = null;
  }
}
