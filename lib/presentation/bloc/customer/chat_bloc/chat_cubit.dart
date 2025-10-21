import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/data/dio_helper.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/services/chat_service.dart'
    show ChatService, ProgressCallback;
import 'package:path/path.dart' as path;
import 'package:spreadlee/services/enhanced_message_status_handler.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/domain/services/media_cache_service.dart';
import 'package:spreadlee/core/di.dart';
import 'chat_state.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../../../../utils/sound_utils.dart';

class ChatCustomerCubit extends Cubit<ChatCustomerState> {
  final ChatService _chatService = ChatService(); // Use singleton
  final MediaCacheService _mediaCacheService;
  final EnhancedMessageStatusHandler _statusHandler =
  EnhancedMessageStatusHandler();
  List<Chats> chat = [];
  Map<String, List<ChatMessage>> chatMessages = {};
  FToast fToast = FToast();
  bool _isSocketInitialized = false;
  late ScrollController _scrollController;
  String? _currentChatId;
  BuildContext? _context;
  final Set<String> _processedMessageIds = {};
  bool _isDisposed = false;
  bool _isChatListManagerInitialized = false;
  // Add per-chat sync flag
  final Map<String, bool> _isSyncing = {};
  String? currentlyOpenChatId; // Track open chat
  Map<String, String> lastSeenMessageId = {}; // chatId -> messageId

  // Pagination variables
  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMoreChats = true;
  bool _isLoadingMore = false;
  String? _lastChatId; // For cursor-based pagination

  // Add user status tracking
  final Map<String, Map<String, bool>> _userOnlineStatus =
  {}; // chatId -> {userId -> isOnline}
  final Map<String, DateTime> _userLastSeen = {}; // userId -> lastSeen

  ChatCustomerCubit()
      : _mediaCacheService = instance<MediaCacheService>(),
        super(const ChatCustomerInitialState()) {
    _scrollController = ScrollController();
    // Initialize socket listeners when ready
    initializeSocketWhenReady();
    // Initialize chat list manager in background (non-blocking)
    Future.microtask(() => _initializeChatListManager());
  }

  static ChatCustomerCubit get(context) => BlocProvider.of(context);

  /// Initialize chat list manager service
  Future<void> _initializeChatListManager() async {
    if (_isDisposed || _isChatListManagerInitialized) return;

    try {
      // Database services are no longer used
      if (kDebugMode) {
        print(
            'ChatCustomerCubit: Database services removed, skipping initialization');
      }

      _isChatListManagerInitialized = true;

      if (kDebugMode) {
        print('ChatCustomerCubit: Chat list manager initialization skipped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatCustomerCubit: Error in initialization: $e');
      }
    }
  }

  /// Reinitialize chat service with updated token
  void reinitializeWithToken(String token) {
    if (_isDisposed) return;

    if (kDebugMode) {
      print('ChatCustomerCubit: Reinitializing with token');
    }

    // Disconnect current service
    _chatService.disconnect();

    // Update singleton with new token
    _chatService.token = token;
    _chatService.baseUrl = Constants.baseUrl;

    // Reinitialize socket
    _isSocketInitialized = false;
    _chatService.initializeSocket();

    // Reinitialize chat list manager in background (non-blocking)
    _isChatListManagerInitialized = false;
    Future.microtask(() => _initializeChatListManager());
  }

  void init(BuildContext context) {
    if (_isDisposed) return;
    _context = context;
    fToast.init(context);
    getCustomerChats();
  }

  /// Initialize socket when ChatService is ready
  void initializeSocketWhenReady() {
    if (_isSocketInitialized) {
      return;
    }

    try {
      // Check if socket is available
      final socket = _chatService.socket;
      if (socket.connected) {
        _initializeSocket();
      } else {
        if (kDebugMode) {
          print('ChatService socket not connected yet, will retry later');
        }
        // Retry after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (!_isSocketInitialized) {
            initializeSocketWhenReady();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatService socket not ready yet: $e');
      }
      // Retry after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (!_isSocketInitialized) {
          initializeSocketWhenReady();
        }
      });
    }
  }

  void _initializeSocket() {
    if (_isSocketInitialized) {
      if (kDebugMode) {
        print('Socket already initialized');
      }
      return;
    }

    // Check if ChatService socket is initialized before accessing it
    try {
      if (kDebugMode) {
        print('=== CUBIT: Initializing socket in ChatCustomerCubit ===');
        print('Socket connected: ${_chatService.socket.connected}');
        print('Socket ID: ${_chatService.socket.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChatService socket not initialized yet: $e');
        print('Skipping socket initialization in ChatCubit');
      }
      return;
    }

    _chatService.addOnNewMessageListener(_onNewMessageHandler);

    if (kDebugMode) {
      print('=== CUBIT: Socket listener added successfully ===');
    }

    // Listen for message_sent events (for sender's own messages)
    if (kDebugMode) {
      print('=== ChatCubit: Registering message_sent callback ===');
    }
    _chatService.onMessageSent((data) {
      if (kDebugMode) {
        print('=== Customer Cubit: Message Sent Event ===');
        print('Data: $data');
        print('Received at: ${DateTime.now()}');
      }
      _handleMessageSent(data);
    });
    if (kDebugMode) {
      print('=== ChatCubit: message_sent callback registered successfully ===');
    }

    _chatService.onMessagesRead((data) {
      if (kDebugMode) {
        print('=== Customer Cubit: Messages Read Event ===');
        print('Received data: $data');
        print('Data keys: ${data.keys.toList()}');
      }

      // Support both 'chat_id' and 'chatId' keys
      final chatId = data['chat_id'] ?? data['chatId'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);
      final userId = data['userId'] ?? data['user_id'];

      if (kDebugMode) {
        print('Extracted chatId: $chatId');
        print('Extracted messageIds: $messageIds');
        print('Extracted userId: $userId');
        print('Current user ID: ${Constants.userId}');
      }

      // Only reset unread counter if the current customer marked the messages as read
      // This prevents the business user marking messages as read from resetting the customer's unread counter
      if (chatId != null &&
          messageIds.isNotEmpty &&
          userId == Constants.userId) {
        final chatIndex = chat.indexWhere((c) => c.sId == chatId);
        if (chatIndex != -1) {
          final updatedChat = chat[chatIndex].copyWith(
            chatNotSeenMessages: 0,
          );
          chat[chatIndex] = updatedChat;
          emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
          if (kDebugMode) {
            print(
                '=== Customer Cubit: Reset unread counter to 0 for chat $chatId (customer marked as read) ===');
          }
        }
      } else if (chatId != null &&
          messageIds.isNotEmpty &&
          userId != Constants.userId) {
        if (kDebugMode) {
          print(
              '=== Customer Cubit: Ignoring messages_read event from other user $userId ===');
          print(
              'This prevents business user from resetting customer unread counter');
        }
      }

      // Always update message statuses regardless of who marked them as read
      // This ensures read receipts work properly for both participants
      if (chatId != null && messageIds.isNotEmpty) {
        if (chatMessages.containsKey(chatId)) {
          final messages = chatMessages[chatId]!;
          var hasChanges = false;

          for (var message in messages) {
            if (messageIds.contains(message.id)) {
              // When a message is marked as read, it should progress to "seen" status
              // If the backend doesn't provide isSeen/isReceived, we infer them:
              // - If message is now read, it should be both received and seen
              final updatedMessage = message.copyWith(
                isRead: true,
                isSeen:
                data['isSeen'] ?? true, // If marked as read, assume seen
                isReceived: data['isReceived'] ??
                    true, // If marked as read, assume received
              );
              final index = messages.indexWhere((m) => m.id == message.id);
              if (index != -1) {
                messages[index] = updatedMessage;
                hasChanges = true;

                if (kDebugMode) {
                  print(
                      'Updated message ${message.id} with isSeen: ${updatedMessage.isSeen}, isReceived: ${updatedMessage.isReceived}, isRead: ${updatedMessage.isRead}');
                }
              }
            }
          }

          if (hasChanges) {
            chatMessages[chatId] = messages;
            emit(ChatCustomerMessagesSuccessState(
              messages: List<ChatMessage>.from(messages),
              chatId: chatId,
            ));

            if (kDebugMode) {
              print('Emitted ChatMessagesSuccessState for real-time update');
            }
          }
        }
      }
    });

    // Add new socket event handlers
    _chatService.onUserStatusChange((data) {
      if (kDebugMode) {
        print('=== User Status Change Event ===');
        print('Data: $data');
      }

      final eventChatId = data['chatId'] ?? data['chat_id'];
      final eventUserId = data['userId'] ?? data['user_id'];
      final isOnline = data['isOnline'] as bool? ?? false;
      final timestamp = data['timestamp'] != null
          ? DateTime.parse(data['timestamp'].toString())
          : DateTime.now();

      if (eventChatId != null && eventUserId != null) {
        // Update user online status tracking
        if (!_userOnlineStatus.containsKey(eventChatId)) {
          _userOnlineStatus[eventChatId] = {};
        }
        _userOnlineStatus[eventChatId]![eventUserId] = isOnline;

        // Update last seen timestamp only when going offline
        if (!isOnline) {
          _userLastSeen[eventUserId] = timestamp;
        } else {
          // When going online, remove from last seen
          _userLastSeen.remove(eventUserId);
        }

        // Update chat list with user status
        final chatIndex = chat.indexWhere((c) => c.sId == eventChatId);
        if (chatIndex != -1) {
          if (kDebugMode) {
            print(
                'User $eventUserId is now ${isOnline ? 'online' : 'offline'} in chat $eventChatId');
            print('Updated user status tracking: $_userOnlineStatus');
          }

          // Emit state to trigger UI update
          _notifyRealTimeUpdate();
        }
      }
    });

    _chatService.onMessageSeenUpdate((data) {
      if (kDebugMode) {
        print('=== Message Seen Update Event ===');
        print('Received data: $data');
        print('Data keys: ${data.keys.toList()}');
        print('Data type: ${data.runtimeType}');
        if (!data.containsKey('isSeen') || !data.containsKey('isReceived')) {
          print(
              'isSeen or isReceived missing in message_seen_update event. readBy: \\${data['readBy']}');
        }
      }

      final eventChatId = data['chatId'] ?? data['chat_id'];
      final messageId = data['messageId'] ?? data['message_id'];
      final eventUserId = data['userId'] ?? data['user_id'];
      final seenAt = data['seenAt'] != null
          ? DateTime.parse(data['seenAt'].toString())
          : DateTime.now();

      // Ignore events for sender's own messages
      if (eventUserId == Constants.userId) {
        if (kDebugMode) {
          print(
              'Ignoring message_seen_update event for sender\'s own message: $messageId');
        }
        return;
      }

      // Update last seen message ID to the latest in this chat
      if (eventChatId != null && messageId != null) {
        lastSeenMessageId[eventChatId] = messageId;
      }

      // Reset unread counter for this chat (same as business implementation)
      if (eventChatId != null) {
        final chatIndex = chat.indexWhere((c) => c.sId == eventChatId);
        if (chatIndex != -1) {
          final updatedChat = chat[chatIndex].copyWith(chatNotSeenMessages: 0);
          chat[chatIndex] = updatedChat;
          emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
          if (kDebugMode) {
            print(
                '=== CUBIT: Reset unread counter to 0 for chat $eventChatId ===');
          }
        }
      }

      if (eventChatId != null && messageId != null) {
        // Update message read status in chatMessages
        if (chatMessages.containsKey(eventChatId)) {
          final messages = chatMessages[eventChatId]!;
          if (kDebugMode) {
            print('Found ${messages.length} messages in chat');
            print('Message IDs in chat: ${messages.map((m) => m.id).toList()}');
          }
          final messageIndex = messages.indexWhere((m) => m.id == messageId);
          if (kDebugMode) {
            print('Looking for messageId: $messageId');
            print('Found at index: $messageIndex');
          }
          if (messageIndex != -1) {
            final updatedMessage = messages[messageIndex].copyWith(
              isRead: true,
              isSeen: data['isSeen'] ?? messages[messageIndex].isSeen,
              isReceived:
              data['isReceived'] ?? messages[messageIndex].isReceived,
            );
            messages[messageIndex] = updatedMessage;
            chatMessages[eventChatId] = messages;

            // Use EnhancedMessageStatusHandler to immediately update UI
            _statusHandler.updateMessageStatus(
              chatId: eventChatId,
              messageId: messageId,
              isRead: true,
              isSeen: data['isSeen'] ?? messages[messageIndex].isSeen,
              isReceived:
              data['isReceived'] ?? messages[messageIndex].isReceived,
              timestamp: seenAt,
            );

            if (kDebugMode) {
              print('Updated message $messageId');
              print('isRead: ${updatedMessage.isRead}');
              print('isSeen: ${updatedMessage.isSeen}');
              print('isReceived: ${updatedMessage.isReceived}');
              print(
                  'Status updated via MessageStatusHandler - no state emission to prevent message duplication');
            }
          } else {
            if (kDebugMode) {
              print('Message $messageId not found in chat messages');
            }
          }
        } else {
          if (kDebugMode) {
            print('Chat $eventChatId not found in chatMessages');
          }
        }
      } else {
        if (kDebugMode) {
          print('Invalid data: chatId=$eventChatId, messageId=$messageId');
        }
      }
      if (eventChatId != null && messageId != null) {
        lastSeenMessageId[eventChatId] = messageId;
      }
    });

    _chatService.onMessageReceived((data) {
      if (kDebugMode) {
        print('=== Message Received Event ===');
        print('Data: $data');
      }

      _handleMessageReceived(data);
    });

    _chatService.onMessagesDelivered((data) {
      if (kDebugMode) {
        print('=== Messages Delivered Event ===');
        print('Received data: $data');
        print('Data keys: ${data.keys.toList()}');
        print('Data type: ${data.runtimeType}');
      }

      final eventChatId = data['chatId'] ?? data['chat_id'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);

      if (kDebugMode) {
        print('Extracted chatId: $eventChatId');
        print('Extracted messageIds: $messageIds');
        print('Current chatMessages keys: ${chatMessages.keys.toList()}');
        print(
            'Has chatMessages for this chat: ${chatMessages.containsKey(eventChatId)}');
      }

      if (eventChatId != null && messageIds.isNotEmpty) {
        // Update message delivery status in chatMessages
        if (chatMessages.containsKey(eventChatId)) {
          final messages = chatMessages[eventChatId]!;
          if (kDebugMode) {
            print('Found ${messages.length} messages in chat');
            print('Message IDs in chat: ${messages.map((m) => m.id).toList()}');
          }
          var hasChanges = false;

          for (final messageId in messageIds) {
            final messageIndex = messages.indexWhere((m) => m.id == messageId);
            if (kDebugMode) {
              print('Looking for messageId: $messageId');
              print('Found at index: $messageIndex');
            }
            if (messageIndex != -1) {
              final updatedMessage = messages[messageIndex].copyWith(
                isReceived: true,
              );
              messages[messageIndex] = updatedMessage;
              hasChanges = true;

              if (kDebugMode) {
                print('Updated message $messageId with isReceived: true');
                print(
                    'Message isReceived after update: ${updatedMessage.isReceived}');
              }
            } else {
              if (kDebugMode) {
                print('Message $messageId not found in chat messages');
              }
            }
          }

          if (hasChanges) {
            chatMessages[eventChatId] = messages;

            // Use EnhancedMessageStatusHandler to immediately update UI
            for (final messageId in messageIds) {
              _statusHandler.updateMessageStatus(
                chatId: eventChatId,
                messageId: messageId,
                isDelivered: true,
                timestamp: DateTime.now(),
              );
            }

            if (kDebugMode) {
              print(
                  'Status updated via MessageStatusHandler for ${messageIds.length} messages - no state emission to prevent message duplication');
            }
          } else {
            if (kDebugMode) {
              print('No changes detected, not emitting state');
            }
          }
        } else {
          if (kDebugMode) {
            print('Chat $eventChatId not found in chatMessages');
          }
        }
      } else {
        if (kDebugMode) {
          print('Invalid data: chatId=$eventChatId, messageIds=$messageIds');
        }
      }
    });

    _chatService.onInvoiceUpdated((data) {
      if (_isDisposed) return;
      if (kDebugMode) print('Received invoice_updated: $data');
      final updatedInvoice = data['invoice'];
      final chatIdFromEvent = data['chatId'];
      var invoiceId = data['invoiceId'];
      if (invoiceId is Map && invoiceId.containsKey('_id')) {
        invoiceId = invoiceId['_id'];
      }
      if (chatIdFromEvent != null && updatedInvoice != null) {
        if (chatMessages.containsKey(chatIdFromEvent)) {
          final messages = chatMessages[chatIdFromEvent]!;
          bool updated = false;
          for (int i = 0; i < messages.length; i++) {
            final msg = messages[i];
            final msgInvoice = msg.messageInvoice ?? msg.messageInvoiceRef;
            String? msgInvoiceId;
            if (msgInvoice is String) {
              msgInvoiceId = msgInvoice;
            } else if (msgInvoice is Map) {
              msgInvoiceId = msgInvoice['_id']?.toString();
            }
            if (msgInvoiceId != null && msgInvoiceId == invoiceId) {
              messages[i] = msg.copyWith(
                messageInvoice: updatedInvoice,
                messageInvoiceRef: updatedInvoice['_id']?.toString(),
                invoiceData: updatedInvoice, // ✅ Also update invoiceData field
              );
              updated = true;
            }
          }
          if (updated) {
            chatMessages[chatIdFromEvent] = messages;

            // Always emit a state update to refresh the UI, regardless of current state
            if (state is ChatCustomerMessagesSuccessState &&
                (state as ChatCustomerMessagesSuccessState).chatId ==
                    chatIdFromEvent) {
              // If viewing this chat's messages, emit ChatCustomerMessagesSuccessState
              emit(ChatCustomerMessagesSuccessState(
                messages: List<ChatMessage>.from(messages),
                chatId: chatIdFromEvent,
                hasMore: (state as ChatCustomerMessagesSuccessState).hasMore,
                uploadProgress:
                (state as ChatCustomerMessagesSuccessState).uploadProgress,
              ));
            } else if (state is ChatCustomerSuccessState) {
              // If on chat list, emit ChatCustomerSuccessState to refresh the list
              emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
            }

            if (kDebugMode) {
              print('Invoice updated in chat $chatIdFromEvent - UI refreshed');
            }
          }
        }
      }

      // Notify UI of real-time update
      _notifyRealTimeUpdate();
    });

    _isSocketInitialized = true;
    if (kDebugMode) {
      print('Socket initialization completed');
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('=== Customer Cubit: Handling Message Sent ===');
      print('Data: $data');
    }

    final tempId = data['tempId'] ?? data['client_message_id'];
    final permanentId = data['_id'] ?? data['messageId'];
    final chatId = data['chat_id'] ?? data['chatId'];

    if (kDebugMode) {
      print('TempId: $tempId');
      print('PermanentId: $permanentId');
      print('ChatId: $chatId');
    }

    if (tempId != null && permanentId != null && chatId != null) {
      // Find and replace the temporary message
      if (chatMessages.containsKey(chatId)) {
        final messages = chatMessages[chatId]!;

        // Try multiple matching strategies
        int tempIndex = -1;

        // Strategy 1: Exact tempId match
        tempIndex = messages.indexWhere((m) => m.id == tempId);

        // Strategy 2: If no exact match, try clientMessageId match
        if (tempIndex == -1 && data['client_message_id'] != null) {
          final clientMessageId = data['client_message_id'];
          tempIndex = messages.indexWhere((m) =>
          m.clientMessageId == clientMessageId && m.id.startsWith('temp_'));
        }

        // Strategy 3: If still no match, try timestamp-based matching for recent messages
        if (tempIndex == -1) {
          final serverTimestamp = data['messageDate'] != null
              ? DateTime.parse(data['messageDate'])
              : DateTime.now();

          tempIndex = messages.indexWhere((m) =>
          m.id.startsWith('temp_') &&
              m.messageCreator?.id == data['messageCreator'] &&
              m.messageDate != null &&
              (m.messageDate!.difference(serverTimestamp).inSeconds).abs() <
                  30);
        }

        // Strategy 4: For media messages, try content matching
        if (tempIndex == -1) {
          final messageType = data['messageType'];
          if (messageType == 'video' && data['messageVideo'] != null) {
            tempIndex = messages.indexWhere((m) =>
            m.id.startsWith('temp_') &&
                m.messageCreator?.id == data['messageCreator'] &&
                m.messageVideo != null &&
                m.messageVideo!.contains(data['messageVideo'].split('/').last));
          } else if (messageType == 'image' && data['messagePhotos'] != null) {
            tempIndex = messages.indexWhere((m) =>
            m.id.startsWith('temp_') &&
                m.messageCreator?.id == data['messageCreator'] &&
                m.messagePhotos?.isNotEmpty == true);
          }
        }

        if (tempIndex != -1) {
          if (kDebugMode) {
            print('=== Message Sent Handler - Found Temp Message ===');
            print('Temp message found at index: $tempIndex');
            print('Temp message ID: ${messages[tempIndex].id}');
            print('Server tempId: $tempId');
            print('Permanent ID: $permanentId');
          }
          if (kDebugMode) {
            print('Found temporary message at index $tempIndex');
            print(
                'Replacing temp message $tempId with permanent message $permanentId');
          }

          // Parse the server response to get the actual message data
          Map<String, dynamic> messageData;
          if (data['message'] != null) {
            messageData = data['message'] as Map<String, dynamic>;
          } else {
            messageData = data;
          }

          // Create permanent message with server data
          final permanentMessage = ChatMessage.fromJson(messageData);

          if (kDebugMode) {
            print('=== Message Sent Handler - Timestamp Debug ===');
            print('Temp message ID: $tempId');
            print('Permanent message ID: $permanentId');
            print('Temp message date: ${messages[tempIndex].messageDate}');
            print('Permanent message date: ${permanentMessage.messageDate}');
            print('Server message data: ${jsonEncode(messageData)}');
          }

          // Replace the temporary message
          final updatedMessages = List<ChatMessage>.from(messages);
          updatedMessages[tempIndex] = permanentMessage;
          chatMessages[chatId] = updatedMessages;

          // Add the permanent message ID to processed set to prevent duplicates from new_message events
          _processedMessageIds.add(permanentId);

          // Emit updated state
          emit(ChatCustomerMessagesSuccessState(
            messages: updatedMessages,
            chatId: chatId,
          ));

          if (kDebugMode) {
            print(
                'Successfully replaced temporary message with permanent message');
            print('Added permanent message ID $permanentId to processed set');
            print('Message photos: ${permanentMessage.messagePhotos}');
            print('Message videos: ${permanentMessage.messageVideos}');
            print('Message document: ${permanentMessage.messageDocument}');
          }
        } else {
          if (kDebugMode) {
            print('Temporary message $tempId not found in chat $chatId');
          }
        }
      } else {
        if (kDebugMode) {
          print('Chat $chatId not found in chatMessages');
        }
      }
    } else {
      if (kDebugMode) {
        print(
            'Missing required fields: tempId=$tempId, permanentId=$permanentId, chatId=$chatId');
      }
    }
  }

  void _onNewMessageHandler(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('=== CUBIT: New Message Event Handler CALLED ===');
      print('Raw data: $data');
      print('Socket connected: ${_chatService.socket.connected}');
      print('Socket ID: ${_chatService.socket.id}');
      print('Current state: ${state.runtimeType}');
      print('Handler called at: ${DateTime.now()}');
    }

    // Support both 'chat_id' and 'chatId' keys
    final chatId = data['chat_id'] ?? data['chatId'];
    Map<String, dynamic>? messageData;
    if (data['message'] != null) {
      messageData = data['message'] as Map<String, dynamic>;
    } else {
      // If the socket sends the message directly (not wrapped)
      messageData = data;
    }

    if (chatId != null) {
      // Get message ID and check if already processed
      final messageId = messageData['_id'] ?? messageData['message_id'] ?? '';
      final messageCreatorRole =
          messageData['messageCreatorRole']?.toString() ?? '';

      if (kDebugMode) {
        print('Processing message:');
        print('- Chat ID: $chatId');
        print('- Message ID: $messageId');
        print('- Message Creator Role: $messageCreatorRole');
        print(
            '- Already processed: ${_processedMessageIds.contains(messageId)}');
        print('=== Raw Message Data ===');
        print('messageData: $messageData');
        print('messageCreator field: ${messageData['messageCreator']}');
        print(
            'messageCreator type: ${messageData['messageCreator']?.runtimeType}');
        print('messageCreatorRole field: ${messageData['messageCreatorRole']}');
      }

      // Temporarily remove role-based filtering to debug the issue
      final creatorRole = messageCreatorRole.toLowerCase();

      // Handle both cases: messageCreator as String or as Map
      String creatorUserRole = '';
      if (messageData['messageCreator'] is Map) {
        creatorUserRole =
            messageData['messageCreator']?['role']?.toString().toLowerCase() ??
                '';
      } else if (messageData['messageCreator'] is String) {
        // If messageCreator is a string (user ID), we can't get role from it
        // Use the messageCreatorRole field instead
        creatorUserRole = messageCreatorRole.toLowerCase();
      }

      if (kDebugMode) {
        print('Role check:');
        print('- messageCreatorRole: $messageCreatorRole');
        print('- creatorRole (lowercase): $creatorRole');
        print('- creatorUserRole: $creatorUserRole');
        print('Processing all messages for debugging...');
      }

      // Comment out role filtering temporarily
      /*
      // Skip if it's from a business user (company, business, admin)
      final isBusinessUser = creatorRole == 'company' || 
                           creatorRole == 'business' || 
                           creatorRole == 'admin' ||
                           creatorUserRole == 'company' || 
                           creatorUserRole == 'business' || 
                           creatorUserRole == 'admin';
                           
      if (isBusinessUser) {
        if (kDebugMode) {
          print('Skipping message from business role: $messageCreatorRole (user role: $creatorUserRole)');
        }
        return;
      }
      */

      // Skip messages that were created by upload_file events (they have optimistic_ IDs)
      // These are duplicates of messages already created by the upload methods
      if (messageId.startsWith('optimistic_') &&
          messageData['messageCreator'] == Constants.userId &&
          messageCreatorRole == Constants.role) {
        if (kDebugMode) {
          print('=== Skipping upload_file created message ===');
          print('Message ID: $messageId');
          print('Message Creator: ${messageData['messageCreator']}');
          print('Message Creator Role: $messageCreatorRole');
          print('Current User ID: ${Constants.userId}');
          print('Current User Role: ${Constants.role}');
        }
        return;
      }

      if (messageId.isEmpty || _processedMessageIds.contains(messageId)) {
        if (kDebugMode) {
          print('Skipping duplicate message: $messageId');
        }
        return;
      }

      // Additional check: if this message already exists in chatMessages, skip it
      if (chatMessages.containsKey(chatId)) {
        final existingMessage =
        chatMessages[chatId]!.any((m) => m.id == messageId);
        if (existingMessage) {
          if (kDebugMode) {
            print(
                'Skipping message that already exists in chatMessages: $messageId');
          }
          return;
        }

        // Additional check: if this message was already handled by _handleMessageSent
        // Check if there's a message with the same clientMessageId that was already processed
        if (messageData['client_message_id'] != null) {
          final clientMessageId = messageData['client_message_id'];
          final alreadyHandled = chatMessages[chatId]!.any((m) =>
          m.clientMessageId == clientMessageId &&
              !m.id.startsWith('temp_'));
          if (alreadyHandled) {
            if (kDebugMode) {
              print(
                  'Skipping message already handled by _handleMessageSent: $messageId (clientMessageId: $clientMessageId)');
            }
            return;
          }
        }
      }

      // Add to processed messages
      _processedMessageIds.add(messageId);

      // Limit the size of processed messages set
      if (_processedMessageIds.length > 1000) {
        _processedMessageIds.clear();
      }

      // Always use ChatMessage.fromJson for parsing
      if (kDebugMode) {
        print('=== DEBUG: Raw message data before parsing ===');
        print('messageData: ${jsonEncode(messageData)}');
        print('messageType: ${messageData['messageType']}');
        print('invoiceData: ${messageData['invoiceData']}');
        print('messageInvoiceRef: ${messageData['messageInvoiceRef']}');
      }
      final newMessage = ChatMessage.fromJson(messageData);

      if (kDebugMode) {
        print('=== New Message Handler - Timestamp Debug ===');
        print('New message ID: ${newMessage.id}');
        print('New message date: ${newMessage.messageDate}');
        print('New message clientMessageId: ${newMessage.clientMessageId}');
        print('New message text: ${newMessage.messageText}');
        print('New message photos: ${newMessage.messagePhotos}');
        print('New message videos: ${newMessage.messageVideos}');
        print('New message document: ${newMessage.messageDocument}');
        print('Server message data: ${jsonEncode(messageData)}');
      }

      if (kDebugMode) {
        print('=== Parsed Message Debug ===');
        print('Message ID: ${newMessage.id}');
        print('Message Creator ID: ${newMessage.messageCreator?.id}');
        print('Message Creator Role: ${newMessage.messageCreator?.role}');
        print(
            'Message Creator Role (direct): ${newMessage.messageCreatorRole}');
        print('Constants.userId: ${Constants.userId}');
        print('Constants.role: ${Constants.role}');
      }

      // Always update the chatMessages map regardless of current state
      // This ensures temporary messages are properly replaced even if state changes
      if (chatMessages.containsKey(chatId)) {
        final messages = chatMessages[chatId]!;

        // Check if this message is from the current user (sender)
        // Use messageCreatorRole instead of messageCreator.id due to backend issue
        final isFromCurrentUser =
            newMessage.messageCreatorRole?.toLowerCase() ==
                Constants.role.toLowerCase();

        // Check if this is a replacement for a temporary message
        int tempMessageIndex = -1;

        // First try to match by clientMessageId (most reliable)
        if (newMessage.clientMessageId != null) {
          tempMessageIndex = messages.indexWhere((m) =>
          m.id.startsWith('temp_') &&
              m.clientMessageId == newMessage.clientMessageId);
        }

        // If no match by clientMessageId, try content matching for text messages
        if (tempMessageIndex == -1 &&
            newMessage.messageText?.isNotEmpty == true) {
          tempMessageIndex = messages.indexWhere((m) =>
          m.id.startsWith('temp_') &&
              m.messageText == newMessage.messageText &&
              m.messageCreator?.id == newMessage.messageCreator?.id &&
              m.messageDate != null &&
              newMessage.messageDate != null &&
              (m.messageDate!.difference(newMessage.messageDate!).inSeconds)
                  .abs() <
                  30);
        }

        // For messages from current user, try timestamp-based matching
        if (tempMessageIndex == -1 && isFromCurrentUser) {
          tempMessageIndex = messages.indexWhere((m) =>
          m.id.startsWith('temp_') &&
              m.messageCreator?.id == newMessage.messageCreator?.id &&
              m.messageDate != null &&
              newMessage.messageDate != null &&
              (m.messageDate!.difference(newMessage.messageDate!).inSeconds)
                  .abs() <
                  5); // Very tight time window for current user messages
        }

        // Additional fallback: match by media content for video/image/document messages
        if (tempMessageIndex == -1) {
          if (newMessage.messageVideo != null) {
            // For video messages, match by creator and timestamp (more reliable than URL matching)
            tempMessageIndex = messages.indexWhere((m) =>
            m.id.startsWith('temp_') &&
                m.messageCreator?.id == newMessage.messageCreator?.id &&
                (m.messageVideo != null ||
                    m.messageVideos?.isNotEmpty == true) &&
                m.messageDate != null &&
                newMessage.messageDate != null &&
                (m.messageDate!.difference(newMessage.messageDate!).inSeconds)
                    .abs() <
                    10);
          } else if (newMessage.messagePhotos?.isNotEmpty == true) {
            tempMessageIndex = messages.indexWhere((m) =>
            m.id.startsWith('temp_') &&
                m.messagePhotos?.isNotEmpty == true &&
                m.messagePhotos!.any(
                        (photo) => newMessage.messagePhotos!.contains(photo)) &&
                m.messageCreator?.id == newMessage.messageCreator?.id);
          } else if (newMessage.messageDocument != null) {
            tempMessageIndex = messages.indexWhere((m) =>
            m.id.startsWith('temp_') &&
                m.messageDocument != null &&
                m.messageDocument == newMessage.messageDocument &&
                m.messageCreator?.id == newMessage.messageCreator?.id);
          }
        }

        // Enhanced matching for video messages - check if temp message has local file and new message has server URL
        if (tempMessageIndex == -1 && newMessage.messageVideo != null) {
          tempMessageIndex = messages.indexWhere((m) =>
          m.id.startsWith('temp_') &&
              m.messageCreator?.id == newMessage.messageCreator?.id &&
              m.messageVideo != null &&
              m.messageVideo!.startsWith('/') && // Local file path
              newMessage.messageVideo!.startsWith('http') && // Server URL
              m.messageDate != null &&
              newMessage.messageDate != null &&
              (m.messageDate!.difference(newMessage.messageDate!).inSeconds)
                  .abs() <
                  30);
        }

        if (kDebugMode) {
          if (tempMessageIndex != -1) {
            print(
                'DEBUG: Found matching temporary message at index $tempMessageIndex');
            print('DEBUG: Temp message ID: ${messages[tempMessageIndex].id}');
            print(
                'DEBUG: Temp message clientMessageId: ${messages[tempMessageIndex].clientMessageId}');
            print(
                'DEBUG: New message clientMessageId: ${newMessage.clientMessageId}');
            print(
                'DEBUG: Temp message video: ${messages[tempMessageIndex].messageVideo}');
            print('DEBUG: New message video: ${newMessage.messageVideo}');
          } else {
            print('DEBUG: No matching temporary message found');
            print('DEBUG: New message ID: ${newMessage.id}');
            print(
                'DEBUG: New message clientMessageId: ${newMessage.clientMessageId}');
            print('DEBUG: New message video: ${newMessage.messageVideo}');
            print(
                'DEBUG: Available temp messages: ${messages.where((m) => m.id.startsWith('temp_')).map((m) => '${m.id} (video: ${m.messageVideo})').toList()}');
          }
        }

        if (tempMessageIndex != -1) {
          // Replace the temporary message with the real one
          final tempMsg = messages[tempMessageIndex];
          ChatMessage finalMessage = newMessage;
          if (tempMsg.messageCreator?.id == newMessage.messageCreator?.id) {
            finalMessage = newMessage.copyWith(
              messagePhotos: tempMsg.messagePhotos?.isNotEmpty == true
                  ? tempMsg.messagePhotos
                  : newMessage.messagePhotos,
              messageVideos: tempMsg.messageVideos?.isNotEmpty == true
                  ? tempMsg.messageVideos
                  : newMessage.messageVideos,
              messageDocument: tempMsg.messageDocument?.isNotEmpty == true
                  ? tempMsg.messageDocument
                  : newMessage.messageDocument,
              messageAudio: tempMsg.messageAudio?.isNotEmpty == true
                  ? tempMsg.messageAudio
                  : newMessage.messageAudio,
            );
          }

          final updatedMessages = List<ChatMessage>.from(messages);
          updatedMessages[tempMessageIndex] = finalMessage;
          chatMessages[chatId] = updatedMessages;

          // Always emit state update for incoming messages to ensure UI updates immediately
          emit(ChatCustomerMessagesSuccessState(
            messages: updatedMessages,
            chatId: chatId,
          ));
          if (kDebugMode) {
            print(
                'DEBUG: Replaced temporary message with real message (chat: $chatId)');
            print('DEBUG: Temp message ID: ${tempMsg.id}');
            print('DEBUG: Real message ID: ${finalMessage.id}');
            print(
                'DEBUG: Total messages after replacement: ${updatedMessages.length}');
          }
        } else {
          // If this is from the current user and no temporary message was found to replace,
          // try one more aggressive matching strategy
          if (isFromCurrentUser) {
            if (kDebugMode) {
              print(
                  'DEBUG: No temp message found for current user, trying aggressive matching');
              print('DEBUG: New message ID: ${newMessage.id}');
              print('DEBUG: New message text: ${newMessage.messageText}');
              print('DEBUG: New message date: ${newMessage.messageDate}');
              print(
                  'DEBUG: Available temp messages: ${messages.where((m) => m.id.startsWith('temp_')).map((m) => '${m.id} (text: ${m.messageText}, date: ${m.messageDate})').toList()}');
            }

            // Try to find any temporary message from the current user within the last 10 seconds
            final recentTempIndex = messages.indexWhere((m) =>
            m.id.startsWith('temp_') &&
                m.messageCreator?.id == newMessage.messageCreator?.id &&
                m.messageDate != null &&
                newMessage.messageDate != null &&
                (m.messageDate!.difference(newMessage.messageDate!).inSeconds)
                    .abs() <
                    10);

            if (recentTempIndex != -1) {
              if (kDebugMode) {
                print(
                    'DEBUG: Found recent temp message at index $recentTempIndex');
                print(
                    'DEBUG: Temp message ID: ${messages[recentTempIndex].id}');
              }

              // Replace the temporary message
              final tempMsg = messages[recentTempIndex];
              ChatMessage finalMessage = newMessage;
              if (tempMsg.messageCreator?.id == newMessage.messageCreator?.id) {
                finalMessage = newMessage.copyWith(
                  messagePhotos: tempMsg.messagePhotos?.isNotEmpty == true
                      ? tempMsg.messagePhotos
                      : newMessage.messagePhotos,
                  messageVideos: tempMsg.messageVideos?.isNotEmpty == true
                      ? tempMsg.messageVideos
                      : newMessage.messageVideos,
                  messageDocument: tempMsg.messageDocument?.isNotEmpty == true
                      ? tempMsg.messageDocument
                      : newMessage.messageDocument,
                  messageAudio: tempMsg.messageAudio?.isNotEmpty == true
                      ? tempMsg.messageAudio
                      : newMessage.messageAudio,
                );
              }

              final updatedMessages = List<ChatMessage>.from(messages);
              updatedMessages[recentTempIndex] = finalMessage;
              chatMessages[chatId] = updatedMessages;

              emit(ChatCustomerMessagesSuccessState(
                messages: updatedMessages,
                chatId: chatId,
              ));

              if (kDebugMode) {
                print('DEBUG: Replaced recent temp message with real message');
                print('DEBUG: Temp message ID: ${tempMsg.id}');
                print('DEBUG: Real message ID: ${finalMessage.id}');
              }
              return;
            }

            if (kDebugMode) {
              print(
                  'DEBUG: No recent temp message found, but allowing message to appear in UI');
            }
            // Don't return here - allow the message to be processed and added to UI
          }

          // Check if this message already exists to prevent duplicates
          final existingMessageIndex =
          messages.indexWhere((m) => m.id == newMessage.id);

          if (existingMessageIndex == -1) {
            // Add as new message if it doesn't exist (for all users)
            final updatedMessages = [newMessage, ...messages];
            chatMessages[chatId] = updatedMessages;

            // Always emit state update for incoming messages to ensure UI updates immediately
            emit(ChatCustomerMessagesSuccessState(
              messages: updatedMessages,
              chatId: chatId,
            ));
            if (kDebugMode) {
              print('DEBUG: Added new message (chat: $chatId)');
              print('DEBUG: New message ID: ${newMessage.id}');
              print(
                  'DEBUG: Total messages after adding: ${updatedMessages.length}');
            }
          } else {
            // Message already exists, just update it
            final updatedMessages = List<ChatMessage>.from(messages);
            updatedMessages[existingMessageIndex] = newMessage;
            chatMessages[chatId] = updatedMessages;

            emit(ChatCustomerMessagesSuccessState(
              messages: updatedMessages,
              chatId: chatId,
            ));
            if (kDebugMode) {
              print('DEBUG: Updated existing message (chat: $chatId)');
              print('DEBUG: Message ID: ${newMessage.id}');
              print(
                  'DEBUG: Total messages after update: ${updatedMessages.length}');
            }
          }
        }
      } else {
        // If no messages exist for this chat, create new list
        chatMessages[chatId] = [newMessage];

        // Only emit if we're currently viewing this chat
        if (state is ChatCustomerMessagesSuccessState &&
            (state as ChatCustomerMessagesSuccessState).chatId == chatId) {
          emit(ChatCustomerMessagesSuccessState(
            messages: [newMessage],
            chatId: chatId,
          ));
          if (kDebugMode) {
            print(
                'DEBUG: Emitted ChatCustomerMessagesSuccessState for new chat $chatId (current chat)');
          }
        } else {
          if (kDebugMode) {
            print(
                'DEBUG: Not emitting state for new chat - not viewing chat $chatId');
          }
        }
      }

      // If we're not in ChatCustomerMessagesSuccessState, we need to emit a new state
      // This can happen if the user navigates away and back, or if the state is reset
      if (state is! ChatCustomerMessagesSuccessState ||
          (state as ChatCustomerMessagesSuccessState).chatId != chatId) {
        if (kDebugMode) {
          print(
              'Not in ChatCustomerMessagesSuccessState, creating new state with message');
          print('Current state type: ${state.runtimeType}');
        }

        // Get existing messages from chatMessages map or create new list
        List<ChatMessage> existingMessages = chatMessages[chatId] ?? [];

        // Add the new message if it doesn't exist
        if (!existingMessages.any((m) => m.id == newMessage.id)) {
          existingMessages = [newMessage, ...existingMessages];

          // Sort by date (newest first for reverse ListView)
          existingMessages.sort((a, b) {
            final aDate = a.messageDate ?? DateTime.now();
            final bDate = b.messageDate ?? DateTime.now();
            return bDate.compareTo(aDate); // Descending order (newest first)
          });

          // Update the chatMessages map
          chatMessages[chatId] = existingMessages;

          // Emit new state
          emit(ChatCustomerMessagesSuccessState(
            messages: existingMessages,
            chatId: chatId,
          ));

          if (kDebugMode) {
            print(
                'DEBUG: Cubit emitted new ChatCustomerMessagesSuccessState for chat $chatId: ${existingMessages.map((m) => m.messageText).toList()}');
          }
        }
      }

      // Update chat list using the dedicated method
      if (kDebugMode) {
        print('=== CUBIT: Calling _updateChatList ===');
        print('Chat ID: $chatId');
        print('Message ID: ${newMessage.id}');
        print('Message text: ${newMessage.messageText}');
        print('Message creator: ${newMessage.messageCreator?.id}');
        print('Current user ID: ${Constants.userId}');
      }

      _updateChatList(chatId, newMessage);

      if (kDebugMode) {
        print('=== CUBIT: After _updateChatList ===');
        print(
            'Chat messages count for $chatId: ${chatMessages[chatId]?.length ?? 0}');
        print('Last seen message ID for $chatId: ${lastSeenMessageId[chatId]}');
      }
    }
  }

  void setCurrentlyOpenChat(String? chatId) {
    if (kDebugMode) {
      print('=== Customer Cubit: Setting currently open chat ===');
      print('Chat ID: $chatId');
      print('Previous open chat: $currentlyOpenChatId');
    }
    
    currentlyOpenChatId = chatId;
  }

  /// Reset unread count to zero for a specific chat (only if it's currently open)
  void _resetUnreadCountForOpenChat(String chatId) {
    // Validate that this is the currently open chat
    if (chatId != currentlyOpenChatId) {
      if (kDebugMode) {
        print('=== Customer Cubit: Chat ID mismatch - not resetting unread count ===');
        print('Requested chat: $chatId');
        print('Currently open chat: $currentlyOpenChatId');
      }
      return;
    }

    if (kDebugMode) {
      print('=== Customer Cubit: Resetting unread count for open chat ===');
      print('Chat ID: $chatId');
    }

    // Update chat list unread count to 0
    final chatIndex = chat.indexWhere((c) => c.sId == chatId);
    if (chatIndex != -1) {
      final updatedChat = chat[chatIndex].copyWith(
        chatNotSeenMessages: 0,
      );
      chat[chatIndex] = updatedChat;
      emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
      
      if (kDebugMode) {
        print('=== Customer Cubit: Unread count reset to 0 for chat $chatId ===');
      }
    } else {
      if (kDebugMode) {
        print('=== Customer Cubit: Chat not found in list: $chatId ===');
      }
    }
  }

  /// Public method to reset unread count for the currently open chat
  void resetUnreadCountForOpenChat(String chatId) {
    _resetUnreadCountForOpenChat(chatId);
  }

  void _updateChatList(String chatId, ChatMessage message) {
    if (kDebugMode) {
      print('=== CUBIT: _updateChatList START ===');
      print('Chat ID: $chatId');
      print('Message creator: ${message.messageCreator?.id}');
      print('Current user ID: ${Constants.userId}');
      print('Currently open chat: $currentlyOpenChatId');
    }

    final updatedChatList = List<Chats>.from(chat);
    final chatIndex = updatedChatList.indexWhere((c) => c.sId == chatId);
    final isFromOtherUser = message.messageCreator?.id != Constants.userId;
    // ✅ FIX: Only consider chat open if currentlyOpenChatId is not null and matches
    final isChatOpen = currentlyOpenChatId != null && currentlyOpenChatId == chatId;

    if (kDebugMode) {
      print('Chat index: $chatIndex');
      print('Is from other user: $isFromOtherUser');
      print('Is chat open: $isChatOpen');
    }

    Chats updatedChat;
    if (chatIndex != -1) {
      // Update last message and unread count
      final oldChat = updatedChatList[chatIndex];
      int newUnread = oldChat.chatNotSeenMessages ?? 0;
      if (isFromOtherUser && !isChatOpen) {
        // Increment unread count for new message from other user when chat is not open
        newUnread++;
        if (kDebugMode) {
          print('=== Customer Cubit: Incrementing unread count for chat $chatId ===');
          print('Current open chat: $currentlyOpenChatId');
          print('New unread count: $newUnread');
        }
      } else if (isFromOtherUser && isChatOpen) {
        if (kDebugMode) {
          print('=== Customer Cubit: NOT incrementing unread count for chat $chatId ===');
          print('Reason: isChatOpen=$isChatOpen (chat is currently open)');
          print('Current open chat: $currentlyOpenChatId');
        }
      }
      updatedChat = oldChat.copyWith(
        chatLastMessage: ChatLastMessage(
          sId: message.id,
          messageText: message.messageText ?? '',
          messageDate: message.messageDate?.toIso8601String(),
          messageCreator: message.messageCreator?.id,
        ),
        updatedAt: message.messageDate?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        chatNotSeenMessages: newUnread,
      );
      updatedChatList.removeAt(chatIndex);
    } else {
      // Create new chat with default values since we don't have company info
      updatedChat = Chats(
        sId: chatId,
        chatLastMessage: ChatLastMessage(
          sId: message.id,
          messageText: message.messageText ?? '',
          messageDate: message.messageDate?.toIso8601String(),
          messageCreator: message.messageCreator?.id,
        ),
        chatUsers: ChatUsers(
          customerId: message.messageCreator?.id,
          companyId: CompanyId(
            sId: message.messageCreator?.id ?? '',
            companyName: '',
            commercialName: '',
          ),
        ),
        isDeleted: false,
        isClosed: false,
        isTicketChat: false,
        isActive: true,
        isAdminJoined: false,
        participants: [message.messageCreator?.id ?? ''],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        chatNotSeenMessages: isFromOtherUser && !isChatOpen ? 1 : 0,
      );
    }

    // Insert at the top
    updatedChatList.insert(0, updatedChat);

    chat = updatedChatList;
    emit(ChatCustomerSuccessState(List<Chats>.from(updatedChatList)));

    if (kDebugMode) {
      print('=== CUBIT: _updateChatList emitted ChatCustomerSuccessState ===');
      print('  - Chat ID: $chatId');
      print('  - Is from other user: $isFromOtherUser');
      print('  - Is chat open: $isChatOpen');
      print('  - Total chats: ${updatedChatList.length}');
      print(
          '  - Updated chat unread count: ${updatedChat.chatNotSeenMessages}');
    }
  }

  void showCustomToast({
    required String message,
    required Color color,
    Color messageColor = Colors.white,
  }) {
    if (_context == null) {
      if (kDebugMode) {
        print('Warning: Context is null, cannot show toast');
      }
      return;
    }
    fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: color,
        ),
        child: Text(
          message,
          style: TextStyle(color: messageColor),
        ),
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }

  void showNoInternetMessage() {
    showCustomToast(
      message: AppStrings.noInternetConnection.tr(),
      color: ColorManager.lightError,
      messageColor: ColorManager.white,
    );
  }

  Future<void> getCustomerChats({bool resetPagination = true}) async {
    if (_isDisposed) {
      if (kDebugMode) {
        print('getCustomerChats: Cubit is disposed, returning early');
      }
      return;
    }
    if (kDebugMode) print('getCustomerChats: START');
    try {
      // Reset pagination if requested
      if (resetPagination) {
        _currentPage = 1;
        _hasMoreChats = true;
        _lastChatId = null;
        chat.clear();
      }

      emit(const ChatCustomerLoadingState());
      if (kDebugMode) {
        print('getCustomerChats: Emitted ChatCustomerLoadingState');
      }

      // Check connectivity first
      final List<ConnectivityResult> connectivityResult =
      await (Connectivity().checkConnectivity());
      if (!connectivityResult.contains(ConnectivityResult.mobile) &&
          !connectivityResult.contains(ConnectivityResult.wifi)) {
        if (kDebugMode) {
          print('No internet connection available');
        }
        emit(const ChatCustomerErrorState('No internet connection available'));
        if (kDebugMode) print('Emitted ChatCustomerErrorState: No internet');
        return;
      }

      // Add timeout to prevent hanging
      const timeoutDuration = Duration(seconds: 30);

      // Ensure chat list manager is initialized with timeout
      if (!_isChatListManagerInitialized) {
        if (kDebugMode) {
          print('Chat list manager not initialized, initializing now...');
        }
        await _initializeChatListManager().timeout(timeoutDuration);
      }

      if (kDebugMode) {
        print('Database services removed - no-op');
      }

      // Then load from server to ensure we have the latest data
      if (kDebugMode) {
        print('Loading chats from server...');
        print('API endpoint: ${Constants.chatCustomerList}');
        print('User ID: ${Constants.userId}');
        print('User role: ${Constants.role}');
        print('Base URL: ${Constants.baseUrl}');
        print('Page: $_currentPage, PageSize: $_pageSize');
      }

      // Build query parameters for pagination
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': _pageSize,
      };
      if (_lastChatId != null) {
        queryParams['lastId'] = _lastChatId;
      }

      final response = await DioHelper.getData(
        endPoint: Constants.chatCustomerList,
        queryParameters: queryParams,
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print("Chats Response: ${response?.data}");
        print("Response status code: ${response?.statusCode}");
        print("Response headers: ${response?.headers}");
      }

      if (response?.data != null) {
        final data = response!.data;
        if (data['status'] == true && data['data'] != null) {
          final autogenerated = Autogenerated.fromJson(data);
          if (autogenerated.data?.chats != null) {
            final newChats = autogenerated.data!.chats!;
            
            // Handle pagination
            if (resetPagination) {
              chat = newChats;
            } else {
              // Append new chats to existing list
              chat.addAll(newChats);
            }

            // Update pagination state
            _hasMoreChats = newChats.length == _pageSize;
            if (newChats.isNotEmpty) {
              _lastChatId = newChats.last.sId ?? newChats.last.id;
            }
            _currentPage++;

            // ✅ NEW: Reset unread count for the currently open chat after server fetch
// This prevents server-side increments (e.g., for own messages) from overriding client-side "read" state
            if (currentlyOpenChatId != null) {
              final openChatIndex = chat.indexWhere((c) => c.sId == currentlyOpenChatId);
              if (openChatIndex != -1) {
                final updatedOpenChat = chat[openChatIndex].copyWith(
                  chatNotSeenMessages: 0,
                );
                chat[openChatIndex] = updatedOpenChat;
                if (kDebugMode) {
                  print('=== Cubit: Reset unread count to 0 for open chat $currentlyOpenChatId after server fetch ===');
                }
              }
            }

            if (kDebugMode) {
              print('Server chats loaded: ${chat.length} (hasMore: $_hasMoreChats)');
            }

            emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
            if (kDebugMode) {
              print('Emitted ChatCustomerSuccessState: serverChats');
            }
          } else {
            if (kDebugMode) {
              print('No chats in server response');
            }
            if (resetPagination) {
              chat = [];
            }
            _hasMoreChats = false;
            emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
            if (kDebugMode) {
              print('Emitted ChatCustomerSuccessState: empty server');
            }
          }
        } else {
          if (kDebugMode) {
            print('Server response error: ${data['message']}');
          }
          emit(ChatCustomerErrorState(
              data['message'] ?? 'Failed to load chats'));
          if (kDebugMode) print('Emitted ChatCustomerErrorState: server error');
        }
      } else {
        if (kDebugMode) {
          print('No data received from server');
        }
        emit(const ChatCustomerErrorState('No data received from server'));
        if (kDebugMode) print('Emitted ChatCustomerErrorState: no data');
        return;
      }
    } catch (error) {
      if (kDebugMode) {
        print("Chats API Error Details: $error");
      }

      // Handle timeout specifically
      if (error.toString().contains('timeout')) {
        emit(const ChatCustomerErrorState(
            'Request timed out. Please check your internet connection.'));
        if (kDebugMode) print('Emitted ChatCustomerErrorState: timeout');
      } else {
        emit(ChatCustomerErrorState(error.toString()));
        if (kDebugMode) print('Emitted ChatCustomerErrorState: $error');
      }
    }
    if (kDebugMode) print('getCustomerChats: END');
  }

  Future<void> getMessages(String chatId,
      {int skip = 0, int limit = 20}) async {
    if (_isSyncing[chatId] == true) return;
    _isSyncing[chatId] = true;
    final List<ConnectivityResult> connectivityResult =
    await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) &&
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      showNoInternetMessage();
      _isSyncing[chatId] = false;
      return;
    }

    List<ChatMessage> localMessages = [];
    try {
      localMessages = []; // Database service removed - no-op
      if (localMessages.isNotEmpty) {
        emit(ChatCustomerMessagesSuccessState(
          messages: localMessages,
          chatId: chatId,
        ));
        chatMessages[chatId] = localMessages;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading local messages: $e");
      }
    }

    try {
      final response = await DioHelper.getData(
        endPoint: '${Constants.chatMessages}/$chatId',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      if (kDebugMode) {
        print("Messages Response: ${response?.data}");
      }
      if (response?.data != null) {
        final data = response!.data;
        if (data['status'] == true) {
          final messages = (data['data']['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();

          // For fresh message fetch (skip == 0), clear cached messages to prevent duplication
          // For pagination (skip > 0), merge with existing messages
          final existingMessages =
          skip == 0 ? <ChatMessage>[] : (chatMessages[chatId] ?? []);
          final allMessages = [...messages, ...existingMessages];

          if (kDebugMode) {
            print(
                'DEBUG: Fresh fetch (skip=$skip) - using ${existingMessages.length} existing messages, ${messages.length} new messages');
          }

          // Remove duplicates and replace temporary messages with permanent ones
          // final uniqueMessages = <ChatMessage>[];
          // final seenIds = <String>{};
          // final seenClientMessageIds = <String>{};
          //
          // for (final message in allMessages) {
          //   // Skip if we've already seen this exact message ID
          //   if (seenIds.contains(message.id)) {
          //     continue;
          //   }
          //
          //   // Check if this is a permanent message that should replace a temporary one
          //   if (message.clientMessageId != null &&
          //       message.clientMessageId!.isNotEmpty &&
          //       !message.id.startsWith('temp_') &&
          //       !message.id.startsWith('optimistic_')) {
          //     // This is a permanent message - check if we have a temporary version
          //     final tempMessageIndex = uniqueMessages.indexWhere((m) =>
          //         m.clientMessageId == message.clientMessageId &&
          //         (m.id.startsWith('temp_') || m.id.startsWith('optimistic_')));
          //
          //     if (tempMessageIndex != -1) {
          //       // Replace the temporary message with the permanent one
          //       if (kDebugMode) {
          //         print('=== Replacing temporary message with permanent ===');
          //         print(
          //             'Temp message ID: ${uniqueMessages[tempMessageIndex].id}');
          //         print('Permanent message ID: ${message.id}');
          //         print('Client message ID: ${message.clientMessageId}');
          //       }
          //       uniqueMessages[tempMessageIndex] = message;
          //       seenIds.add(message.id);
          //       seenClientMessageIds.add(message.clientMessageId!);
          //       continue;
          //     }
          //   }
          //
          //   // Add the message if we haven't seen it before
          //   seenIds.add(message.id);
          //   if (message.clientMessageId != null &&
          //       message.clientMessageId!.isNotEmpty) {
          //     seenClientMessageIds.add(message.clientMessageId!);
          //   }
          //   uniqueMessages.add(message);
          // }

          // Sort messages by date (oldest first for chat - newest at bottom)

          // Enhanced deduplication: Use ID, clientMessageId, timestamp proximity, and content hash
          final uniqueMessages = <ChatMessage>[];
          final seenIds = <String>{};
          final seenClientMessageIds = <String>{};
          final seenTimestamps = <String>{};  // New: Track by timestamp bucket (±5s) for near-matches

// Helper: Simple content hash for text/media to catch variants (e.g., local vs server URL)
          String _getContentHash(ChatMessage msg) {
            final timestampKey = '${msg.messageDate?.millisecondsSinceEpoch ?? 0}';
            final contentKey = '${msg.messageText ?? ''}_${msg.messagePhotos?.join(',') ?? ''}_${msg.messageVideos?.join(',') ?? ''}_${msg.messageDocument ?? ''}';
            return '$timestampKey:$contentKey'.hashCode.toString();
          }

          for (final message in allMessages) {
            final messageId = message.id;
            final clientId = message.clientMessageId ?? '';
            final timestampBucket = (message.messageDate?.millisecondsSinceEpoch ?? 0) ~/ 5000;  // 5s buckets
            final contentHash = _getContentHash(message);

            // Skip exact ID matches
            if (seenIds.contains(messageId)) continue;

            // Skip clientMessageId matches
            if (clientId.isNotEmpty && seenClientMessageIds.contains(clientId)) continue;

            // Skip near-duplicates: Same timestamp bucket + content hash (catches optimistic vs permanent)
            final timestampKey = '$timestampBucket:$contentHash';
            if (seenTimestamps.contains(timestampKey)) {
              if (kDebugMode) {
                print('=== Deduped near-duplicate via timestamp+content: $messageId (hash: $contentHash) ===');
              }
              continue;
            }

            // Enhanced temp replacement: Broader matching for media (e.g., local path vs server URL)
            if (clientId.isNotEmpty &&
                !messageId.startsWith('temp_') &&
                !messageId.startsWith('optimistic_')) {
              // Search for temp by clientId or content/timestamp match
              final tempMessageIndex = uniqueMessages.indexWhere((m) {
                final mClientId = m.clientMessageId ?? '';
                if (mClientId == clientId) return true;
                // Fallback: Match by content hash + timestamp proximity if no clientId
                if (mClientId.isEmpty) {
                  final mHash = _getContentHash(m);
                  final mBucket = (m.messageDate?.millisecondsSinceEpoch ?? 0) ~/ 5000;
                  return mHash == contentHash && (mBucket - timestampBucket).abs() <= 1;
                }
                return false;
              });

              if (tempMessageIndex != -1) {
                // Replace with permanent (prefer server URLs for media)
                if (kDebugMode) {
                  print('=== Replacing temporary message with permanent (enhanced) ===');
                  print('Temp ID: ${uniqueMessages[tempMessageIndex].id}');
                  print('Permanent ID: $messageId');
                  print('Client ID: $clientId');
                  print('Content hash match: ${_getContentHash(uniqueMessages[tempMessageIndex])} == $contentHash');
                }
                uniqueMessages[tempMessageIndex] = message;
                seenIds.add(messageId);
                if (clientId.isNotEmpty) seenClientMessageIds.add(clientId);
                seenTimestamps.add(timestampKey);
                continue;
              }
            }

            // Add if unique
            seenIds.add(messageId);
            if (clientId.isNotEmpty) seenClientMessageIds.add(clientId);
            seenTimestamps.add(timestampKey);
            uniqueMessages.add(message);
          }

// Sort messages by date (oldest first for chat - newest at bottom)
          uniqueMessages.sort((a, b) {
            final aDate = a.messageDate ?? DateTime.now();
            final bDate = b.messageDate ?? DateTime.now();
            return aDate.compareTo(bDate); // Ascending order (oldest first)
          });




          uniqueMessages.sort((a, b) {
            final aDate = a.messageDate ?? DateTime.now();
            final bDate = b.messageDate ?? DateTime.now();
            return aDate.compareTo(bDate); // Ascending order (oldest first)
          });

          // Update state with merged messages
          emit(ChatCustomerMessagesSuccessState(
            messages: uniqueMessages,
            chatId: chatId,
          ));

          // Update chatMessages map
          chatMessages[chatId] = uniqueMessages;

          if (kDebugMode) {
            print(
                "ChatCustomerCubit: Updated state with merged server messages (${uniqueMessages.length} total)");
          }
        } else {
          if (localMessages.isEmpty) {
            emit(ChatCustomerMessagesErrorState(
              error: data['message'] ?? 'Failed to load messages',
              chatId: chatId,
            ));
          } else {
            showCustomToast(
              message:
              data['message'] ?? 'Failed to update messages from server',
              color: ColorManager.lightError,
            );
          }
        }
      } else {
        throw Exception("No data received from server");
      }
    } catch (error) {
      if (kDebugMode) {
        print("Messages API Error Details: $error");
      }

      // Handle specific error types
      String errorMessage = 'Failed to load messages';
      if (error.toString().contains('timeout')) {
        errorMessage =
        'Request timed out. Please check your internet connection.';
      } else if (error.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (error.toString().contains('401') ||
          error.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication error. Please log in again.';
      } else if (error.toString().contains('403') ||
          error.toString().contains('Forbidden')) {
        errorMessage =
        'Access denied. You may not have permission to view this chat.';
      } else if (error.toString().contains('404') ||
          error.toString().contains('Not Found')) {
        errorMessage = 'Chat not found.';
      } else if (error.toString().contains('500') ||
          error.toString().contains('Internal Server Error')) {
        errorMessage = 'Server error. Please try again later.';
      }

      // If server request fails, emit error state
      emit(ChatCustomerMessagesErrorState(
        error: errorMessage,
        chatId: chatId,
      ));
    } finally {
      _isSyncing[chatId] = false;
    }
  }

  Future<MessageCreator?> _getCurrentUser() async {
    try {
      // TODO: Implement getting current user from your user service
      return MessageCreator(
        id: Constants.userId,
        role: Constants.role,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      return null;
    }
  }

  void _updateMessageInList(ChatMessage newMessage) {
    if (state is! ChatCustomerMessagesSuccessState) {
      if (kDebugMode) {
        print('Not in ChatMessagesSuccessState, cannot update message');
      }
      return;
    }

    final currentState = state as ChatCustomerMessagesSuccessState;
    final messages = List<ChatMessage>.from(currentState.messages);

    if (kDebugMode) {
      print('Updating message in list:');
      print('- New message ID: ${newMessage.id}');
      print('- Current messages count: ${messages.length}');
    }

    // First try to find and update an existing message
    final existingIndex = messages.indexWhere((m) => m.id == newMessage.id);
    if (existingIndex != -1) {
      if (kDebugMode) {
        print('Found existing message at index $existingIndex');
      }
      messages[existingIndex] = newMessage;
    } else {
      // If no existing message found, add the new message
      if (kDebugMode) {
        print('No existing message found, adding new message');
      }
      messages.add(newMessage);
    }

    // Sort messages by date (oldest first for chat - newest at bottom)
    messages.sort((a, b) {
      final aDate = a.messageDate ?? DateTime.now();
      final bDate = b.messageDate ?? DateTime.now();
      return aDate.compareTo(bDate); // Ascending order (oldest first)
    });

    if (kDebugMode) {
      print('Emitting updated state with ${messages.length} messages');
    }

    emit(ChatCustomerMessagesSuccessState(
      chatId: currentState.chatId,
      messages: messages,
      hasMore: currentState.hasMore,
      uploadProgress: currentState.uploadProgress,
    ));
  }

  /// Handle messages_read socket event from ChatProvider
  void onMessagesRead(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('=== CUBIT: onMessagesRead called from ChatProvider ===');
      print('Data: $data');
    }

    // Extract data from the socket event
    final eventChatId = data['chatId'] ?? data['chat_id'];
    final eventMessageIds = data['messageIds'] ?? data['message_ids'] ?? [];
    final eventUserId = data['userId'] ?? data['user_id'];
    final eventReadAt = data['readAt'] ?? data['read_at'];

    if (kDebugMode) {
      print('  - Chat ID: $eventChatId');
      print('  - Message IDs: $eventMessageIds');
      print('  - User ID: $eventUserId');
      print('  - Read At: $eventReadAt');
    }

    // Process the messages_read event
    _processMessagesReadEvent(
        eventChatId, eventMessageIds, eventUserId, eventReadAt);
  }

  /// Optimistically update unread count for immediate UI feedback
  void updateUnreadCountOptimistically(String chatId) {
    final chatIndex = chat.indexWhere((c) => c.sId == chatId);
    if (chatIndex != -1) {
      final updatedChat = chat[chatIndex].copyWith(
        chatNotSeenMessages: 0,
      );
      chat[chatIndex] = updatedChat;
      emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
    }
  }

  void markMessagesAsRead(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print('=== Customer Cubit: Mark Messages As Read ===');
      print('Chat ID: $chatId');
      print('Message IDs: $messageIds');
      print('Message IDs count: ${messageIds.length}');
    }
    
    // Remove the state check so it works on both home and chat screens
    if (messageIds.isEmpty) {
      if (kDebugMode) {
        print('Customer Cubit: messageIds is EMPTY, returning without marking as read!');
      }
      return;
    }

    if (kDebugMode) {
      print('Customer Cubit: Step 1 - Updating chat list unread count');
    }
    
    // Update chat list unread count
    final chatIndex = chat.indexWhere((c) => c.sId == chatId);
    if (kDebugMode) {
      print('Customer Cubit: Chat index: $chatIndex, Total chats: ${chat.length}');
    }
    
    if (chatIndex != -1) {
      final updatedChat = chat[chatIndex].copyWith(
        chatNotSeenMessages: 0,
      );
      chat[chatIndex] = updatedChat;
      emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
      // Don't refresh chat list from backend after marking as read
      // This prevents overriding real-time updates
      if (kDebugMode) {
        print('=== CUBIT: Marked messages as read for chat $chatId ===');
        print('Not refreshing chat list to preserve real-time updates');
      }
    } else {
      if (kDebugMode) {
        print('WARNING: Chat $chatId not found in chat list!');
      }
    }

    if (kDebugMode) {
      print('Customer Cubit: Step 2 - Checking if chat has messages in map');
      print('chatMessages contains chatId: ${chatMessages.containsKey(chatId)}');
      print('chatMessages keys: ${chatMessages.keys.toList()}');
    }

    // Update messages in chatMessages map if they exist
    if (chatMessages.containsKey(chatId)) {
      final messages = chatMessages[chatId]!;
      var hasChanges = false;

      for (var message in messages) {
        if (messageIds.contains(message.id) && message.isRead != true) {
          final updatedMessage = message.copyWith(isRead: true);
          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            messages[index] = updatedMessage;
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        chatMessages[chatId] = messages;

        // Use EnhancedMessageStatusHandler to immediately update UI
        for (final messageId in messageIds) {
          _statusHandler.updateMessageStatus(
            chatId: chatId,
            messageId: messageId,
            isRead: true,
            isSeen: true,
            isReceived: true,
            timestamp: DateTime.now(),
          );
        }

        // Always emit ChatCustomerMessagesSuccessState for read status updates
        // This ensures both chat screen and chat list can show updated read status
        emit(ChatCustomerMessagesSuccessState(
          messages: List<ChatMessage>.from(messages),
          chatId: chatId,
        ));

        if (kDebugMode) {
          print(
              '=== CUBIT: Emitted ChatCustomerMessagesSuccessState for read status update ===');
          print('  - Updated messages with read status changes');
          print(
              '  - Messages with isRead=true: ${messages.where((m) => m.isRead == true).length}');
          print(
              '  - Messages with isSeen=true: ${messages.where((m) => m.isSeen == true).length}');
          print('  - Current state type: ${state.runtimeType}');
          print(
              '  - Emitted ChatCustomerMessagesSuccessState to show read receipts');
          print(
              '  - EnhancedMessageStatusHandler updates sent for immediate UI refresh');
        }
      }
    }

    if (kDebugMode) {
      print('Customer Cubit: Step 3 - Updating last seen message ID');
    }
    
    // Update last seen message ID to the latest in this chat
    if (chatMessages.containsKey(chatId) && chatMessages[chatId]!.isNotEmpty) {
      final latestMessage = chatMessages[chatId]!.last;
      lastSeenMessageId[chatId] = latestMessage.id;
      if (kDebugMode) {
        print('Updated lastSeenMessageId for chat $chatId');
      }
    }

    if (kDebugMode) {
      print('Customer Cubit: Step 4 - ABOUT TO CALL BACKEND API');
      print('  This is the CRITICAL step that must happen!');
    }

    // Send read status to server
    if (kDebugMode) {
      print('=== Customer Cubit: Calling ChatService.markMessagesAsRead ===');
      print('  Chat ID: $chatId');
      print('  Message IDs: $messageIds');
      print('  Message count: ${messageIds.length}');
    }
    
    try {
      _chatService.markMessagesAsRead(chatId, messageIds);
      if (kDebugMode) {
        print('Customer Cubit: ChatService.markMessagesAsRead called successfully');
      }
      
      // ✅ RESET: Reset unread count to zero when messages are marked as read
      _resetUnreadCountForOpenChat(chatId);
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to call ChatService.markMessagesAsRead: $e');
      }
    }
  }

  void markMessagesAsDelivered(String chatId, List<String> messageIds) {
    if (messageIds.isEmpty) return;

    // Update messages in chatMessages map if they exist
    if (chatMessages.containsKey(chatId)) {
      final messages = chatMessages[chatId]!;
      var hasChanges = false;

      for (var message in messages) {
        if (messageIds.contains(message.id) && message.isReceived != true) {
          final updatedMessage = message.copyWith(
            isReceived: true,
          );
          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            messages[index] = updatedMessage;
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        chatMessages[chatId] = messages;

        // Use EnhancedMessageStatusHandler to immediately update UI
        for (final messageId in messageIds) {
          _statusHandler.updateMessageStatus(
            chatId: chatId,
            messageId: messageId,
            isReceived: true,
            timestamp: DateTime.now(),
          );
        }

        // Emit the updated messages state to trigger UI refresh
        emit(ChatCustomerMessagesSuccessState(
          messages: List<ChatMessage>.from(messages),
          chatId: chatId,
        ));

        if (kDebugMode) {
          print('=== CUBIT: Marked messages as delivered ===');
          print('  - Updated ${messageIds.length} messages');
          print(
              '  - Messages with isReceived=true: ${messages.where((m) => m.isReceived == true).length}');
        }
      }
    }

    // Send delivery status to server
    _chatService.markMessagesAsDelivered(chatId, messageIds);
  }

  /// Process messages_read socket event
  void _processMessagesReadEvent(
      String chatId, List<dynamic> messageIds, String userId, dynamic readAt) {
    if (kDebugMode) {
      print('=== CUBIT: Processing messages_read event ===');
      print('Chat ID: $chatId');
      print('Message IDs: $messageIds');
      print('User ID: $userId');
      print('Read At: $readAt');
    }

    // Convert messageIds to List<String>
    final List<String> stringMessageIds =
    messageIds.map((id) => id.toString()).toList();

    // Update messages in chatMessages map if they exist
    if (chatMessages.containsKey(chatId)) {
      final messages = chatMessages[chatId]!;
      var hasChanges = false;

      for (var message in messages) {
        if (stringMessageIds.contains(message.id) && message.isRead != true) {
          final updatedMessage = message.copyWith(
            isRead: true,
            isSeen: true,
            isReceived: true,
          );
          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            messages[index] = updatedMessage;
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        chatMessages[chatId] = messages;

        // Use EnhancedMessageStatusHandler to immediately update UI
        for (final messageId in stringMessageIds) {
          _statusHandler.updateMessageStatus(
            chatId: chatId,
            messageId: messageId,
            isRead: true,
            isSeen: true,
            isReceived: true,
            timestamp: readAt != null
                ? DateTime.parse(readAt.toString())
                : DateTime.now(),
          );
        }

        // Always emit the updated messages state to trigger UI refresh
        // This ensures the chat screen gets updated even when in ChatCustomerSuccessState
        emit(ChatCustomerMessagesSuccessState(
          messages: List<ChatMessage>.from(messages),
          chatId: chatId,
        ));

        if (kDebugMode) {
          print(
              '=== CUBIT: Emitted ChatCustomerMessagesSuccessState for real-time update ===');
          print('  - Updated ${stringMessageIds.length} messages');
          print(
              '  - Messages with isRead=true: ${messages.where((m) => m.isRead == true).length}');
          print(
              '  - Messages with isSeen=true: ${messages.where((m) => m.isSeen == true).length}');
          print('  - Current state type: ${state.runtimeType}');
          print(
              '  - Emitted ChatCustomerMessagesSuccessState to force UI update');
          print(
              '  - EnhancedMessageStatusHandler updates sent for immediate UI refresh');
        }

        // Don't reset unread counter here - let it persist until user actually reads the chat
        // The counter should only be reset when user opens the chat or marks messages as read
      }
    }
  }

  Future<void> sendMessage({
    required String chatId,
    String? messageText,
    List<String>? messagePhotos,
    List<String>? messageVideos,
    String? messageDocument,
    Map<String, dynamic>? location,
    dynamic messageInvoice,
    String? messageAudio,
    ProgressCallback? onProgress,
  }) async {
    // Create tempId at the start of the method
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    try {
      if (kDebugMode) {
        print('=== Starting sendMessage ===');
        print('Chat ID: $chatId');
        print('Message text: $messageText');
        print('Location parameter: $location');
        print('Location parameter type: ${location.runtimeType}');
        print('Socket connected: ${_chatService.socket.connected}');
        print('Socket ID: ${_chatService.socket.id}');
      }

      // Ensure chatMessages map is initialized
      await _ensureChatMessagesInitialized(chatId);

      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        if (kDebugMode) {
          print('Error: User not found');
        }
        emit(ChatCustomerMessagesErrorState(
          error: 'User not found',
          chatId: chatId,
        ));
        return;
      }

      // Check if this is a media message (photos, videos, documents, audio)
      final hasMedia = (messagePhotos?.isNotEmpty == true) ||
          (messageVideos?.isNotEmpty == true) ||
          (messageDocument != null) ||
          (messageAudio != null);

      // Cache attachments immediately if they exist
      if (hasMedia) {
        onProgress?.call(0.1, 'Caching attachments...');

        // Cache photos
        if (messagePhotos?.isNotEmpty == true) {
          for (final photoPath in messagePhotos!) {
            if (photoPath.startsWith('http')) {
              // Remote URL - cache it
              try {
                await _mediaCacheService.cacheMedia(photoPath, MediaType.image);
              } catch (e) {
                if (kDebugMode) {
                  print('Error caching photo: $e');
                }
              }
            }
          }
        }

        // Cache videos
        if (messageVideos?.isNotEmpty == true) {
          for (final videoPath in messageVideos!) {
            if (videoPath.startsWith('http')) {
              try {
                await _mediaCacheService.cacheMedia(videoPath, MediaType.video);
              } catch (e) {
                if (kDebugMode) {
                  print('Error caching video: $e');
                }
              }
            }
          }
        }

        // Cache document
        if (messageDocument != null && messageDocument.startsWith('http')) {
          try {
            await _mediaCacheService.cacheMedia(
                messageDocument, MediaType.document);
          } catch (e) {
            if (kDebugMode) {
              print('Error caching document: $e');
            }
          }
        }

        // Cache audio
        if (messageAudio != null && messageAudio.startsWith('http')) {
          try {
            await _mediaCacheService.cacheMedia(
                messageAudio, MediaType.document);
          } catch (e) {
            if (kDebugMode) {
              print('Error caching audio: $e');
            }
          }
        }
      }

      // Create a temporary message for immediate UI feedback
      // For media messages, include the local file paths in the optimistic message
      final tempMessage = ChatMessage(
        id: tempId,
        clientMessageId: tempId,
        messageText: messageText,
        messageCreator: currentUser,
        messageCreatorRole: Constants
            .role, // Add messageCreatorRole for proper isMe determination
        messageDate: DateTime.now(),
        messagePhotos: messagePhotos,
        messageVideos: messageVideos,
        messageVideo:
        messageVideos?.isNotEmpty == true ? messageVideos!.first : null,
        messageDocument: messageDocument,
        location: location,
        messageInvoiceRef: messageInvoice,
        invoiceData: messageInvoice is Map
            ? Map<String, dynamic>.from(messageInvoice)
            : null, // ✅ Add invoice data for immediate display
        messageAudio: messageAudio,
        isTemp: hasMedia,
      );

      // Update state with temporary message if we're in chat screen
      if (kDebugMode) {
        print('=== Adding optimistic message ===');
        print('Current state: ${state.runtimeType}');
        print('Target chat ID: $chatId');
        print('Temp message ID: $tempId');
        print('Temp message text: ${tempMessage.messageText}');
        print('Temp message videos: ${tempMessage.messageVideos}');
        print('Temp message video: ${tempMessage.messageVideo}');
        print('Is temp: ${tempMessage.isTemp}');
      }

      if (state is ChatCustomerMessagesSuccessState &&
          (state as ChatCustomerMessagesSuccessState).chatId == chatId) {
        if (kDebugMode) {
          print(
              'Adding temporary message to existing ChatCustomerMessagesSuccessState');
        }
        final currentState = state as ChatCustomerMessagesSuccessState;
        final messages = [tempMessage, ...currentState.messages];
        emit(ChatCustomerMessagesSuccessState(
          messages: messages,
          chatId: chatId,
          hasMore: currentState.hasMore,
        ));

        // Also update the chatMessages map to keep it in sync
        chatMessages[chatId] = messages;

        if (kDebugMode) {
          print('Updated chatMessages map with ${messages.length} messages');
        }
      } else {
        // If we're not in the right state, check if we have existing messages for this chat
        if (kDebugMode) {
          print(
              'Not in ChatCustomerMessagesSuccessState, checking existing messages');
        }

        // Check if we have existing messages in chatMessages map
        final existingMessages = chatMessages[chatId] ?? [];
        if (kDebugMode) {
          print('Existing messages in map: ${existingMessages.length}');
        }

        // Create new state with existing messages + optimistic message
        final allMessages = [tempMessage, ...existingMessages];

        emit(ChatCustomerMessagesSuccessState(
          messages: allMessages,
          chatId: chatId,
          hasMore: false,
        ));

        // Also update the chatMessages map
        chatMessages[chatId] = allMessages;

        if (kDebugMode) {
          print(
              '=== Temporary message added successfully to customer state ===');
          print('State emitted with ${allMessages.length} messages');
          print('chatMessages map updated for chat $chatId');
        }
      }

      // Send message to server
      if (kDebugMode) {
        print('Sending message to server...');
      }

      onProgress?.call(0.3, 'Sending message...');

      if (kDebugMode) {
        print('=== About to call _chatService.sendMessage ===');
        print('Location being sent to chat service: $location');
        print('Location type: ${location.runtimeType}');
        if (location != null) {
          print('Location keys: ${location.keys.toList()}');
          print('Latitude: ${location['latitude']}');
          print('Longitude: ${location['longitude']}');
          print('Address: ${location['address']}');
        }
      }

      // Handle different types of media uploads
      String? uploadedImageUrl;
      String? uploadedDocumentUrl;
      String? uploadedVideoUrl;

      // Upload images using the new method
      if (messagePhotos?.isNotEmpty == true) {
        onProgress?.call(0.2, 'Uploading image...');
        final imageFile = File(messagePhotos!.first);
        uploadedImageUrl = await _chatService.uploadImageMessage(
          imageFile,
          chatId,
          userRole: currentUser.role,
          tempId: tempId,
          onProgress: (progress, status) {
            onProgress?.call(0.2 + (progress * 0.2), 'Image: $status');
          },
        );

        if (uploadedImageUrl == null) {
          emit(ChatCustomerMessagesErrorState(
            error: 'Failed to upload image',
            chatId: chatId,
          ));
          return;
        }
      }

      // Upload documents using the new method
      if (messageDocument != null) {
        onProgress?.call(0.4, 'Uploading document...');
        final documentFile = File(messageDocument);
        uploadedDocumentUrl = await _chatService.uploadDocumentMessage(
          documentFile,
          chatId,
          userRole: currentUser.role,
          tempId: tempId,
          onProgress: (progress, status) {
            onProgress?.call(0.4 + (progress * 0.2), 'Document: $status');
          },
        );

        if (uploadedDocumentUrl == null) {
          emit(ChatCustomerMessagesErrorState(
            error: 'Failed to upload document',
            chatId: chatId,
          ));
          return;
        }
      }

      // Upload videos using the existing method
      if (messageVideos?.isNotEmpty == true) {
        onProgress?.call(0.6, 'Uploading video...');
        final videoFile = File(messageVideos!.first);
        uploadedVideoUrl = await _chatService.uploadVideoMessage(
          videoFile,
          chatId,
          userRole: currentUser.role,
          tempId: tempId,
          onProgress: (progress, status) {
            onProgress?.call(0.6 + (progress * 0.2), 'Video: $status');
          },
        );

        if (uploadedVideoUrl == null) {
          emit(ChatCustomerMessagesErrorState(
            error: 'Failed to upload video',
            chatId: chatId,
          ));
          return;
        }
      }

      // Check if we have any file uploads that were handled by the new methods
      final hasFileUploads = uploadedImageUrl != null ||
          uploadedVideoUrl != null ||
          uploadedDocumentUrl != null;

      // Only call sendMessage if we don't have file uploads (they're already sent)
      // or if we have audio/location/invoice messages
      dynamic response;
      if (!hasFileUploads ||
          messageAudio != null ||
          location != null ||
          messageInvoice != null) {
        onProgress?.call(0.8, 'Sending message...');

        // Prepare files for the sendMessage call (only for audio and other non-uploaded files)
        final files = [
          if (messageAudio != null) File(messageAudio),
        ].toList();

        response = await _chatService.sendMessage(
          chatId: chatId,
          messageText: messageText ?? '',
          messageCreator: currentUser.id,
          messageCreatorRole: currentUser.role,
          userId: currentUser.id,
          messageType: messageInvoice != null
              ? 'invoice'
              : _determineMessageType(location, null, files),
          files: files,
          location: location,
          messageInvoiceRef: messageInvoice,
          audioDuration: null,
          clientMessageId: tempId,
          onProgress: (progress, status) {
            onProgress?.call(0.8 + (progress * 0.2), status);
          },
        );
      } else {
        // File uploads were already handled by the new methods, just mark as complete
        onProgress?.call(1.0, 'File uploaded and message sent');
      }

      if (kDebugMode) {
        print('Message sent successfully');
        if (hasFileUploads) {
          print('File upload completed via new methods');
        } else {
          print('Server response: $response');
        }
      }

      onProgress?.call(1.0, 'Message sent successfully');

      // Add a fallback to ensure progress reaches 100% after a short delay
      // This prevents the loading dialog from staying open indefinitely
      Timer(const Duration(seconds: 3), () {
        onProgress?.call(1.0, 'Message sent successfully');
      });

      // Play message sent sound
      // await SoundUtils.playMessageSentSound();

      // Mark message as delivered after successful send (only for non-file messages)
      if (!hasFileUploads && response != null) {
        final messageId = response.id;
        _chatService.markMessagesAsDelivered(chatId, [messageId]);
        if (kDebugMode) {
          print('Marked message as delivered: $messageId');
        }
      }

      // Add fallback mechanism: reload messages after a short delay if socket event doesn't come through
      Timer(const Duration(seconds: 2), () async {
        // Check if the temporary message is still in the state
        if (state is ChatCustomerMessagesSuccessState &&
            (state as ChatCustomerMessagesSuccessState).chatId == chatId) {
          final currentState = state as ChatCustomerMessagesSuccessState;
          final hasTempMessage =
          currentState.messages.any((m) => m.id == tempId);

          if (hasTempMessage) {
            if (kDebugMode) {
              print(
                  'Temporary message still present after 2 seconds, checking if socket event processed it...');
            }

            // Check if there's a permanent message with the same clientMessageId
            final hasPermanentMessage = currentState.messages.any((m) =>
            m.clientMessageId == tempId &&
                !m.id.startsWith('temp_') &&
                !m.id.startsWith('optimistic_'));

            if (hasPermanentMessage) {
              if (kDebugMode) {
                print(
                    'Permanent message found with same clientMessageId, skipping reload');
              }
              return;
            }

            if (kDebugMode) {
              print('No permanent message found, reloading messages...');
            }

            // Instead of reloading all messages, just remove the temporary message
            // The permanent message will be added by the next socket event or API call
            if (kDebugMode) {
              print(
                  'Removing temporary message instead of reloading all messages');
            }

            // Remove the temporary message from the state
            if (state is ChatCustomerMessagesSuccessState &&
                (state as ChatCustomerMessagesSuccessState).chatId == chatId) {
              final currentState = state as ChatCustomerMessagesSuccessState;
              final messages =
              currentState.messages.where((m) => m.id != tempId).toList();
              emit(ChatCustomerMessagesSuccessState(
                messages: messages,
                chatId: chatId,
                hasMore: currentState.hasMore,
              ));
              // Also update the chatMessages map
              chatMessages[chatId] = messages;
            }
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      // Remove temporary message on error
      if (state is ChatCustomerMessagesSuccessState &&
          (state as ChatCustomerMessagesSuccessState).chatId == chatId) {
        final currentState = state as ChatCustomerMessagesSuccessState;
        final messages =
        currentState.messages.where((m) => m.id != tempId).toList();
        emit(ChatCustomerMessagesSuccessState(
          messages: messages,
          chatId: chatId,
          hasMore: currentState.hasMore,
        ));
        // Also update the chatMessages map
        chatMessages[chatId] = messages;
      } else {
        // If we're not in the right state, just remove from chatMessages map
        if (chatMessages.containsKey(chatId)) {
          final messages =
          chatMessages[chatId]!.where((m) => m.id != tempId).toList();
          chatMessages[chatId] = messages;
        }
      }
      if (!e.toString().contains('timeout') &&
          !e.toString().contains('retry')) {
        emit(ChatCustomerMessagesErrorState(
          error: e.toString(),
          chatId: chatId,
        ));
      }
      rethrow;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Get the current chat list
  List<Chats> getCurrentChats() {
    return List<Chats>.from(chat);
  }

  Future<void> getMoreMessages(String chatId, int skip, int limit) async {
    final List<ConnectivityResult> connectivityResult =
    await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) &&
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      showNoInternetMessage();
      return;
    }

    try {
      // Use DioHelper for message loading with pagination
      final response = await DioHelper.getData(
        endPoint: '${Constants.chatMessages}/$chatId',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (kDebugMode) {
        print("More Messages Response: ${response?.data}");
      }

      if (response?.data != null) {
        final data = response!.data;
        if (data['status'] == true) {
          final messages = (data['data']['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();

          // If we got fewer messages than requested, we've reached the end
          bool hasMore = messages.length == limit;

          // Update state with new messages
          if (state is ChatCustomerMessagesSuccessState &&
              (state as ChatCustomerMessagesSuccessState).chatId == chatId) {
            final currentMessages =
                (state as ChatCustomerMessagesSuccessState).messages;
            final updatedMessages = [...currentMessages, ...messages];
            emit(ChatCustomerMessagesSuccessState(
              messages: updatedMessages,
              chatId: chatId,
              hasMore: hasMore,
            ));
          }

          // Update chatMessages map
          if (!chatMessages.containsKey(chatId)) {
            chatMessages[chatId] = [];
          }
          chatMessages[chatId]!.addAll(messages);
        } else {
          emit(ChatCustomerMessagesErrorState(
            error: data['message'] ?? 'Failed to load more messages',
            chatId: chatId,
          ));
        }
      } else {
        throw Exception("No data received from server");
      }
    } catch (error) {
      if (kDebugMode) {
        print("More Messages API Error Details: $error");
      }
      emit(ChatCustomerMessagesErrorState(
        error: error.toString(),
        chatId: chatId,
      ));
    }
  }

  Future<void> getChatCustomer() async {
    await getCustomerChats();
  }

  @override
  Future<void> close() {
    _chatService.removeOnNewMessageListener(_onNewMessageHandler);
    _chatService.disconnect();
    _isDisposed = true;
    _context = null; // Clear the context reference

    // Clear real-time state
    _userOnlineStatus.clear();
    _userLastSeen.clear();

    return super.close();
  }

  void clearContext() {
    _context = null;
  }

  // New methods for user status and typing indicators
  void updateUserStatus({required bool isOnline, DateTime? lastSeen}) {
    if (kDebugMode) {
      print('Updating user status: isOnline=$isOnline, lastSeen=$lastSeen');
    }
    _chatService.updateUserStatus(isOnline: isOnline, lastSeen: lastSeen);
  }

  void markMessageAsSeen(String messageId, String chatId) {
    if (kDebugMode) {
      print('Marking message as seen: messageId=$messageId, chatId=$chatId');
    }
    _chatService.markMessageAsSeen(messageId, chatId);
  }

  void confirmMessagesReceived(String chatId, List<String> messageIds) {
    if (kDebugMode) {
      print(
          'Confirming messages received: chatId=$chatId, messageIds=$messageIds');
    }
    for (final messageId in messageIds) {
      _chatService.confirmMessageReceived(messageId, chatId);
    }
  }

  /// Delete a chat by chatId
  Future<void> deleteChat(String chatId) async {
    if (_isDisposed) return;

    try {
      if (kDebugMode) {
        print('Deleting chat: $chatId');
      }

      final response = await DioHelper.updateData(
        endPoint: '${Constants.deleteChat}/$chatId',
        data: {
          'isDeleted': true,
        },
      );

      if (kDebugMode) {
        print("Delete Chat Response: ${response?.data}");
      }

      if (response?.data != null) {
        final data = response!.data;
        if (data['status'] == true) {
          // Remove chat from local list
          final initialLength = chat.length;
          chat.removeWhere((c) => c.sId == chatId);
          final finalLength = chat.length;

          if (kDebugMode) {
            print(
                'Chat list before deletion: $initialLength, after: $finalLength');
          }

          // Remove messages from local cache
          chatMessages.remove(chatId);

          // Always emit the success state with the updated chat list
          emit(ChatCustomerSuccessState(List<Chats>.from(chat)));

          if (kDebugMode) {
            print('Chat deleted successfully: $chatId');
            print('Remaining chats: ${chat.length}');
          }

          // Show success message
          if (!_isDisposed) {
            showCustomToast(
              message: 'Chat deleted successfully',
              color: ColorManager.success,
            );
          }
        } else {
          if (kDebugMode) {
            print('Failed to delete chat: ${data['message']}');
          }
          if (!_isDisposed) {
            showCustomToast(
              message: data['message'] ?? 'Failed to delete chat',
              color: ColorManager.lightError,
            );
          }
        }
      } else {
        throw Exception("No data received from server");
      }
    } catch (error) {
      if (kDebugMode) {
        print("Delete Chat API Error Details: $error");
      }
      if (!_isDisposed) {
        showCustomToast(
          message: 'Error deleting chat',
          color: ColorManager.lightError,
        );
      }
    }
  }

  /// Close a chat by chatId
  Future<void> closeChat(String chatId) async {
    if (_isDisposed) return;

    try {
      if (kDebugMode) {
        print('Closing chat: $chatId');
      }

      final response = await DioHelper.updateData(
        endPoint: '${Constants.closeChat}/$chatId',
        data: {
          'isClosed': true,
        },
      );

      if (kDebugMode) {
        print("Close Chat Response: ${response?.data}");
      }

      if (response?.data != null) {
        final data = response!.data;
        if (data['status'] == true) {
          // Update chat in local list
          final chatIndex = chat.indexWhere((c) => c.sId == chatId);
          if (chatIndex != -1) {
            final updatedChat = chat[chatIndex].copyWith(isClosed: true);
            chat[chatIndex] = updatedChat;

            emit(ChatCustomerSuccessState(List<Chats>.from(chat)));

            if (kDebugMode) {
              print('Chat closed successfully: $chatId');
            }

            // Show success message
            if (!_isDisposed) {
              showCustomToast(
                message: 'Chat closed successfully',
                color: ColorManager.success,
              );
            }
          }
        } else {
          if (kDebugMode) {
            print('Failed to close chat: ${data['message']}');
          }
          if (!_isDisposed) {
            showCustomToast(
              message: data['message'] ?? 'Failed to close chat',
              color: ColorManager.lightError,
            );
          }
        }
      } else {
        throw Exception("No data received from server");
      }
    } catch (error) {
      if (kDebugMode) {
        print("Close Chat API Error Details: $error");
      }
      if (!_isDisposed) {
        showCustomToast(
          message: 'Error closing chat',
          color: ColorManager.lightError,
        );
      }
    }
  }

  void _handleMessageReceived(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('=== Handling Message Received ===');
      print('Data: $data');
    }

    final eventChatId = data['chatId'] ?? data['chat_id'];
    final messageId = data['messageId'] ?? data['message_id'];
    final eventUserId = data['userId'] ?? data['user_id'];
    final receivedAt = data['receivedAt'] != null
        ? DateTime.parse(data['receivedAt'].toString())
        : DateTime.now();

    // Ignore events for sender's own messages
    if (eventUserId == Constants.userId) {
      if (kDebugMode) {
        print(
            'Ignoring message_received event for sender\'s own message: $messageId');
      }
      return;
    }

    if (eventChatId != null && messageId != null) {
      // Update message received status in chatMessages
      if (chatMessages.containsKey(eventChatId)) {
        final messages = chatMessages[eventChatId]!;
        final messageIndex = messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final updatedMessage = messages[messageIndex].copyWith(
            isReceived: data['isReceived'] ?? true,
            isSeen: data['isSeen'] ?? messages[messageIndex].isSeen,
          );
          messages[messageIndex] = updatedMessage;
          chatMessages[eventChatId] = messages;

          // Use EnhancedMessageStatusHandler to immediately update UI
          _statusHandler.updateMessageStatus(
            chatId: eventChatId,
            messageId: messageId,
            isReceived: data['isReceived'] ?? true,
            isSeen: data['isSeen'] ?? messages[messageIndex].isSeen,
            timestamp: receivedAt,
          );

          if (kDebugMode) {
            print('=== CUSTOMER CUBIT: Message received status updated ===');
            print('  - Message ID: $messageId');
            print('  - Chat ID: $eventChatId');
            print('  - isReceived: ${data['isReceived'] ?? true}');
            print(
                '  - isSeen: ${data['isSeen'] ?? messages[messageIndex].isSeen}');
            print(
                'Status updated via MessageStatusHandler - no state emission to prevent message duplication');
          }
        }
      }
      if (kDebugMode) {
        print(
            'Message $messageId received in chat $eventChatId by user $eventUserId at $receivedAt');
      }
    }
  }

  // Add getter for user online status
  bool isUserOnline(String chatId, String userId) {
    return _userOnlineStatus[chatId]?[userId] ?? false;
  }

  DateTime? getUserLastSeen(String userId) {
    return _userLastSeen[userId];
  }

  // Add method to maintain real-time state
  void _maintainRealTimeState() {
    if (!_isDisposed) {
      // Ensure current state is preserved
      final currentState = state;
      if (currentState is ChatCustomerSuccessState) {
        // Re-emit to ensure UI is updated
        emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
      }
    }
  }

  // Add method to notify listeners of real-time updates
  void _notifyRealTimeUpdate() {
    if (!_isDisposed) {
      // Force a state emission to trigger UI rebuild
      emit(ChatCustomerSuccessState(List<Chats>.from(chat)));
    }
  }

  // Add method to persist user status
  void _persistUserStatus() {
    if (kDebugMode) {
      print('=== Persisting User Status ===');
      print('Online status: $_userOnlineStatus');
      print('Last seen: $_userLastSeen');
    }

    // This method can be called to save status to local storage if needed
    // For now, we'll just log the current state
  }

  // Add method to restore user status
  void _restoreUserStatus() {
    if (kDebugMode) {
      print('=== Restoring User Status ===');
      print('Restored online status: $_userOnlineStatus');
      print('Restored last seen: $_userLastSeen');
    }

    // This method can be called to restore status from local storage if needed
    // For now, we'll just log the current state
  }

  // Add method to get all online users for a chat
  Set<String> getOnlineUsers(String chatId) {
    final onlineUsers = <String>{};
    final chatStatus = _userOnlineStatus[chatId];
    if (chatStatus != null) {
      chatStatus.forEach((userId, isOnline) {
        if (isOnline) {
          onlineUsers.add(userId);
        }
      });
    }
    return onlineUsers;
  }

  // Add method to get all offline users for a chat
  Set<String> getOfflineUsers(String chatId) {
    final offlineUsers = <String>{};
    final chatStatus = _userOnlineStatus[chatId];
    if (chatStatus != null) {
      chatStatus.forEach((userId, isOnline) {
        if (!isOnline) {
          offlineUsers.add(userId);
        }
      });
    }
    return offlineUsers;
  }

  // Add method to prevent status reset
  void _preventStatusReset() {
    if (kDebugMode) {
      print('=== Preventing Status Reset ===');
      print('Current online status: $_userOnlineStatus');
      print('Current last seen: $_userLastSeen');
    }

    // This method ensures that user status is not reset by other operations
    // It can be called before operations that might reset the status
  }

  // Add method to validate user status
  bool _isValidUserStatus(String chatId, String userId) {
    final chatStatus = _userOnlineStatus[chatId];
    if (chatStatus != null && chatStatus.containsKey(userId)) {
      return true;
    }
    return false;
  }

  // Add method to force status update
  void forceUserStatusUpdate(String chatId, String userId, bool isOnline) {
    if (kDebugMode) {
      print('=== Force User Status Update ===');
      print('Chat ID: $chatId');
      print('User ID: $userId');
      print('Is Online: $isOnline');
    }

    if (!_userOnlineStatus.containsKey(chatId)) {
      _userOnlineStatus[chatId] = {};
    }
    _userOnlineStatus[chatId]![userId] = isOnline;

    if (!isOnline) {
      _userLastSeen[userId] = DateTime.now();
    } else {
      _userLastSeen.remove(userId);
    }

    // Notify UI of the forced update
    _notifyRealTimeUpdate();

    if (kDebugMode) {
      print('Updated user status tracking: $_userOnlineStatus');
    }
  }

  /// Filter chats with server-side filtering
  Future<void> filterChats({
    String? invoiceStatus,
    String? messageFilter,
  }) async {
    if (_isDisposed) return;

    try {
      if (kDebugMode) {
        print(
            'Filtering chats with: invoiceStatus=$invoiceStatus, messageFilter=$messageFilter');
      }

      emit(const ChatCustomerLoadingState());

      // Build query parameters
      final queryParams = <String, String>{};
      if (invoiceStatus != null) {
        queryParams['invoiceStatus'] = invoiceStatus;
      }
      if (messageFilter != null) {
        queryParams['messageFilter'] = messageFilter;
      }

      final response = await DioHelper.getData(
        endPoint: Constants.chatFilter,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (kDebugMode) {
        print("Filter Chats Response: ${response?.data}");
      }

      if (response?.data != null) {
        final data = response!.data;
        if (data['status'] == true && data['data'] != null) {
          final autogenerated = Autogenerated.fromJson(data);
          if (autogenerated.data?.chats != null) {
            chat = autogenerated.data!.chats!;

            emit(ChatCustomerSuccessState(List<Chats>.from(chat)));

            if (kDebugMode) {
              print('Filtered chats loaded successfully: ${chat.length} chats');
            }
          } else {
            // No chats found with the filter
            chat = [];
            emit(ChatCustomerSuccessState(List<Chats>.from(chat)));

            if (kDebugMode) {
              print('No chats found with the applied filter');
            }
          }
        } else {
          emit(ChatCustomerErrorState(
              data['message'] ?? 'Failed to filter chats'));
        }
      } else {
        throw Exception("No data received from server");
      }
    } catch (error) {
      if (kDebugMode) {
        print("Filter Chats API Error Details: $error");
      }
      emit(ChatCustomerErrorState(error.toString()));
    }
  }

  /// Load more chats for pagination
  Future<void> loadMoreChats() async {
    if (_isDisposed || _isLoadingMore || !_hasMoreChats) {
      if (kDebugMode) {
        print('loadMoreChats: Cannot load more - disposed: $_isDisposed, loading: $_isLoadingMore, hasMore: $_hasMoreChats');
      }
      return;
    }

    _isLoadingMore = true;
    if (kDebugMode) {
      print('loadMoreChats: Loading page $_currentPage');
    }

    try {
      await getCustomerChats(resetPagination: false);
    } catch (e) {
      if (kDebugMode) {
        print('loadMoreChats: Error loading more chats: $e');
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Check if there are more chats to load
  bool get hasMoreChats => _hasMoreChats;

  /// Check if currently loading more chats
  bool get isLoadingMore => _isLoadingMore;

  /// Clear filter and load all chats
  Future<void> clearFilter() async {
    if (kDebugMode) {
      print('Clearing chat filter');
    }
    await getCustomerChats();
  }

  /// Ensure chatMessages map is initialized for a chat
  Future<void> _ensureChatMessagesInitialized(String chatId) async {
    if (!chatMessages.containsKey(chatId) || chatMessages[chatId]!.isEmpty) {
      if (kDebugMode) {
        print('Initializing chatMessages map for chat: $chatId');
      }
      chatMessages[chatId] = [];
      if (kDebugMode) {
        print('Initialized chatMessages map with 0 messages');
      }
    }
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

  /// Fetch invoice data by ID for View button - returns InvoiceModel or null
  Future<InvoiceModel?> fetchInvoiceDataById(String invoiceId) async {
    try {
      print('=== ChatCustomerCubit: Fetching Invoice Data by ID ===');
      print('Invoice ID: $invoiceId');
      print('API Endpoint: ${Constants.invoiceById}?invoiceId=$invoiceId');

      // Fetch invoice data from API using the correct endpoint
      final response = await DioHelper.getData(
        endPoint: '${Constants.invoiceById}/$invoiceId',
      );

      print('=== API Response Details ===');
      print('Response: $response');
      print('Response data: ${response?.data}');

      if (response?.statusCode == 200 && response?.data != null) {
        final responseData = response!.data;
        print('Response data type: ${responseData.runtimeType}');

        if (responseData is Map<String, dynamic>) {
          // Check if the response contains invoice data
          if (responseData.containsKey('data') &&
              responseData['data'] != null) {
            final data = responseData['data'];
            print('Data type: ${data.runtimeType}');

            if (data is List && data.isNotEmpty) {
              // Find the specific invoice by ID
              for (final invoice in data) {
                if (invoice is Map<String, dynamic> &&
                    (invoice['_id']?.toString() == invoiceId ||
                        invoice['invoice_id']?.toString() == invoiceId ||
                        invoice['invoiceId']?.toString() == invoiceId)) {
                  print('=== Found Matching Invoice ===');
                  print(
                      'Invoice ID: ${invoice['invoice_id'] ?? invoice['_id'] ?? invoice['invoiceId']}');
                  print(
                      'Invoice Status: ${invoice['invoice_status'] ?? invoice['status']}');
                  print('Payment Method: ${invoice['payment_method']}');

                  // Create InvoiceModel from the data
                  final invoiceModel = InvoiceModel.fromJson(invoice);
                  print('Invoice model created successfully');
                  print('Invoice ID: ${invoiceModel.invoice_id}');

                  return invoiceModel;
                }
              }
            } else if (data is Map<String, dynamic>) {
              // Single invoice object
              print('=== Found Single Invoice ===');
              print(
                  'Invoice ID: ${data['invoice_id'] ?? data['_id'] ?? data['invoiceId']}');
              print(
                  'Invoice Status: ${data['invoice_status'] ?? data['status']}');
              print('Payment Method: ${data['payment_method']}');

              final invoiceModel = InvoiceModel.fromJson(data);
              print('Invoice model created successfully');
              print('Invoice ID: ${invoiceModel.invoice_id}');

              return invoiceModel;
            }
          }
        }

        print('=== No Invoice Found ===');
        print('Searched for invoice ID: $invoiceId');
        print('Response structure: ${responseData.keys.toList()}');

        return null;
      } else {
        print('=== API Error ===');
        print('Status Code: ${response?.statusCode}');
        print('Error: ${response?.data}');
        return null;
      }
    } catch (e) {
      print('=== Error Fetching Invoice Data ===');
      print('Error: $e');
      print('Invoice ID that failed: $invoiceId');
      return null;
    }
  }
}