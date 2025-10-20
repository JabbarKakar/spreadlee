import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/presentation/bloc/customer/chat_bloc/chat_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/chat_bloc/chat_state.dart';
import 'package:spreadlee/presentation/customer/chat/view/chat_screen.dart';
import 'package:spreadlee/presentation/business/home/widget/delete_chat_dialog.dart';
import 'package:spreadlee/presentation/business/home/widget/close_chat_dialog.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/presentation/customer/chat/widget/chat_container.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
// Note: UserStatusProvider is no longer used directly in this file
import 'package:spreadlee/providers/presence_provider.dart';
import 'package:spreadlee/services/chat_event_manager.dart';
import 'package:spreadlee/services/connection_popup_service.dart';
import 'package:spreadlee/services/connection_monitor_service.dart';
import 'package:spreadlee/services/socket_service.dart';
import 'package:spreadlee/services/chat_service.dart';
import '../../../resources/color_manager.dart';
import 'dart:async';

class ChatListCustomer extends StatefulWidget {
  const ChatListCustomer({super.key});

  @override
  State<ChatListCustomer> createState() => _ChatListCustomerState();
}

class _ChatListCustomerState extends State<ChatListCustomer>
    with WidgetsBindingObserver {
  final ConnectionPopupService _popupService = ConnectionPopupService();
  final ConnectionMonitorService _connectionMonitor =
      ConnectionMonitorService();
  final SocketService _socketService = SocketService();
  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date: $dateTimeStr');
      }
      return '';
    }
  }

  // Add real-time update management
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  Timer? _chatUpdateTimer;

  // Cache the last successful chat list state to prevent distortion
  List<Chats>? _lastSuccessfulChats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // ✅ CLEANUP: Clear any open chat when returning to chat list
    final cubit = context.read<ChatCustomerCubit>();
    if (kDebugMode) {
      print('=== Customer ChatList: Clearing open chat (was: ${cubit.currentlyOpenChatId}) ===');
    }
    cubit.setCurrentlyOpenChat(null);
    
    cubit.getCustomerChats();
    // Initialize popup services with context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _popupService.initialize(context);
        _popupService.setConnectionServices(_connectionMonitor, _socketService);
        _socketService.initializePopupService(context);
        _connectionMonitor.initializePopupService(context);
      }
    });

    // Initialize real-time updates
    _initializeRealTimeUpdates();

    // Load chats initially (but not on every dependency change)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // ✅ ADD: Initialize socket before loading chats
        try {
          final chatService = Provider.of<ChatService>(context, listen: false);
          await chatService.waitForSocketReady();
        } catch (e) {
          if (kDebugMode) {
            print('Socket initialization failed in chat list: $e');
          }
        }

        final cubit = context.read<ChatCustomerCubit>();
        cubit.getCustomerChats();
      }
    });

    // Start periodic refresh for chat list
    _startPeriodicRefresh();

    // Restore user status when returning to chat list
    _restoreUserStatusOnReturn();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ CLEANUP: Clear any open chat when returning to chat list
    final cubit = context.read<ChatCustomerCubit>();
    if (kDebugMode) {
      print('=== Customer Chat List: didChangeDependencies called ===');
      print('Clearing open chat (was: ${cubit.currentlyOpenChatId})');
    }
    cubit.setCurrentlyOpenChat(null);

    // Refresh chat list when returning from chat screen to ensure latest data
    // This matches the business behavior where chat list refreshes on navigation back
    if (kDebugMode) {
      print('Refreshing chat list to ensure latest data after navigation');
    }

    // Refresh chat list when dependencies change (e.g., returning from chat screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshChatList();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _chatUpdateTimer?.cancel();

    // Cleanup popup services
    _popupService.dispose();

    // Persist user status when leaving chat list
    _persistUserStatusOnExit();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Refresh chat list when app resumes
      _refreshChatList();
      // Restore user status when app resumes
      _restoreUserStatusOnReturn();
    } else if (state == AppLifecycleState.paused) {
      // Update user status to offline when app is paused
      _updateUserStatus(false);
      // Persist user status when app is paused
      _persistUserStatusOnExit();
    }
  }

  void _initializeRealTimeUpdates() {
    // Listen to chat events for real-time updates
    ChatEventManager().addEventListener(ChatEventType.userStatusChange,
        (event) {
      if (mounted) {
        // Note: UserStatusProvider.notifyListeners has been deprecated
        // The new presence system handles notifications automatically

        setState(() {
          // Trigger rebuild to update online status
        });
      }
    });

    ChatEventManager().addEventListener(ChatEventType.messageSeenUpdate,
        (event) {
      if (mounted) {
        // Note: UserStatusProvider.notifyListeners has been deprecated
        // The new presence system handles notifications automatically

        // ✅ REMOVED: Unread count logic - let the cubit handle this
        if (kDebugMode) {
          print('=== Customer Chat List: Received messageSeenUpdate ===');
          print('Letting cubit handle unread count updates');
        }
      }
    });

    ChatEventManager().addEventListener(ChatEventType.newMessage, (event) {
      if (mounted) {
        // Note: UserStatusProvider.notifyListeners has been deprecated
        // The new presence system handles notifications automatically

        // Update chat list when new message arrives
        _handleNewMessage(event.data);
      }
    });
  }

  void _startPeriodicRefresh() {
    // Disable periodic status refresh to prevent interference with real-time updates
    if (kDebugMode) {
      print(
          'CustomerHome: Periodic status refresh disabled to prevent flickering');
    }

    // Only refresh chat list, not user statuses
    _refreshTimer = Timer.periodic(const Duration(seconds: 300), (_) {
      if (mounted && !_isRefreshing) {
        if (kDebugMode) {
          print(
              'CustomerHome: Periodic chat list refresh (status refresh disabled)');
        }
        // Only refresh chat list, not user statuses
        // _refreshChatList(); // Disabled to prevent flickering
      }
    });
  }

  // Request user statuses immediately with proper initialization
  void _requestUserStatusesImmediately(List<Chats> chats) {
    try {
      final presenceProvider =
          Provider.of<PresenceProvider>(context, listen: false);

      final allUserIds = <String>{};

      for (final chat in chats) {
        // Check if chat is deleted
        if (chat.isDeleted == true) {
          continue; // Skip deleted chats for status requests
        }

        // Add company user ID for active chats
        final companyUserId = chat.chatUsers?.companyId?.sId;
        if (companyUserId != null && companyUserId != Constants.userId) {
          allUserIds.add(companyUserId);
        }

        // Add customer user ID
        final customerUserId = chat.chatUsers?.customerId;
        if (customerUserId != null && customerUserId != Constants.userId) {
          allUserIds.add(customerUserId);
        }
      }

      // Request presence data for all users at once
      if (allUserIds.isNotEmpty) {
        presenceProvider.requestPresenceForUsers(allUserIds.toList());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting user presence data: $e');
      }
    }
  }

  void _refreshChatList() async {
    if (!_isRefreshing) {
      _isRefreshing = true;

      if (kDebugMode) {
        print('CustomerHome: Refreshing chat list (status refresh disabled)');
      }

      // ✅ ADD: Initialize socket before refreshing chats
      try {
        final chatService = Provider.of<ChatService>(context, listen: false);
        await chatService.waitForSocketReady();
      } catch (e) {
        if (kDebugMode) {
          print('Socket initialization failed during refresh: $e');
        }
      }

      // Only refresh chat list, not user statuses
      context.read<ChatCustomerCubit>().getCustomerChats();

      // Reset refresh flag after a delay
      Future.delayed(const Duration(seconds: 2), () {
        _isRefreshing = false;
      });
    }
  }

  // Method to request status for all users in chat list
  void _requestStatusForAllChatUsers(List<Chats> chats) {
    try {
      final presenceProvider =
          Provider.of<PresenceProvider>(context, listen: false);

      final allUserIds = <String>{};

      for (final chat in chats) {
        // Add company user ID
        final companyUserId = chat.chatUsers?.companyId?.sId;
        if (companyUserId != null && companyUserId != Constants.userId) {
          allUserIds.add(companyUserId);
        }

        // Add customer user ID
        final customerUserId = chat.chatUsers?.customerId;
        if (customerUserId != null && customerUserId != Constants.userId) {
          allUserIds.add(customerUserId);
        }
      }

      if (allUserIds.isNotEmpty) {
        if (kDebugMode) {
          print('Requesting presence data for all chat users: $allUserIds');
        }

        // Request presence data for all users at once (more efficient)
        presenceProvider.requestPresenceForUsers(allUserIds.toList());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting presence data for chat users: $e');
      }
    }
  }

  void _updateUserStatus(bool isOnline) {
    try {
      // Note: UserStatusProvider.updateCurrentUserStatus has been deprecated
      // The new presence system handles current user status automatically via socket events
      if (kDebugMode) {
        print('CustomerChatList: User status update requested: $isOnline');
        print(
            'CustomerChatList: Status updates now handled by presence system');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user status: $e');
      }
    }
  }


  void _handleNewMessage(Map<String, dynamic> data) {
    final chatId = data['chat_id'] ?? data['chatId'];
    if (chatId != null) {
      // Don't refresh chat list automatically - let the cubit handle real-time updates
      // This prevents interference with real-time unread counter updates
      if (kDebugMode) {
        print(
            '=== Customer Chat List: Received new message for chat $chatId ===');
        print('Not refreshing chat list to preserve real-time updates');
      }
    }
  }

  void _handleDeleteChat(Chats chat) {
    if (kDebugMode) {
      print('=== Starting Delete Chat Process ===');
      print('Chat ID: ${chat.id}');
      print('Chat company: ${chat.chatUsers?.companyId?.companyName}');
    }

    showDialog(
      context: context,
      builder: (dialogContext) => DeleteChatDialog(
        onDelete: () async {
          if (kDebugMode) {
            print('=== Delete Confirmed ===');
            print('Deleting chat: ${chat.id}');
          }

          try {
            // Call the deleteChat function from the cubit
            // The cubit will handle the refresh internally
            await context.read<ChatCustomerCubit>().deleteChat(chat.id);

            // Refresh the chat list after successful deletion
            _refreshChatList();

            if (kDebugMode) {
              print('=== Delete Chat Completed ===');
              print('Chat list refreshed after deletion');
            }

            // Safely close the dialog
            if (dialogContext.mounted) {
              try {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error closing delete dialog: $e');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error during delete process: $e');
            }
            // Close dialog even if there's an error
            if (dialogContext.mounted) {
              try {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              } catch (dialogError) {
                if (kDebugMode) {
                  print('Error closing dialog after error: $dialogError');
                }
              }
            }
          }
        },
      ),
    );
  }

  void _handleCloseChat(Chats chat) {
    showDialog(
      context: context,
      builder: (dialogContext) => CloseChatDialog(
        onClose: () async {
          try {
            // Call the closeChat function from the cubit
            await context.read<ChatCustomerCubit>().closeChat(chat.id);

            // Refresh the chat list after successful closure
            _refreshChatList();

            // Safely close the dialog
            if (dialogContext.mounted) {
              try {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error closing dialog: $e');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error during customer close process: $e');
            }
            // Close dialog even if there's an error
            if (dialogContext.mounted) {
              try {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              } catch (dialogError) {
                if (kDebugMode) {
                  print('Error closing dialog after error: $dialogError');
                }
              }
            }
          }
        },
      ),
    );
  }

  void _handleChatTap(Chats chat) async {
    // // ✅ ADD: Initialize socket before opening chat
    // try {
    //   final chatService = Provider.of<ChatService>(context, listen: false);
    //   await chatService.waitForSocketReady();

    //   // ✅ ADD: Fast socket readiness check for chat navigation
    //   await chatService.ensureSocketReadyForChatNavigation(chat.sId ?? chat.id);
    //   if (kDebugMode) {
    //     print('Socket ready for specific chat: ${chat.sId ?? chat.id}');
    //   }
    // } catch (e) {
    //   if (kDebugMode) {
    //     print('Socket initialization failed when opening chat: $e');
    //   }
    // }

    // Optimistically update unread count (will be properly updated by the cubit)
    final cubit = context.read<ChatCustomerCubit>();
    // Optimistically set unread count to 0 in local state (same as business)
    // Use chat.sId to match the business implementation
    cubit.updateUnreadCountOptimistically(chat.sId ?? chat.id);
    // Mark messages as read if there are any unread messages
    if (chat.chatNotSeenMessages != null && chat.chatNotSeenMessages! > 0) {
      cubit.markMessagesAsRead(
        chat.sId ?? chat.id,
        [],
      );
      // Don't refresh chat list after marking as read - let the cubit handle updates
      // This prevents interference with real-time unread counter updates
      if (kDebugMode) {
        print(
            '=== Customer Chat List: Marked messages as read for chat ${chat.sId ?? chat.id} ===');
        print('Not refreshing chat list to preserve real-time updates');
      }
    }

    // Track and request status for the company user when opening the chat
    final companyUserId = chat.chatUsers?.companyId?.sId;
    if (companyUserId != null) {
      final presenceProvider =
          Provider.of<PresenceProvider>(context, listen: false);
      presenceProvider.requestPresenceForUsers([companyUserId]);
    }

    // Get real-time user status from PresenceProvider
    final presenceProvider =
        Provider.of<PresenceProvider>(context, listen: false);
    final realTimeIsOnline = companyUserId != null
        ? presenceProvider.isUserOnline(companyUserId)
        : false;

    // Navigate to chat screen with proper arguments
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenCustomer(
          chatId: chat.sId ?? chat.id,
          userId: chat.chatUsers?.customerId ?? '',
          userRole: 'customer',
          companyName: chat.chatUsers?.companyId?.companyName ?? '',
          isOnline: realTimeIsOnline,
          initialMessages: null,
          chat: chat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: ColorManager.white,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 25.0,
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, Routes.customerHomeRoute);
            },
          ),
        ),
        title: const Text('Chats'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatCustomerCubit, ChatCustomerState>(
                listener: (context, state) {
                  // Listen for state changes to ensure UI updates
                  if (kDebugMode) {
                    print('=== ChatList State Changed ===');
                    print('State type: ${state.runtimeType}');
                    if (state is ChatCustomerSuccessState) {
                      print('Chats count: ${state.chats.length}');
                    }
                  }

                  // Handle real-time updates
                  if (state is ChatCustomerSuccessState) {
                    // Request status for all users in the chat list when it updates
                    _requestStatusForAllChatUsers(state.chats.cast<Chats>());
                  }
                },
                buildWhen: (previous, current) {
                  // Always rebuild for any state change to catch real-time updates
                  return true;
                },
                builder: (context, state) {
                  if (kDebugMode) {
                    print('=== Building Chat List ===');
                    print('State type: ${state.runtimeType}');
                    print('State: $state');
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStateContent(state),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6, // Show 6 shimmer items
      itemBuilder: (context, index) {
        return _buildShimmerItem();
      },
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar shimmer
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name shimmer
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Message shimmer
                Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Time shimmer
          Container(
            height: 12,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated chat icon
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: ColorManager.blueLight800.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: ColorManager.blueLight800.withOpacity(0.6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'No Chats Available',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: ColorManager.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Start a conversation to see your chats here',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorManager.blueLight800,
                  ColorManager.blueLight800.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to start conversation or search companies
                Navigator.pushReplacementNamed(
                    context, Routes.customerHomeRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Find Companies',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    // Check if this is a connection-related error
    if (error.toLowerCase().contains('internet') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('host lookup') ||
        error.toLowerCase().contains('socket')) {
      // Show connection popup for connection errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _popupService.showConnectionError(customMessage: error);
        }
      });
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated error icon
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: ColorManager.lightError.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.error,
                    size: 60,
                    color: ColorManager.lightError.withOpacity(0.6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Please try again later',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorManager.blueLight800,
                  ColorManager.blueLight800.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: () {
                // Retry loading chats
                final cubit = context.read<ChatCustomerCubit>();
                cubit.getCustomerChats();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedChatItem({
    required Chats chat,
    required int index,
    required bool isOnline,
    required String chatId,
    required String userId,
  }) {
    return TweenAnimationBuilder<double>(
      duration:
          Duration(milliseconds: 300 + (index * 100)), // Staggered animation
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)), // Slide up from bottom
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ChatCustomerContainer(
                companyName: chat.chatUsers?.companyId?.companyName ?? '',
                commercialName: chat.chatCustomerCommercialName ?? '',
                publicName: chat.chatUsers?.companyId?.publicName ?? '',
                lastMessage: _getLastMessageText(chat),
                lastMessageTime: _formatTime(
                    chat.chatLastMessage?.messageDate ?? chat.updatedAt),
                unreadCount: chat.chatNotSeenMessages ?? 0,
                isOnline: isOnline,
                onTap: () => _handleChatTap(chat),
                onDelete: () => _handleDeleteChat(chat),
                onClose: () => _handleCloseChat(chat),
                chatId: chatId,
                userId: userId,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLastMessageText(Chats chat) {
    final lastMessage = chat.chatLastMessage?.messageText ?? 'No message';

    return lastMessage;
  }

  Widget _buildStateContent(ChatCustomerState state) {
    if (state is ChatCustomerInitialState) {
      if (kDebugMode) {
        print('Showing loading for initial state');
      }
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is ChatCustomerLoadingState) {
      if (kDebugMode) {
        print('Showing loading state');
      }
      return _buildShimmerLoading();
    }

    if (state is ChatCustomerErrorState) {
      if (kDebugMode) {
        print('Showing error state: ${state.error}');
      }
      return _buildErrorState(state.error);
    }

    // Handle ChatCustomerMessagesSuccessState by using cached chats
    if (state is ChatCustomerMessagesSuccessState) {
      if (kDebugMode) {
        print(
            'Using cached chats for ChatCustomerMessagesSuccessState in chat list');
      }
      // Use cached chats if available, otherwise show loading
      if (_lastSuccessfulChats != null) {
        return _buildChatListContent(_lastSuccessfulChats!);
      }
      return _buildShimmerLoading();
    }

    // Get chats from the current state
    final chats = state is ChatCustomerSuccessState ? state.chats : [];

    if (kDebugMode) {
      print('=== CHAT LIST: _buildStateContent ===');
      print('  - State type: ${state.runtimeType}');
      print('  - Chats count: ${chats.length}');
      if (state is ChatCustomerSuccessState) {
        print('  - Success state chats: ${state.chats.length}');
        for (final chat in state.chats) {
          print('    - Chat ${chat.sId}: unread=${chat.chatNotSeenMessages}');
        }
      }
    }

    // Cache successful chats for use when messages state is received
    if (state is ChatCustomerSuccessState && chats.isNotEmpty) {
      _lastSuccessfulChats = chats.cast<Chats>();
    }

    return _buildChatListContent(chats.cast<Chats>());
  }

  Widget _buildChatListContent(List<Chats> chats) {
    if (kDebugMode) {
      print('=== Building Chat List ===');
      print('Chats count: ${chats.length}');
    }

    if (chats.isEmpty) {
      if (kDebugMode) {
        print('Chats list is empty, showing "No Chats Available"');
      }
      return _buildEmptyState();
    }

    // Request user statuses immediately
    _requestUserStatusesImmediately(chats.cast<Chats>());

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(
          height: 30,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (kDebugMode) {
                print('Pull to refresh triggered');
              }
              final cubit = context.read<ChatCustomerCubit>();
              cubit.getCustomerChats();
            },
            child: Container(
              decoration: const BoxDecoration(),
              child: Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24.0),
                  scrollDirection: Axis.vertical,
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final companyUserId = chat.chatUsers?.companyId?.sId;
                    return Consumer<PresenceProvider>(
                      key: ValueKey('chat_${chat.sId}_status'),
                      builder: (context, presenceProvider, child) {
                        bool isOnline = false;
                        if (companyUserId != null && chat.sId != null) {
                          try {
                            // Get presence data for the company user
                            final presence =
                                presenceProvider.getUserPresence(companyUserId);
                            isOnline = presence?.isOnline ?? false;

                            // If no presence data, request it
                            if (presence == null) {
                              presenceProvider
                                  .requestPresenceForUsers([companyUserId]);
                            }

                            // Reduced debug logging - only log when presence data exists
                            if (kDebugMode && presence != null) {
                              print(
                                  '=== Customer Chat List Real-time Status Update ===');
                              print('Chat ID: ${chat.sId}');
                              print('Company User ID: $companyUserId');
                              print('Is Online: $isOnline');
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print(
                                  'Error getting online status for chat ${chat.sId}: $e');
                            }
                            isOnline = false;
                          }
                        }
                        // Reduced debug logging - only log when presence data exists
                        if (kDebugMode &&
                            presenceProvider
                                    .getUserPresence(companyUserId ?? '') !=
                                null) {
                          print('=== Customer Chat List Item Status ===');
                          print('Chat ID: ${chat.sId}');
                          print('Company User ID: $companyUserId');
                          print('Is Online: $isOnline');
                        }

                        return _buildAnimatedChatItem(
                          chat: chat,
                          index: index,
                          isOnline: isOnline,
                          chatId: chat.sId!,
                          userId: companyUserId ?? '',
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Method to persist user status when exiting chat list
  void _persistUserStatusOnExit() {
    try {
      // Note: UserStatusProvider persistence methods have been deprecated
      // The new presence system handles persistence automatically
      if (kDebugMode) {
        print(
            'CustomerChatList: User status persistence now handled by presence system');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error with user status persistence: $e');
      }
    }
  }

  // Method to restore user status when returning to chat list
  void _restoreUserStatusOnReturn() {
    try {
      // Note: UserStatusProvider restoration methods have been deprecated
      // The new presence system handles restoration automatically
      if (kDebugMode) {
        print(
            'CustomerChatList: User status restoration now handled by presence system');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error with user status restoration: $e');
      }
    }
  }
}
