import 'package:flutter/material.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/presentation/widgets/photo_message_widget.dart';

class BusinessPhotoMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final Function(String)? onPhotoTap;
  final Function(String)? onPhotoLongPress;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;

  const BusinessPhotoMessageWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    this.onPhotoTap,
    this.onPhotoLongPress,
    required this.chatId,
    required this.currentUserId,
    this.onMessageVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PhotoMessageWidget(
      message: message,
      isFromUser: isFromUser,
      lastReadMessageDate: lastReadMessageDate,
      onPhotoTap: onPhotoTap,
      onPhotoLongPress: onPhotoLongPress,
      chatId: chatId,
      currentUserId: currentUserId,
      onMessageVisible: onMessageVisible,
    );
  }
}
