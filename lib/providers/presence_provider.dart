import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/socket_service.dart';
import '../models/user_presence.dart';

/// Clean provider for managing user presence data in UI components
class PresenceProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  final Map<String, UserPresence> _presences = {};

  // Rate limiting for presence requests
  DateTime? _lastPresenceRequest;
  static const Duration _presenceRequestCooldown = Duration(seconds: 1);

  // Track recent status changes to prevent bulk updates from overriding them
  final Map<String, DateTime> _recentStatusChanges = {};
  static const Duration _statusChangeProtection = Duration(seconds: 5);

  Map<String, UserPresence> get presences => Map.unmodifiable(_presences);

  PresenceProvider() {
    if (kDebugMode) {
      print('PresenceProvider: Constructor called');
    }

    // Delay the setup to ensure the socket service is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPresenceListener();
    });
  }

  void _setupPresenceListener() {
    if (kDebugMode) {
      print('PresenceProvider: Setting up presence listener');
      print(
          'PresenceProvider: Socket connected: ${_socketService.isConnected}');
    }

    _socketService.presenceStream.listen((data) {
      if (kDebugMode) {
        print('PresenceProvider: Received event: $data');
      }

      final type = data['type'];

      if (type == 'presence_change') {
        _handleSinglePresenceChange(data);
      } else if (type == 'presence_bulk_update') {
        _handleBulkPresenceUpdate(data);
      } else if (type == 'status_change') {
        _handleStatusChange(data);
      } else if (kDebugMode) {
        print('PresenceProvider: Unknown event type: $type');
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('PresenceProvider: Error in presence stream: $error');
      }
    });
  }

  void _handleSinglePresenceChange(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('PresenceProvider: Handling single presence change: $data');
    }

    try {
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

        _presences[userId] = presence;

        if (kDebugMode) {
          print('PresenceProvider: Updated presence for $userId: $status');
          print('PresenceProvider: Total presences: ${_presences.length}');
        }

        notifyListeners();
      } else {
        if (kDebugMode) {
          print(
              'PresenceProvider: Invalid data for presence change: userId=$userId, status=$status');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('PresenceProvider: Error in single presence change: $e');
      }
    }
  }

  void _handleBulkPresenceUpdate(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('PresenceProvider: Handling bulk presence update: $data');
    }

    final presences = data['presences'];

    // Add null check and type validation
    if (presences == null) {
      if (kDebugMode) {
        print('PresenceProvider: presences field is null');
      }
      return;
    }

    if (presences is! Map) {
      if (kDebugMode) {
        print(
            'PresenceProvider: presences is not a Map: ${presences.runtimeType}');
      }
      return;
    }

    try {
      for (final entry in presences.entries) {
        final userId = entry.key;
        final presenceData = entry.value;

        // Check if presenceData is a Map and convert it safely
        if (presenceData is Map) {
          // Convert to Map<String, dynamic> safely
          final safePresenceData = Map<String, dynamic>.from(presenceData);

          if (safePresenceData['status'] != null) {
            // Check if there was a recent status change that should be protected
            final recentStatusChange = _recentStatusChanges[userId];
            final now = DateTime.now();

            if (recentStatusChange != null &&
                now.difference(recentStatusChange) < _statusChangeProtection) {
              if (kDebugMode) {
                print(
                    'PresenceProvider: Skipping bulk update for $userId - recent status change protected');
              }
              continue; // Skip this user's update
            }

            final presence = UserPresence(
              userId: userId,
              status: safePresenceData['status'],
              lastSeen: safePresenceData['lastSeen'] != null
                  ? DateTime.tryParse(safePresenceData['lastSeen'])
                  : null,
              lastActive: safePresenceData['lastActive'] != null
                  ? DateTime.tryParse(safePresenceData['lastActive'])
                  : null,
            );

            _presences[userId] = presence;

            if (kDebugMode) {
              print(
                  'PresenceProvider: Updated presence for $userId: ${safePresenceData['status']}');
            }
          }
        } else {
          if (kDebugMode) {
            print(
                'PresenceProvider: Invalid presence data format for user $userId: $presenceData');
          }
        }
      }

      if (kDebugMode) {
        print(
            'PresenceProvider: Bulk update completed. Total presences: ${_presences.length}');
      }

      notifyListeners();

      // Clean up old status change tracking
      _cleanupOldStatusChanges();
    } catch (e) {
      if (kDebugMode) {
        print('PresenceProvider: Error in bulk presence update: $e');
      }
    }
  }

  /// Clean up old status change tracking entries
  void _cleanupOldStatusChanges() {
    final now = DateTime.now();
    _recentStatusChanges.removeWhere((userId, timestamp) =>
        now.difference(timestamp) > _statusChangeProtection);
  }

  /// Handle status change events (for backward compatibility with user_status_change)
  void _handleStatusChange(Map<String, dynamic> data) {
    try {
      final userId = data['userId'] as String?;
      final isOnline = data['isOnline'] as bool?;

      if (userId == null || isOnline == null) {
        if (kDebugMode) {
          print('PresenceProvider: Invalid status change data: $data');
        }
        return;
      }

      // Update the presence based on status change
      final currentPresence = _presences[userId];
      final newPresence = UserPresence(
        userId: userId,
        status: isOnline ? 'online' : 'offline',
        lastSeen: isOnline
            ? DateTime.now()
            : (currentPresence?.lastSeen ?? DateTime.now()),
        lastActive: DateTime.now(),
      );

      _presences[userId] = newPresence;

      // Track this status change to prevent bulk updates from overriding it
      _recentStatusChanges[userId] = DateTime.now();

      if (kDebugMode) {
        print(
            'PresenceProvider: Updated presence for $userId: ${isOnline ? 'online' : 'offline'}');
        print('PresenceProvider: Total presences: ${_presences.length}');
        print('PresenceProvider: Current presence data: ${_presences[userId]}');
        print('PresenceProvider: Calling notifyListeners()');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('PresenceProvider: Error handling status change: $e');
      }
    }
  }

  UserPresence? getUserPresence(String userId) {
    return _presences[userId];
  }

  bool isUserOnline(String userId) {
    final presence = _presences[userId];
    final isOnline = presence?.isOnline ?? false;
    // Reduced logging - only log when presence data exists
    if (kDebugMode && presence != null) {
      print('PresenceProvider: isUserOnline($userId) -> $isOnline');
    }
    return isOnline;
  }

  String getUserStatus(String userId) {
    final presence = _presences[userId];
    return presence?.statusDisplay ?? 'Offline';
  }

  void requestPresenceForUsers(List<String> userIds) {
    // Filter out users we already have presence data for
    final newUserIds =
        userIds.where((userId) => !_presences.containsKey(userId)).toList();

    // If no new users to request, return early
    if (newUserIds.isEmpty) {
      return;
    }

    // Rate limiting: prevent too many rapid requests
    final now = DateTime.now();
    if (_lastPresenceRequest != null &&
        now.difference(_lastPresenceRequest!) < _presenceRequestCooldown) {
      if (kDebugMode) {
        print(
            'PresenceProvider: Rate limiting presence request - too soon since last request');
      }
      return;
    }
    _lastPresenceRequest = now;

    if (kDebugMode) {
      print('PresenceProvider: Requesting presence for new users: $newUserIds');
      print(
          'PresenceProvider: Socket connected: ${_socketService.isConnected}');
    }

    if (_socketService.isConnected) {
      _socketService.requestPresenceData(newUserIds);
    } else {
      if (kDebugMode) {
        print(
            'PresenceProvider: Socket not connected, cannot request presence data');
      }
    }
  }

  /// Test method to manually add presence data for debugging
  void addTestPresence(String userId, String status) {
    if (kDebugMode) {
      print('PresenceProvider: Adding test presence for $userId: $status');
    }

    final presence = UserPresence(
      userId: userId,
      status: status,
      lastSeen: DateTime.now(),
      lastActive: DateTime.now(),
    );

    _presences[userId] = presence;
    notifyListeners();

    if (kDebugMode) {
      print(
          'PresenceProvider: Test presence added. Total presences: ${_presences.length}');
    }
  }
}
