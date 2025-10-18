import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/services/enhanced_message_status_handler.dart';

/// Helper class to integrate enhanced message status handler with existing chat system
class ChatStatusIntegrationHelper {
  static final ChatStatusIntegrationHelper _instance =
      ChatStatusIntegrationHelper._internal();
  factory ChatStatusIntegrationHelper() => _instance;
  ChatStatusIntegrationHelper._internal();

  final EnhancedMessageStatusHandler _statusHandler =
      EnhancedMessageStatusHandler();
  bool _isInitialized = false;

  /// Initialize the helper
  void initialize() {
    if (_isInitialized) return;

    _statusHandler.initialize();
    _isInitialized = true;

    if (kDebugMode) {
      print('ChatStatusIntegrationHelper: Initialized');
    }
  }

  /// Mark messages as read when they become visible
  void markMessagesAsRead(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print('ChatStatusIntegrationHelper: Marking messages as read');
      print('Chat ID: $chatId, Message IDs: $messageIds');
    }

    if (messageIds.isEmpty) return;

    try {
      for (final messageId in messageIds) {
        _statusHandler.updateMessageStatus(
          chatId: chatId,
          messageId: messageId,
          isRead: true,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'ChatStatusIntegrationHelper: Error marking messages as read: $e');
      }
    }
  }

  /// Mark a single message as read
  void markMessageAsRead(String chatId, String messageId) {
    markMessagesAsRead(chatId, [messageId]);
  }

  /// Mark messages as delivered
  void markMessagesAsDelivered(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print('ChatStatusIntegrationHelper: Marking messages as delivered');
      print('Chat ID: $chatId, Message IDs: $messageIds');
    }

    if (messageIds.isEmpty) return;

    try {
      for (final messageId in messageIds) {
        _statusHandler.updateMessageStatus(
          chatId: chatId,
          messageId: messageId,
          isDelivered: true,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'ChatStatusIntegrationHelper: Error marking messages as delivered: $e');
      }
    }
  }

  /// Mark a single message as delivered
  void markMessageAsDelivered(String chatId, String messageId) {
    markMessagesAsDelivered(chatId, [messageId]);
  }

  /// Mark a message as received
  void markMessageAsReceived(String chatId, String messageId) {
    if (kDebugMode) {
      print('ChatStatusIntegrationHelper: Marking message as received');
      print('Chat ID: $chatId, Message ID: $messageId');
    }

    try {
      _statusHandler.updateMessageStatus(
        chatId: chatId,
        messageId: messageId,
        isReceived: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print(
            'ChatStatusIntegrationHelper: Error marking message as received: $e');
      }
    }
  }

  /// Get current message status
  MessageStatus? getMessageStatus(String chatId, String messageId) {
    return _statusHandler.getMessageStatus(chatId, messageId);
  }

  /// Get all message statuses for a chat
  List<MessageStatus> getChatMessageStatuses(String chatId) {
    return _statusHandler.getChatMessageStatuses(chatId);
  }

  /// Clear status cache for a specific chat
  void clearChatStatusCache(String chatId) {
    _statusHandler.clearChatStatusCache(chatId);
  }

  /// Get the status update stream
  Stream<MessageStatusUpdate> get statusUpdateStream =>
      _statusHandler.statusUpdateStream;

  /// Dispose the helper
  void dispose() {
    _statusHandler.dispose();
    _isInitialized = false;

    if (kDebugMode) {
      print('ChatStatusIntegrationHelper: Disposed');
    }
  }

  /// Check if a message should be marked as read
  bool shouldMarkAsRead(ChatMessage message, String currentUserId) {
    // Only mark as read if:
    // 1. Message is not from current user
    // 2. Message is not already read
    // 3. Message is not a temporary message
    return message.messageCreator?.id != currentUserId &&
        message.isRead != true &&
        message.isTemp != true;
  }

  /// Get human-readable status text for a message
  String getStatusText(ChatMessage message, String chatId) {
    final status = getMessageStatus(chatId, message.id);

    if (status != null) {
      if (status.isSeen) {
        return 'Seen';
      } else if (status.isRead) {
        return 'Read';
      } else if (status.isReceived) {
        return 'Delivered';
      } else {
        return 'Sent';
      }
    }

    // Fallback to message properties
    if (message.isSeen == true) {
      return 'Seen';
    } else if (message.isRead == true) {
      return 'Read';
    } else if (message.isReceived == true) {
      return 'Delivered';
    } else {
      return 'Sent';
    }
  }

  /// Get status icon for a message
  IconData getStatusIcon(ChatMessage message, String chatId) {
    final status = getMessageStatus(chatId, message.id);

    if (status != null) {
      if (status.isSeen) {
        return Icons.done_all; // Blue double check
      } else if (status.isRead) {
        return Icons.done_all; // Gray double check
      } else if (status.isReceived) {
        return Icons.done; // Single check
      } else {
        return Icons.check; // Clock
      }
    }

    // Fallback to message properties
    if (message.isSeen == true) {
      return Icons.done_all;
    } else if (message.isRead == true) {
      return Icons.done_all;
    } else if (message.isReceived == true) {
      return Icons.done;
    } else {
      return Icons.check;
    }
  }

  /// Get status color for a message
  Color getStatusColor(ChatMessage message, String chatId) {
    final status = getMessageStatus(chatId, message.id);

    if (status != null) {
      if (status.isSeen) {
        return Colors.blue; // Blue for seen
      } else if (status.isRead) {
        return Colors.grey; // Gray for read
      } else if (status.isReceived) {
        return Colors.grey; // Gray for delivered
      } else {
        return Colors.grey; // Gray for sent
      }
    }

    // Fallback to message properties
    if (message.isSeen == true) {
      return Colors.blue;
    } else if (message.isRead == true) {
      return Colors.grey;
    } else if (message.isReceived == true) {
      return Colors.grey;
    } else {
      return Colors.grey;
    }
  }
}
