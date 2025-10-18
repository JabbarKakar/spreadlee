import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:path/path.dart' as path;
import '../../../../domain/chat_model.dart';
import '../../../../services/chat_service.dart';
import 'package:flutter/material.dart';
import '../../../../domain/services/media_cache_service.dart';
import '../../../../core/di.dart';
import '../../../../providers/user_status_provider.dart';
import '../../../../utils/sound_utils.dart';
import '../../../../services/message_visibility_tracker.dart';
import '../../../../services/message_status_handler.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final bool _isConnected = false;
  final String chatId;
  final String userId;
  final String userRole;
  bool _isDisposed = false;
  final int _currentPage = 0;
  Chats? _currentChat;
  final bool _isUpdating = false;
  final Set<String> _processedMessageIds = {};
  final Map<String, ChatMessage> _pendingMessages = {};
  int _tempMessageCounter = 0;

  // Note: messages_read callback removed - events now handled directly in cubit

  // New properties for online/offline status and typing indicators
  bool _isUserOnline = false;
  String? _onlineUserId;
  DateTime? _lastSeen;

  // Add proper tracking for other user's status
  bool _isOtherUserOnline = false;
  String? _otherUserId;
  DateTime? _otherUserLastSeen;

  // Add UserStatusProvider reference
  UserStatusProvider? _userStatusProvider;

  // Add MessageVisibilityTracker reference
  final MessageVisibilityTracker _visibilityTracker =
      MessageVisibilityTracker();

  // Add MessageStatusHandler reference
  final MessageStatusHandler _statusHandler = MessageStatusHandler();

  // Add message status map to persist status across widget rebuilds
  final Map<String, Map<String, dynamic>> _messageStatuses = {};

  // Track recently replaced messages to prevent duplicates from new_message events
  final Map<String, String> _recentlyReplacedMessages =
      {}; // tempId -> permanentId

  // Method to get message status from persistent map
  Map<String, dynamic>? getMessageStatus(String messageId) {
    return _messageStatuses[messageId];
  }

  // Method to update message status
  void updateMessageStatus(String messageId, Map<String, dynamic> status) {
    if (_isDisposed) return;

    // Store status in persistent map
    _messageStatuses[messageId] = status;

    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      final message = _messages[messageIndex];
      final updatedMessage = message.copyWith(
        isRead: status['isRead'] ?? message.isRead,
        isSeen: status['isSeen'] ?? message.isSeen,
        isReceived: status['isReceived'] ?? message.isReceived,
        isDelivered: status['isDelivered'] ?? message.isDelivered,
      );

      _messages[messageIndex] = updatedMessage;

      if (kDebugMode) {
        print('ChatProvider: Updated message status for $messageId');
        print('  isRead: ${updatedMessage.isRead}');
        print('  isSeen: ${updatedMessage.isSeen}');
        print('  isReceived: ${updatedMessage.isReceived}');
        print('  isDelivered: ${updatedMessage.isDelivered}');
      }

      notifyListeners();
    }
  }

  // Method to handle bulk message status updates
  void updateBulkMessageStatus(
      List<String> messageIds, Map<String, dynamic> status) {
    if (_isDisposed) return;

    bool hasChanges = false;
    for (final messageId in messageIds) {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final updatedMessage = message.copyWith(
          isRead: status['isRead'] ?? message.isRead,
          isSeen: status['isSeen'] ?? message.isSeen,
          isReceived: status['isReceived'] ?? message.isReceived,
          isDelivered: status['isDelivered'] ?? message.isDelivered,
        );

        _messages[messageIndex] = updatedMessage;
        hasChanges = true;

        if (kDebugMode) {
          print('ChatProvider: Updated bulk message status for $messageId');
        }
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  // Method to replace temporary ID with permanent ID
  void replaceMessageId(
      String tempId, String permanentId, Map<String, dynamic> status) {
    if (_isDisposed) return;

    // Skip replacement if this message was already handled by the Cubit
    // The Cubit is the primary state manager and handles message replacement
    if (kDebugMode) {
      print('ChatProvider: Skipping replaceMessageId - handled by Cubit');
      print('  tempId: $tempId');
      print('  permanentId: $permanentId');
    }

    // Just update the status if the message exists
    final messageIndex =
        _messages.indexWhere((m) => m.id == tempId || m.id == permanentId);
    if (messageIndex != -1) {
      final message = _messages[messageIndex];
      final updatedMessage = message.copyWith(
        isRead: status['isRead'] ?? message.isRead,
        isSeen: status['isSeen'] ?? message.isSeen,
        isReceived: status['isReceived'] ?? message.isReceived,
        isDelivered: status['isDelivered'] ?? message.isDelivered,
      );

      _messages[messageIndex] = updatedMessage;

      if (kDebugMode) {
        print('ChatProvider: Updated message status only');
        print('  isRead: ${updatedMessage.isRead}');
        print('  isSeen: ${updatedMessage.isSeen}');
        print('  isReceived: ${updatedMessage.isReceived}');
        print('  isDelivered: ${updatedMessage.isDelivered}');
      }

      notifyListeners();
    }
  }

  // Method to handle message visibility for read status
  void onMessageVisible(String messageId, bool isFromCurrentUser) {
    if (_isDisposed) return;

    // ✅ DISABLED: Mark as read functionality removed
    if (kDebugMode) {
      print(
          'ChatProvider: onMessageVisible called but mark as read disabled: $messageId');
    }

    // Original code commented out
    // _visibilityTracker.markMessageAsVisible(
    //     chatId, messageId, isFromCurrentUser);
    //
    // // If this is a message from another user, mark it as read after a delay
    // if (!isFromCurrentUser) {
    //   _visibilityTracker.markVisibleMessagesAsRead(chatId, userId);
    // }
  }

  // Method to handle message no longer visible
  void onMessageInvisible(String messageId) {
    if (_isDisposed) return;

    _visibilityTracker.markMessageAsInvisible(chatId, messageId);
  }

  // Method to mark all visible messages as read (called when chat becomes active)
  void markAllVisibleMessagesAsRead() {
    if (_isDisposed) return;

    _visibilityTracker.markVisibleMessagesAsRead(chatId, userId);
  }

  // Timer for periodic status updates
  Timer? _statusUpdateTimer;

  final MediaCacheService _mediaCacheService = instance<MediaCacheService>();

  // In-memory map for fast lookup of remote URL to local file path
  final Map<String, String> _remoteUrlToLocalPath = {};

  final ChatService _chatService = ChatService(); // Use singleton

  ChatProvider({
    required this.chatId,
    required this.userId,
    required this.userRole,
  }) {
    // Debug logging to check userRole value
    if (kDebugMode) {
      print('ChatProvider: Constructor called with userRole: "$userRole"');
      print('ChatProvider: userId: "$userId"');
      print('ChatProvider: chatId: "$chatId"');
    }
  }

  // Add initialize method
  void initialize() {
    if (_isDisposed) return;
    _chatService.initializeSocket();
    _visibilityTracker.initialize();

    // Connect MessageStatusHandler callbacks to ChatProvider
    _statusHandler.onStatusUpdate((chatId, messageId, status) {
      if (chatId == this.chatId) {
        updateMessageStatus(messageId, status);
      }
    });

    _statusHandler.onBulkStatusUpdate((chatId, messageIds, status) {
      if (chatId == this.chatId) {
        updateBulkMessageStatus(messageIds, status);
      }
    });

    // Set current user as online initially
    _isUserOnline = true;
    // Initialize services asynchronously
    _initializeAsync();
  }

  // Note: setMessagesReadCallback method removed - events now handled directly in cubit

  /// Set UserStatusProvider reference for real-time status updates
  void setUserStatusProvider(UserStatusProvider userStatusProvider) {
    _userStatusProvider = userStatusProvider;

    // Connect to real-time status updates
    if (kDebugMode) {
      print(
          'ChatProvider: Connected to UserStatusProvider for real-time updates');
    }

    // Listen to UserStatusProvider updates
    userStatusProvider.addListener(_onUserStatusChanged);

    if (kDebugMode) {
      print('ChatProvider: Added listener to UserStatusProvider');
    }

    // Set up socket event listeners for real-time status updates
    _setupRealTimeStatusListeners();

    // Start periodic status updates for real-time responsiveness
    _startPeriodicStatusUpdates();
  }

  /// Set up real-time status listeners
  void _setupRealTimeStatusListeners() {
    if (_userStatusProvider == null) return;

    // Listen to user status changes from socket
    _chatService.onUserStatusChange((data) {
      if (_isDisposed) return;
      if (kDebugMode) {
        print('ChatProvider: User status change: $data');
      }

      final eventChatId = data['chatId'] ?? data['chat_id'];
      final eventUserId = data['userId'] ?? data['user_id'];
      final isOnline = data['isOnline'] as bool? ?? false;
      final timestamp = data['timestamp'] != null
          ? DateTime.parse(data['timestamp'].toString())
          : DateTime.now();

      if (eventChatId == chatId) {
        if (eventUserId == userId) {
          // This is the current user's status update
          if (kDebugMode) {
            print('ChatProvider: Updating current user status to: $isOnline');
          }
          _isUserOnline = isOnline;
        } else {
          // This is the other user's status update
          if (kDebugMode) {
            print('ChatProvider: Updating other user status to: $isOnline');
          }
          _isOtherUserOnline = isOnline;
        }

        // Update local state for real-time UI updates
        // Note: UserStatusProvider no longer has updateUserStatus method
        // The new presence system handles this automatically via socket events

        // Force immediate UI update
        if (kDebugMode) {
          print('ChatProvider: Forcing immediate UI update for status change');
        }

        // Use WidgetsBinding to ensure UI updates happen in the next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            notifyListeners();
          }
        });
      }
    });
  }

  /// Handle UserStatusProvider updates
  void _onUserStatusChanged() {
    if (kDebugMode) {
      print('ChatProvider: _onUserStatusChanged called');
      print('ChatProvider: _isDisposed = $_isDisposed');
      print('ChatProvider: _otherUserId = $_otherUserId');
    }

    if (_isDisposed || _otherUserId == null) return;

    if (kDebugMode) {
      print('ChatProvider: UserStatusProvider update received');
      print('ChatProvider: Checking status for other user: $_otherUserId');
    }

    // Note: UserStatusProvider methods have been deprecated
    // The new presence system handles status updates automatically via socket events
    // Local state is updated directly from socket events, so no need to query UserStatusProvider

    if (kDebugMode) {
      print('ChatProvider: Status updates now handled by presence system');
      print(
          'ChatProvider: Current local state - _isOtherUserOnline: $_isOtherUserOnline');
    }
  }

  /// Start periodic status updates for real-time responsiveness
  void _startPeriodicStatusUpdates() {
    if (_isDisposed) return;

    // Cancel any existing timer
    _statusUpdateTimer?.cancel();

    // Update status every 10 seconds for better performance
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDisposed || _otherUserId == null) {
        timer.cancel();
        return;
      }

      if (kDebugMode) {
        print('ChatProvider: Periodic status update for user: $_otherUserId');
      }

      // Request fresh status from server
      _requestOtherUserStatus();

      // Note: UserStatusProvider methods have been deprecated
      // The new presence system handles status updates automatically via socket events
      // No need to manually check UserStatusProvider as it's handled by the presence system

      if (kDebugMode) {
        print('ChatProvider: Periodic status update completed');
        print(
            'ChatProvider: Current local state - _isOtherUserOnline: $_isOtherUserOnline');
      }
    });
  }

  // Method to force UI refresh for real-time updates
  void forceUIUpdate() {
    if (_isDisposed) return;

    if (kDebugMode) {
      print('ChatProvider: Forcing UI update');
    }

    // Use WidgetsBinding to ensure UI updates happen in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  /// Initialize async components
  Future<void> _initializeAsync() async {
    if (_isDisposed) return;

    try {
      // Set up socket event listeners with deduplication
      _setupSocketEventListeners();

      // Start periodic status updates
      _startPeriodicStatusUpdates();

      if (kDebugMode) {
        print('ChatProvider: Async initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatProvider: Error in async initialization: $e');
      }
    }
  }

  /// Set up socket event listeners with deduplication
  void _setupSocketEventListeners() {
    if (_isDisposed) return;

    // Track processed events to prevent duplicates - use more specific keys
    final Set<String> processedEventIds = {};
    final Map<String, DateTime> lastEventTimestamps = {};

    _chatService.addOnNewMessageListener((data) {
      if (_isDisposed) return;

      // Skip processing new_message events - let the ChatCubit handle them exclusively
      // This prevents conflicts between ChatProvider and ChatCubit message processing
      if (kDebugMode) {
        print(
            'ChatProvider: Skipping new_message event - handled by ChatCubit');
        print(
            '  Message ID: ${data['message_id'] ?? data['_id'] ?? 'unknown'}');
        print('  Chat ID: ${data['chatId'] ?? data['chat_id'] ?? 'unknown'}');
      }

      // Just notify listeners to update UI without processing the message
      notifyListeners();
    });

    _chatService.onMessageReceived((data) {
      if (_isDisposed) return;

      // Create more specific event ID using message data
      final messageId = data['message_id'] ?? data['_id'] ?? 'unknown';
      final chatId = data['chatId'] ?? data['chat_id'] ?? 'unknown';
      final eventId = 'received_${chatId}_$messageId';

      // Check if this exact message was already processed
      if (processedEventIds.contains(eventId)) {
        if (kDebugMode) {
          print(
              'ChatProvider: Duplicate message received event ignored: $eventId');
        }
        return;
      }

      // Check if this is a recent duplicate (within 5 seconds)
      final now = DateTime.now();
      final lastTimestamp = lastEventTimestamps[eventId];
      if (lastTimestamp != null &&
          now.difference(lastTimestamp).inSeconds < 5) {
        if (kDebugMode) {
          print(
              'ChatProvider: Recent duplicate message received event ignored: $eventId');
        }
        return;
      }

      processedEventIds.add(eventId);
      lastEventTimestamps[eventId] = now;

      if (kDebugMode) {
        print('ChatProvider: Message received: $data');
        print('ChatProvider: Event ID: $eventId');
      }

      final eventChatId = data['chatId'] ?? data['chat_id'];
      if (eventChatId == chatId) {
        if (kDebugMode) {
          print('ChatProvider: New message received for this chat');
        }

        // Force immediate UI update for new message
        if (kDebugMode) {
          print('ChatProvider: Forcing immediate UI update for new message');
        }

        // Use WidgetsBinding to ensure UI updates happen in the next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            notifyListeners();
          }
        });

        // Clean up old event IDs to prevent memory leaks
        if (processedEventIds.length > 100) {
          processedEventIds.clear();
          lastEventTimestamps.clear();
        }
      }
    });

    _chatService.onMessageSeenUpdate((data) {
      if (_isDisposed) return;

      // Create more specific event ID using message data
      final messageId = data['message_id'] ?? data['_id'] ?? 'unknown';
      final chatId = data['chatId'] ?? data['chat_id'] ?? 'unknown';
      final eventId = 'seen_${chatId}_$messageId';

      // Check if this exact message was already processed
      if (processedEventIds.contains(eventId)) {
        if (kDebugMode) {
          print('ChatProvider: Duplicate message seen event ignored: $eventId');
        }
        return;
      }

      // Check if this is a recent duplicate (within 5 seconds)
      final now = DateTime.now();
      final lastTimestamp = lastEventTimestamps[eventId];
      if (lastTimestamp != null &&
          now.difference(lastTimestamp).inSeconds < 5) {
        if (kDebugMode) {
          print(
              'ChatProvider: Recent duplicate message seen event ignored: $eventId');
        }
        return;
      }

      processedEventIds.add(eventId);
      lastEventTimestamps[eventId] = now;

      if (kDebugMode) {
        print('ChatProvider: Message seen: $data');
        print('ChatProvider: Event ID: $eventId');
      }

      final eventChatId = data['chatId'] ?? data['chat_id'];
      if (eventChatId == chatId) {
        if (kDebugMode) {
          print('ChatProvider: Message seen update for this chat');
        }

        // Force immediate UI update for message seen status
        if (kDebugMode) {
          print('ChatProvider: Forcing immediate UI update for message seen');
        }

        // Use WidgetsBinding to ensure UI updates happen in the next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            notifyListeners();
          }
        });

        // Clean up old event IDs to prevent memory leaks
        if (processedEventIds.length > 100) {
          processedEventIds.clear();
          lastEventTimestamps.clear();
        }
      }
    });

    ChatService().onMessageError((data) {
      if (kDebugMode) {
        print('Message error: $data');
      }
    });

    // Note: messages_read events are now handled directly in the cubit
    // to avoid duplicate processing and ensure proper real-time updates

    _chatService.onInvoiceUpdated((data) {
      if (_isDisposed) return;
      if (kDebugMode) {
        print('ChatProvider: Received invoice_updated: $data');
      }
      final updatedInvoice = data['invoice'];
      final chatIdFromEvent = data['chatId'];
      var invoiceId = data['invoiceId'];
      if (invoiceId is Map && invoiceId.containsKey('_id')) {
        invoiceId = invoiceId['_id'];
      }
      if (chatIdFromEvent == chatId && updatedInvoice != null) {
        bool updated = false;
        for (int i = 0; i < _messages.length; i++) {
          final msg = _messages[i];
          // Support both Map and String for messageInvoice/messageInvoiceRef
          final msgInvoice = msg.messageInvoice ?? msg.messageInvoiceRef;
          String? msgInvoiceId;
          if (msgInvoice is String) {
            msgInvoiceId = msgInvoice;
          } else if (msgInvoice is Map) {
            msgInvoiceId = msgInvoice['_id']?.toString();
          }
          if (msgInvoiceId != null && msgInvoiceId == invoiceId) {
            _messages[i] = msg.copyWith(
              messageInvoice: updatedInvoice,
              messageInvoiceRef: updatedInvoice['_id']?.toString(),
              invoiceData: updatedInvoice, // Also update invoiceData field
            );
            updated = true;
          }
        }
        if (updated) {
          if (kDebugMode) {
            print(
                'ChatProvider: Updated invoice in chat messages - notifying listeners');
          }
          // Force immediate UI update using WidgetsBinding
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed) {
              notifyListeners();
            }
          });
          // Also notify synchronously
          notifyListeners();
        }
      }
    });

    // Note: message_sent events are handled by ChatCustomerCubit to avoid duplicates
    // The ChatProvider focuses on real-time status updates and UI state management
    // All message creation and replacement logic is handled by ChatCubit
  }

  /// Add a message to the list
  void _addMessageToList(ChatMessage message) {
    // Check if message already exists
    if (!_messages.any((m) => m.id == message.id)) {
      _messages.add(message); // Add to end instead of beginning
      notifyListeners();
    }
  }

  // Getters
  Chats? get currentChat {
    if (_isDisposed) return null;
    if (kDebugMode) {
      print('ChatProvider: currentChat getter called');
      print('ChatProvider: _currentChat = $_currentChat');
      print(
          'ChatProvider: _currentChat?.isTicketChat = ${_currentChat?.isTicketChat}');
    }
    return _currentChat;
  }

  // Add getter for other user's online status
  bool? get isOtherUserOnline {
    if (_isDisposed) return null;
    return _isOtherUserOnline;
  }

  // Add getter for other user ID
  String? get onlineUserId {
    if (_isDisposed) return null;
    return _otherUserId;
  }

  List<ChatMessage> get messages => _isDisposed ? [] : _messages;
  bool get isConnected => _isDisposed ? false : _isConnected;
  bool get isUpdating => _isUpdating;

  // New getters for online/offline status and typing indicators
  bool get isUserOnline {
    if (_isDisposed) return false;
    if (kDebugMode) {
      print('=== isUserOnline getter called ===');
      print('ChatProvider: _isOtherUserOnline = $_isOtherUserOnline');
      print('ChatProvider: _otherUserId = $_otherUserId');
      print('ChatProvider: userId = $userId');
      print('ChatProvider: userRole = $userRole');
    }

    // Use local state that gets updated by the listener
    // This ensures real-time updates work correctly
    if (kDebugMode) {
      print('ChatProvider: Using local state, isOnline = $_isOtherUserOnline');
    }
    return _isOtherUserOnline;
  }

  // Getter for current user's online status
  bool get isCurrentUserOnline {
    if (_isDisposed) return false;
    if (kDebugMode) {
      print(
          'ChatProvider: isCurrentUserOnline getter called, value: $_isUserOnline');
    }
    return _isUserOnline;
  }

  DateTime? get lastSeen => _isDisposed ? null : _otherUserLastSeen;

  void setCurrentChat(Chats chat) {
    if (_isDisposed) return;
    _currentChat = chat;

    // Debug log
    if (kDebugMode) {
      print('=== setCurrentChat Debug ===');
      print('ChatProvider: userId = $userId');
      print('ChatProvider: userRole = $userRole');
      print('ChatProvider: chat.sId = ${chat.sId}');
      print('ChatProvider: chat.participants = ${chat.participants}');
      print('ChatProvider: chat.chatUsers = ${chat.chatUsers}');
      print(
          'ChatProvider: chat.chatUsers?.customerId = ${chat.chatUsers?.customerId}');
      print(
          'ChatProvider: chat.chatUsers?.companyId?.sId = ${chat.chatUsers?.companyId?.sId}');
      print('ChatProvider: chat.isTicketChat = ${chat.isTicketChat}');
    }

    // Try to get other user ID from chatUsers first (most reliable)
    if (chat.chatUsers?.companyId != null ||
        chat.chatUsers?.subaccountId != null) {
      if ((userRole == 'company' ||
              userRole == 'influencer' ||
              userRole == 'subaccount') &&
          chat.chatUsers!.customerId != null) {
        // For company/influencer/subaccount users, the other user is the customer
        _otherUserId = chat.chatUsers!.customerId;
        if (kDebugMode) {
          print(
              'ChatProvider: Set other user ID from customerId: $_otherUserId');
        }
      } else if (userRole == 'customer' &&
          chat.chatUsers!.companyId?.sId != null) {
        // For customer users, the other user is the company
        _otherUserId = chat.chatUsers!.companyId!.sId;
        if (kDebugMode) {
          print(
              'ChatProvider: Set other user ID from companyId: $_otherUserId');
        }
      } else {
        if (kDebugMode) {
          print('ChatProvider: Could not determine other user from chatUsers');
          print('ChatProvider: userRole = $userRole');
          print('ChatProvider: customerId = ${chat.chatUsers!.customerId}');
          print(
              'ChatProvider: companyId?.sId = ${chat.chatUsers!.companyId?.sId}');
        }
      }
    }

    // Fallback: try participants if chatUsers didn't work
    if (_otherUserId == null &&
        chat.participants != null &&
        chat.participants!.length == 2) {
      for (final participantId in chat.participants!) {
        if (participantId != userId) {
          _otherUserId = participantId;
          if (kDebugMode) {
            print(
                'ChatProvider: Set other user ID from participants: $_otherUserId');
          }
          break;
        }
      }
    }

    // Last fallback: try to extract from messages
    if (_otherUserId == null) {
      if (kDebugMode) {
        print(
            'ChatProvider: Not a 1:1 chat or participants missing, extracting other user from messages');
      }
      _extractOtherUserIdFromMessages();
    }

    // Request the other user's status if we found them
    if (_otherUserId != null) {
      _requestOtherUserStatus();

      // Note: UserStatusProvider methods have been deprecated
      // The new presence system will handle status updates automatically via socket events
      // Initialize with default offline state
      _isOtherUserOnline = false;
      _otherUserLastSeen = null;

      if (kDebugMode) {
        print(
            'ChatProvider: Initialized local state with default offline status');
        print('ChatProvider: _isOtherUserOnline = $_isOtherUserOnline');
        print('ChatProvider: _otherUserLastSeen = $_otherUserLastSeen');
      }
    }

    // Request status after a delay to ensure socket is ready
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isDisposed && _otherUserId != null) {
        if (kDebugMode) {
          print('ChatProvider: Delayed status request for user: $_otherUserId');
        }
        _requestOtherUserStatus();
      }
    });

    if (kDebugMode) {
      print('ChatProvider: Final _otherUserId = $_otherUserId');
      print('=== End setCurrentChat Debug ===');
    }

    notifyListeners();
  }

  void _requestOtherUserStatus() {
    if (_otherUserId != null && !_isDisposed) {
      if (kDebugMode) {
        print('ChatProvider: Requesting status for other user: $_otherUserId');
      }

      // Use UserStatusProvider if available, otherwise fall back to ChatService
      if (_userStatusProvider != null) {
        if (kDebugMode) {
          print('ChatProvider: Using UserStatusProvider to request status');
        }
        _userStatusProvider!.requestUserStatus(_otherUserId!);
      } else {
        if (kDebugMode) {
          print(
              'ChatProvider: UserStatusProvider not available, skipping status request');
        }
      }
    }
  }

  void _extractOtherUserIdFromMessages() {
    if (_otherUserId != null || _messages.isEmpty) return;

    // Find the first message that's not from the current user
    for (final message in _messages) {
      if (message.messageCreator?.id != null &&
          message.messageCreator!.id != userId) {
        _otherUserId = message.messageCreator!.id;
        if (kDebugMode) {
          print(
              'ChatProvider: Extracted other user ID from messages: $_otherUserId');
        }
        _requestOtherUserStatus();
        break;
      }
    }
  }

  Future<void> sendMessage({
    String? messageText,
    List<String>? photoPaths,
    List<String>? videoPath,
    List<Map<String, dynamic>>? documents,
    String? audioPath,
    Map<String, dynamic>? location,
    String? paymentType,
    double? audioDuration,
  }) async {
    if (_isDisposed) return;
    if (messageText?.trim().isEmpty == true &&
        photoPaths == null &&
        videoPath == null &&
        audioPath == null &&
        location == null &&
        paymentType == null) {
      return;
    }

    print('DEBUG: sendMessage called with text: "$messageText"');

    // Check if this is a media message (photos, videos, documents, audio)
    final hasMedia = (photoPaths?.isNotEmpty == true) ||
        (videoPath != null) ||
        (documents?.isNotEmpty == true) ||
        (audioPath != null);

    // Cache attachments immediately if they exist
    if (hasMedia) {
      // Cache photos
      if (photoPaths?.isNotEmpty == true) {
        for (final photoPath in photoPaths!) {
          if (photoPath.startsWith('http')) {
            try {
              await _mediaCacheService.cacheMedia(photoPath, MediaType.image);
            } catch (e) {
              print('Error caching photo: $e');
            }
          }
        }
      }

      // Cache videos
      if (videoPath?.isNotEmpty == true) {
        for (final videoPathItem in videoPath!) {
          if (videoPathItem.startsWith('http')) {
            try {
              await _mediaCacheService.cacheMedia(
                  videoPathItem, MediaType.video);
            } catch (e) {
              print('Error caching video: $e');
            }
          }
        }
      }

      // Cache documents
      if (documents?.isNotEmpty == true) {
        for (final document in documents!) {
          final docPath = document['url'] as String?;
          if (docPath != null && docPath.startsWith('http')) {
            try {
              await _mediaCacheService.cacheMedia(docPath, MediaType.document);
            } catch (e) {
              print('Error caching document: $e');
            }
          }
        }
      }

      // Cache audio
      if (audioPath != null && audioPath.startsWith('http')) {
        try {
          await _mediaCacheService.cacheMedia(audioPath, MediaType.document);
        } catch (e) {
          print('Error caching audio: $e');
        }
      }
    }

    // Generate temp ID and clientMessageId
    final tempId =
        'temp_${DateTime.now().millisecondsSinceEpoch}_${_tempMessageCounter++}';
    final clientMessageId = tempId; // Use tempId as clientMessageId
    final now = DateTime.now();

    // Create temp message
    debugPrint('DEBUG: Creating temp message with audioPath: $audioPath');
    final tempMessage = ChatMessage(
      id: tempId,
      clientMessageId: clientMessageId,
      messageText: messageText ?? '',
      messageDate: now,
      messageCreator: MessageCreator(
        id: userId,
        role: userRole,
      ),
      messageCreatorRole: userRole,
      isRead: false,
      isDeleted: false,
      messagePhotos: photoPaths,
      messageVideos: videoPath,
      messageDocument: documents?.isNotEmpty == true
          ? documents!.first['url'] as String
          : null,
      location: location,
      messageInvoiceRef: paymentType,
      messageAudio: audioPath,
    );
    debugPrint(
        'DEBUG: Temp message created with audio: ${tempMessage.messageAudio}');

    // Add temp message to pending messages
    _pendingMessages[tempId] = tempMessage;

    // Add temp message to messages list for immediate UI feedback
    _messages.add(tempMessage); // Add to end instead of beginning

    notifyListeners();

    // Send message with retry logic
    int retryCount = 0;
    const maxRetries = 2;
    bool success = false;

    while (!success && retryCount < maxRetries) {
      try {
        // Debug logging to check messageCreatorRole value
        if (kDebugMode) {
          print(
              'ChatProvider: Sending message with messageCreatorRole: "$userRole"');
          print('ChatProvider: userId: "$userId"');
          print('ChatProvider: chatId: "$chatId"');
        }

        await _chatService.sendMessage(
          chatId: chatId,
          messageText: messageText ?? '',
          messageCreator: userId,
          messageCreatorRole: userRole,
          userId: userId,
          messageType: _determineMessageType(
            location,
            paymentType,
            _prepareFiles(
                photoPaths,
                videoPath?.isNotEmpty == true ? videoPath!.first : null,
                audioPath),
          ),
          files: _prepareFiles(
              photoPaths,
              videoPath?.isNotEmpty == true ? videoPath!.first : null,
              audioPath),
          location: location,
          messageInvoiceRef: paymentType,
          audioDuration: audioDuration,
          clientMessageId: clientMessageId, // Pass to backend
        );
        success = true;
      } catch (e) {
        retryCount++;

        // Check if it's a file size error
        if (e.toString().contains('File size error') ||
            e.toString().contains('exceeds maximum allowed size')) {
          // Remove the temp message from UI since it can't be sent
          _messages.removeWhere((msg) => msg.id == tempId);
          _pendingMessages.remove(tempId);
          notifyListeners();

          // Show error message to user
          print('DEBUG: File size error - removing temp message: $e');
          return; // Exit without retrying
        }

        if (retryCount >= maxRetries) {
          // Don't throw exception, just log warning
          // The optimistic message will be replaced by real message from socket
          print('DEBUG: Message send failed after $maxRetries attempts: $e');
          print(
              'DEBUG: Keeping optimistic message, waiting for socket confirmation');
          return; // Exit without throwing
        }
        // Wait before retry with exponential backoff
        await Future.delayed(
            Duration(milliseconds: 1000 * pow(2, retryCount - 1).toInt()));
      }
    }

    // // Play message sent sound on successful send
    // if (success) {
    //   await SoundUtils.playMessageSentSound();
    // }

    // After send success, cache remote media URLs in the background (never cache local file paths)
    // Photos
    if (tempMessage.messagePhotos != null) {
      for (final url in tempMessage.messagePhotos!) {
        if (url.startsWith('http')) {
          // Always cache remote photo URLs, even for own messages
          _mediaCacheService
              .cacheMedia(url, MediaType.image)
              .catchError((_) {});
          // If this is our own message and we have a local file path, register the mapping
          if (tempMessage.messageCreator?.id == userId &&
              tempMessage.messagePhotos != null &&
              tempMessage.messagePhotos!.isNotEmpty) {
            // Register mapping for each remote URL to the corresponding local file path
            final localPath = tempMessage.messagePhotos!.length ==
                    tempMessage.messagePhotos!.length
                ? tempMessage
                    .messagePhotos![tempMessage.messagePhotos!.indexOf(url)]
                : tempMessage.messagePhotos!.first;
            if (!localPath.startsWith('http')) {
              _mediaCacheService.registerLocalPathForRemoteUrl(url, localPath);
            }
          }
        }
      }
    }
    // Videos
    if (tempMessage.messageVideos != null) {
      for (final url in tempMessage.messageVideos!) {
        if (url.startsWith('http')) {
          _mediaCacheService
              .cacheMedia(url, MediaType.video)
              .catchError((_) {});
        }
      }
    }
    // Document
    if (tempMessage.messageDocument != null &&
        tempMessage.messageDocument!.isNotEmpty) {
      final url = tempMessage.messageDocument!;
      if (url.startsWith('http')) {
        _mediaCacheService
            .cacheMedia(url, MediaType.document)
            .catchError((_) {});
      }
    }
    // Audio (use MediaType.document as fallback)
    if (tempMessage.messageAudio != null &&
        tempMessage.messageAudio!.isNotEmpty) {
      final url = tempMessage.messageAudio!;
      if (url.startsWith('http')) {
        _mediaCacheService
            .cacheMedia(url, MediaType.document)
            .catchError((_) {});
      }
    }

    // Now add the real message if not present
    if (!_messages.any((m) => m.id == tempMessage.id)) {
      _messages.add(tempMessage); // Add to end instead of beginning
      print('DEBUG: Added new message: id=${tempMessage.id}');
    }
    notifyListeners();
  }

  List<File>? _prepareFiles(
      List<String>? photoPaths, String? videoPath, String? audioPath) {
    final files = <File>[];
    if (photoPaths != null) {
      files.addAll(photoPaths.map((path) => File(path)));
    }
    if (videoPath != null) {
      files.add(File(videoPath));
    }
    if (audioPath != null) {
      files.add(File(audioPath));
    }
    return files.isEmpty ? null : files;
  }

  /// Determine the appropriate message type based on content
  String _determineMessageType(
    Map<String, dynamic>? location,
    String? messageInvoiceRef,
    List<File>? files,
  ) {
    if (messageInvoiceRef != null) {
      return 'invoice';
    } else if (location != null) {
      return 'location';
    } else if (files != null && files.isNotEmpty) {
      // Check file types to determine appropriate message type
      bool hasVideos = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm']
            .contains(extension);
      });

      bool hasImages = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
      });

      bool hasAudio = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return ['.mp3', '.wav', '.ogg', '.m4a', '.aac'].contains(extension);
      });

      bool hasDocuments = files.any((file) {
        final extension = path.extension(file.path).toLowerCase();
        return [
          '.pdf',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.ppt',
          '.pptx',
          '.txt',
          '.rtf'
        ].contains(extension);
      });

      // Return specific message type based on file content
      if (hasVideos) {
        return 'video';
      } else if (hasImages) {
        return 'image';
      } else if (hasAudio) {
        return 'audio';
      } else if (hasDocuments) {
        return 'document';
      } else {
        // Fallback for unknown file types
        return 'document';
      }
    } else {
      return 'text';
    }
  }

  Future<void> handleNewMessage(ChatMessage message) async {
    // Find index of temp message with the same clientMessageId
    final tempIndex = _messages.indexWhere((m) =>
        m.clientMessageId != null &&
        message.clientMessageId != null &&
        m.clientMessageId == message.clientMessageId);

    if (tempIndex != -1) {
      // Replace the temp message with the real one
      final tempMessage = _messages[tempIndex];

      // For video messages, ensure we preserve the video URL from server response
      if (message.messageText == '[VIDEO]' && message.messageVideo != null) {
        if (kDebugMode) {
          print('=== Updating Video Message ===');
          print('Temp message video: ${tempMessage.messageVideo}');
          print('Server message video: ${message.messageVideo}');
        }

        // Update the temp message with the server video URL
        final updatedMessage = tempMessage.copyWith(
          id: message.id,
          messageVideo: message.messageVideo,
          messageVideos: message.messageVideos,
          isRead: message.isRead,
          isSeen: message.isSeen,
          isReceived: message.isReceived,
          isTemp: false,
        );

        _messages[tempIndex] = updatedMessage;

        if (kDebugMode) {
          print('=== Video Message Updated ===');
          print('Updated message video: ${updatedMessage.messageVideo}');
        }
      } else {
        // For non-video messages, replace completely
        _messages[tempIndex] = message;
      }
    } else {
      // Check for duplicate by _id or clientMessageId
      final alreadyExists = _messages.any((m) =>
          m.id == message.id ||
          (m.clientMessageId != null &&
              m.clientMessageId == message.clientMessageId));
      if (!alreadyExists) {
        _messages.add(message);
      }
    }

    // Optionally, sort messages by timestamp if needed
    _messages.sort((a, b) => (a.messageDate ?? DateTime.now())
        .compareTo(b.messageDate ?? DateTime.now()));

    notifyListeners();
  }

  // Optional: Clean up old temp messages (older than 5 minutes)
  void cleanUpOldTempMessages() {
    final now = DateTime.now();
    _messages.removeWhere((m) =>
        m.id.startsWith('temp_') &&
        m.messageDate != null &&
        now.difference(m.messageDate!).inMinutes > 5);
    notifyListeners();
  }

  void updateUserStatus({required bool isOnline, DateTime? lastSeen}) {
    if (_isDisposed) return;
    if (kDebugMode) {
      print('ChatProvider: Updating user status: isOnline=$isOnline');
    }
    _isUserOnline = isOnline;
    _lastSeen = isOnline ? null : lastSeen;
    _chatService.updateUserStatus(isOnline: isOnline, lastSeen: lastSeen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  void markMessageAsSeen(String messageId) {
    if (_isDisposed) return;
    if (kDebugMode) {
      print('ChatProvider: Marking message as seen: $messageId');
    }
    _chatService.markMessageAsSeen(messageId, chatId);
  }

  void markMessagesAsRead(List<String> messageIds) {
    if (_isDisposed) return;

    // Update in-memory messages
    for (final messageId in messageIds) {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final updatedMessage = message.copyWith(isRead: true);
        _messages[messageIndex] = updatedMessage;
      }
    }

    // Send to server (ChatManagerService already handles this)
    // _chatService.markMessagesAsRead(chatId, messageIds);

    notifyListeners();
  }

  void setMessages(List<ChatMessage> messages) {
    if (_isDisposed) return;

    if (kDebugMode) {
      print('=== setMessages called ===');
      print('Messages count: ${messages.length}');
      print('Current user ID: $userId');
    }

    // Apply the same fix for own messages when loading from server
    final processedMessages = messages.map((message) {
      final isOwnMessage = message.messageCreator?.id == userId;
      if (isOwnMessage && message.isRead == true) {
        if (kDebugMode) {
          print('Fixing own message isRead: ${message.id} -> false');
        }
        return message.copyWith(isRead: false);
      }
      return message;
    }).toList();

    _messages
      ..clear()
      ..addAll(processedMessages);

    // Extract other user ID from messages if not already set
    _extractOtherUserIdFromMessages();

    if (kDebugMode) {
      print('=== setMessages complete ===');
      print('Final messages count: ${_messages.length}');
      // Print the first few messages to verify their isRead status
      for (int i = 0; i < _messages.length && i < 3; i++) {
        final msg = _messages[i];
        print(
            'Message $i: ID=${msg.id}, isRead=${msg.isRead}, creator=${msg.messageCreator?.id}');
      }
    }

    notifyListeners();
  }

  void addOptimisticMessage(ChatMessage message) {
    if (_isDisposed) return;
    _messages.add(message); // Add to end instead of beginning

    notifyListeners();
  }

  void addOptimisticMessageIfNotExists(ChatMessage message) {
    if (_isDisposed) return;

    // Skip adding optimistic messages - the Cubit handles all message management
    // This prevents conflicts between Cubit and ChatProvider message lists
    if (kDebugMode) {
      print(
          'ChatProvider: Skipping addOptimisticMessageIfNotExists - handled by Cubit');
      print('  Message ID: ${message.id}');
      print('  Message text: ${message.messageText}');
    }

    // Just notify listeners to update UI without adding the message
    notifyListeners();
  }

  // Register mapping in both Hive and in-memory map
  Future<void> registerLocalPathForRemoteUrl(
      String remoteUrl, String localFilePath) async {
    _remoteUrlToLocalPath[remoteUrl] = localFilePath;
    await _mediaCacheService.registerLocalPathForRemoteUrl(
        remoteUrl, localFilePath);
  }

  // Synchronous getter for local path if available in memory
  String? getLocalPathForRemoteUrlSync(String remoteUrl) {
    final path = _remoteUrlToLocalPath[remoteUrl];
    if (path != null && File(path).existsSync()) {
      return path;
    }
    return null;
  }

  /// Force sync messages from server
  Future<void> forceSyncMessages() async {
    if (_isDisposed) return;

    if (kDebugMode) {
      print('ChatProvider: Force syncing messages for chat: $chatId');
    }

    // await _backgroundSyncService?.forceSyncChat(chatId);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    if (_isDisposed) return 0;
    return 0; // No local database service, so return 0
  }

  /// Update a message
  Future<void> updateMessage(String chatId, ChatMessage message) async {
    // No local database service, so this is a no-op
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel timers
    _statusUpdateTimer?.cancel();

    // Remove listener from UserStatusProvider
    _userStatusProvider?.removeListener(_onUserStatusChanged);

    // Clear visibility tracking for this chat
    _visibilityTracker.clearChatTracking(chatId);

    // Remove status handler listeners
    _statusHandler.removeStatusUpdateListener((chatId, messageId, status) {});
    _statusHandler
        .removeBulkStatusUpdateListener((chatId, messageIds, status) {});

    // Dispose of services
    // _backgroundSyncService?.stop();
    // _chatService.disconnect(); // Removed to prevent global socket disconnect

    _messages.clear();
    _currentChat = null;
    _pendingMessages.clear();
    _processedMessageIds.clear();
    _remoteUrlToLocalPath.clear();

    _chatService.socket.off('invoice_updated');

    super.dispose();
  }

  /// Join a specific chat room for real-time updates
  void joinChatRoom(String chatId) {
    if (kDebugMode) {
      print('ChatProvider: Joining chat room: $chatId');
    }
    _chatService.joinChatRoom(chatId);
  }

  /// Leave a specific chat room
  void leaveChatRoom(String chatId) {
    if (kDebugMode) {
      print('ChatProvider: Leaving chat room: $chatId');
    }
    _chatService.leaveChatRoom(chatId);
  }
}
