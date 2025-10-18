import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../providers/user_status_provider.dart';
import '../services/socket_service.dart';
import '../services/connection_popup_service.dart';
import '../core/constant.dart';

/// Service to monitor network connectivity and handle connection loss scenarios
/// Provides multiple layers of protection for user offline status
class ConnectionMonitorService {
  static final ConnectionMonitorService _instance =
      ConnectionMonitorService._internal();
  factory ConnectionMonitorService() => _instance;
  ConnectionMonitorService._internal();

  UserStatusProvider? _userStatusProvider;
  SocketService? _socketService;
  final ConnectionPopupService _popupService = ConnectionPopupService();
  Timer? _connectivityTimer;
  Timer? _pingTimer;
  Timer? _pingTimeoutTimer;
  bool _isMonitoring = false;
  bool _lastKnownConnectivity = true;
  DateTime? _lastSuccessfulPing;
  int _consecutiveFailures = 0;

  // Configuration
  static const Duration _connectivityCheckInterval = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);
  static const int _maxConsecutiveFailures = 3;
  static const Duration _connectionTimeout = Duration(seconds: 10);

  /// Initialize the connection monitor
  void initialize(
      UserStatusProvider userStatusProvider, SocketService socketService) {
    _userStatusProvider = userStatusProvider;
    _socketService = socketService;

    if (kDebugMode) {
      print('ConnectionMonitorService: Initialized');
    }
  }

  /// Initialize popup service with context
  void initializePopupService(BuildContext context) {
    _popupService.initialize(context);
  }

  /// Start monitoring network connectivity
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    if (kDebugMode) {
      print('ConnectionMonitorService: Started monitoring');
    }

    // Start periodic connectivity checks
    _connectivityTimer = Timer.periodic(_connectivityCheckInterval, (_) {
      _checkConnectivity();
    });

    // Start periodic ping tests
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _performPingTest();
    });
  }

  /// Stop monitoring network connectivity
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _connectivityTimer?.cancel();
    _pingTimer?.cancel();
    _pingTimeoutTimer?.cancel();

    if (kDebugMode) {
      print('ConnectionMonitorService: Stopped monitoring');
    }
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      // Check if we can reach the internet
      final result = await InternetAddress.lookup('google.com')
          .timeout(_connectionTimeout);

      final hasConnectivity =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (hasConnectivity != _lastKnownConnectivity) {
        _lastKnownConnectivity = hasConnectivity;

        if (hasConnectivity) {
          _handleConnectivityRestored();
        } else {
          _handleConnectivityLost();
        }
      }

      // Reset consecutive failures on successful connectivity check
      if (hasConnectivity) {
        _consecutiveFailures = 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ConnectionMonitorService: Connectivity check failed: $e');
      }

      _consecutiveFailures++;

      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _handleConnectivityLost();
      }
    }
  }

  /// Perform ping test to server
  Future<void> _performPingTest() async {
    // DISABLED: Ping-based socket detection is unreliable and causes false positives
    // The socket service has its own robust connection monitoring via heartbeats
    // We only need to check the socket's actual connection state

    if (_socketService?.isConnected != true) {
      if (kDebugMode) {
        print(
            'ConnectionMonitorService: Socket is not connected - checking if this is a real disconnection');
      }
      // Only show popup if this is a real disconnection (not a false positive)
      // The socket service will handle its own reconnection logic
      return;
    }

    // Socket is connected - no action needed
    if (kDebugMode) {
      print(
          'ConnectionMonitorService: Socket is connected - ping test skipped');
    }
  }

  /// Handle connectivity lost
  void _handleConnectivityLost() {
    if (kDebugMode) {
      print(
          'ConnectionMonitorService: Connectivity lost - marking user offline');
    }

    // Show internet connection lost popup
    _popupService.showInternetConnectionLost();

    // Mark user as offline immediately
    _userStatusProvider?.updateCurrentUserStatus(false, emitToBackend: true);

    // Disconnect socket
    _socketService?.disconnect();
  }

  /// Handle connectivity restored
  void _handleConnectivityRestored() {
    if (kDebugMode) {
      print(
          'ConnectionMonitorService: Connectivity restored - attempting reconnection');
    }

    // Show internet connection restored popup
    _popupService.showInternetConnectionRestored();

    // Attempt to reconnect
    if (Constants.userId.isNotEmpty && Constants.token.isNotEmpty) {
      _socketService?.connect(Constants.userId, Constants.token);

      // Wait for connection to establish, then mark as online
      Timer(const Duration(seconds: 2), () {
        if (_socketService?.isConnected == true) {
          _userStatusProvider?.updateCurrentUserStatus(true,
              emitToBackend: true);
        }
      });
    }
  }

  /// Handle socket disconnected
  void _handleSocketDisconnected() {
    // DISABLED: This method is no longer called since ping-based detection is disabled
    // The socket service handles its own connection monitoring and popup display
    if (kDebugMode) {
      print(
          'ConnectionMonitorService: _handleSocketDisconnected called but disabled - socket service handles its own monitoring');
    }
    return;
  }

  /// Handle ping response received
  void handlePingResponse() {
    // Cancel the ping timeout timer since we received a response
    _pingTimeoutTimer?.cancel();
    _pingTimeoutTimer = null;

    _lastSuccessfulPing = DateTime.now();
    _consecutiveFailures = 0;

    if (kDebugMode) {
      print('ConnectionMonitorService: Ping response received');
    }
  }

  /// Force check connectivity (for manual triggers)
  Future<void> forceConnectivityCheck() async {
    if (kDebugMode) {
      print('ConnectionMonitorService: Force connectivity check');
    }

    await _checkConnectivity();
  }

  /// Force ping test (for manual triggers)
  Future<void> forcePingTest() async {
    if (kDebugMode) {
      print('ConnectionMonitorService: Force ping test');
    }

    await _performPingTest();
  }

  /// Check if currently monitoring
  bool get isMonitoring => _isMonitoring;

  /// Get last known connectivity status
  bool get lastKnownConnectivity => _lastKnownConnectivity;

  /// Get time since last successful ping
  Duration? get timeSinceLastPing {
    if (_lastSuccessfulPing == null) return null;
    return DateTime.now().difference(_lastSuccessfulPing!);
  }

  /// Get consecutive failure count
  int get consecutiveFailures => _consecutiveFailures;

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _popupService.dispose();
    _userStatusProvider = null;
    _socketService = null;
  }
}
