import 'dart:async';
import 'package:flutter/foundation.dart';
import 'chat_service.dart';

/// Simple message status handler that works with your existing codebase
class MessageStatusHandler {
  static final MessageStatusHandler _instance =
      MessageStatusHandler._internal();
  factory MessageStatusHandler() => _instance;
  MessageStatusHandler._internal();

  final ChatService _chatService = ChatService();

  // Callbacks for status updates - support multiple listeners
  final List<
          Function(
              String chatId, String messageId, Map<String, dynamic> status)>
      _statusUpdateListeners = [];
  final List<
      Function(String chatId, List<String> messageIds,
          Map<String, dynamic> status)> _bulkStatusUpdateListeners = [];

  // Track pending status updates to avoid duplicates
  final Map<String, Set<String>> _pendingReadUpdates = {};
  final Map<String, Set<String>> _pendingDeliveredUpdates = {};

  // Timer for debouncing status updates
  Timer? _readStatusTimer;
  Timer? _deliveredStatusTimer;

  /// Initialize the handler
  void initialize() {
    _setupSocketListeners();
    if (kDebugMode) {
      print('MessageStatusHandler: Initialized');
    }
  }

  /// Add listener for status updates
  void onStatusUpdate(
      Function(String chatId, String messageId, Map<String, dynamic> status)
          callback) {
    if (!_statusUpdateListeners.contains(callback)) {
      _statusUpdateListeners.add(callback);
      if (kDebugMode) {
        print(
            'MessageStatusHandler: Added status update listener (total: ${_statusUpdateListeners.length})');
      }
    }
  }

  /// Add listener for bulk status updates
  void onBulkStatusUpdate(
      Function(String chatId, List<String> messageIds,
              Map<String, dynamic> status)
          callback) {
    if (!_bulkStatusUpdateListeners.contains(callback)) {
      _bulkStatusUpdateListeners.add(callback);
      if (kDebugMode) {
        print(
            'MessageStatusHandler: Added bulk status update listener (total: ${_bulkStatusUpdateListeners.length})');
      }
    }
  }

  /// Remove listener for status updates
  void removeStatusUpdateListener(
      Function(String chatId, String messageId, Map<String, dynamic> status)
          callback) {
    _statusUpdateListeners.remove(callback);
    if (kDebugMode) {
      print(
          'MessageStatusHandler: Removed status update listener (total: ${_statusUpdateListeners.length})');
    }
  }

  /// Remove listener for bulk status updates
  void removeBulkStatusUpdateListener(
      Function(String chatId, List<String> messageIds,
              Map<String, dynamic> status)
          callback) {
    _bulkStatusUpdateListeners.remove(callback);
    if (kDebugMode) {
      print(
          'MessageStatusHandler: Removed bulk status update listener (total: ${_bulkStatusUpdateListeners.length})');
    }
  }

  void _setupSocketListeners() {
    if (kDebugMode) {
      print('MessageStatusHandler: Setting up socket listeners...');
    }

    // Set up callbacks for each event type
    _chatService.onMessagesRead((data) {
      if (kDebugMode) {
        print('MessageStatusHandler: Received messages_read event: $data');
      }
      _handleMessagesRead(data);
    });

    _chatService.onMessagesDelivered((data) {
      if (kDebugMode) {
        print('MessageStatusHandler: Received messages_delivered event: $data');
      }
      _handleMessagesDelivered(data);
    });

    _chatService.onMessageReceived((data) {
      if (kDebugMode) {
        print('MessageStatusHandler: Received message_received event: $data');
      }
      _handleMessageReceived(data);
    });

    _chatService.onMessageSeenUpdate((data) {
      if (kDebugMode) {
        print(
            'MessageStatusHandler: Received message_seen_update event: $data');
      }
      _handleMessageSeenUpdate(data);
    });

    // Remove message_sent callback - let the cubit handle it exclusively
    // This prevents conflicts between MessageStatusHandler and ChatCubit
    if (kDebugMode) {
      print(
          'MessageStatusHandler: Skipping message_sent callback - handled by cubit');
    }

    _chatService.onMessagesUpdated((data) {
      if (kDebugMode) {
        print('MessageStatusHandler: Received messages_updated event: $data');
      }
      _handleMessagesUpdated(data);
    });

    if (kDebugMode) {
      print('MessageStatusHandler: Socket listeners setup complete');
    }
  }

  /// Handle messages read event from backend
  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] ?? data['chat_id'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);
      final userId = data['userId'] ?? data['user_id'];
      final readAt = data['readAt'] ?? data['read_at'];
      final unreadCount = data['unreadCount'] ?? data['unread_count'];

      if (kDebugMode) {
        print('MessageStatusHandler: Messages read event received');
        print('  ChatId: $chatId');
        print('  MessageIds: $messageIds');
        print('  UserId: $userId');
        print('  ReadAt: $readAt');
        print('  UnreadCount: $unreadCount');
      }

      if (chatId != null && messageIds.isNotEmpty) {
        final status = {
          'isRead': true,
          'isSeen': true,
          'isReceived': true,
          'isDelivered': true,
          'readAt': readAt,
          'readBy': [userId],
        };

        // Notify all bulk status update listeners
        for (final listener in _bulkStatusUpdateListeners) {
          try {
            listener(chatId, messageIds, status);
          } catch (e) {
            if (kDebugMode) {
              print(
                  'MessageStatusHandler: Error in bulk status update listener: $e');
            }
          }
        }

        if (kDebugMode) {
          print(
              'MessageStatusHandler: Updated ${messageIds.length} messages as read');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MessageStatusHandler: Error handling messages read: $e');
      }
    }
  }

  /// Handle messages delivered event from backend
  void _handleMessagesDelivered(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] ?? data['chat_id'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);
      final deliveredBy = data['deliveredBy'] ?? data['delivered_by'];
      final deliveredAt = data['deliveredAt'] ?? data['delivered_at'];

      if (kDebugMode) {
        print('MessageStatusHandler: Messages delivered event received');
        print('  ChatId: $chatId');
        print('  MessageIds: $messageIds');
        print('  DeliveredBy: $deliveredBy');
        print('  DeliveredAt: $deliveredAt');
      }

      if (chatId != null && messageIds.isNotEmpty) {
        // Only mark as delivered if the recipient is actually online
        // The backend should only send this event when the recipient is online
        final status = {
          'isRead': false,
          'isSeen': false,
          'isReceived': true,
          'isDelivered': true, // Only true when recipient is online
          'deliveredAt': deliveredAt,
        };

        // Notify all bulk status update listeners
        for (final listener in _bulkStatusUpdateListeners) {
          try {
            listener(chatId, messageIds, status);
          } catch (e) {
            if (kDebugMode) {
              print(
                  'MessageStatusHandler: Error in bulk status update listener: $e');
            }
          }
        }

        if (kDebugMode) {
          print(
              'MessageStatusHandler: Updated ${messageIds.length} messages as delivered');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MessageStatusHandler: Error handling messages delivered: $e');
      }
    }
  }

  /// Handle message received event from backend
  void _handleMessageReceived(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] ?? data['chat_id'];
      final messageId = data['messageId'] ?? data['message_id'];
      final recipientId = data['recipientId'] ?? data['recipient_id'];

      if (kDebugMode) {
        print('MessageStatusHandler: Message received event received');
        print('  ChatId: $chatId');
        print('  MessageId: $messageId');
        print('  RecipientId: $recipientId');
      }

      if (chatId != null && messageId != null) {
        // Only mark as received when the message actually reaches the recipient's device
        // This event should only be triggered when the recipient is online and receives the message
        final status = {
          'isRead': false,
          'isSeen': false,
          'isReceived': true, // Message was received by the server
          'isDelivered': true, // Message was delivered to recipient's device
          'receivedAt': DateTime.now().toIso8601String(),
        };

        // Notify all status update listeners
        for (final listener in _statusUpdateListeners) {
          try {
            listener(chatId, messageId, status);
          } catch (e) {
            if (kDebugMode) {
              print(
                  'MessageStatusHandler: Error in status update listener: $e');
            }
          }
        }

        if (kDebugMode) {
          print('MessageStatusHandler: Updated message $messageId as received');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MessageStatusHandler: Error handling message received: $e');
      }
    }
  }

  /// Handle message seen update event from backend
  void _handleMessageSeenUpdate(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] ?? data['chat_id'];
      final messageId = data['messageId'] ?? data['message_id'];
      final userId = data['userId'] ?? data['user_id'];
      final seenAt = data['seenAt'] ?? data['seen_at'];

      if (kDebugMode) {
        print('MessageStatusHandler: Message seen update event received');
        print('  ChatId: $chatId');
        print('  MessageId: $messageId');
        print('  UserId: $userId');
        print('  SeenAt: $seenAt');
      }

      if (chatId != null && messageId != null) {
        final status = {
          'isRead': false,
          'isSeen': true,
          'isReceived': true,
          'isDelivered': true,
          'seenAt': seenAt,
        };

        // Notify all status update listeners
        for (final listener in _statusUpdateListeners) {
          try {
            listener(chatId, messageId, status);
          } catch (e) {
            if (kDebugMode) {
              print(
                  'MessageStatusHandler: Error in status update listener: $e');
            }
          }
        }

        if (kDebugMode) {
          print('MessageStatusHandler: Updated message $messageId as seen');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MessageStatusHandler: Error handling message seen update: $e');
      }
    }
  }

  /// Handle messages updated event from backend
  void _handleMessagesUpdated(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] ?? data['chat_id'];
      final messages = data['messages'] ?? [];

      if (kDebugMode) {
        print('MessageStatusHandler: Messages updated event received');
        print('  ChatId: $chatId');
        print('  Messages count: ${messages.length}');
      }

      if (chatId != null && messages is List) {
        for (final messageData in messages) {
          if (messageData is Map<String, dynamic>) {
            final messageId = messageData['_id'] ?? messageData['messageId'];
            final isSeen = messageData['isSeen'] ?? false;
            final isReceived = messageData['isReceived'] ?? false;
            final readBy = messageData['readBy'] ?? [];

            if (messageId != null) {
              final status = {
                'isRead': readBy.isNotEmpty,
                'isSeen': isSeen,
                'isReceived': isReceived,
                'isDelivered': true,
                'readBy': readBy,
              };

              // Notify all status update listeners
              for (final listener in _statusUpdateListeners) {
                try {
                  listener(chatId, messageId, status);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                        'MessageStatusHandler: Error in status update listener: $e');
                  }
                }
              }

              if (kDebugMode) {
                print(
                    'MessageStatusHandler: Updated message $messageId status');
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MessageStatusHandler: Error handling messages updated: $e');
      }
    }
  }

  /// Mark messages as read (triggers backend event)
  void markMessagesAsRead(String chatId, List<String> messageIds) {
    if (messageIds.isEmpty) return;

    // Filter out temporary/optimistic IDs (backend will reject them)
    final validMessageIds = messageIds
        .where((id) =>
                !id.startsWith('temp_') &&
                !id.startsWith('optimistic_') &&
                id.length > 10 // Basic validation for real ObjectIds
            )
        .toList();

    if (validMessageIds.isEmpty) {
      if (kDebugMode) {
        print('MessageStatusHandler: No valid message IDs to mark as read');
      }
      return;
    }

    if (kDebugMode) {
      print('MessageStatusHandler: Marking messages as read');
      print('  ChatId: $chatId');
      print('  ValidMessageIds: $validMessageIds');
      print(
          '  Filtered out: ${messageIds.length - validMessageIds.length} temporary IDs');
    }

    // Add to pending updates to avoid duplicates
    _pendingReadUpdates.putIfAbsent(chatId, () => <String>{});
    _pendingReadUpdates[chatId]!.addAll(validMessageIds);

    // Debounce the request
    _readStatusTimer?.cancel();
    _readStatusTimer = Timer(const Duration(milliseconds: 500), () {
      _sendMarkMessagesRead(chatId, validMessageIds);
    });
  }

  /// Mark messages as delivered (triggers backend event)
  void markMessagesAsDelivered(String chatId, List<String> messageIds) {
    if (messageIds.isEmpty) return;

    // Filter out temporary/optimistic IDs
    final validMessageIds = messageIds
        .where((id) =>
            !id.startsWith('temp_') &&
            !id.startsWith('optimistic_') &&
            id.length > 10)
        .toList();

    if (validMessageIds.isEmpty) {
      if (kDebugMode) {
        print(
            'MessageStatusHandler: No valid message IDs to mark as delivered');
      }
      return;
    }

    if (kDebugMode) {
      print('MessageStatusHandler: Marking messages as delivered');
      print('  ChatId: $chatId');
      print('  ValidMessageIds: $validMessageIds');
    }

    // Add to pending updates
    _pendingDeliveredUpdates.putIfAbsent(chatId, () => <String>{});
    _pendingDeliveredUpdates[chatId]!.addAll(validMessageIds);

    // Debounce the request
    _deliveredStatusTimer?.cancel();
    _deliveredStatusTimer = Timer(const Duration(milliseconds: 500), () {
      _sendMarkMessagesDelivered(chatId, validMessageIds);
    });
  }

  /// Confirm message received (triggers backend event)
  void confirmMessageReceived(String messageId, String chatId) {
    if (messageId.startsWith('temp_') || messageId.startsWith('optimistic_')) {
      if (kDebugMode) {
        print(
            'MessageStatusHandler: Skipping delivery confirmation for temporary message: $messageId');
      }
      return;
    }

    if (kDebugMode) {
      print('MessageStatusHandler: Confirming message received');
      print('  MessageId: $messageId');
      print('  ChatId: $chatId');
    }

    _chatService.confirmMessageReceived(messageId, chatId);
  }

  /// Send mark messages read request to backend
  void _sendMarkMessagesRead(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print('MessageStatusHandler: Sending mark_messages_read to backend');
      print('  ChatId: $chatId');
      print('  MessageIds: $messageIds');
    }

    _chatService.markMessagesAsRead(chatId, messageIds);

    // Clear pending updates
    _pendingReadUpdates.remove(chatId);
  }

  /// Send mark messages delivered request to backend
  void _sendMarkMessagesDelivered(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print('MessageStatusHandler: Sending mark_messages_delivered to backend');
      print('  ChatId: $chatId');
      print('  MessageIds: $messageIds');
    }

    _chatService.markMessagesAsDelivered(chatId, messageIds);

    // Clear pending updates
    _pendingDeliveredUpdates.remove(chatId);
  }

  /// Get message status for display
  String getMessageDisplayStatus({
    required bool isRead,
    required bool isSeen,
    required bool isReceived,
    required bool isDelivered,
    required bool isSentByMe,
    bool? isRecipientOnline, // Add recipient online status
  }) {
    if (!isSentByMe) {
      // For received messages, we don't show status
      return 'none';
    }

    if (isRead && isSeen) {
      return 'read';
    } else if (isDelivered && isReceived) {
      return 'delivered';
    } else if (isReceived) {
      // Show "sent" status when message is received by server, regardless of recipient online status
      return 'sent';
    } else {
      return 'pending';
    }
  }

  /// Dispose resources
  void dispose() {
    _readStatusTimer?.cancel();
    _deliveredStatusTimer?.cancel();
    _pendingReadUpdates.clear();
    _pendingDeliveredUpdates.clear();
    _statusUpdateListeners.clear();
    _bulkStatusUpdateListeners.clear();
  }
}
