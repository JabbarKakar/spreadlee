import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/presentation/customer/chat/widget/messages/audio_message_widget.dart';
import 'package:spreadlee/presentation/customer/chat/widget/messages/document_message_widget.dart';
import 'package:spreadlee/presentation/customer/chat/widget/messages/location_message_widget.dart';
import 'package:spreadlee/presentation/customer/chat/widget/messages/message_invoice_widget.dart';
import 'package:spreadlee/presentation/customer/chat/widget/messages/photo_message_widget.dart';
import 'package:spreadlee/presentation/customer/chat/widget/messages/text_message_widget.dart';
import 'package:spreadlee/presentation/customer/chat/widget/messages/video_message_widget.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';

class MessageCustomerWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final VoidCallback? onVideoTap;
  final Function(String)? onPhotoTap;
  final Function(String)? onDocumentTap;
  final String? chatId;
  final String? currentUserId;
  final VoidCallback? onMessageVisible;
  final bool? isRecipientOnline; // Add recipient online status

  const MessageCustomerWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    this.onVideoTap,
    this.onPhotoTap,
    this.onDocumentTap,
    this.chatId,
    this.currentUserId,
    this.onMessageVisible,
    this.isRecipientOnline,
  }) : super(key: key);

  Widget _wrapWithFailedState(Widget child) {
    if (message.isFailed != true) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ColorManager.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              color: ColorManager.error,
              onPressed: () {
                // TODO: Implement retry functionality
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _hasInvoiceRef(dynamic invoiceRef) {
    if (invoiceRef == null) return false;
    if (invoiceRef is String) return invoiceRef.isNotEmpty;
    if (invoiceRef is Map) {
      // Common id fields used across backend/frontend
      const idKeys = ['_id', 'invoiceId', 'invoice_id'];
      for (final k in idKeys) {
        final v = invoiceRef[k];
        if (v != null && v.toString().isNotEmpty) return true;
      }

      // Check for other meaningful invoice fields that indicate a real invoice
      const meaningfulKeys = [
        'invoice_amount',
        'invoice_status',
        'status',
        'amount',
        'grandTotal',
        'payment_method'
      ];
      for (final k in meaningfulKeys) {
        final v = invoiceRef[k];
        if (v != null && v.toString().isNotEmpty) return true;
      }

      // Ignore maps that only contain empty placeholders like firstParty/secondParty
      final keys = invoiceRef.keys.map((e) => e.toString()).toSet();
      final placeholderOnly =
          keys.every((k) => k == 'firstParty' || k == 'secondParty');
      if (placeholderOnly) return false;

      // If any key has a non-empty value (or non-empty nested map), treat as invoice
      for (final k in keys) {
        final v = invoiceRef[k];
        if (v == null) continue;
        if (v is Map && v.isNotEmpty) return true;
        if (v is Iterable && v.isNotEmpty) return true;
        if (v.toString().isNotEmpty) return true;
      }

      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging for invoice detection

    Widget messageWidget;

    // Determine the message type and return the appropriate widget
    if (message.location != null && message.location!.isNotEmpty) {
      messageWidget = LocationMessageCustomerWidget(
        message: message,
        isFromUser: isFromUser,
        lastReadMessageDate: lastReadMessageDate,
        chatId: chatId!,
        currentUserId: currentUserId!,
        onMessageVisible: onMessageVisible,
      );
    } else if (message.messagePhotos != null &&
        message.messagePhotos!.isNotEmpty) {
      messageWidget = BusinessPhotoMessageCustomerWidget(
        message: message,
        isFromUser: isFromUser,
        lastReadMessageDate: lastReadMessageDate,
        onPhotoTap: onPhotoTap,
        chatId: chatId!,
        currentUserId: currentUserId!,
        onMessageVisible: onMessageVisible,
      );
    } else if (message.messageVideo != null &&
        message.messageVideo!.isNotEmpty) {
      messageWidget = VideoMessageCustomerWidget(
        message: message,
        isFromUser: isFromUser,
        lastReadMessageDate: lastReadMessageDate,
        onVideoTap: (String url) => onVideoTap?.call(),
        chatId: chatId!,
        currentUserId: currentUserId!,
        onMessageVisible: onMessageVisible,
      );
    } else if (message.messageAudio != null &&
        message.messageAudio!.isNotEmpty) {
      messageWidget = AudioMessageCustomerWidget(
        message: message,
        isFromUser: isFromUser,
        lastReadMessageDate: lastReadMessageDate,
        chatId: chatId!,
        currentUserId: currentUserId!,
        onMessageVisible: onMessageVisible,
      );
    } else if (message.messageDocument != null &&
        message.messageDocument!.isNotEmpty) {
      messageWidget = DocumentMessageCustomerWidget(
        message: message,
        isFromUser: isFromUser,
        lastReadMessageDate: lastReadMessageDate,
        onDocumentTap: onDocumentTap,
        chatId: chatId!,
        currentUserId: currentUserId!,
        onMessageVisible: onMessageVisible,
      );
    } else if ((_hasInvoiceRef(message.invoiceData)) ||
        (message.messageType == 'invoice' &&
            _hasInvoiceRef(message.invoiceData)) ||
        (message.messageText != null &&
            message.messageText!.isNotEmpty &&
            message.messageText!.contains('[INVOICE]') &&
            _hasInvoiceRef(message.invoiceData))) {
      messageWidget = MessageInvoiceCustomerWidget(
        message: message,
        isFromUser: isFromUser,
        lastReadMessageDate: lastReadMessageDate,
        onViewTap: (invoice) {
          final routeName = invoice.payment_method == 'Bank Transfer'
              ? Routes.invoiceDetailsBankTransfer
              : Routes.invoiceDetails;
          Navigator.pushNamed(context, routeName, arguments: invoice);
        },
        chatId: chatId!,
        currentUserId: currentUserId!,
        onMessageVisible: onMessageVisible,
      );
    } else if (message.messageText != null &&
        message.messageText!.isNotEmpty &&
        !message.messageText!.startsWith('[LOCATION]') &&
        !message.messageText!.startsWith('[VIDEO]') &&
        !message.messageText!.startsWith('[IMAGE]') &&
        !message.messageText!.startsWith('[Document]')) {
      // Skip text display for location and video messages
      messageWidget = TextMessageCustomerWidget(
        message: message,
        isFromUser: isFromUser,
        lastReadMessageDate: lastReadMessageDate,
        chatId: chatId!,
        currentUserId: currentUserId!,
        onMessageVisible: onMessageVisible,
        isRecipientOnline: isRecipientOnline,
      );
    } else {
      messageWidget = const SizedBox.shrink();
    }

    // Wrap the message widget with failed state if needed
    return _wrapWithFailedState(messageWidget);
  }
}
