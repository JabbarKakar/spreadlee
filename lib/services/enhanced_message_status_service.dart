import 'dart:async';
import 'package:flutter/foundation.dart';
import 'chat_service.dart';

/// Enhanced message status service that properly handles message read/unread,
/// delivery, and seen status according to backend implementation
class EnhancedMessageStatusService {
  static final EnhancedMessageStatusService _instance =
      EnhancedMessageStatusService._internal();
  factory EnhancedMessageStatusService() => _instance;
  EnhancedMessageStatusService._internal();

  final ChatService _chatService = ChatService();

  // Callbacks for status updates
  Function(String chatId, String messageId, MessageStatus status)?
      _onStatusUpdate;
  Function(String chatId, List<String> messageIds, MessageStatus status)?
      _onBulkStatusUpdate;

  // Track pending status updates to avoid duplicates
  final Map<String, Set<String>> _pendingReadUpdates = {};
  final Map<String, Set<String>> _pendingDeliveredUpdates = {};

  // Timer for debouncing status updates
  Timer? _readStatusTimer;
  Timer? _deliveredStatusTimer;

  /// Initialize the service
  void initialize() {
    _setupSocketListeners();
    if (kDebugMode) {
      print('EnhancedMessageStatusService: Initialized');
    }
  }

  /// Set callback for status updates
  void onStatusUpdate(
      Function(String chatId, String messageId, MessageStatus status)
          callback) {
    _onStatusUpdate = callback;
  }

  /// Set callback for bulk status updates
  void onBulkStatusUpdate(
      Function(String chatId, List<String> messageIds, MessageStatus status)
          callback) {
    _onBulkStatusUpdate = callback;
  }

  void _setupSocketListeners() {
    // Listen for messages read events
    _chatService.onMessagesRead((data) {
      _handleMessagesRead(data);
    });

    // Listen for messages delivered events
    _chatService.onMessagesDelivered((data) {
      _handleMessagesDelivered(data);
    });

    // Listen for message received events
    _chatService.onMessageReceived((data) {
      _handleMessageReceived(data);
    });

    // Listen for message seen updates
    _chatService.onMessageSeenUpdate((data) {
      _handleMessageSeenUpdate(data);
    });
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
        print('EnhancedMessageStatusService: Messages read event received');
        print('  ChatId: $chatId');
        print('  MessageIds: $messageIds');
        print('  UserId: $userId');
        print('  ReadAt: $readAt');
        print('  UnreadCount: $unreadCount');
      }

      if (chatId != null && messageIds.isNotEmpty) {
        final status = MessageStatus(
          isRead: true,
          isSeen: true,
          isReceived: true,
          isDelivered: true,
          readAt: readAt != null
              ? DateTime.tryParse(readAt.toString())
              : DateTime.now(),
          readBy: [userId],
        );

        _onBulkStatusUpdate?.call(chatId, messageIds, status);

        if (kDebugMode) {
          print(
              'EnhancedMessageStatusService: Updated ${messageIds.length} messages as read');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedMessageStatusService: Error handling messages read: $e');
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
        print(
            'EnhancedMessageStatusService: Messages delivered event received');
        print('  ChatId: $chatId');
        print('  MessageIds: $messageIds');
        print('  DeliveredBy: $deliveredBy');
        print('  DeliveredAt: $deliveredAt');
      }

      if (chatId != null && messageIds.isNotEmpty) {
        final status = MessageStatus(
          isRead: false,
          isSeen: false,
          isReceived: true,
          isDelivered: true,
          deliveredAt: deliveredAt != null
              ? DateTime.tryParse(deliveredAt.toString())
              : DateTime.now(),
        );

        _onBulkStatusUpdate?.call(chatId, messageIds, status);

        if (kDebugMode) {
          print(
              'EnhancedMessageStatusService: Updated ${messageIds.length} messages as delivered');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusService: Error handling messages delivered: $e');
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
        print('EnhancedMessageStatusService: Message received event received');
        print('  ChatId: $chatId');
        print('  MessageId: $messageId');
        print('  RecipientId: $recipientId');
      }

      if (chatId != null && messageId != null) {
        final status = MessageStatus(
          isRead: false,
          isSeen: false,
          isReceived: true,
          isDelivered: true,
          receivedAt: DateTime.now(),
        );

        _onStatusUpdate?.call(chatId, messageId, status);

        if (kDebugMode) {
          print(
              'EnhancedMessageStatusService: Updated message $messageId as received');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusService: Error handling message received: $e');
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
        print(
            'EnhancedMessageStatusService: Message seen update event received');
        print('  ChatId: $chatId');
        print('  MessageId: $messageId');
        print('  UserId: $userId');
        print('  SeenAt: $seenAt');
      }

      if (chatId != null && messageId != null) {
        final status = MessageStatus(
          isRead: false,
          isSeen: true,
          isReceived: true,
          isDelivered: true,
          seenAt: seenAt != null
              ? DateTime.tryParse(seenAt.toString())
              : DateTime.now(),
        );

        _onStatusUpdate?.call(chatId, messageId, status);

        if (kDebugMode) {
          print(
              'EnhancedMessageStatusService: Updated message $messageId as seen');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusService: Error handling message seen update: $e');
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
        print(
            'EnhancedMessageStatusService: No valid message IDs to mark as read');
      }
      return;
    }

    if (kDebugMode) {
      print('EnhancedMessageStatusService: Marking messages as read');
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
            'EnhancedMessageStatusService: No valid message IDs to mark as delivered');
      }
      return;
    }

    if (kDebugMode) {
      print('EnhancedMessageStatusService: Marking messages as delivered');
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
            'EnhancedMessageStatusService: Skipping delivery confirmation for temporary message: $messageId');
      }
      return;
    }

    if (kDebugMode) {
      print('EnhancedMessageStatusService: Confirming message received');
      print('  MessageId: $messageId');
      print('  ChatId: $chatId');
    }

    _chatService.confirmMessageReceived(messageId, chatId);
  }

  /// Send mark messages read request to backend
  void _sendMarkMessagesRead(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print(
          'EnhancedMessageStatusService: Sending mark_messages_read to backend');
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
      print(
          'EnhancedMessageStatusService: Sending mark_messages_delivered to backend');
      print('  ChatId: $chatId');
      print('  MessageIds: $messageIds');
    }

    _chatService.markMessagesAsDelivered(chatId, messageIds);

    // Clear pending updates
    _pendingDeliveredUpdates.remove(chatId);
  }

  /// Get message status for display
  MessageDisplayStatus getMessageDisplayStatus({
    required bool isRead,
    required bool isSeen,
    required bool isReceived,
    required bool isDelivered,
    required bool isSentByMe,
  }) {
    if (!isSentByMe) {
      // For received messages, we don't show status
      return MessageDisplayStatus.none;
    }

    if (isRead && isSeen) {
      return MessageDisplayStatus.read;
    } else if (isDelivered && isReceived) {
      return MessageDisplayStatus.delivered;
    } else if (isReceived) {
      return MessageDisplayStatus.sent;
    } else {
      return MessageDisplayStatus.pending;
    }
  }

  /// Dispose resources
  void dispose() {
    _readStatusTimer?.cancel();
    _deliveredStatusTimer?.cancel();
    _pendingReadUpdates.clear();
    _pendingDeliveredUpdates.clear();
  }
}

/// Message status data class
class MessageStatus {
  final bool isRead;
  final bool isSeen;
  final bool isReceived;
  final bool isDelivered;
  final DateTime? readAt;
  final DateTime? seenAt;
  final DateTime? receivedAt;
  final DateTime? deliveredAt;
  final List<String>? readBy;

  const MessageStatus({
    required this.isRead,
    required this.isSeen,
    required this.isReceived,
    required this.isDelivered,
    this.readAt,
    this.seenAt,
    this.receivedAt,
    this.deliveredAt,
    this.readBy,
  });

  MessageStatus copyWith({
    bool? isRead,
    bool? isSeen,
    bool? isReceived,
    bool? isDelivered,
    DateTime? readAt,
    DateTime? seenAt,
    DateTime? receivedAt,
    DateTime? deliveredAt,
    List<String>? readBy,
  }) {
    return MessageStatus(
      isRead: isRead ?? this.isRead,
      isSeen: isSeen ?? this.isSeen,
      isReceived: isReceived ?? this.isReceived,
      isDelivered: isDelivered ?? this.isDelivered,
      readAt: readAt ?? this.readAt,
      seenAt: seenAt ?? this.seenAt,
      receivedAt: receivedAt ?? this.receivedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readBy: readBy ?? this.readBy,
    );
  }
}

/// Message display status enum
enum MessageDisplayStatus {
  none,
  pending,
  sent,
  delivered,
  read,
}
