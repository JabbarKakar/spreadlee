import 'package:flutter/material.dart';
import 'package:spreadlee/core/force_logout_handler.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';

/// Global service to handle force logout events throughout the app
class ForceLogoutService {
  static ForceLogoutService? _instance;
  static ChatService _chatService = ChatService(); // Use singleton
  static bool _isInitialized = false;
  static final List<Function(Map<String, dynamic>)> _listeners = [];
  static GlobalKey<NavigatorState>? _navigatorKey;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  ForceLogoutService._();

  static ForceLogoutService get instance {
    _instance ??= ForceLogoutService._();
    return _instance!;
  }

  /// Get the initialization status
  static bool get isInitialized => _isInitialized;

  /// Set global navigator key for force logout handling
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    if (kDebugMode) {
      print('=== Force Logout Service: Navigator Key Set ===');
    }
  }

  /// Initialize the force logout service
  static void initialize() {
    if (_isInitialized) return;

    if (kDebugMode) {
      print('=== Initializing Force Logout Service ===');
      print('Token available: ${Constants.token.isNotEmpty}');
      print('Base URL: ${Constants.baseUrl}');
    }

    // Only initialize if we have a valid token
    if (Constants.token.isEmpty) {
      if (kDebugMode) {
        print('Token not available, skipping initialization');
      }
      return;
    }

    _initializeChatService();
  }

  /// Reinitialize the service when token becomes available
  static void reinitialize() {
    if (kDebugMode) {
      print('=== Reinitializing Force Logout Service ===');
      print('Token available: ${Constants.token.isNotEmpty}');
    }

    // Dispose existing service if any
    // _chatService!.disconnect(); // This line was removed as per the edit hint

    _isInitialized = false;

    // Initialize if token is available
    if (Constants.token.isNotEmpty) {
      _initializeChatService();
    }
  }

  /// Initialize the chat service with current token
  static void _initializeChatService() {
    if (kDebugMode) {
      print('=== Initializing Chat Service for Force Logout ===');
      print('Base URL: ${Constants.baseUrl}');
      print(
          'Token: ${Constants.token.substring(0, min(10, Constants.token.length))}...');
    }

    try {
      _chatService = ChatService();

      _chatService.onForceLogout((data) {
        if (kDebugMode) {
          print('=== Force Logout Service: Event Received ===');
          print('Data: $data');
        }

        // Handle force logout immediately from any screen
        _handleForceLogoutEvent(data);

        // Also notify all listeners
        for (final listener in _listeners) {
          try {
            listener(data);
          } catch (e) {
            if (kDebugMode) {
              print('Error in force logout listener: $e');
            }
          }
        }
      });

      _isInitialized = true;

      if (kDebugMode) {
        print('=== Force Logout Service Initialized Successfully ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing force logout service: $e');
      }
      _isInitialized = false;
    }
  }

  /// Handle force logout event immediately from any screen
  static Future<void> _handleForceLogoutEvent(Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('=== Handling Force Logout Event Globally ===');
      print('Navigator key available: ${_navigatorKey != null}');
    }

    // Try to inform backend and clean up sockets before clearing storage
    try {
      if (kDebugMode) print('ForceLogoutService: attempting chat shutdown');
      await ChatService().shutdown();
    } catch (e) {
      if (kDebugMode) print('Error shutting down chat during force logout: $e');
    }

    // Clear all stored data
    await _clearAllStoredData();

    // Navigate to login screen from any screen
    if (_navigatorKey?.currentState != null) {
      try {
        _navigatorKey!.currentState!.pushNamedAndRemoveUntil(
          Routes.loginCustomerRoute,
          (route) => false,
        );

        if (kDebugMode) {
          print('=== Force Logout: Navigated to Login Screen ===');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error navigating to login screen: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('No navigator key available for force logout');
      }
    }
  }

  /// Clear all stored user data
  static Future<void> _clearAllStoredData() async {
    try {
      await _secureStorage.delete(key: 'token');
      await _secureStorage.delete(key: 'role');
      await _secureStorage.delete(key: 'subMainAccount');
      await _secureStorage.delete(key: 'username');
      await _secureStorage.delete(key: 'photoUrl');
      await _secureStorage.delete(key: 'commercialName');
      await _secureStorage.delete(key: 'publicName');
      await _secureStorage.delete(key: 'userId');
      await _secureStorage.delete(key: 'phoneNumber');
      await _secureStorage.write(key: "isUserLoggedIn", value: "false");

      // Clear constants
      Constants.token = "";
      Constants.role = "";
      Constants.subMainAccount = "";
      Constants.username = "";
      Constants.photoUrl = "";
      Constants.commercialName = "";
      Constants.publicName = "";
      Constants.userId = "";

      if (kDebugMode) {
        print('=== Force Logout: All User Data Cleared ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing stored data: $e');
      }
    }
  }

  /// Add a listener for force logout events
  static void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);

    // If service is not initialized but we have a token, try to initialize
    if (!_isInitialized && Constants.token.isNotEmpty) {
      _initializeChatService();
    }
  }

  /// Remove a listener for force logout events
  static void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  /// Handle force logout with context (for UI components that need context)
  static void handleForceLogoutWithContext(
      BuildContext context, Map<String, dynamic> data) {
    ForceLogoutHandler.handleForceLogout(context, data);
  }

  /// Disconnect the service
  static void dispose() {
    if (kDebugMode) {
      print('=== Disposing Force Logout Service ===');
    }

    _listeners.clear();
    // Attempt to shutdown chat service as part of dispose
    try {
      ChatService().shutdown();
    } catch (e) {
      if (kDebugMode)
        print('Error during ForceLogoutService.dispose shutdown: $e');
    }
    _isInitialized = false;
  }
}
