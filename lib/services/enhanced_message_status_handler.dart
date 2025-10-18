import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/models/chat_response_model.dart';

enum MessageStatusType {
  seen,
  received,
  delivered,
  read,
}

class MessageStatusUpdate {
  final MessageStatusType type;
  final String chatId;
  final String messageId;
  final String userId;
  final MessageStatus status;
  final DateTime timestamp;

  MessageStatusUpdate({
    required this.type,
    required this.chatId,
    required this.messageId,
    required this.userId,
    required this.status,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MessageStatusUpdate(type: $type, chatId: $chatId, messageId: $messageId, userId: $userId, timestamp: $timestamp)';
  }
}

class MessageStatus {
  final String messageId;
  final String chatId;
  final bool isSeen;
  final bool isReceived;
  final bool isDelivered;
  final bool isRead;
  final DateTime? seenAt;
  final DateTime? receivedAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<ReadBy> readBy;

  MessageStatus({
    required this.messageId,
    required this.chatId,
    this.isSeen = false,
    this.isReceived = false,
    this.isDelivered = false,
    this.isRead = false,
    this.seenAt,
    this.receivedAt,
    this.deliveredAt,
    this.readAt,
    this.readBy = const [],
  });

  MessageStatus copyWith({
    String? messageId,
    String? chatId,
    bool? isSeen,
    bool? isReceived,
    bool? isDelivered,
    bool? isRead,
    DateTime? seenAt,
    DateTime? receivedAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    List<ReadBy>? readBy,
  }) {
    return MessageStatus(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      isSeen: isSeen ?? this.isSeen,
      isReceived: isReceived ?? this.isReceived,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      seenAt: seenAt ?? this.seenAt,
      receivedAt: receivedAt ?? this.receivedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      readBy: readBy ?? this.readBy,
    );
  }

  @override
  String toString() {
    return 'MessageStatus(messageId: $messageId, chatId: $chatId, isSeen: $isSeen, isReceived: $isReceived, isDelivered: $isDelivered, isRead: $isRead)';
  }
}

class EnhancedMessageStatusHandler {
  static final EnhancedMessageStatusHandler _instance =
      EnhancedMessageStatusHandler._internal();
  factory EnhancedMessageStatusHandler() => _instance;
  EnhancedMessageStatusHandler._internal();

  final ChatService _chatService = ChatService();
  late StreamController<MessageStatusUpdate> _statusUpdateController =
      StreamController<MessageStatusUpdate>.broadcast();
  final Map<String, MessageStatus> _messageStatusCache = {};
  bool _isInitialized = false;
  int _activeListeners = 0; // Track active listeners

  Stream<MessageStatusUpdate> get statusUpdateStream =>
      _statusUpdateController.stream;

  bool get isInitialized => _isInitialized;

  void initialize() {
    _activeListeners++;

    if (_isInitialized) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Already initialized, listener count: $_activeListeners');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Initializing...');
      }

      // Ensure controller is open (recreate if previously closed)
      _ensureControllerOpen();
      _setupSocketListeners();
      _isInitialized = true;

      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Error during initialization: $e');
      }
    }
  }

  void _ensureControllerOpen() {
    // If controller was closed previously we need to recreate it so listeners
    // can subscribe and emits won't throw.
    try {
      if (_statusUpdateController.isClosed) {
        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Recreating closed StreamController');
        }
        _statusUpdateController =
            StreamController<MessageStatusUpdate>.broadcast();
      }
    } catch (e) {
      // Some platforms may not expose isClosed; defensively recreate if anything goes wrong
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: _ensureControllerOpen error: $e');
      }
      _statusUpdateController =
          StreamController<MessageStatusUpdate>.broadcast();
    }
  }

  void _setupSocketListeners() {
    if (kDebugMode) {
      print('EnhancedMessageStatusHandler: Setting up socket listeners...');
    }

    // Listen for message seen updates
    _chatService.onMessageSeenUpdate((data) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: onMessageSeenUpdate callback triggered with data: $data');
      }
      _handleMessageSeenUpdate(data);
    });

    // Listen for message received updates
    _chatService.onMessageReceived((data) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: onMessageReceived callback triggered with data: $data');
      }
      _handleMessageReceived(data);
    });

    // Listen for messages read updates
    _chatService.onMessagesRead((data) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: onMessagesRead callback triggered with data: $data');
      }
      _handleMessagesRead(data);
    });

    // Listen for messages delivered updates
    _chatService.onMessagesDelivered((data) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: onMessagesDelivered callback triggered with data: $data');
      }
      _handleMessagesDelivered(data);
    });

    // Listen for message sent updates (permanent ID replacement)
    _chatService.onMessageSent((data) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: onMessageSent callback triggered with data: $data');
      }
      _handleMessageSent(data);
    });

    if (kDebugMode) {
      print('EnhancedMessageStatusHandler: Socket listeners setup complete');
    }
  }

  void _handleMessageSeenUpdate(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Processing seen update: $data');
      }

      final messageId =
          data['messageId']?.toString() ?? data['_id']?.toString();
      final chatId = data['chatId']?.toString() ?? data['chat_id']?.toString();
      final userId = data['userId']?.toString() ?? data['user_id']?.toString();
      final seenAt = data['seenAt'] != null
          ? DateTime.parse(data['seenAt'].toString())
          : DateTime.now();

      if (messageId == null || chatId == null || userId == null) {
        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Missing required fields in seen update data');
        }
        return;
      }

      final statusKey = '${chatId}_$messageId';
      final currentStatus = _messageStatusCache[statusKey] ??
          MessageStatus(
            messageId: messageId,
            chatId: chatId,
          );

      final updatedStatus = currentStatus.copyWith(
        isSeen: true,
        seenAt: seenAt,
      );

      _messageStatusCache[statusKey] = updatedStatus;

      // Emit status update
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Emitting seen status update for message $messageId in chat $chatId');
      }
      _emitStatusUpdate(MessageStatusUpdate(
        type: MessageStatusType.seen,
        chatId: chatId,
        messageId: messageId,
        userId: userId,
        status: updatedStatus,
        timestamp: seenAt,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Error handling seen update: $e');
      }
    }
  }

  void _handleMessageReceived(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Processing received update: $data');
      }

      final messageId =
          data['messageId']?.toString() ?? data['_id']?.toString();
      final chatId = data['chatId']?.toString() ?? data['chat_id']?.toString();
      final userId = data['userId']?.toString() ?? data['user_id']?.toString();
      final receivedAt = data['receivedAt'] != null
          ? DateTime.parse(data['receivedAt'].toString())
          : DateTime.now();

      if (messageId == null || chatId == null || userId == null) {
        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Missing required fields in received update data');
        }
        return;
      }

      final statusKey = '${chatId}_$messageId';
      final currentStatus = _messageStatusCache[statusKey] ??
          MessageStatus(
            messageId: messageId,
            chatId: chatId,
          );

      final updatedStatus = currentStatus.copyWith(
        isReceived: true,
        receivedAt: receivedAt,
      );

      _messageStatusCache[statusKey] = updatedStatus;

      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Emitting received status update for message $messageId in chat $chatId');
      }
      _emitStatusUpdate(MessageStatusUpdate(
        type: MessageStatusType.received,
        chatId: chatId,
        messageId: messageId,
        userId: userId,
        status: updatedStatus,
        timestamp: receivedAt,
      ));
    } catch (e) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Error handling received update: $e');
      }
    }
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Processing read update: $data');
      }

      final messageIds = (data['messageIds'] as List?)?.cast<String>() ?? [];
      final chatId = data['chatId']?.toString() ?? data['chat_id']?.toString();
      final userId = data['userId']?.toString() ?? data['user_id']?.toString();
      final readAt = data['readAt'] != null
          ? DateTime.parse(data['readAt'].toString())
          : DateTime.now();

      if (messageIds.isEmpty || chatId == null || userId == null) {
        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Missing required fields in read update data');
        }
        return;
      }

      for (final messageId in messageIds) {
        final statusKey = '${chatId}_$messageId';
        final currentStatus = _messageStatusCache[statusKey] ??
            MessageStatus(
              messageId: messageId,
              chatId: chatId,
            );

        final updatedStatus = currentStatus.copyWith(
          isRead: true,
          readAt: readAt,
        );

        _messageStatusCache[statusKey] = updatedStatus;

        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Emitting read status update for message $messageId in chat $chatId');
        }
        _emitStatusUpdate(MessageStatusUpdate(
          type: MessageStatusType.read,
          chatId: chatId,
          messageId: messageId,
          userId: userId,
          status: updatedStatus,
          timestamp: readAt,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Error handling read update: $e');
      }
    }
  }

  void _handleMessagesDelivered(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Processing delivered update: $data');
      }

      final messageIds = (data['messageIds'] as List?)?.cast<String>() ?? [];
      final chatId = data['chatId']?.toString() ?? data['chat_id']?.toString();
      final userId = data['userId']?.toString() ?? data['user_id']?.toString();
      final deliveredAt = data['deliveredAt'] != null
          ? DateTime.parse(data['deliveredAt'].toString())
          : DateTime.now();

      if (messageIds.isEmpty || chatId == null || userId == null) {
        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Missing required fields in delivered update data');
        }
        return;
      }

      for (final messageId in messageIds) {
        final statusKey = '${chatId}_$messageId';
        final currentStatus = _messageStatusCache[statusKey] ??
            MessageStatus(
              messageId: messageId,
              chatId: chatId,
            );

        final updatedStatus = currentStatus.copyWith(
          isDelivered: true,
          deliveredAt: deliveredAt,
        );

        _messageStatusCache[statusKey] = updatedStatus;

        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Emitting delivered status update for message $messageId in chat $chatId');
        }
        _emitStatusUpdate(MessageStatusUpdate(
          type: MessageStatusType.delivered,
          chatId: chatId,
          messageId: messageId,
          userId: userId,
          status: updatedStatus,
          timestamp: deliveredAt,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Error handling delivered update: $e');
      }
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Processing sent update: $data');
      }

      final tempId = data['tempId'] ?? data['client_message_id'];
      final permanentId = data['_id'] ?? data['messageId'];
      final chatId = data['chat_id'] ?? data['chatId'];
      final status = data['status'] ?? 'sent';

      if (tempId == null || permanentId == null || chatId == null) {
        if (kDebugMode) {
          print(
              'EnhancedMessageStatusHandler: Missing required fields in sent update data');
        }
        return;
      }

      // Create status for the permanent message
      final statusKey = '${chatId}_$permanentId';
      final sentStatus = MessageStatus(
        messageId: permanentId,
        chatId: chatId,
        isSeen: false,
        isReceived: true, // Message was received by the server
        isDelivered: status == 'delivered',
        isRead: false,
        receivedAt: DateTime.now(),
        deliveredAt: status == 'delivered' ? DateTime.now() : null,
        readBy: [],
      );

      _messageStatusCache[statusKey] = sentStatus;

      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Emitting sent status update for message $permanentId in chat $chatId');
        print('  - Replaced tempId: $tempId with permanentId: $permanentId');
        print('  - Status: $status');
        print('  - isReceived: ${sentStatus.isReceived}');
        print('  - isDelivered: ${sentStatus.isDelivered}');
      }

      _emitStatusUpdate(MessageStatusUpdate(
        type: MessageStatusType.received,
        chatId: chatId,
        messageId: permanentId,
        userId: '', // No specific user for sent status
        status: sentStatus,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Error handling sent update: $e');
      }
    }
  }

  /// Manually update message status (useful for immediate UI updates)
  void updateMessageStatus({
    required String chatId,
    required String messageId,
    bool? isRead,
    bool? isSeen,
    bool? isReceived,
    bool? isDelivered,
    DateTime? timestamp,
  }) {
    try {
      final statusKey = '${chatId}_$messageId';
      final currentStatus = _messageStatusCache[statusKey] ??
          MessageStatus(
            messageId: messageId,
            chatId: chatId,
          );

      final updatedStatus = currentStatus.copyWith(
        isRead: isRead ?? currentStatus.isRead,
        isSeen: isSeen ?? currentStatus.isSeen,
        isReceived: isReceived ?? currentStatus.isReceived,
        isDelivered: isDelivered ?? currentStatus.isDelivered,
        readAt: isRead == true
            ? (timestamp ?? DateTime.now())
            : currentStatus.readAt,
        seenAt: isSeen == true
            ? (timestamp ?? DateTime.now())
            : currentStatus.seenAt,
        receivedAt: isReceived == true
            ? (timestamp ?? DateTime.now())
            : currentStatus.receivedAt,
        deliveredAt: isDelivered == true
            ? (timestamp ?? DateTime.now())
            : currentStatus.deliveredAt,
      );

      _messageStatusCache[statusKey] = updatedStatus;

      // Determine the status type for the update
      MessageStatusType updateType = MessageStatusType.read;
      if (isSeen == true) updateType = MessageStatusType.seen;
      if (isReceived == true) updateType = MessageStatusType.received;
      if (isDelivered == true) updateType = MessageStatusType.delivered;

      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Manually updating status for message $messageId in chat $chatId');
        print('  - Type: $updateType');
        print(
            '  - isRead: $isRead, isSeen: $isSeen, isReceived: $isReceived, isDelivered: $isDelivered');
      }

      _emitStatusUpdate(MessageStatusUpdate(
        type: updateType,
        chatId: chatId,
        messageId: messageId,
        userId: '', // Not available in manual updates
        status: updatedStatus,
        timestamp: timestamp ?? DateTime.now(),
      ));
    } catch (e) {
      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Error in manual status update: $e');
      }
    }
  }

  void dispose() {
    _activeListeners--;

    if (kDebugMode) {
      print(
          'EnhancedMessageStatusHandler: dispose called, active listeners: $_activeListeners');
    }

    if (_activeListeners <= 0) {
      _isInitialized = false;
      try {
        if (!_statusUpdateController.isClosed) {
          _statusUpdateController.close();
        }
      } catch (e) {
        if (kDebugMode) {
          print('EnhancedMessageStatusHandler: Error closing controller: $e');
        }
      }
      _messageStatusCache.clear();

      if (kDebugMode) {
        print(
            'EnhancedMessageStatusHandler: Fully disposed (controller closed)');
      }
    }
  }

  void _emitStatusUpdate(MessageStatusUpdate update) {
    // Ensure controller is open and attempt to emit; if closed recreate once
    try {
      _ensureControllerOpen();
      _statusUpdateController.add(update);
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedMessageStatusHandler: Error emitting update: $e');
        print('Attempting to recreate controller and re-emit');
      }
      try {
        _statusUpdateController =
            StreamController<MessageStatusUpdate>.broadcast();
        _statusUpdateController.add(update);
      } catch (e2) {
        if (kDebugMode) {
          print('EnhancedMessageStatusHandler: Failed to re-emit update: $e2');
        }
        // Give up silently to avoid crashing the app
      }
    }
  }

  /// Force refresh all message statuses (useful for debugging)
  void refreshAllStatuses() {
    if (kDebugMode) {
      print('EnhancedMessageStatusHandler: Refreshing all statuses');
      print('  - Cache size: ${_messageStatusCache.length}');
      print('  - Active listeners: $_activeListeners');
      print('  - Is initialized: $_isInitialized');
    }
  }

  /// Get current message status for a specific message
  MessageStatus? getMessageStatus(String chatId, String messageId) {
    final statusKey = '${chatId}_$messageId';
    return _messageStatusCache[statusKey];
  }

  /// Get all message statuses for a chat
  List<MessageStatus> getChatMessageStatuses(String chatId) {
    return _messageStatusCache.values
        .where((status) => status.chatId == chatId)
        .toList();
  }

  /// Clear status cache for a specific chat
  void clearChatStatusCache(String chatId) {
    final keysToRemove = _messageStatusCache.keys
        .where((key) => key.startsWith('${chatId}_'))
        .toList();

    for (final key in keysToRemove) {
      _messageStatusCache.remove(key);
    }

    if (kDebugMode) {
      print('EnhancedMessageStatusHandler: Cleared cache for chat $chatId');
      print('  - Removed ${keysToRemove.length} status entries');
    }
  }
}
