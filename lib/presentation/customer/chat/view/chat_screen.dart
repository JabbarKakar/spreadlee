import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import '../../../../domain/chat_model.dart';
import '../widget/message_input.dart';
import '../../../../core/constant.dart';
import '../../../bloc/customer/chat_bloc/chat_cubit.dart';
import '../../../bloc/customer/chat_bloc/chat_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../provider/chat_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widget/messages/message_widget.dart';
import '../widget/messages/view_pdf.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import '../../../../providers/user_status_provider.dart';
import '../../../../services/chat_service.dart';
import '../../../../providers/presence_provider.dart';
import '../../../../services/message_status_handler.dart';

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class ChatProviderInherited extends InheritedWidget {
  final ChatProvider provider;

  const ChatProviderInherited({
    Key? key,
    required this.provider,
    required Widget child,
  }) : super(key: key, child: child);

  static ChatProvider of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ChatProviderInherited>();
    assert(widget != null, 'No ChatProviderInherited found in context');
    return widget!.provider;
  }

  @override
  bool updateShouldNotify(ChatProviderInherited oldWidget) {
    return provider != oldWidget.provider;
  }
}

class ChatScreenCustomer extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userRole;
  final String companyName;
  final bool isOnline;
  final List<ChatMessage>? initialMessages;
  final Chats? chat;
  final bool isTicketChat;

  ChatScreenCustomer({
    Key? key,
    required this.chatId,
    required this.userId,
    required this.userRole,
    required this.companyName,
    this.isOnline = false,
    this.initialMessages,
    this.chat,
    this.isTicketChat = false,
  }) : super(key: key) {
    // Debug logging to check userRole value
    if (kDebugMode) {
      print(
          'ChatScreenCustomer: Constructor called with userRole: "$userRole"');
      print('ChatScreenCustomer: userId: "$userId"');
      print('ChatScreenCustomer: chatId: "$chatId"');
    }
  }

  @override
  State<ChatScreenCustomer> createState() => _ChatScreenCustomerState();
}

class _ChatScreenCustomerState extends State<ChatScreenCustomer>
    with TickerProviderStateMixin {
  late final ChatProvider _chatProvider;
  // Add ValueNotifier for message list like customer screen
  late ValueNotifier<List<dynamic>> _messageListNotifier;
  late final AnimationController _entranceAnimationController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  // Enhanced message status handler
  final MessageStatusHandler _statusHandler = MessageStatusHandler();
  
  // Store cubit reference to avoid context issues in dispose
  late final ChatCustomerCubit _cubit;
  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    
    // Initialize cubit reference to avoid context issues in dispose
    _cubit = context.read<ChatCustomerCubit>();
    _chatService = Provider.of<ChatService>(context, listen: false);
    
    _cubit.setCurrentlyOpenChat(widget.chatId);
    
    // Also set in ChatService for socket events
    _chatService.setCurrentOpenChat(widget.chatId);
    
    // ✅ EXPLICIT: Reset unread count only when chat screen is actually opened
    _resetUnreadCountForOpenChat();
    _chatProvider = ChatProvider(
      chatId: widget.chatId,
      userId: widget.userId,
      userRole: widget.userRole,
    );
    _messageListNotifier = ValueNotifier<List<dynamic>>([]);
    _entranceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _entranceAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceAnimationController,
      curve: Curves.easeOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceAnimationController,
      curve: Curves.easeOutBack,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceAnimationController.forward();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Initialize the enhanced message status handler for real-time updates
      _statusHandler.initialize();

      // Set up status update callbacks
      _statusHandler.onStatusUpdate((chatId, messageId, status) {
        if (chatId == widget.chatId) {
          _handleStatusUpdate(messageId, status);
        }
      });

      _statusHandler.onBulkStatusUpdate((chatId, messageIds, status) {
        if (chatId == widget.chatId) {
          for (final messageId in messageIds) {
            _handleStatusUpdate(messageId, status);
          }
        }
      });

      // ✅ Ensure socket is ready before joining room. Be resilient to
      // timing races where the service may still be suspended or token
      // not yet available. Retry with a short backoff instead of letting
      // an unhandled exception crash the screen.
      () async {
        final chatService = Provider.of<ChatService>(context, listen: false);
        bool ready = false;
        Exception? lastError;
        for (int attempt = 0; attempt < 12; attempt++) {
          try {
            await chatService.waitForSocketReady();
            ready = true;
            break;
          } catch (e) {
            lastError = e is Exception ? e : Exception(e.toString());
            if (kDebugMode) {
              print(
                  'ChatScreenCustomer: waitForSocketReady attempt \\${attempt + 1} failed: $e');
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (!ready) {
          if (kDebugMode) {
            print(
                'ChatScreenCustomer: Socket did not become ready: $lastError');
          }
          // Don't crash; allow UI to continue. ChatProvider will attempt
          // to initialize when socket becomes available later.
          try {
            _chatProvider.initialize();
          } catch (_) {}
          return;
        }

        _chatProvider.initialize();
        _chatProvider.joinChatRoom(widget.chatId);
      }();

      // Note: messages_read events are now handled directly in the cubit
      // to avoid duplicate processing and ensure proper real-time updates

      final userStatusProvider =
          Provider.of<UserStatusProvider>(context, listen: false);
      _chatProvider.setUserStatusProvider(userStatusProvider);
      if (widget.chat != null) {
        _chatProvider.setCurrentChat(widget.chat!);
      }
      if (widget.initialMessages != null) {
        _chatProvider.setMessages(widget.initialMessages!);
      }

      // Add listener for real-time updates from ChatProvider
      _chatProvider.addListener(_onChatProviderUpdate);
    });
  }

  // Add method to handle real-time updates from ChatProvider
  void _onChatProviderUpdate() {
    if (mounted) {
      // Force immediate UI rebuild to reflect real-time updates
      setState(() {
        // This will trigger a rebuild of the entire chat screen
        // including the online status indicator
      });
    }
  }

  // Handle message status updates from backend
  void _handleStatusUpdate(String messageId, Map<String, dynamic> status) {
    if (kDebugMode) {
      print('ChatScreenCustomer: Status update for message $messageId');
      print('  Status: $status');
    }

    // Check if this is a permanent ID replacement
    if (status.containsKey('tempId') && status.containsKey('permanentId')) {
      final tempId = status['tempId'];
      final permanentId = status['permanentId'];
      _chatProvider.replaceMessageId(tempId, permanentId, status);
    } else {
      // Regular status update
      _chatProvider.updateMessageStatus(messageId, status);
    }

    // Note: No setState() call needed here because ChatProvider.updateMessageStatus()
    // already calls notifyListeners() which will trigger the UI update via _onChatProviderUpdate()
  }

  /// Reset unread count for the currently open chat
  void _resetUnreadCountForOpenChat() {
    if (kDebugMode) {
      print('=== Customer ChatScreen: Resetting unread count for open chat ===');
      print('Chat ID: ${widget.chatId}');
    }

    // Call the cubit method to reset unread count
    _cubit.resetUnreadCountForOpenChat(widget.chatId);
  }

  @override
  void dispose() {
    _cubit.setCurrentlyOpenChat(null);
    
    // Also clear in ChatService
    _chatService.clearCurrentOpenChat();
    
    _chatProvider.removeListener(_onChatProviderUpdate);
    _statusHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatProviderInherited(
      provider: _chatProvider,
      child: _ChatScreenContent(
        chatId: widget.chatId,
        userId: widget.userId,
        userRole: widget.userRole,
        companyName: widget.companyName,
        isOnline: widget.isOnline,
        initialMessages: widget.initialMessages,
        chatProvider: _chatProvider,
        isTicketChat: widget.isTicketChat,
        messageListNotifier: _messageListNotifier,
        entranceAnimationController: _entranceAnimationController,
        slideAnimation: _slideAnimation,
        fadeAnimation: _fadeAnimation,
        scaleAnimation: _scaleAnimation,
        statusHandler: _statusHandler,
      ),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userRole;
  final String companyName;
  final bool isOnline;
  final List<ChatMessage>? initialMessages;
  final ChatProvider chatProvider;
  final bool isTicketChat;
  final ValueNotifier<List<dynamic>> messageListNotifier;
  final AnimationController entranceAnimationController;
  final Animation<double> slideAnimation;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final MessageStatusHandler statusHandler;

  const _ChatScreenContent({
    Key? key,
    required this.chatId,
    required this.userId,
    required this.userRole,
    required this.companyName,
    this.isOnline = false,
    this.initialMessages,
    required this.chatProvider,
    this.isTicketChat = false,
    required this.messageListNotifier,
    required this.entranceAnimationController,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.statusHandler,
  }) : super(key: key);

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isLoadingMessages = false; // Add separate flag for message loading
  DateTime? _lastReadMessageDateTime;
  bool _isInitialized = false;
  bool _hasFetchedInitialMessages = false;

  // Track previous message IDs to identify new messages
  final Set<String> _previousMessageIds = <String>{};

  // Track the previous message list to identify new messages
  List<String> _previousMessageIdsList = <String>[];

  // Properties for typing indicators and online status
  Timer? _typingTimer;
  Timer? _cleanupTimer;
  Timer? _periodicCheckTimer;
  Timer? _socketHealthCheckTimer; // ✅ NEW: Periodic socket health check

  // Track unread messages for proper read status handling
  final Set<String> _unreadMessageIds = <String>{};
  final Set<String> _markedAsReadIds = <String>{};

  // Flag to prevent duplicate processing
  bool _isProcessingBlocUpdate = false;
  Timer? _resetProcessingFlagTimer;

  @override
  void initState() {
    super.initState();

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Add scroll listener for read status updates
    _scrollController.addListener(_onScrollUpdate);

    _loadToken();

    // Set up cleanup timer for typing indicators
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        // Cleanup timer - no longer needed for typing indicators
      }
    });

    // Disable automatic periodic read marking to prevent unread counter from disappearing
    // Only mark messages as read when user actively views them
    // _periodicCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
    //   if (mounted && !_isLoadingMessages) {
    //     _checkForNewMessagesAndMarkAsRead();
    //   }
    // });

    // ✅ NEW: Periodic socket health check every 30 seconds
    _socketHealthCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _checkSocketHealth();
      }
    });

    // Listen to provider changes to update message list for receiver
    widget.chatProvider.addListener(_onProviderUpdate);

    // Mark messages as read when user opens the chat screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _markMessagesAsReadWhenAppropriate();
      }
    });
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('=== Customer ChatScreen: App Resumed ===');
        print('Attempting to reconnect socket...');
      }
      
      // Reconnect socket when app resumes from background/locked screen
      _reconnectSocketAfterResume();
    } else if (state == AppLifecycleState.paused) {
      if (kDebugMode) {
        print('=== Customer ChatScreen: App Paused/Screen Locked ===');
      }
      // Leave chat room to optimize battery and prevent unnecessary updates
      try {
        widget.chatProvider.leaveChatRoom(widget.chatId);
        if (kDebugMode) {
          print('Customer ChatScreen: Left chat room: ${widget.chatId}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Customer ChatScreen: Error leaving chat room: $e');
        }
      }
    }
  }
  
  /// Check socket health periodically and reconnect if needed
  Future<void> _checkSocketHealth() async {
    if (!mounted) return;
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // Check if socket is connected
      if (!chatService.socket.connected) {
        if (kDebugMode) {
          print('=== Customer ChatScreen: Socket Health Check - DISCONNECTED ===');
          print('Attempting automatic reconnection...');
        }
        
        // Attempt reconnection
        await _reconnectSocketAfterResume();
      } else {
        // Socket is connected, optionally verify we're still in the chat room
        if (kDebugMode) {
          print('Customer ChatScreen: Socket Health Check - OK (connected)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Customer ChatScreen: Error in socket health check: $e');
      }
    }
  }
  
  /// Reconnect socket after app resumes from background or screen unlock
  Future<void> _reconnectSocketAfterResume() async {
    if (!mounted) return;
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      if (kDebugMode) {
        print('=== Customer ChatScreen: Reconnection Start ===');
        print('Socket connected: ${chatService.socket.connected}');
      }
      
      // Wait briefly for socket to stabilize after resume
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // ✅ CRITICAL: Manually reconnect socket if disconnected
      if (!chatService.socket.connected) {
        if (kDebugMode) {
          print('Customer ChatScreen: Socket disconnected, manually reconnecting...');
        }
        
        try {
          chatService.socket.connect();
          if (kDebugMode) {
            print('Customer ChatScreen: Socket.connect() called');
          }
          
          // Wait for connection to establish
          int connectAttempts = 0;
          while (!chatService.socket.connected && connectAttempts < 20) {
            await Future.delayed(const Duration(milliseconds: 250));
            connectAttempts++;
            if (kDebugMode && connectAttempts % 4 == 0) {
              print('Customer ChatScreen: Waiting for socket connection... (${connectAttempts * 250}ms)');
            }
          }
          
          if (kDebugMode) {
            print('Customer ChatScreen: Socket connected: ${chatService.socket.connected}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Customer ChatScreen: Error calling socket.connect(): $e');
          }
        }
      }
      
      // Retry mechanism similar to initial setup
      bool ready = false;
      Exception? lastError;
      for (int attempt = 0; attempt < 10; attempt++) {
        try {
          if (kDebugMode) {
            print('Customer ChatScreen: waitForSocketReady attempt ${attempt + 1}');
          }
          await chatService.waitForSocketReady();
          ready = true;
          break;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          if (kDebugMode) {
            print('Customer ChatScreen: waitForSocketReady attempt ${attempt + 1} failed: $e');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (!ready) {
        if (kDebugMode) {
          print('Customer ChatScreen: Socket did not become ready: $lastError');
        }
        // Try to initialize anyway
        try {
          widget.chatProvider.initialize();
        } catch (e) {
          if (kDebugMode) {
            print('Customer ChatScreen: Error initializing provider: $e');
          }
        }
        return;
      }
      
      if (kDebugMode) {
        print('Customer ChatScreen: Socket ready after resume');
        print('Socket connected: ${chatService.socket.connected}');
      }
      
      // Reinitialize the provider to set up listeners again
      if (mounted) {
        try {
          widget.chatProvider.initialize();
          if (kDebugMode) {
            print('Customer ChatScreen: Provider reinitialized');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Customer ChatScreen: Error reinitializing provider: $e');
          }
        }
      }
      
      // Rejoin the current chat room
      if (mounted) {
        widget.chatProvider.joinChatRoom(widget.chatId);
        
        if (kDebugMode) {
          print('Customer ChatScreen: Rejoined chat room: ${widget.chatId}');
        }
        
        // Force UI update via provider to show any missed messages
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          try {
            widget.chatProvider.forceUIUpdate();
            if (kDebugMode) {
              print('Customer ChatScreen: Forced UI update after reconnection');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Customer ChatScreen: Error forcing UI update: $e');
            }
          }
        }
        
        if (kDebugMode) {
          print('=== Customer ChatScreen: Reconnection Complete ===');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Customer ChatScreen: Error reconnecting socket: $e');
      }
    }
  }

  // Enhanced provider update handler for real-time updates with debouncing
  Timer? _uiUpdateDebounceTimer;
  bool _isProcessingProviderUpdate = false;

  void _onProviderUpdate() {
    if (!mounted || _isProcessingProviderUpdate) return;

    _isProcessingProviderUpdate = true;

    // Cancel any existing timer
    _uiUpdateDebounceTimer?.cancel();

    // Debounce UI updates to prevent excessive rebuilds
    _uiUpdateDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        _isProcessingProviderUpdate = false;
        // Single setState call to prevent excessive rebuilds
        setState(() {
          // Force rebuild to reflect real-time updates from socket events
          // This ensures immediate UI updates for:
          // - User online/offline status changes
          // - Message seen/received status updates
          // - Typing indicators
          // - New messages
        });
      }
    });
  }

  void _onScrollUpdate() {
    if (!mounted || _isLoadingMessages) return; // Skip during pagination

    // Disable automatic read marking on scroll to prevent unread counter from clearing
    // Only mark messages as read when user explicitly views them or sends a message
    // final visibleMessageIds = _getVisibleMessageIds();
    // final unreadVisibleIds = visibleMessageIds
    //     .where((id) =>
    //         _unreadMessageIds.contains(id) && !_markedAsReadIds.contains(id))
    //     .toList();

    // if (unreadVisibleIds.isNotEmpty) {
    //   _debouncedMarkAsRead(unreadVisibleIds);
    // }

    // Check if user scrolled to bottom (newest messages)
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final isAtBottom = position.pixels <= 0; // Since we use reverse: true

      if (isAtBottom) {
        // User is at the bottom, but don't automatically mark as read
        // _forceCheckVisibleMessages();
      }
    }
  }

  // Add debouncing for mark as read calls
  Timer? _markAsReadTimer;
  final List<String> _pendingMarkAsReadIds = [];

  void _debouncedMarkAsRead(List<String> messageIds) {
    // ✅ DISABLED: Mark as read functionality removed
    if (kDebugMode) {
      print(
          'ChatScreen: _debouncedMarkAsRead called but disabled (${messageIds.length} messages)');
    }
    return;

    // Original code commented out
    // Filter out messages that are already marked as read or in pending list
    // final filteredIds = messageIds
    //     .where((id) =>
    //         !_markedAsReadIds.contains(id) &&
    //         !_pendingMarkAsReadIds.contains(id))
    //     .toList();
  }

  /// Get currently visible message IDs (improved implementation)
  List<String> _getVisibleMessageIds() {
    // Use the ValueListenableBuilder messages
    final messages = widget.messageListNotifier.value;
    final visibleIds = <String>[];

    // Try to use scrollController to get visible range
    if (_scrollController.hasClients && messages.isNotEmpty) {
      final position = _scrollController.position;
      const itemExtent = 80.0; // Approximate height of a message bubble
      int firstVisible = (position.pixels / itemExtent).floor();
      int lastVisible =
          ((position.pixels + position.viewportDimension) / itemExtent).ceil();

      // Clamp indices to valid range
      firstVisible = firstVisible.clamp(0, messages.length - 1);
      lastVisible = lastVisible.clamp(0, messages.length);

      for (int i = firstVisible; i < lastVisible && i < messages.length; i++) {
        if (i < 0) continue; // Defensive: skip negative indices
        final item = messages[i];
        if (item is ChatMessage) {
          visibleIds.add(item.id);
        }
      }
    } else {
      // Fallback: consider the first 10 messages as visible
      for (int i = 0; i < messages.length && i < 10; i++) {
        final item = messages[i];
        if (item is ChatMessage) {
          visibleIds.add(item.id);
        }
      }
    }
    return visibleIds;
  }

  /// Update unread message tracking when messages are loaded
  void _updateUnreadMessageTracking(List<ChatMessage> messages) {
    _unreadMessageIds.clear();
    final currentUserId = widget.userId;

    for (final message in messages) {
      if (message.messageCreator?.id == currentUserId ||
          message.isDeleted == true) {
        continue;
      }

      // Check if message is already read by current user
      bool isReadByCurrentUser = message.isRead == true;

      // If not read by current user, add to unread list
      if (!isReadByCurrentUser) {
        _unreadMessageIds.add(message.id);
      }
    }
  }

  Future<void> _loadToken() async {
    try {
      final token = await _secureStorage.read(key: 'token');

      if (token == null || token.isEmpty) {
        if (Constants.token.isNotEmpty) {
          Constants.token = '';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication error: No valid token found'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
            return;
          }
        }
      } else {
        Constants.token = token;
        // Update Constants.token if it's empty
        if (Constants.token.isEmpty) {
          Constants.token = token;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading authentication token'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;
      try {
        final provider = ChatProviderInherited.of(context);
        provider.initialize();

        // Add provider listener for updates
        provider.addListener(_handleProviderUpdate);

        if (widget.initialMessages != null &&
            widget.initialMessages!.isNotEmpty) {
          _isLoadingMessages = false;
          // Initialize tracking for initial messages
          _previousMessageIds.addAll(widget.initialMessages!
              .where((message) => message.id.isNotEmpty)
              .map((message) => message.id));
          _previousMessageIdsList = widget.initialMessages!
              .where((message) => message.id.isNotEmpty)
              .map((message) => message.id)
              .toList();

          // Update the message list with initial messages
          _updateMessageList(widget.initialMessages!, scrollToBottom: false);

          // Mark all unread messages as read when chat opens with initial messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _markAllUnreadMessagesAsRead(widget.initialMessages!);
              _forceCheckVisibleMessages();
            }
          });
        } else if (!_hasFetchedInitialMessages) {
          _hasFetchedInitialMessages = true;
          print(
              'DEBUG: Calling _fetchInitialMessages() - hasFetchedInitialMessages: $_hasFetchedInitialMessages');
          _fetchInitialMessages();
        } else {
          // If we've already fetched messages but still loading, set to false
          if (_isLoadingMessages) {
            setState(() {
              _isLoadingMessages = false;
            });
          }

          // If we don't have any messages in the notifier, fetch them
          if (widget.messageListNotifier.value.isEmpty && !_isLoadingMessages) {
            print('DEBUG: No messages in notifier, fetching messages');
            _fetchInitialMessages();
          }
        }
        final chatState = context.read<ChatCustomerCubit>().state;
        if (chatState is ChatCustomerSuccessState) {
          final chats =
              chatState.chats.where((chat) => chat.sId == widget.chatId);
          if (chats.isNotEmpty) {
            provider.setCurrentChat(chats.first);
          }
        }
      } catch (e) {
        // Handle error silently
      }
    } else {
      // Screen became active again, reset message tracking to prevent duplication
      print('DEBUG: Screen became active - resetting message tracking');
      _previousMessageIds.clear();
      _previousMessageIdsList.clear();

      // Reset the fetched flag to allow refetching if needed
      _hasFetchedInitialMessages = false;

      // Clear the message list notifier to prevent duplication
      widget.messageListNotifier.value = [];
      print('DEBUG: Cleared message list notifier');

      // Only check visible messages if we have messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isLoadingMessages) {
          _forceCheckVisibleMessages();
        }
      });
    }
  }

  Future<void> _fetchInitialMessages() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Prevent multiple simultaneous calls
        if (_isLoadingMessages) return;

        _isLoadingMessages = true;
        print(
            'DEBUG: Starting to fetch initial messages for chatId: ${widget.chatId} (attempt ${retryCount + 1})');
        final chatCubit = context.read<ChatCustomerCubit>();
        await chatCubit.getMessages(widget.chatId,
            skip: 0, limit: 20); // Only fetch first page
        final state = chatCubit.state;

        if (state is ChatCustomerMessagesSuccessState &&
            state.chatId == widget.chatId) {
          print('DEBUG: Successfully loaded ${state.messages.length} messages');

          _previousMessageIds.addAll(state.messages
              .where((message) => message.id.isNotEmpty)
              .map((message) => message.id));
          _previousMessageIdsList = state.messages
              .where((message) => message.id.isNotEmpty)
              .map((message) => message.id)
              .toList();
          setState(() {
            _isLoadingMessages = false;
          });
          _updateMessageList(state.messages, scrollToBottom: true);

          // Mark all unread messages as read when chat opens
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _markAllUnreadMessagesAsRead(state.messages);
              _forceCheckVisibleMessages();
            }
          });
          return; // Success, exit retry loop
        } else if (state is ChatCustomerMessagesErrorState) {
          print('DEBUG: Error loading messages: ${state.error}');

          retryCount++;
          if (retryCount < maxRetries) {
            print('DEBUG: Retrying message fetch in 2 seconds...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          } else {
            setState(() {
              _isLoadingMessages = false;
            });

            // Show error message to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to load messages after $maxRetries attempts: ${state.error}'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isLoadingMessages = true;
                      });
                      _fetchInitialMessages();
                    },
                  ),
                ),
              );
            }
            return;
          }
        } else {
          print('DEBUG: Unexpected state: ${state.runtimeType}');
          setState(() {
            _isLoadingMessages = false;
          });
          return;
        }
      } catch (e) {
        print('DEBUG: Exception in _fetchInitialMessages: $e');

        retryCount++;
        if (retryCount < maxRetries) {
          print('DEBUG: Retrying message fetch in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          // Handle error and ensure loading state is cleared
          setState(() {
            _isLoadingMessages = false;
          });

          // Show error message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error loading messages after $maxRetries attempts: $e'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _isLoadingMessages = true;
                    });
                    _fetchInitialMessages();
                  },
                ),
              ),
            );
          }
          return;
        }
      }
    }
  }

  void _updateMessageList(List<ChatMessage> messages,
      {bool scrollToBottom = false}) {
    if (!mounted) return;

    print(
        'DEBUG: _updateMessageList called with ${messages.length} messages, scrollToBottom: $scrollToBottom');

    // Store previous IDs BEFORE updating the list
    final previousMessageIds = Set<String>.from(_previousMessageIdsList);

    // Check if we actually have new messages to avoid unnecessary updates
    final currentMessageIds =
        messages.where((msg) => msg.id.isNotEmpty).map((msg) => msg.id).toSet();

    // Get current messages in the notifier to check for duplicates
    final currentNotifierMessages = widget.messageListNotifier.value
        .whereType<ChatMessage>()
        .where((msg) => msg.id.isNotEmpty)
        .map((msg) => msg.id)
        .toSet();

    // If no new messages and we already have the same messages, skip update
    if (currentMessageIds.every((id) => currentNotifierMessages.contains(id)) &&
        currentNotifierMessages.isNotEmpty &&
        !scrollToBottom) {
      print('DEBUG: Skipping update - no new messages');
      return;
    }

    // Additional check: if the message counts are the same and all IDs match, skip
    if (currentMessageIds.length == currentNotifierMessages.length &&
        currentMessageIds.every((id) => currentNotifierMessages.contains(id)) &&
        !scrollToBottom) {
      print('DEBUG: Skipping update - same message count and IDs');
      return;
    }

    // Get existing messages from the notifier to merge with new ones
    final existingMessages =
        widget.messageListNotifier.value.whereType<ChatMessage>().toList();

    // Create a map of existing messages by ID for efficient lookup
    final existingMessagesMap = <String, ChatMessage>{};
    for (final message in existingMessages) {
      if (message.id.isNotEmpty) {
        existingMessagesMap[message.id] = message;
      }
    }

    // Merge new messages with existing ones, preferring newer versions
    final allMessages = <String, ChatMessage>{};

    // Add existing messages first
    allMessages.addAll(existingMessagesMap);

    // Add/update with new messages
    for (final message in messages) {
      if (message.id.isNotEmpty) {
        // Check if this message replaces a temporary message
        bool isReplacement = false;
        if (message.clientMessageId != null) {
          // Find and remove any temporary message with the same clientMessageId
          final tempMessageKey = existingMessagesMap.keys.firstWhere(
            (key) =>
                existingMessagesMap[key]?.clientMessageId ==
                    message.clientMessageId &&
                key.startsWith('temp_'),
            orElse: () => '',
          );
          if (tempMessageKey.isNotEmpty) {
            allMessages.remove(tempMessageKey);
            isReplacement = true;
            print(
                'DEBUG: Replaced temporary message $tempMessageKey with permanent message ${message.id}');
          }
        }

        // Only update if this is a newer version, if we don't have it, or if it's a replacement
        if (!allMessages.containsKey(message.id) ||
            isReplacement ||
            (message.messageDate ?? DateTime.now()).isAfter(
                allMessages[message.id]?.messageDate ?? DateTime(1900))) {
          allMessages[message.id] = message;
        }
      }
    }

    // Convert back to list and sort by date
    final sortedMessages = allMessages.values.toList()
      ..sort((a, b) => (a.messageDate ?? DateTime.now())
          .compareTo(b.messageDate ?? DateTime.now()));

    // Use a grouping mechanism to place date headers correctly
    final messageList = <dynamic>[];
    if (sortedMessages.isEmpty) {
      // Only clear if this is the initial load and there were never any messages
      if (_previousMessageIdsList.isEmpty) {
        _previousMessageIdsList = [];
      }
      widget.messageListNotifier.value = [];
      return;
    }

    DateTime? currentDate;
    for (var i = 0; i < sortedMessages.length; i++) {
      final message = sortedMessages[i];
      if (message.isDeleted == true) {
        continue;
      }

      DateTime messageDate;
      if (message.messageDate != null) {
        messageDate = message.messageDate!;
      } else {
        messageDate = DateTime.now();
      }

      final messageDay = DateTime(
        messageDate.year,
        messageDate.month,
        messageDate.day,
      );

      if (currentDate == null || !_isSameDay(currentDate, messageDay)) {
        currentDate = messageDay;
        messageList.add(currentDate);
      }

      messageList.add(message);
    }

    // Update the message list notifier - reverse for reverse ListView to show newest at bottom
    final reversedList = messageList.reversed.toList();
    // Force the ValueNotifier to notify listeners even if the list appears the same
    // This ensures UI updates when message properties change

    // Create a new list reference to ensure ValueNotifier detects the change
    final newList = List<dynamic>.from(reversedList);
    widget.messageListNotifier.value = newList;

    // Update the previous list AFTER updating the notifier
    _previousMessageIdsList = messageList
        .whereType<ChatMessage>()
        .map((m) => m.id)
        .where((id) => id.isNotEmpty)
        .toList();

    // Update the _previousMessageIds set to match the current list
    _previousMessageIds.clear();
    _previousMessageIds.addAll(_previousMessageIdsList);

    // Check for new messages that need immediate marking as read
    final newMessageIds = _previousMessageIdsList
        .where((id) => !previousMessageIds.contains(id))
        .toList();

    if (newMessageIds.isNotEmpty) {}

    // Mark messages as read when they become visible
    _markMessagesAsRead(sortedMessages);

    // Update unread message tracking
    _updateUnreadMessageTracking(sortedMessages);

    // Only scroll to bottom if requested (not during pagination)
    if (scrollToBottom) {
      _scrollToBottom();
    }
  }

  /// Mark messages as read when they become visible
  void _markMessagesAsRead(List<ChatMessage> messages) {
    // ✅ DISABLED: Mark as read functionality removed
    if (kDebugMode) {
      print(
          'ChatScreen: _markMessagesAsRead called but disabled (${messages.length} messages)');
    }
    return;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Since we're using reverse: true, 0 is the bottom (newest messages)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateDebounceTimer?.cancel();
    _typingTimer?.cancel();
    _cleanupTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _socketHealthCheckTimer?.cancel(); // ✅ NEW: Cancel socket health check timer
    _markAsReadTimer?.cancel();
    _resetProcessingFlagTimer?.cancel();
    _scrollController.removeListener(_onScrollUpdate);
    _scrollController.dispose();

    // Remove observer for app lifecycle changes
    WidgetsBinding.instance.removeObserver(this);

    // Dispose the provider here
    widget.chatProvider.removeListener(_onProviderUpdate);
    widget.chatProvider.removeListener(_handleProviderUpdate);
    widget.chatProvider.dispose();
    super.dispose();
  }

  void _handleProviderUpdate() {
    if (!mounted || _isProcessingProviderUpdate) return;

    final provider = ChatProviderInherited.of(context);
    final newMessages = provider.messages;

    // Check if we actually have new messages to avoid unnecessary updates
    final currentMessageIds = newMessages
        .where((msg) => msg.id.isNotEmpty)
        .map((msg) => msg.id)
        .toSet();

    // Get current messages in the notifier to check for duplicates
    final currentNotifierMessages = widget.messageListNotifier.value
        .whereType<ChatMessage>()
        .where((msg) => msg.id.isNotEmpty)
        .map((msg) => msg.id)
        .toSet();

    // Only update if we have new messages or if the list is empty
    final hasNewMessages =
        currentMessageIds.any((id) => !currentNotifierMessages.contains(id));
    final isEmpty = currentNotifierMessages.isEmpty;

    if (hasNewMessages || isEmpty) {
      // CRITICAL: Check for new messages BEFORE updating the message list
      // This ensures _previousMessageIds hasn't been updated yet
      _checkAndMarkNewMessagesAsRead(newMessages);
      
      // THEN update the message list (which updates _previousMessageIds)
      _updateMessageList(newMessages);

      // Force check visible messages to ensure they are marked as read
      _forceCheckVisibleMessages();

      // Force a UI rebuild
      if (mounted) {
        setState(() {});
      }
    }

    // If we were loading messages and now we have some, update loading state
    if (_isLoadingMessages && newMessages.isNotEmpty) {
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  /// Mark ALL unread messages in the chat as read when opening the chat
  void _markAllUnreadMessagesAsRead(List<ChatMessage> messages) {
    if (!mounted) return;
    
    try {
      final currentUserId = widget.userId;
      final unreadMessageIds = <String>{};

      for (final message in messages) {
        // Skip if message is from current user, deleted, or already marked as read
        if (message.messageCreator?.id == currentUserId ||
            message.isDeleted == true ||
            _markedAsReadIds.contains(message.id) ||
            message.isRead == true ||
            message.isSeen == true) {
          continue;
        }

        // This is an unread message - mark it as read
        unreadMessageIds.add(message.id);
      }

      // Filter out invalid/temporary message IDs
      final validMessageIds = unreadMessageIds
          .where((id) => 
              id.isNotEmpty && 
              !id.startsWith('temp_') && 
              !id.startsWith('optimistic_') &&
              id.length > 10) // Basic validation for MongoDB ObjectIds
          .toList();

      // Mark ALL unread messages as read
      if (validMessageIds.isNotEmpty) {
        if (kDebugMode) {
          print('=== Customer ChatScreen: Marking ALL ${validMessageIds.length} unread messages as read on chat open ===');
          print('Chat ID: ${widget.chatId}');
          print('Valid Message IDs to mark as read: $validMessageIds');
          if (unreadMessageIds.length != validMessageIds.length) {
            print('WARNING: Filtered out ${unreadMessageIds.length - validMessageIds.length} invalid/temporary IDs');
          }
        }
        
        // Add to marked as read set BEFORE calling the API to prevent duplicates
        _markedAsReadIds.addAll(validMessageIds);
        _previousMessageIds.addAll(validMessageIds);
        
        // Mark as delivered first, then as read
        context.read<ChatCustomerCubit>().markMessagesAsDelivered(
              widget.chatId,
              validMessageIds,
            );

        // Small delay to ensure delivery status is processed before read status
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            if (kDebugMode) {
              print('Customer ChatScreen: Calling cubit.markMessagesAsRead for ALL ${validMessageIds.length} unread messages');
            }
            context.read<ChatCustomerCubit>().markMessagesAsRead(
                  widget.chatId,
                  validMessageIds,
                );
          }
        });
      } else {
        if (kDebugMode) {
          print('Customer ChatScreen: No valid unread message IDs to mark as read on chat open');
          if (unreadMessageIds.isNotEmpty) {
            print('WARNING: All ${unreadMessageIds.length} message IDs were invalid/temporary: $unreadMessageIds');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Customer ChatScreen: Error marking all unread messages as read: $e');
      }
    }
  }

  /// Check for new messages and mark them as read immediately if they should be
  void _checkAndMarkNewMessagesAsRead(List<ChatMessage> newMessages) {
    try {
      final currentUserId = widget.userId;
      final unreadMessageIds = <String>{};

      for (final message in newMessages) {
        // Skip if message is from current user, deleted, or already marked as read
        if (message.messageCreator?.id == currentUserId ||
            message.isDeleted == true ||
            _markedAsReadIds.contains(message.id) ||
            message.isRead == true ||
            message.isSeen == true) {
          continue;
        }

        // Check if this is a new message that wasn't in our previous tracking
        if (!_previousMessageIds.contains(message.id)) {
          // This is a new message - mark it as read immediately
          unreadMessageIds.add(message.id);
        }
      }

      // Mark new messages as read immediately
      if (unreadMessageIds.isNotEmpty) {
        if (kDebugMode) {
          print('=== Customer ChatScreen: Marking ${unreadMessageIds.length} new messages as read ===');
          print('Chat ID: ${widget.chatId}');
          print('Message IDs to mark as read: $unreadMessageIds');
        }
        
        // Add to marked as read set BEFORE calling the API to prevent duplicates
        _markedAsReadIds.addAll(unreadMessageIds);
        _previousMessageIds.addAll(unreadMessageIds);

        // Mark as delivered first, then as read
        context.read<ChatCustomerCubit>().markMessagesAsDelivered(
              widget.chatId,
              unreadMessageIds.toList(),
            );

        // Small delay to ensure delivery status is processed before read status
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            if (kDebugMode) {
              print('Customer ChatScreen: Calling cubit.markMessagesAsRead for ${unreadMessageIds.length} messages');
            }
            context.read<ChatCustomerCubit>().markMessagesAsRead(
                  widget.chatId,
                  unreadMessageIds.toList(),
                );
          } else {
            if (kDebugMode) {
              print('Customer ChatScreen: Widget not mounted, skipping markMessagesAsRead');
            }
          }
        });
      } else {
        if (kDebugMode) {
          print('Customer ChatScreen: No unread messages to mark as read');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Customer ChatScreen: Error marking new messages as read: $e');
      }
    }
  }

  /// Force check visible messages and mark them as read
  void _forceCheckVisibleMessages() {
    if (!mounted || _isLoadingMessages) return;

    // ✅ DISABLED: Mark as read functionality removed
    // Messages are only marked as delivered, not read
    if (kDebugMode) {
      print('ChatScreen: Mark as read functionality disabled');
    }

    // Get currently visible message IDs (for potential future use)
    final visibleMessageIds = _getVisibleMessageIds();
    final unreadVisibleIds = visibleMessageIds
        .where((id) =>
            _unreadMessageIds.contains(id) && !_markedAsReadIds.contains(id))
        .toList();

    if (unreadVisibleIds.isNotEmpty && kDebugMode) {
      print(
          'ChatScreen: ${unreadVisibleIds.length} visible messages (read functionality disabled)');
    }
  }

  /// Force refresh the message list to reflect status changes
  void _forceRefreshMessageList() {
    if (!mounted) return;

    // Force a rebuild of the message list
    setState(() {});
  }

  /// Mark messages as read only when user explicitly views the chat or sends a message
  void _markMessagesAsReadWhenAppropriate() {
    if (!mounted) return;

    // ✅ DISABLED: Mark as read functionality removed
    if (kDebugMode) {
      print(
          'ChatScreen: _markMessagesAsReadWhenAppropriate called but disabled');
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCustomerCubit, ChatCustomerState>(
      listener: (context, state) {
        if (state is ChatCustomerSuccessState) {
          // Find the current chat in the list
          final chatIndex = state.chats.indexWhere(
            (chat) => chat.sId == widget.chatId,
          );

          // Update the provider with the current chat if found
          if (chatIndex != -1) {
            try {
              ChatProviderInherited.of(context)
                  .setCurrentChat(state.chats[chatIndex]);
            } catch (e) {
              // Provider might be disposed, ignore
            }
          }
        } else if (state is ChatCustomerMessagesSuccessState &&
            state.chatId == widget.chatId) {
          // Prevent duplicate processing
          if (_isProcessingBlocUpdate) return;
          _isProcessingBlocUpdate = true;

          final provider = ChatProviderInherited.of(context);

          // Update the previous message IDs tracking
          final currentMessageIds = state.messages
              .where((message) => message.id.isNotEmpty)
              .map((message) => message.id)
              .toSet();

          // Check if this is an optimistic message update
          final optimisticMessages =
              state.messages.where((m) => m.id.startsWith('temp_')).toList();

          if (optimisticMessages.isNotEmpty && provider.messages.isNotEmpty) {
            // If we have optimistic messages and existing messages, only add the optimistic ones
            for (final optimisticMessage in optimisticMessages) {
              provider.addOptimisticMessageIfNotExists(optimisticMessage);
            }
          } else {
            // For regular message updates or when no existing messages, replace all messages
            provider.setMessages(state.messages);
          }

          // Check if there are new messages
          final hasNewMessages =
              currentMessageIds.any((id) => !_previousMessageIds.contains(id));

          if (hasNewMessages) {
            // Update the tracking sets
            _previousMessageIds.addAll(currentMessageIds);
            _previousMessageIdsList = state.messages
                .where((message) => message.id.isNotEmpty)
                .map((message) => message.id)
                .toList();
          }

          setState(() {
            _isLoadingMessages = false;
          });

          // Disable automatic message confirmation to prevent unread counter from clearing
          // Only confirm messages when user actively views them
          // _confirmNewMessagesReceived(state.messages);

          // Update the message list to reflect status changes (including read status and invoice updates)
          // Check for new messages, status changes, or invoice data changes
          final hasStatusChanges =
              state.messages.any((m) => m.isRead == true || m.isSeen == true);
          final hasInvoiceChanges = state.messages.any((m) =>
              m.messageInvoice != null ||
              m.invoiceData != null ||
              m.messageInvoiceRef != null);

          if (hasNewMessages || hasStatusChanges || hasInvoiceChanges) {
            if (kDebugMode) {
              print('ChatScreen: Updating message list with changes');
              print('  - Total messages: ${state.messages.length}');
              print('  - Has new messages: $hasNewMessages');
              print('  - Has status changes: $hasStatusChanges');
              print('  - Has invoice changes: $hasInvoiceChanges');
              print(
                  '  - Messages with isRead=true: ${state.messages.where((m) => m.isRead == true).length}');
              print(
                  '  - Messages with isSeen=true: ${state.messages.where((m) => m.isSeen == true).length}');
              print(
                  '  - Messages with invoice data: ${state.messages.where((m) => m.messageInvoice != null || m.invoiceData != null).length}');
            }
            _updateMessageList(state.messages, scrollToBottom: false);
            // Force UI update to reflect status changes
            setState(() {});
          }

          // Reset the flag after processing with a timeout
          _resetProcessingFlagTimer?.cancel();
          _resetProcessingFlagTimer =
              Timer(const Duration(milliseconds: 500), () {
            _isProcessingBlocUpdate = false;
          });
        } else if (state is ChatCustomerMessagesErrorState &&
            state.chatId == widget.chatId) {
          // Update loading state on error
          setState(() {
            _isLoadingMessages = false;
          });
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Connection Error'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: ColorManager.gray100,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AnimatedBuilder(
              animation: widget.entranceAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -20 + (widget.slideAnimation.value * 0.4)),
                  child: Opacity(
                    opacity: widget.fadeAnimation.value,
                    child: AppBar(
                      elevation: 1,
                      scrolledUnderElevation: 0,
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, Routes.chatCustomerRoute),
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.black),
                      ),
                      centerTitle: false,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.companyName.isEmpty
                                ? 'Company'
                                : widget.companyName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              return Consumer<PresenceProvider>(
                                key: ValueKey(
                                    'chat_screen_status_${widget.chatId}'),
                                builder: (context, presenceProvider, child) {
                                  final provider =
                                      ChatProviderInherited.of(context);
                                  final otherUserId = provider.onlineUserId;
                                  final isTicketChat =
                                      provider.currentChat?.isTicketChat ==
                                              true ||
                                          widget.isTicketChat;
                                  if (isTicketChat) {
                                    return const SizedBox.shrink();
                                  }

                                  // Get presence data for the other user
                                  final presence = otherUserId != null
                                      ? presenceProvider
                                          .getUserPresence(otherUserId)
                                      : null;
                                  final isOnline = presence?.isOnline ?? false;

                                  // If no presence data, request it
                                  if (otherUserId != null && presence == null) {
                                    presenceProvider
                                        .requestPresenceForUsers([otherUserId]);
                                  }

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isOnline
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          color: isOnline
                                              ? Colors.green
                                              : Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          body: AnimatedBuilder(
            animation: widget.entranceAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, widget.slideAnimation.value),
                child: Transform.scale(
                  scale: widget.scaleAnimation.value,
                  child: Opacity(
                    opacity: widget.fadeAnimation.value,
                    child: Column(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<List<dynamic>>(
                            valueListenable: widget.messageListNotifier,
                            builder: (context, messages, child) {
                              // Show loading indicator while either token or messages are loading
                              if (_isLoading || _isLoadingMessages) {
                                print(
                                    'DEBUG: Showing loading indicator - _isLoading: $_isLoading, _isLoadingMessages: $_isLoadingMessages');
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              // Only show 'No messages yet' if the list is empty
                              if (messages.isEmpty) {
                                return const Center(
                                    child: Text('No messages yet'));
                              }

                              return ListView.separated(
                                key: PageStorageKey(
                                    'chat_list_${widget.chatId}'),
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(
                                  height: 10,
                                ),
                                controller: _scrollController,
                                itemCount: messages.length,
                                reverse: true,
                                itemBuilder: (context, index) {
                                  // Show loading indicator at the top (oldest messages) when loading more messages
                                  // Since we're using reverse: true, the last index is at the top
                                  if (index == messages.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }

                                  // Adjust index for loading indicator
                                  final adjustedIndex = index;
                                  if (adjustedIndex < 0 ||
                                      adjustedIndex >= messages.length) {
                                    return null;
                                  }

                                  final item = messages[adjustedIndex];
                                  if (item is DateTime) {
                                    return _DateHeader(
                                        date: item, index: adjustedIndex);
                                  } else if (item is ChatMessage) {
                                    // Determine if message is from current user based on role
                                    // Since messageCreator.id is always company ID due to backend issue,
                                    // we need to use messageCreatorRole to determine the actual sender
                                    final isMe = (item.messageCreatorRole
                                                    ?.toLowerCase() ==
                                                'customer' &&
                                            widget.userRole.toLowerCase() ==
                                                'customer') ||
                                        (item.messageCreatorRole
                                                    ?.toLowerCase() ==
                                                'company' &&
                                            widget.userRole.toLowerCase() ==
                                                'company') ||
                                        (item.messageCreatorRole
                                                    ?.toLowerCase() ==
                                                'subaccount' &&
                                            widget.userRole.toLowerCase() ==
                                                'subaccount');
                                    // Check if this message is truly new by comparing with the previous list
                                    // Only consider it new if it wasn't in the previous list AND we have a previous list
                                    const isNewMessage =
                                        false; // Simplify for now
                                    double topMargin = 8.0;
                                    if (adjustedIndex < messages.length - 1) {
                                      final prev = messages[adjustedIndex + 1];
                                      if (prev is ChatMessage) {
                                        final prevIsMe =
                                            prev.messageCreator?.id ==
                                                widget.userId;
                                        if (prevIsMe == isMe) {
                                          topMargin =
                                              2.0; // Same sender, small margin
                                        }
                                      }
                                    } else {
                                      topMargin =
                                          16.0; // First message, larger margin
                                    }
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        left: 20.0,
                                        right: 20.0,
                                        top: topMargin,
                                        bottom: 2.0,
                                      ),
                                      child: Builder(
                                        builder: (context) {
                                          final chatProvider =
                                              ChatProviderInherited.of(context);
                                          return _MessageBubble(
                                            key: ValueKey(
                                                '${item.id}_${item.isRead}_${item.isSeen}_${item.isReceived}_${item.messageDate?.millisecondsSinceEpoch}_${item.invoice?.toString()}_${item.invoiceData?.toString()}_${item.messageInvoice?.toString()}_${item.messageInvoiceRef?.toString()}'),
                                            message: item,
                                            isMe: isMe,
                                            lastReadMessageDateTime:
                                                _lastReadMessageDateTime,
                                            index: adjustedIndex,
                                            isNewMessage: isNewMessage,
                                            chatId: widget.chatId,
                                            currentUserId: widget.userId,
                                            isRecipientOnline:
                                                chatProvider.isOtherUserOnline,
                                            onMessageVisible: () {
                                              // Use ChatProvider's visibility tracking for read status
                                              chatProvider.onMessageVisible(
                                                  item.id, isMe);
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ),
                        ChatProviderInherited(
                          provider: ChatProviderInherited.of(context),
                          child: ListenableBuilder(
                            listenable: ChatProviderInherited.of(context),
                            builder: (context, child) {
                              try {
                                final provider =
                                    ChatProviderInherited.of(context);
                                final isChatClosed =
                                    provider.currentChat?.isClosed == true;
                                final isChatDeleted =
                                    provider.currentChat?.isDeleted == true;

                                // Hide MessageInput if chat is closed
                                if (isChatClosed || isChatDeleted) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            color: Colors.grey[600],
                                            size: 32,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isChatClosed
                                                ? 'This chat has been closed'
                                                : 'This chat has been deleted',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return MessageCustomerInput(
                                  controller: _messageController,
                                  isCustomer: widget.userRole == 'customer',
                                  isTicketChat: widget.isTicketChat == true,
                                );
                              } catch (e) {
                                // Provider might be disposed, show default input
                                return MessageCustomerInput(
                                  controller: _messageController,
                                  isCustomer: widget.userRole == 'customer',
                                  isTicketChat: widget.isTicketChat == true,
                                );
                              }
                            },
                          ),
                        ),
                        // Add typing indicator
                        Builder(
                          builder: (context) {
                            try {
                              final userStatusProvider =
                                  Provider.of<UserStatusProvider>(context,
                                      listen: true);
                              final provider =
                                  ChatProviderInherited.of(context);
                              final isChatClosed =
                                  provider.currentChat?.isClosed == true;
                              final isChatDeleted =
                                  provider.currentChat?.isDeleted == true;
                              // Get typing users for this chat
                              final typingUsers = userStatusProvider
                                  .getTypingUsers(widget.chatId);
                              final otherUserId = provider.onlineUserId;

                              // Hide typing indicator if chat is closed or no one is typing
                              if (typingUsers.isEmpty ||
                                  isChatClosed ||
                                  isChatDeleted) {
                                return const SizedBox.shrink();
                              }

                              // Filter out current user from typing list
                              final otherTypingUsers = typingUsers
                                  .where((userId) => userId != widget.userId)
                                  .toList();

                              if (otherTypingUsers.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final typingUserNames =
                                  otherTypingUsers.map((userId) {
                                // You can customize this to show actual user names
                                return userId == otherUserId
                                    ? 'Someone'
                                    : 'Someone';
                              }).join(', ');

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                color: Colors.grey[100],
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.grey[600]!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$typingUserNames ${otherTypingUsers.length == 1 ? 'is' : 'are'} typing...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              // Provider might be disposed, hide typing indicator
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DateHeader extends StatefulWidget {
  final DateTime date;
  final int index;

  const _DateHeader({required this.date, required this.index});

  @override
  State<_DateHeader> createState() => _DateHeaderState();
}

class _DateHeaderState extends State<_DateHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 30)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation after a short delay
    Future.delayed(Duration(milliseconds: widget.index * 20), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay =
        DateTime(widget.date.year, widget.date.month, widget.date.day);

    String displayText;
    if (messageDay == today) {
      displayText = 'Today';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      displayText = 'Yesterday';
    } else {
      displayText = DateFormat('MMM dd, y').format(widget.date);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorManager.blueLight800,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 10,
                      color: ColorManager.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final DateTime? lastReadMessageDateTime;
  final int index;
  final bool isNewMessage;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;
  final bool? isRecipientOnline; // Add recipient online status

  const _MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.lastReadMessageDateTime,
    required this.index,
    this.isNewMessage = false,
    required this.chatId,
    required this.currentUserId,
    this.onMessageVisible,
    this.isRecipientOnline,
  }) : super(key: key);

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();

    // Only apply entrance animation if this is a new message
    if (widget.isNewMessage) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );

      // WhatsApp-like slide up animation for NEW messages only
      _slideAnimation = Tween<double>(
        begin: 50.0, // Start from below
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));

      // Add scale animation for a more polished effect
      _scaleAnimation = Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ));

      // Start animation immediately for new messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasAnimated) {
          _animationController.forward();
          _hasAnimated = true;
        }
      });
    } else {
      // For existing messages, create a simple controller that's already completed
      _animationController = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );

      _slideAnimation = Tween<double>(
        begin: 0.0,
        end: 0.0,
      ).animate(_animationController);

      _fadeAnimation = Tween<double>(
        begin: 1.0,
        end: 1.0,
      ).animate(_animationController);

      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.0,
      ).animate(_animationController);

      // Mark as already completed for existing messages
      _animationController.value = 1.0;
      _hasAnimated = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: MessageCustomerWidget(
                key: ValueKey(widget.message.id),
                message: widget.message,
                isFromUser: widget.isMe,
                lastReadMessageDate: widget.lastReadMessageDateTime,
                chatId: widget.chatId,
                currentUserId: widget.currentUserId,
                onMessageVisible: widget.onMessageVisible,
                isRecipientOnline: widget.isRecipientOnline,
                onPhotoTap: (photoUrl) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        body: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                onDocumentTap: (documentUrl) async {
                  try {
                    // Clean the URL by removing square brackets
                    String cleanUrl =
                        documentUrl.replaceAll('[', '').replaceAll(']', '');

                    if (cleanUrl.toLowerCase().endsWith('.pdf')) {
                      // For PDFs, use the ViewPdf widget
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPdf(
                              messageDocument: cleanUrl,
                            ),
                          ),
                        );
                      }
                    } else {
                      // For other document types
                      if (cleanUrl.startsWith('http')) {
                        // Remote URL - try to launch with system app
                        final Uri url = Uri.parse(cleanUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open the document'),
                              ),
                            );
                          }
                        }
                      } else {
                        // Local file - check if it exists and try to open
                        final file = File(cleanUrl);
                        if (await file.exists()) {
                          // For local files, we need to use a different approach
                          // Try to open with the system's default app
                          final Uri fileUri = Uri.file(cleanUrl);
                          if (await canLaunchUrl(fileUri)) {
                            await launchUrl(fileUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No app available to open this document type'),
                                ),
                              );
                            }
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Document file not found'),
                              ),
                            );
                          }
                        }
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error opening document'),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
