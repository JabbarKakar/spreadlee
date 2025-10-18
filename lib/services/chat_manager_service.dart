import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/chat_model.dart';
import 'chat_socket_service.dart';
import '../data/dio_helper.dart';
import '../core/constant.dart';

/// Callback types for chat events
typedef ChatMessageCallback = void Function(String chatId, ChatMessage message);
typedef ChatListCallback = void Function(List<Chats> chats);
typedef ChatErrorCallback = void Function(String error);

/// Clean and efficient chat manager service
class ChatManagerService {
  static final ChatManagerService _instance = ChatManagerService._internal();
  factory ChatManagerService() => _instance;
  ChatManagerService._internal();

  // Services
  final ChatSocketService _socketService = ChatSocketService();

  // State
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Event callbacks
  ChatMessageCallback? _onNewMessage;
  ChatMessageCallback? _onMessageUpdated;
  ChatListCallback? _onChatListUpdated;
  ChatErrorCallback? _onError;

  // Message processing
  final Set<String> _processedMessageIds = {};
  final Map<String, Timer> _messageCleanupTimers = {};

  // Sync state
  final Map<String, bool> _isSyncing = {};
  final Map<String, DateTime> _lastSyncTime = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSocketConnected => _socketService.isConnected;

  /// Initialize the chat manager
  Future<void> initialize({
    required String baseUrl,
    required String token,
    ChatMessageCallback? onNewMessage,
    ChatMessageCallback? onMessageUpdated,
    ChatListCallback? onChatListUpdated,
    ChatErrorCallback? onError,
  }) async {
    if (_isInitialized || _isDisposed) return;

    try {
      // Set up callbacks
      _onNewMessage = onNewMessage;
      _onMessageUpdated = onMessageUpdated;
      _onChatListUpdated = onChatListUpdated;
      _onError = onError;

      // Initialize socket
      await _socketService.initialize(
        baseUrl: baseUrl,
        token: token,
        onConnectionChanged: _handleSocketConnectionChanged,
        onError: _handleSocketError,
      );

      // Set up socket event listeners
      _setupSocketEventListeners();

      _isInitialized = true;

      if (kDebugMode) {
        print('ChatManagerService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Initialization failed: $e');
      }
      _onError?.call('Failed to initialize chat manager: $e');
      rethrow;
    }
  }

  /// Set up socket event listeners
  void _setupSocketEventListeners() {
    // New message event
    _socketService.addEventListener('new_message', _handleNewMessage);

    // Message status updates
    _socketService.addEventListener(
        'message_seen_update', _handleMessageSeenUpdate);
    _socketService.addEventListener('message_received', _handleMessageReceived);
    _socketService.addEventListener(
        'messages_delivered', _handleMessagesDelivered);
    _socketService.addEventListener('messages_read', _handleMessagesRead);

    // User status events
    _socketService.addEventListener(
        'user_status_change', _handleUserStatusChange);
    _socketService.addEventListener(
        'user_started_typing', _handleUserStartedTyping);
    _socketService.addEventListener(
        'user_stopped_typing', _handleUserStoppedTyping);

    // Other events
    _socketService.addEventListener('invoice_updated', _handleInvoiceUpdated);
    _socketService.addEventListener('force_logout', _handleForceLogout);
  }

  /// Handle socket connection changes
  void _handleSocketConnectionChanged(bool isConnected) {
    if (kDebugMode) {
      print('ChatManagerService: Socket connection changed: $isConnected');
    }

    if (isConnected) {
      // Perform initial sync when connection is established
      _performInitialSync();
    }
  }

  /// Handle socket errors
  void _handleSocketError(String error) {
    if (kDebugMode) {
      print('ChatManagerService: Socket error: $error');
    }
    _onError?.call('Socket error: $error');
  }

  // MARK: - Message Handling

  /// Handle new message from socket
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final chatId = data['chat_id'] ?? data['chatId'];
      if (chatId == null) return;

      // Check if already processed
      final messageId = data['_id'] ?? data['message_id'] ?? '';
      if (messageId.isEmpty || _processedMessageIds.contains(messageId)) {
        return;
      }

      // Mark as processed
      _processedMessageIds.add(messageId);

      // Clean up processed message IDs periodically
      _scheduleMessageCleanup();

      // Parse message
      final message = ChatMessage.fromJson(data);

      // // Save to database
      // _saveMessageToDatabase(chatId, message);

      // Notify listeners
      _onNewMessage?.call(chatId, message);

      if (kDebugMode) {
        print(
            'ChatManagerService: Processed new message ${message.id} for chat $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error handling new message: $e');
      }
      _onError?.call('Error processing new message: $e');
    }
  }

  /// Handle message seen update
  void _handleMessageSeenUpdate(Map<String, dynamic> data) {
    try {
      final chatId = data['chat_id'] ?? data['chatId'];
      final messageId = data['message_id'] ?? data['messageId'];

      if (chatId != null && messageId != null) {
        _updateMessageStatus(chatId, messageId, isSeen: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error handling message seen update: $e');
      }
    }
  }

  /// Handle message received
  void _handleMessageReceived(Map<String, dynamic> data) {
    try {
      final chatId = data['chat_id'] ?? data['chatId'];
      final messageId = data['message_id'] ?? data['messageId'];

      if (chatId != null && messageId != null) {
        _updateMessageStatus(chatId, messageId, isReceived: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error handling message received: $e');
      }
    }
  }

  /// Handle messages delivered
  void _handleMessagesDelivered(Map<String, dynamic> data) {
    try {
      final chatId = data['chat_id'] ?? data['chatId'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);

      if (chatId != null && messageIds.isNotEmpty) {
        for (final messageId in messageIds) {
          _updateMessageStatus(chatId, messageId, isReceived: true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error handling messages delivered: $e');
      }
    }
  }

  /// Handle messages read
  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      final chatId = data['chat_id'] ?? data['chatId'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);

      if (chatId != null && messageIds.isNotEmpty) {
        for (final messageId in messageIds) {
          _updateMessageStatus(chatId, messageId, isRead: true, isSeen: true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error handling messages read: $e');
      }
    }
  }

  /// Handle user status change
  void _handleUserStatusChange(Map<String, dynamic> data) {
    // This can be used to update user online/offline status
    if (kDebugMode) {
      print('ChatManagerService: User status change: $data');
    }
  }

  /// Handle user started typing
  void _handleUserStartedTyping(Map<String, dynamic> data) {
    // This can be used to show typing indicators
    if (kDebugMode) {
      print('ChatManagerService: User started typing: $data');
    }
  }

  /// Handle user stopped typing
  void _handleUserStoppedTyping(Map<String, dynamic> data) {
    // This can be used to hide typing indicators
    if (kDebugMode) {
      print('ChatManagerService: User stopped typing: $data');
    }
  }

  /// Handle invoice updated
  void _handleInvoiceUpdated(Map<String, dynamic> data) {
    // This can be used to update invoice information in messages
    if (kDebugMode) {
      print('ChatManagerService: Invoice updated: $data');
    }
  }

  /// Handle force logout
  void _handleForceLogout(Map<String, dynamic> data) {
    // This can be used to force user logout
    if (kDebugMode) {
      print('ChatManagerService: Force logout: $data');
    }
  }

  // MARK: - Database Operations

  /// Update message status
  Future<void> _updateMessageStatus(
    String chatId,
    String messageId, {
    bool? isRead,
    bool? isSeen,
    bool? isReceived,
  }) async {
    // No local database service, so this is a no-op
  }

  // MARK: - Public API

  /// Send message
  Future<void> sendMessage({
    required String chatId,
    required String messageText,
    required String messageCreator,
    required String messageCreatorRole,
    required String userId,
    List<File>? files,
    Map<String, dynamic>? location,
    String? messageInvoiceRef,
    String? clientMessageId,
  }) async {
    try {
      // Create temporary message for immediate UI feedback
      final tempMessage = ChatMessage(
        id: clientMessageId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        clientMessageId: clientMessageId,
        messageText: messageText,
        messageCreator: MessageCreator(
          id: messageCreator,
          role: messageCreatorRole,
        ),
        messageDate: DateTime.now(),
        location: location,
        messageInvoiceRef: messageInvoiceRef,
        isTemp: true,
      );

      // Prepare files data for socket
      List<Map<String, dynamic>>? filesData;
      if (files != null && files.isNotEmpty) {
        filesData = files
            .map((file) async => {
                  'path': file.path,
                  'name': file.path.split('/').last,
                  'size': await file.length(),
                })
            .cast<Map<String, dynamic>>()
            .toList();
      }

      // Send via socket
      _socketService.sendMessage(
        chatId: chatId,
        messageText: messageText,
        messageCreator: messageCreator,
        messageCreatorRole: messageCreatorRole,
        userId: userId,
        files: filesData,
        location: location,
        messageInvoiceRef: messageInvoiceRef,
        clientMessageId: clientMessageId,
      );

      if (kDebugMode) {
        print('ChatManagerService: Sent message for chat $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error sending message: $e');
      }

      // Check if this is a connection error
      if (e.toString().contains('Socket not connected') ||
          e.toString().contains('Connection lost') ||
          e.toString().contains('reconnect manually')) {
        _onError?.call('Connection lost - please reconnect');
      } else {
        _onError?.call('Failed to send message: $e');
      }

      // Don't rethrow to prevent app crashes
      return;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(
      String chatId, List<String> messageIds) async {
    try {
      // No local database service, so this is a no-op

      // Send to server via socket
      _socketService.markMessagesAsRead(chatId, messageIds);

      if (kDebugMode) {
        print(
            'ChatManagerService: Marked ${messageIds.length} messages as read in chat $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error marking messages as read: $e');
      }
      _onError?.call('Failed to mark messages as read: $e');
    }
  }

  /// Mark messages as delivered
  Future<void> markMessagesAsDelivered(
      String chatId, List<String> messageIds) async {
    try {
      // No local database service, so this is a no-op

      // Send to server via socket
      _socketService.markMessagesAsDelivered(chatId, messageIds);

      if (kDebugMode) {
        print(
            'ChatManagerService: Marked ${messageIds.length} messages as delivered in chat $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error marking messages as delivered: $e');
      }
      _onError?.call('Failed to mark messages as delivered: $e');
    }
  }

  /// Update user status
  void updateUserStatus({required bool isOnline, DateTime? lastSeen}) {
    _socketService.updateUserStatus(isOnline: isOnline, lastSeen: lastSeen);
  }

  /// Start typing indicator
  void startTyping(String chatId) {
    _socketService.startTyping(chatId);
  }

  /// Stop typing indicator
  void stopTyping(String chatId) {
    _socketService.stopTyping(chatId);
  }

  // MARK: - Chat List Operations

  /// Load chat list from server
  Future<List<Chats>> loadChatList({String? userRole}) async {
    try {
      final response = await DioHelper.getData(
        endPoint: userRole == 'business'
            ? Constants.chatBusinessList
            : Constants.chatCustomerList,
      );

      if (response?.data != null) {
        final data = response!.data;
        if (data['status'] == true && data['data'] != null) {
          final autogenerated = Autogenerated.fromJson(data);
          if (autogenerated.data?.chats != null) {
            final chats = autogenerated.data!.chats!;

            // Notify listeners
            _onChatListUpdated?.call(chats);

            if (kDebugMode) {
              print(
                  'ChatManagerService: Loaded ${chats.length} chats from server');
            }

            return chats;
          }
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error loading chat list: $e');
      }
      _onError?.call('Failed to load chat list: $e');
      rethrow;
    }
  }

  /// Get chat list
  Future<List<Chats>> getChatList({String? userRole}) async {
    // No local database service, so return empty list
    return [];
  }

  /// Load messages for a chat
  Future<List<ChatMessage>> loadMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
    bool fromServer = false,
  }) async {
    try {
      if (fromServer) {
        // Load from server
        final response = await DioHelper.getData(
          endPoint: '${Constants.chatMessages}/$chatId',
          queryParameters: {'skip': offset, 'limit': limit},
        );

        if (response?.data != null) {
          final data = response!.data;
          if (data['status'] == true) {
            final messages = (data['data']['messages'] as List)
                .map((msg) => ChatMessage.fromJson(msg))
                .toList();

            if (kDebugMode) {
              print(
                  'ChatManagerService: Loaded ${messages.length} messages from server for chat $chatId');
            }

            return messages;
          }
        }

        return [];
      } else {
        // No local database service, so return empty list
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error loading messages: $e');
      }
      _onError?.call('Failed to load messages: $e');
      rethrow;
    }
  }

  /// Get messages
  Future<List<ChatMessage>> getMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    // No local database service, so return empty list
    return [];
  }

  // MARK: - Sync Operations

  /// Perform initial sync when connection is established
  Future<void> _performInitialSync() async {
    try {
      // Sync chat list
      await loadChatList();

      if (kDebugMode) {
        print('ChatManagerService: Initial sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error during initial sync: $e');
      }
    }
  }

  /// Sync specific chat
  Future<void> syncChat(String chatId) async {
    if (_isSyncing[chatId] == true) return;

    _isSyncing[chatId] = true;

    try {
      // Check if sync is needed
      final lastSync = _lastSyncTime[chatId];
      final now = DateTime.now();

      if (lastSync == null || now.difference(lastSync).inMinutes > 5) {
        // Load messages from server
        await loadMessages(chatId, fromServer: true);
        _lastSyncTime[chatId] = now;

        if (kDebugMode) {
          print('ChatManagerService: Synced chat $chatId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatManagerService: Error syncing chat $chatId: $e');
      }
    } finally {
      _isSyncing[chatId] = false;
    }
  }

  // MARK: - Utility Methods

  /// Schedule cleanup of processed message IDs
  void _scheduleMessageCleanup() {
    if (_processedMessageIds.length > 1000) {
      _processedMessageIds.clear();

      if (kDebugMode) {
        print('ChatManagerService: Cleaned up processed message IDs');
      }
    }
  }

  /// Get service statistics
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'isSocketConnected': isSocketConnected,
      'processedMessageIds': _processedMessageIds.length,
    };
  }

  /// Dispose service
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Cancel cleanup timers
    for (final timer in _messageCleanupTimers.values) {
      timer.cancel();
    }
    _messageCleanupTimers.clear();

    // Clear processed message IDs
    _processedMessageIds.clear();

    // Dispose services
    _socketService.dispose();

    if (kDebugMode) {
      print('ChatManagerService: Disposed');
    }
  }
}
