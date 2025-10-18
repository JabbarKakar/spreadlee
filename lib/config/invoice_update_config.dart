import 'package:spreadlee/core/constant.dart';

/// Configuration for invoice update service
class InvoiceUpdateConfig {
  /// Get the socket base URL from constants
  static String get socketBaseUrl => Constants.socketBaseUrl;

  /// Get the user token from constants
  static String get userToken => Constants.token;

  /// Get the user ID from constants
  static String get userId => Constants.userId;

  /// Get the user role from constants
  static String get userRole => Constants.role;

  /// Check if the service is properly configured
  static bool get isConfigured {
    return socketBaseUrl.isNotEmpty &&
        userToken.isNotEmpty &&
        userId.isNotEmpty &&
        userRole.isNotEmpty;
  }

  /// Get configuration status message
  static String get configurationStatus {
    if (isConfigured) {
      return 'Invoice update service is properly configured';
    }

    final missing = <String>[];
    if (socketBaseUrl.isEmpty) missing.add('socketBaseUrl');
    if (userToken.isEmpty) missing.add('userToken');
    if (userId.isEmpty) missing.add('userId');
    if (userRole.isEmpty) missing.add('userRole');

    return 'Missing configuration: ${missing.join(', ')}';
  }
}
