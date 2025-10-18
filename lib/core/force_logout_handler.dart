import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:flutter/foundation.dart';

class ForceLogoutHandler {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Handle force logout when account is deleted
  static void handleForceLogout(
      BuildContext context, Map<String, dynamic> data) {
    // Show dialog to user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Deleted'),
        content: Text(data['message'] ?? 'Your account has been deleted.'),
        actions: [
          TextButton(
            onPressed: () {
              // First, attempt to gracefully shutdown chats/sockets
              try {
                ChatService().shutdown();
              } catch (e) {
                if (kDebugMode)
                  print('Error during chat shutdown in ForceLogoutHandler: $e');
              }

              // Clear user data
              clearUserData();

              // Navigate to appropriate login screen based on role
              _navigateToLoginScreen(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Clear all user data from secure storage
  static Future<void> clearUserData() async {
    try {
      // Clear all authentication-related data
      await _secureStorage.delete(key: 'token');
      await _secureStorage.delete(key: 'userId');
      await _secureStorage.delete(key: 'role');
      await _secureStorage.delete(key: 'userContact');
      await _secureStorage.delete(key: 'userEmail');
      await _secureStorage.delete(key: 'commercialName');
      await _secureStorage.delete(key: 'publicName');
      await _secureStorage.delete(key: 'photoUrl');
      await _secureStorage.delete(key: 'subMainAccount');
      await _secureStorage.delete(key: 'username');
      await _secureStorage.delete(key: 'userNumber');
      await _secureStorage.delete(key: 'otpExpired');
      await _secureStorage.delete(key: 'passwordGen');

      // Set login status to false
      await _secureStorage.write(key: "isUserLoggedIn", value: "false");

      // Clear Constants
      Constants.token = "";
      Constants.userId = "";
      Constants.userContact = "";
      Constants.userEmail = "";
      Constants.role = "";
      Constants.commercialName = "";
      Constants.publicName = "";
      Constants.photoUrl = "";
      Constants.subMainAccount = "";
      Constants.username = "";
      Constants.userNumber = 0;

      debugPrint('All user data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  /// Clear authentication tokens specifically
  static Future<void> clearAuthTokens() async {
    try {
      await _secureStorage.delete(key: 'token');
      await _secureStorage.delete(key: 'userId');
      await _secureStorage.delete(key: 'role');
      await _secureStorage.write(key: "isUserLoggedIn", value: "false");

      // Clear Constants
      Constants.token = "";
      Constants.userId = "";
      Constants.role = "";

      debugPrint('Authentication tokens cleared successfully');
    } catch (e) {
      debugPrint('Error clearing authentication tokens: $e');
    }
  }

  /// Navigate to appropriate login screen based on current role
  static void _navigateToLoginScreen(BuildContext context) {
    // Determine which login screen to navigate to based on the current role
    // or default to customer login if role is not available
    final currentRole = Constants.role.toLowerCase();

    String loginRoute;
    if (currentRole == 'company' ||
        currentRole == 'subaccount' ||
        currentRole == 'influencer') {
      loginRoute = Routes.logincompanyRoute;
    } else {
      loginRoute = Routes.loginCustomerRoute;
    }

    // Navigate and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      loginRoute,
      (route) => false,
    );
  }

  /// Handle force logout without showing dialog (for programmatic logout)
  static Future<void> forceLogoutSilently(BuildContext context) async {
    await clearUserData();
    _navigateToLoginScreen(context);
  }
}
