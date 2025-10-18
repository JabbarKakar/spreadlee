import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constant.dart';

/// Service to handle offline status emission via HTTP as backup to socket
/// This ensures user status is updated even if socket connection fails
class OfflineStatusService {
  static final OfflineStatusService _instance =
      OfflineStatusService._internal();
  factory OfflineStatusService() => _instance;
  OfflineStatusService._internal();

  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Emit offline status via HTTP API
  Future<void> emitOfflineStatus({
    required String userId,
    required String reason,
    String? token,
  }) async {
    if (kDebugMode) {
      print('OfflineStatusService: Emitting offline status via HTTP');
      print('OfflineStatusService: UserId: $userId, Reason: $reason');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}/users/set-offline'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userId': userId,
              'status': 'offline',
              'reason': reason,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print(
              'OfflineStatusService: Successfully emitted offline status via HTTP');
        }
        _retryAttempts = 0; // Reset retry attempts on success
      } else {
        if (kDebugMode) {
          print(
              'OfflineStatusService: HTTP request failed with status: ${response.statusCode}');
        }
        _scheduleRetry(userId, reason, token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('OfflineStatusService: HTTP request failed with error: $e');
      }
      _scheduleRetry(userId, reason, token);
    }
  }

  /// Schedule retry for failed offline status emission
  void _scheduleRetry(String userId, String reason, String? token) {
    if (_retryAttempts >= _maxRetryAttempts) {
      if (kDebugMode) {
        print('OfflineStatusService: Max retry attempts reached, giving up');
      }
      return;
    }

    _retryAttempts++;

    if (kDebugMode) {
      print(
          'OfflineStatusService: Scheduling retry attempt $_retryAttempts/$_maxRetryAttempts');
    }

    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      emitOfflineStatus(
        userId: userId,
        reason: '${reason}_retry_$_retryAttempts',
        token: token,
      );
    });
  }

  /// Force emit offline status with current user credentials
  Future<void> forceEmitCurrentUserOffline(
      {String reason = 'force_offline'}) async {
    if (Constants.userId.isNotEmpty) {
      await emitOfflineStatus(
        userId: Constants.userId,
        reason: reason,
        token: Constants.token,
      );
    } else {
      if (kDebugMode) {
        print('OfflineStatusService: Cannot emit offline status - no user ID');
      }
    }
  }

  /// Cancel any pending retries
  void cancelRetries() {
    _retryTimer?.cancel();
    _retryAttempts = 0;
  }

  /// Dispose resources
  void dispose() {
    cancelRetries();
  }
}
