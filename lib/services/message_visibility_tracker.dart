import 'dart:async';
import 'package:flutter/foundation.dart';
import 'message_status_handler.dart';

/// Tracks which messages are visible on screen and handles read status updates
class MessageVisibilityTracker {
  static final MessageVisibilityTracker _instance =
      MessageVisibilityTracker._internal();
  factory MessageVisibilityTracker() => _instance;
  MessageVisibilityTracker._internal();

  final MessageStatusHandler _statusHandler = MessageStatusHandler();

  // Track visible messages by chat ID
  final Map<String, Set<String>> _visibleMessages = {};

  // Track messages that should be marked as read
  final Map<String, Set<String>> _messagesToMarkAsRead = {};

  // Timer for debouncing read status updates
  Timer? _readStatusTimer;

  // Debounce delay for marking messages as read
  static const Duration _readStatusDelay = Duration(milliseconds: 1000);

  /// Initialize the tracker
  void initialize() {
    _statusHandler.initialize();
    if (kDebugMode) {
      print('MessageVisibilityTracker: Initialized');
    }
  }

  /// Mark a message as visible in a chat
  void markMessageAsVisible(
      String chatId, String messageId, bool isFromCurrentUser) {
    // Only track visibility for messages not sent by current user
    if (isFromCurrentUser) return;

    _visibleMessages.putIfAbsent(chatId, () => <String>{});
    _visibleMessages[chatId]!.add(messageId);

    if (kDebugMode) {
      print(
          'MessageVisibilityTracker: Message $messageId marked as visible in chat $chatId');
    }
  }

  /// Mark a message as no longer visible
  void markMessageAsInvisible(String chatId, String messageId) {
    _visibleMessages[chatId]?.remove(messageId);

    if (kDebugMode) {
      print(
          'MessageVisibilityTracker: Message $messageId marked as invisible in chat $chatId');
    }
  }

  /// Get all visible messages for a chat
  Set<String> getVisibleMessages(String chatId) {
    return _visibleMessages[chatId] ?? <String>{};
  }

  /// Mark all visible messages in a chat as read
  void markVisibleMessagesAsRead(String chatId, String currentUserId) {
    final visibleMessages = _visibleMessages[chatId];
    if (visibleMessages == null || visibleMessages.isEmpty) return;

    // Filter out temporary IDs and messages sent by current user
    final messagesToMarkAsRead = visibleMessages
        .where((messageId) =>
            !messageId.startsWith('temp_') &&
            !messageId.startsWith('optimistic_') &&
            messageId.length > 10)
        .toList();

    if (messagesToMarkAsRead.isEmpty) return;

    _messagesToMarkAsRead.putIfAbsent(chatId, () => <String>{});
    _messagesToMarkAsRead[chatId]!.addAll(messagesToMarkAsRead);

    if (kDebugMode) {
      print(
          'MessageVisibilityTracker: Scheduling ${messagesToMarkAsRead.length} messages to be marked as read in chat $chatId');
      print('Messages: $messagesToMarkAsRead');
    }

    // Debounce the read status update
    _readStatusTimer?.cancel();
    _readStatusTimer = Timer(_readStatusDelay, () {
      _sendReadStatusUpdate(chatId);
    });
  }

  /// Send read status update to backend
  void _sendReadStatusUpdate(String chatId) {
    final messagesToRead = _messagesToMarkAsRead[chatId];
    if (messagesToRead == null || messagesToRead.isEmpty) return;

    final messageList = messagesToRead.toList();

    if (kDebugMode) {
      print(
          'MessageVisibilityTracker: Sending read status for ${messageList.length} messages in chat $chatId');
    }

    // Use the status handler to mark messages as read
    _statusHandler.markMessagesAsRead(chatId, messageList);

    // Clear the pending messages
    _messagesToMarkAsRead[chatId]!.clear();
  }

  /// Clear all tracking for a chat (when leaving chat)
  void clearChatTracking(String chatId) {
    _visibleMessages.remove(chatId);
    _messagesToMarkAsRead.remove(chatId);

    if (kDebugMode) {
      print('MessageVisibilityTracker: Cleared tracking for chat $chatId');
    }
  }

  /// Dispose resources
  void dispose() {
    _readStatusTimer?.cancel();
    _visibleMessages.clear();
    _messagesToMarkAsRead.clear();
  }
}
