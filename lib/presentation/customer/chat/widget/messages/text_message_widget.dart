import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:intl/intl.dart';
import 'package:spreadlee/services/message_status_handler.dart';
import '../../view/chat_screen.dart';

class TextMessageCustomerWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;
  final bool? isRecipientOnline; // Add recipient online status

  const TextMessageCustomerWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    required this.chatId,
    required this.currentUserId,
    this.onMessageVisible,
    this.isRecipientOnline,
  }) : super(key: key);

  @override
  State<TextMessageCustomerWidget> createState() =>
      _TextMessageCustomerWidgetState();
}

class _TextMessageCustomerWidgetState extends State<TextMessageCustomerWidget> {
  static final MessageStatusHandler _statusHandler = MessageStatusHandler();
  static bool _isInitialized = false;
  late final Function(String, String, Map<String, dynamic>)
      _statusUpdateCallback;
  late final Function(String, List<String>, Map<String, dynamic>)
      _bulkStatusUpdateCallback;

  @override
  void initState() {
    super.initState();
    _initializeStatusListener();
    _triggerMessageVisible();
  }

  void _initializeStatusListener() {
    if (kDebugMode) {
      print(
          'TextMessageCustomerWidget: Initializing status listener for message ${widget.message.id} in chat ${widget.chatId}');
    }
    // Initialize the handler only once for all instances
    if (!_isInitialized) {
      _statusHandler.initialize();
      _isInitialized = true;
      if (kDebugMode) {
        print('MessageStatusHandler initialized globally for customer');
      }
    }

    // Set up status update callbacks for this specific message
    _statusUpdateCallback = (chatId, messageId, status) {
      if (chatId == widget.chatId && messageId == widget.message.id) {
        if (kDebugMode) {
          print(
              'TextMessageCustomerWidget: Status update matches current message, updating UI');
        }
        setState(() {
          // Status is now managed at provider level, just trigger rebuild
        });
      }
    };

    _bulkStatusUpdateCallback = (chatId, messageIds, status) {
      if (chatId == widget.chatId && messageIds.contains(widget.message.id)) {
        if (kDebugMode) {
          print(
              'TextMessageCustomerWidget: Bulk status update matches current message, updating UI');
        }
        setState(() {
          // Status is now managed at provider level, just trigger rebuild
        });
      }
    };

    // Add callbacks to the shared handler
    _statusHandler.onStatusUpdate(_statusUpdateCallback);
    _statusHandler.onBulkStatusUpdate(_bulkStatusUpdateCallback);
  }

  void _triggerMessageVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMessageVisible?.call();
    });
  }

  @override
  void dispose() {
    // Remove this widget's callbacks from the shared handler
    _statusHandler.removeStatusUpdateListener(_statusUpdateCallback);
    _statusHandler.removeBulkStatusUpdateListener(_bulkStatusUpdateCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get status from provider instead of local _currentStatus
    Map<String, dynamic>? currentStatus;
    try {
      final provider = ChatProviderInherited.of(context);
      currentStatus = provider.getMessageStatus(widget.message.id);
    } catch (e) {
      // ChatProviderInherited not available in this context, use message status only
      if (kDebugMode) {
        print(
            'TextMessageCustomerWidget: ChatProviderInherited not available: $e');
      }
      currentStatus = null;
    }

    // Determine sender role - prioritize messageCreatorRole over messageCreator.role
    // This handles cases where messageCreator object might be incorrect but messageCreatorRole is correct
    final senderRole = widget.message.messageCreatorRole?.toLowerCase() ??
        (widget.message.messageCreator?.role?.toLowerCase() ?? '');
    Color bubbleColor;
    if (senderRole == 'customer') {
      bubbleColor = ColorManager.blueLight800;
    } else if (senderRole == 'company' || senderRole == 'influencer') {
      bubbleColor = ColorManager.gray500;
    } else if (senderRole == 'subaccount') {
      bubbleColor = ColorManager.primaryGreen;
    } else {
      bubbleColor = ColorManager.primaryGreen;
    }

    // Get status values from message object first, then fall back to provider status
    // This ensures UI reflects the most up-to-date message data from the cubit
    final isSeen = widget.message.isSeen ?? currentStatus?['isSeen'] ?? false;
    final isReceived =
        widget.message.isReceived ?? currentStatus?['isReceived'] ?? false;
    final isRead = widget.message.isRead ?? currentStatus?['isRead'] ?? false;
    final isDelivered =
        widget.message.isDelivered ?? currentStatus?['isDelivered'] ?? false;

    // For sender's own messages, show proper status progression
    // For received messages, don't show status icons
    final shouldShowStatus =
        widget.isFromUser && widget.message.isFailed != true;

    // Determine message status based on proper progression: sent → delivered → read
    // Consider recipient's online status for accurate delivery status
    String? messageStatus;
    if (shouldShowStatus) {
      if (isRead || isSeen) {
        messageStatus = 'read'; // Blue double check - message has been read
      } else if (isReceived && isDelivered) {
        messageStatus =
            'delivered'; // Gray double check - message delivered but not read
      } else if (isReceived) {
        messageStatus =
            'sent'; // Gray single check - message sent to server (regardless of recipient online status)
      } else {
        messageStatus =
            'pending'; // No check - message pending (not yet received by server)
      }
    }

    return Column(
      crossAxisAlignment:
          widget.isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: widget.isFromUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.message.isFailed == true
                      ? Border.all(color: ColorManager.error)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (senderRole.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          senderRole == 'customer'
                              ? 'Customer'
                              : (senderRole == 'company' ||
                                      senderRole == 'influencer')
                                  ? 'Manager'
                                  : senderRole == 'subaccount'
                                      ? 'Employee'
                                      : 'Employee',
                          style: getRegularStyle(
                            fontSize: 12,
                            color: widget.message.isFailed == true
                                ? ColorManager.error
                                : ColorManager.primary,
                          ),
                        ),
                      ),
                    Text(
                      widget.message.messageText ?? '',
                      style: getRegularStyle(
                        fontSize: 14,
                        color: widget.message.isFailed == true
                            ? ColorManager.error
                            : ColorManager.white,
                      ),
                    ),
                    if (widget.message.isFailed == true &&
                        widget.message.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Failed to send: ${widget.message.errorMessage}',
                          style: getRegularStyle(
                            fontSize: 12,
                            color: ColorManager.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.message.isFailed == true)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  color: ColorManager.error,
                  onPressed: () {
                    // TODO: Implement retry functionality
                  },
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.isFromUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Text(
                _formatMessageTime(widget.message.messageDate),
                style: getRegularStyle(
                  fontSize: 12,
                  color: widget.message.isFailed == true
                      ? ColorManager.error
                      : ColorManager.black.withOpacity(0.7),
                ),
              ),
              if (shouldShowStatus && messageStatus != 'pending' ||
                  widget.message.isTemp == true)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    messageStatus == 'read' ||
                            messageStatus == 'delivered' ||
                            widget.message.isDelivered == true ||
                            widget.message.isRead == true
                        ? Icons.done_all // Double check for delivered/read
                        : Icons.check, // Single check for sent
                    size: 16,
                    color: messageStatus == 'read' ||
                            widget.message.isSeen == true ||
                            widget.message.isRead == true
                        ? ColorManager.black
                            .withOpacity(0.7)
                        : ColorManager.black
                            .withOpacity(0.7), // Gray for sent/delivered
                  ),
                )
            ],
          ),
        ),
      ],
    );
  }
}

String _formatMessageTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) {
    return 'moments ago';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes} minutes ago';
  } else if (diff.inHours < 24 &&
      now.day == dateTime.day &&
      now.month == dateTime.month &&
      now.year == dateTime.year) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}
