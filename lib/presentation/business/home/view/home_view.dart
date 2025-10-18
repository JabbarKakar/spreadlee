import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/presentation/bloc/business/review_bloc/review_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/chat_bloc/chat_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/chat_bloc/chat_state.dart';
import 'package:spreadlee/presentation/customer/home/widget/search.dart';
import 'package:spreadlee/presentation/business/home/widget/chat_container.dart';
import 'package:spreadlee/presentation/business/home/widget/delete_chat_dialog.dart';
import 'package:spreadlee/presentation/business/home/widget/close_chat_dialog.dart';
import 'package:spreadlee/presentation/business/chat/view/chat_screen.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/domain/chat_model.dart';
// Note: UserStatusProvider is no longer used directly in this file
import 'package:spreadlee/providers/presence_provider.dart';
// Note: MediaCacheService is no longer used in this file
// Note: ChatService is no longer used directly in this file
import 'package:spreadlee/services/chat_event_manager.dart';
import 'package:spreadlee/services/connection_popup_service.dart';
import 'package:spreadlee/services/connection_monitor_service.dart';
import 'package:spreadlee/services/socket_service.dart';
import 'package:spreadlee/services/chat_service.dart';
// Note: SocketService is no longer used directly in this file
// Note: DI is no longer used directly in this file
import 'dart:async';

import '../../../resources/assets_manager.dart';
import '../../../resources/color_manager.dart';
import '../widget/drawer_business.dart';

class HomeViewBusiness extends StatefulWidget {
  const HomeViewBusiness({super.key});

  @override
  State<HomeViewBusiness> createState() => _HomeViewBusinessState();
}

class _HomeViewBusinessState extends State<HomeViewBusiness>
    with WidgetsBindingObserver {
  final ConnectionPopupService _popupService = ConnectionPopupService();
  final ConnectionMonitorService _connectionMonitor =
      ConnectionMonitorService();
  final SocketService _socketService = SocketService();

  bool isFilterShown = false;
  String? selectedFilter;
  String? appliedFilter;

  final List<String> filterOptions = [
    'Paid Invoice',
    'Unpaid Invoice',
    'Expired Invoice',
    'Read Chat',
    'Unread Chat',
  ];

  // Add real-time update management
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  final Set<String> _typingChats = {};
  final Map<String, DateTime> _typingTimestamps = {};
  Timer? _typingCleanupTimer;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
 context.read<ChatBusinessCubit>().getChats();
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

    // Start periodic refresh for chat list
    _startPeriodicRefresh();

    // Start typing indicator cleanup
    _startTypingCleanup();

    // Restore user status when returning to home view
    _restoreUserStatusOnReturn();

    // Initialize reviews and chats when the home view is created
    // Only fetch reviews for non-subaccount users
    if (Constants.role != 'subaccount') {
      context.read<ReviewCompanyCubit>().getReviews();
    }

    // Initialize chat list manager service and then load chats
    _initializeAndLoadChats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _typingCleanupTimer?.cancel();

    // Cleanup popup services
    _popupService.dispose();

    // Persist user status when leaving home view
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

    ChatEventManager().addEventListener(ChatEventType.userStartedTyping,
        (event) {
      if (mounted) {
        final chatId = event.data['chatId'] ?? event.data['chat_id'];
        final userId = event.data['userId'] ?? event.data['user_id'];

        // Only show typing for other users
        if (userId != Constants.userId && chatId != null) {
          setState(() {
            _typingChats.add(chatId);
            _typingTimestamps[chatId] = DateTime.now();
          });
        }
      }
    });

    ChatEventManager().addEventListener(ChatEventType.userStoppedTyping,
        (event) {
      if (mounted) {
        final chatId = event.data['chatId'] ?? event.data['chat_id'];
        final userId = event.data['userId'] ?? event.data['user_id'];

        if (userId != Constants.userId && chatId != null) {
          setState(() {
            _typingChats.remove(chatId);
            _typingTimestamps.remove(chatId);
          });
        }
      }
    });

    ChatEventManager().addEventListener(ChatEventType.messageSeenUpdate,
        (event) {
      if (mounted) {
        // Note: UserStatusProvider.notifyListeners has been deprecated
        // The new presence system handles notifications automatically

        // Update unread count when messages are seen
        _updateUnreadCount(event.data);
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
          'BusinessHome: Periodic status refresh disabled to prevent flickering');
    }

    // Only refresh chat list, not user statuses
    _refreshTimer = Timer.periodic(const Duration(seconds: 300), (_) {
      if (mounted && !_isRefreshing) {
        if (kDebugMode) {
          print(
              'BusinessHome: Periodic chat list refresh (status refresh disabled)');
        }
        // Only refresh chat list, not user statuses
        // _refreshChatList(); // Disabled to prevent flickering
      }
    });
  }

  void _startTypingCleanup() {
    _typingCleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _cleanupStaleTypingIndicators();
      }
    });
  }

  void _cleanupStaleTypingIndicators() {
    final now = DateTime.now();
    const staleThreshold = Duration(seconds: 30);

    setState(() {
      _typingChats.removeWhere((chatId) {
        final timestamp = _typingTimestamps[chatId];
        if (timestamp != null && now.difference(timestamp) > staleThreshold) {
          _typingTimestamps.remove(chatId);
          return true;
        }
        return false;
      });
    });
  }

  void _refreshChatList() {
    if (!_isRefreshing) {
      _isRefreshing = true;

      if (kDebugMode) {
        print('BusinessHome: Refreshing chat list (status refresh disabled)');
      }

      // Only refresh chat list, not user statuses
      context.read<ChatBusinessCubit>().getChats();

      // Reset refresh flag after a delay
      Future.delayed(const Duration(seconds: 2), () {
        _isRefreshing = false;
      });
    }
  }

  // Method to request status for all users in chat list with anti-flickering
  void _requestStatusForAllChatUsers(List<Chats> chats) {
    try {
      final presenceProvider =
          Provider.of<PresenceProvider>(context, listen: false);

      final allUserIds = <String>{};

      for (final chat in chats) {
        // Check if chat is deleted
        if (chat.isDeleted == true) {
          continue; // Skip deleted chats for status requests
        }

        // Add customer user ID for active chats
        final customerUserId = chat.chatUsers?.customerId;
        if (customerUserId != null && customerUserId != Constants.userId) {
          allUserIds.add(customerUserId);
        }

        // Add company user ID
        final companyUserId = chat.chatUsers?.companyId?.sId;
        if (companyUserId != null && companyUserId != Constants.userId) {
          allUserIds.add(companyUserId);
        }
      }

      // Request presence data for all users at once
      if (allUserIds.isNotEmpty) {
        presenceProvider.requestPresenceForUsers(allUserIds.toList());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting status for business chat users: $e');
      }
    }
  }

  void _updateUserStatus(bool isOnline) {
    try {
      // Note: UserStatusProvider.updateCurrentUserStatus has been deprecated
      // The new presence system handles current user status automatically via socket events
      if (kDebugMode) {
        print('BusinessHome: User status update requested: $isOnline');
        print('BusinessHome: Status updates now handled by presence system');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user status: $e');
      }
    }
  }

  void _updateUnreadCount(Map<String, dynamic> data) {
    final chatId = data['chatId'] ?? data['chat_id'];
    if (chatId != null) {
      // Update the chat list to reflect new unread count
      _refreshChatList();
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final chatId = data['chat_id'] ?? data['chatId'];
    if (chatId != null) {
      // Update chat list to show new message
      _refreshChatList();
    }
  }

  // Add method to get online status with fallback
  bool _getUserOnlineStatus(String chatId, String userId) {
    try {
      final presenceProvider =
          Provider.of<PresenceProvider>(context, listen: false);

      // Get presence data for the user
      final presence = presenceProvider.getUserPresence(userId);
      bool isOnline = presence?.isOnline ?? false;

      // If no presence data, request it
      if (presence == null) {
        if (kDebugMode) {
          print('User $userId not tracked, requesting presence data...');
        }
        presenceProvider.requestPresenceForUsers([userId]);
      }

      return isOnline;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting online status: $e');
      }
      return false;
    }
  }

  /// Initialize chat list manager service and load chats
  Future<void> _initializeAndLoadChats() async {
    try {
      // ✅ ADD: Initialize socket before loading chats
      try {
        final chatService = Provider.of<ChatService>(context, listen: false);
        await chatService.waitForSocketReady();
      } catch (e) {
        if (kDebugMode) {
          print('Socket initialization failed in business home: $e');
        }
      }

      // Initialize chat list manager service first
      await _initializeChatServices();

      // Now load chats from server
      if (mounted) {
        context.read<ChatBusinessCubit>().getChats();
      }
    } catch (e) {
      if (kDebugMode) {
        print('HomeViewBusiness: Error in initialization: $e');
      }
      // Even if initialization fails, still try to load chats
      if (mounted) {
        context.read<ChatBusinessCubit>().getChats();
      }
    }
  }

  /// Initialize chat services
  Future<void> _initializeChatServices() async {
    try {
      // Chat services are now handled directly by the cubit
      if (mounted) {
        context.read<ChatBusinessCubit>().getChats();
      }
    } catch (e) {
      if (kDebugMode) {
        print('HomeViewBusiness: Error in initialization: $e');
      }
      // Even if initialization fails, still try to load chats
      if (mounted) {
        context.read<ChatBusinessCubit>().getChats();
      }
    }
  }

  void _handleDeleteChat(Chats chat) {
    showDialog(
      context: context,
      builder: (dialogContext) => DeleteChatDialog(
        onDelete: () async {
          try {
            // Call the deleteChat function from the cubit
            // The cubit will handle the refresh internally
            await context.read<ChatBusinessCubit>().deleteChat(chat.id);

            // Refresh the chat list after successful deletion
            _refreshChatList();

            // Safely close the dialog
            try {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error closing delete dialog: $e');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error during business delete process: $e');
            }
            // Close dialog even if there's an error
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
            await context.read<ChatBusinessCubit>().closeChat(chat.id);

            // Refresh the chat list after successful closure
            _refreshChatList();

            // Safely close the dialog
            try {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error closing dialog: $e');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error during business close process: $e');
            }
            // Close dialog even if there's an error
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
    //     print('Socket initialization failed when opening business chat: $e');
    //   }
    // }

    // Optimistically set unread count to 0 in local state
    final cubit = context.read<ChatBusinessCubit>();
    final chatIndex = cubit.chat.indexWhere((c) => c.sId == chat.id);
    if (chatIndex != -1) {
      final updatedChat =
          cubit.chat[chatIndex].copyWith(chatNotSeenMessages: 0);
      cubit.chat[chatIndex] = updatedChat;
      cubit.emit(ChatBusinessSuccessState(List<Chats>.from(cubit.chat)));
    }
    // Mark messages as read if there are any unread messages
    if (chat.chatNotSeenMessages != null && chat.chatNotSeenMessages! > 0) {
      cubit.markMessagesAsRead(
        chat.id,
        [],
      );
      // // Optionally, refresh chat list after marking as read
      // Future.delayed(const Duration(milliseconds: 500), () {
      //   cubit.getChats();
      // });
    }
    final isCompany = Constants.role == 'company';
    final isSubaccount = Constants.role == 'subaccount';
    final isInfluencer = Constants.role == 'influencer';

    // Debug logging for subaccount role issue
    if (kDebugMode) {
      print('=== _handleChatTap Debug ===');
      print('Constants.role = "${Constants.role}"');
      print('isCompany = $isCompany');
      print('isSubaccount = $isSubaccount');
      print('isInfluencer = $isInfluencer');
    }

    // Track and request status for the customer user when opening the chat
    final customerUserId = chat.chatUsers?.customerId;
    if (customerUserId != null) {
      final presenceProvider =
          Provider.of<PresenceProvider>(context, listen: false);
      presenceProvider.requestPresenceForUsers([customerUserId]);
    }
    // Get real-time user status from PresenceProvider
    final presenceProvider =
        Provider.of<PresenceProvider>(context, listen: false);
    final realTimeIsOnline = customerUserId != null
        ? presenceProvider.isUserOnline(customerUserId)
        : false;
    // Calculate userRole for debug
    final calculatedUserRole = isCompany
        ? 'company'
        : isSubaccount
            ? 'subaccount'
            : isInfluencer
                ? 'influencer'
                : 'customer';

    // Debug logging for calculated userRole
    if (kDebugMode) {
      print('=== Calculated userRole ===');
      print('calculatedUserRole = "$calculatedUserRole"');
    }

    // Navigate to chat screen with proper arguments using push instead of pushNamed
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.id ?? '',
          userId: isCompany
              ? chat.chatUsers?.companyId?.sId ?? ''
              : chat.chatUsers?.subaccountId?.sId ?? '',
          userRole: calculatedUserRole,
          companyName: chat.chatCustomerCommercialName ?? '',
          isOnline: realTimeIsOnline,
          chat: chat,
        ),
      ),
    );
  }

  void _clearFilter() {
    setState(() {
      selectedFilter = null;
      appliedFilter = null;
    });
    // Clear the filter and load all chats
    context.read<ChatBusinessCubit>().clearFilter();
  }

  /// Apply the selected filter to the chat list
  void _applyFilter(String? filterValue) {
    if (filterValue == null) return;

    setState(() {
      appliedFilter = filterValue;
      isFilterShown = false;
    });

    // Map filter options to API parameters
    String? invoiceStatus;
    String? messageFilter;

    switch (filterValue) {
      case 'Paid Invoice':
        invoiceStatus = 'Paid';
        break;
      case 'Unpaid Invoice':
        invoiceStatus = 'Unpaid';
        break;
      case 'Expired Invoice':
        invoiceStatus = 'Expired';
        break;
      case 'Read Chat':
        messageFilter = 'read';
        break;
      case 'Unread Chat':
        messageFilter = 'unread';
        break;
    }

    if (kDebugMode) {
      print('Applying filter: $filterValue');
      print('- Invoice status: $invoiceStatus');
      print('- Message filter: $messageFilter');
    }

    // Apply the filter using the cubit
    context.read<ChatBusinessCubit>().filterChats(
          invoiceStatus: invoiceStatus,
          messageFilter: messageFilter,
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ReviewCompanyCubit()..getReviews()),
      ],
      child: Scaffold(
        backgroundColor: ColorManager.gray50,
        appBar: AppBar(
          backgroundColor: ColorManager.white,
          surfaceTintColor: Colors.transparent,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                ImageManager.drawerIcon,
                width: 30,
                height: 30,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          title: SearchTextField(
            onSearchChanged: (query) {
              if (query.isEmpty) {
                // If search is cleared, reload all chats
                context.read<ChatBusinessCubit>().getChats();
              } else {
                // Perform search
                context.read<ChatBusinessCubit>().searchChats(query);
              }
            },
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_alt,
                      color: isFilterShown
                          ? ColorManager.blueLight800
                          : Colors.grey,
                      size: 25.0,
                    ),
                    iconSize: 40.0,
                    splashRadius: 20.0,
                    onPressed: () {
                      setState(() {
                        isFilterShown = !isFilterShown;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: const AppDrawerBusiness(),
        body: SafeArea(
          child: Column(
            children: [
              if (isFilterShown)
                Container(
                  width: double.infinity,
                  height: 140.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 24.0,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0.0, 12.0),
                        spreadRadius: 4.0,
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        16.0, 8.0, 14.0, 10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Applying Filter:',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.black,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              height: 44.0,
                              decoration: BoxDecoration(
                                color: ColorManager.gray100,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: ColorManager.gray200,
                                  width: 0.0,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedFilter,
                                  hint: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 14.0),
                                    child: Text(
                                      'Select option',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.grey,
                                    size: 22.0,
                                  ),
                                  dropdownColor: ColorManager.gray200,
                                  menuMaxHeight: 300,
                                  menuWidth: 300,
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                          horizontal: 20),
                                  itemHeight: 48,
                                  items: filterOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: Text(
                                          value,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedFilter = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              _applyFilter(selectedFilter);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.blueLight800,
                              minimumSize: const Size(116.0, 32.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (appliedFilter != null && appliedFilter!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 8.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: ColorManager.blueLight800.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: ColorManager.blueLight800.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                color: ColorManager.blueLight800,
                                size: 16.0,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Filter: $appliedFilter',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: ColorManager.blueLight800,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      InkWell(
                        onTap: _clearFilter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: ColorManager.lightError.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: ColorManager.lightError.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: ColorManager.lightError,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: BlocConsumer<ChatBusinessCubit, ChatBusinessState>(
                  listener: (context, state) {
                    // Listen for state changes to ensure UI updates

                    // Handle error states
                    if (state is ChatBusinessErrorState) {
                      if (kDebugMode) {
                        print('Chat business error: ${state.error}');
                      }

                      // Check if this is a connection-related error
                      if (state.error.toLowerCase().contains('internet') ||
                          state.error.toLowerCase().contains('connection') ||
                          state.error.toLowerCase().contains('network') ||
                          state.error.toLowerCase().contains('host lookup') ||
                          state.error.toLowerCase().contains('socket')) {
                        // Show connection popup for connection errors
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _popupService.showConnectionError(
                                customMessage: state.error);
                          }
                        });
                      } else {}
                    }

                    // When user finds results after filtering, keep filter active
                    // User must manually clear the filter to see all chats
                    if (state is ChatBusinessSuccessState &&
                        appliedFilter != null &&
                        appliedFilter!.isNotEmpty &&
                        state.chats.isNotEmpty) {
                      if (kDebugMode) {
                        print(
                            'Filter applied and results found: ${state.chats.length} chats');
                        print(
                            'Filter remains active until user manually clears it');
                      }
                    }
                  },
                  buildWhen: (previous, current) {
                    // Always rebuild for success states
                    if (current is ChatBusinessSuccessState) {
                      return true;
                    }
                    if (current is ChatBusinessLoadingState) {
                      return true;
                    }
                    if (current is ChatBusinessErrorState) {
                      return true;
                    }
                    return false;
                  },
                  builder: (context, state) {
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
                    Icons.error_outline,
                    size: 60,
                    color: ColorManager.lightError.withOpacity(0.6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Chats',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: ColorManager.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

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
                context.read<ChatBusinessCubit>().getChats();
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
                    appliedFilter != null && appliedFilter!.isNotEmpty
                        ? Icons.filter_alt_outlined
                        : Icons.chat_bubble_outline,
                    size: 60,
                    color: ColorManager.blueLight800.withOpacity(0.6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            appliedFilter != null && appliedFilter!.isNotEmpty
                ? 'No chats found with the current filter'
                : 'No Chats Available',
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
              appliedFilter != null && appliedFilter!.isNotEmpty
                  ? 'Try changing your filter or clear it to see all chats'
                  : 'Start a conversation to see chats here',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (appliedFilter != null && appliedFilter!.isNotEmpty) ...[
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
                onPressed: _clearFilter,
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
                  'Clear Filter',
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
              child: ChatContainer(
                companyName: chat.chatCustomerCommercialName ?? '',
                lastMessage: _getLastMessageText(chat),
                lastMessageTime: _formatTime(
                    chat.chatLastMessage?.messageDate ?? chat.updatedAt),
                unreadCount: chat.chatNotSeenMessages ?? 0,
                isOnline: isOnline,
                isTyping: _typingChats.contains(chat.id),
                onTap: () => _handleChatTap(chat),
                onDelete: () => _handleDeleteChat(chat),
                onClose: () => _handleCloseChat(chat),
                chatId: chatId,
                userId: userId,
                userRole: Constants.role,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLastMessageText(Chats chat) {
    final lastMessage = chat.chatLastMessage?.messageText ?? 'No message';

    // Check if user is typing
    if (_typingChats.contains(chat.id)) {
      return 'Typing...';
    }

    return lastMessage;
  }

  Widget _buildStateContent(ChatBusinessState state) {
    if (state is ChatBusinessLoadingState) {
      return _buildShimmerLoading();
    }

    if (state is ChatBusinessErrorState) {
      return _buildErrorState(state.error);
    }

    // Get chats from the current state
    final chats = state is ChatBusinessSuccessState ? state.chats : [];

    if (kDebugMode) {
      print('=== Building Business Chat List ===');
      print('State type: ${state.runtimeType}');
      print('Chats count: ${chats.length}');
    }

    if (chats.isEmpty) {
      return _buildEmptyState();
    }

    // Prefetch user statuses for all users in the chat list
    _requestStatusForAllChatUsers(chats.cast<Chats>());

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Animated header
        // _buildAnimatedHeader(chats.length),
        // Show Clear Filter button when filter is applied and results are found
        const SizedBox(
          height: 30,
        ),
        if (appliedFilter != null &&
            appliedFilter!.isNotEmpty &&
            chats.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
            child: ElevatedButton(
              onPressed: _clearFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.blueLight800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.clear,
                    color: Colors.white,
                    size: 18.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'Clear Filter',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (kDebugMode) {
                print('Pull to refresh triggered');
              }
              context.read<ChatBusinessCubit>().getChats();
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
                    return Consumer<PresenceProvider>(
                      key: ValueKey('chat_${chat.sId}_status'),
                      builder: (context, presenceProvider, child) {
                        bool isOnline = false;
                        final customerUserId = chat.chatUsers?.customerId;
                        if (customerUserId != null && chat.sId != null) {
                          try {
                            // Get presence data for the customer user
                            final presence = presenceProvider
                                .getUserPresence(customerUserId);
                            isOnline = presence?.isOnline ?? false;

                            // If no presence data, request it
                            if (presence == null) {
                              presenceProvider
                                  .requestPresenceForUsers([customerUserId]);
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
                                    .getUserPresence(customerUserId ?? '') !=
                                null) {
                          print('=== Business Home Chat Item Status ===');
                          print('Chat ID: ${chat.sId}');
                          print('Customer User ID: $customerUserId');
                          print('Is Online: $isOnline');
                        }

                        return _buildAnimatedChatItem(
                          chat: chat,
                          index: index,
                          isOnline: isOnline,
                          chatId: chat.sId!,
                          userId: customerUserId ?? '',
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  // Method to persist user status when exiting home view
  void _persistUserStatusOnExit() {
    try {
      // Note: UserStatusProvider persistence methods have been deprecated
      // The new presence system handles persistence automatically
      if (kDebugMode) {
        print(
            'BusinessHome: User status persistence now handled by presence system');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error with user status persistence: $e');
      }
    }
  }

  // Method to restore user status when returning to home view
  void _restoreUserStatusOnReturn() {
    try {
      // Note: UserStatusProvider restoration methods have been deprecated
      // The new presence system handles restoration automatically
      if (kDebugMode) {
        print(
            'BusinessHome: User status restoration now handled by presence system');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error with user status restoration: $e');
      }
    }
  }
}
