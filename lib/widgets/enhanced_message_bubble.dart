import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/services/enhanced_message_status_handler.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:intl/intl.dart';

/// Enhanced message bubble widget with proper status indicators
class EnhancedMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isFromUser;
  final String currentUserId;
  final String chatId;
  final VoidCallback? onMessageVisible;
  final VoidCallback? onStatusTap;

  const EnhancedMessageBubble({
    Key? key,
    required this.message,
    required this.isFromUser,
    required this.currentUserId,
    required this.chatId,
    this.onMessageVisible,
    this.onStatusTap,
  }) : super(key: key);

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble> {
  late MessageStatus? _messageStatus;
  late StreamSubscription<MessageStatusUpdate> _statusSubscription;
  final EnhancedMessageStatusHandler _statusHandler =
      EnhancedMessageStatusHandler();

  @override
  void initState() {
    super.initState();
    _initializeMessageStatus();
    _setupStatusListener();

    // Trigger onMessageVisible callback when message becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMessageVisible?.call();
    });
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    super.dispose();
  }

  /// Initialize message status from cache
  void _initializeMessageStatus() {
    _messageStatus = _statusHandler.getMessageStatus(
      widget.chatId,
      widget.message.id,
    );
  }

  /// Set up listener for status updates
  void _setupStatusListener() {
    _statusSubscription = _statusHandler.statusUpdateStream.listen((update) {
      if (update.messageId == widget.message.id &&
          update.chatId == widget.chatId) {
        setState(() {
          _messageStatus = update.status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: widget.isFromUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isFromUser) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: _buildMessageContent(),
              ),
              if (widget.isFromUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Build message avatar
  Widget _buildAvatar() {
    final role = widget.message.messageCreator?.role ??
        widget.message.messageCreatorRole ??
        '';

    Color avatarColor;
    switch (role.toLowerCase()) {
      case 'customer':
        avatarColor = ColorManager.blueLight800;
        break;
      case 'company':
      case 'influencer':
        avatarColor = ColorManager.gray500;
        break;
      default:
        avatarColor = ColorManager.primaryGreen;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: avatarColor,
      child: Text(
        _getInitials(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get initials for avatar
  String _getInitials() {
    final username = widget.message.messageCreator?.username ??
        widget.message.messageCreatorRole ??
        '';
    if (username.isEmpty) return '?';

    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username[0].toUpperCase();
  }

  /// Build message content
  Widget _buildMessageContent() {
    final role = widget.message.messageCreator?.role ??
        widget.message.messageCreatorRole ??
        '';

    Color bubbleColor;
    switch (role.toLowerCase()) {
      case 'customer':
        bubbleColor = ColorManager.blueLight800;
        break;
      case 'company':
      case 'influencer':
        bubbleColor = ColorManager.gray500;
        break;
      default:
        bubbleColor = ColorManager.primaryGreen;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isFromUser ? bubbleColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageText(),
          const SizedBox(height: 4),
          _buildMessageFooter(),
        ],
      ),
    );
  }

  /// Build message text content
  Widget _buildMessageText() {
    if (widget.message.messageText?.isNotEmpty == true) {
      return Text(
        widget.message.messageText!,
        style: TextStyle(
          color: widget.isFromUser ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      );
    }

    // Handle other message types (photos, videos, documents, etc.)
    if (widget.message.messagePhotos?.isNotEmpty == true) {
      return _buildMediaIndicator('📷 Photo');
    }

    if (widget.message.messageVideo?.isNotEmpty == true) {
      return _buildMediaIndicator('🎥 Video');
    }

    if (widget.message.messageDocument?.isNotEmpty == true) {
      return _buildMediaIndicator('📄 Document');
    }

    if (widget.message.messageAudio?.isNotEmpty == true) {
      return _buildMediaIndicator('🎵 Audio');
    }

    if (widget.message.location != null) {
      return _buildMediaIndicator('📍 Location');
    }

    return const Text(
      'Unsupported message type',
      style: TextStyle(
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Build media indicator
  Widget _buildMediaIndicator(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (widget.message.messagePhotos?.length == 1) ...[
          const SizedBox(width: 4),
          Text('(${widget.message.messagePhotos!.length})'),
        ],
      ],
    );
  }

  /// Build message footer with time and status
  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(widget.message.messageDate),
          style: TextStyle(
            fontSize: 12,
            color: widget.isFromUser ? Colors.white70 : Colors.grey[600],
          ),
        ),
        if (widget.isFromUser) ...[
          const SizedBox(width: 8),
          _buildStatusIndicator(),
        ],
      ],
    );
  }

  /// Build status indicator for sent messages
  Widget _buildStatusIndicator() {
    if (widget.message.isFailed == true) {
      return GestureDetector(
        onTap: widget.onStatusTap,
        child: const Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red,
        ),
      );
    }

    // Use enhanced status handler if available
    if (_messageStatus != null) {
      return _buildEnhancedStatusIndicator();
    }

    // Fallback to message properties
    return _buildFallbackStatusIndicator();
  }

  /// Build enhanced status indicator using status handler
  Widget _buildEnhancedStatusIndicator() {
    final status = _messageStatus!;

    if (status.isSeen) {
      return GestureDetector(
        onTap: widget.onStatusTap,
        child: const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.blue,
        ),
      );
    }

    if (status.isRead) {
      return GestureDetector(
        onTap: widget.onStatusTap,
        child: const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.grey,
        ),
      );
    }

    if (status.isReceived) {
      return GestureDetector(
        onTap: widget.onStatusTap,
        child: const Icon(
          Icons.done,
          size: 16,
          color: Colors.grey,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onStatusTap,
      child: const Icon(
        Icons.check,
        size: 16,
        color: Colors.grey,
      ),
    );
  }

  /// Build fallback status indicator using message properties
  Widget _buildFallbackStatusIndicator() {
    final isSeen = widget.message.isSeen ?? false;
    final isReceived = widget.message.isReceived ?? false;
    final isRead = widget.message.isRead ?? false;

    if (isSeen) {
      return GestureDetector(
        onTap: widget.onStatusTap,
        child: const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.blue,
        ),
      );
    }

    if (isRead) {
      return GestureDetector(
        onTap: widget.onStatusTap,
        child: const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.grey,
        ),
      );
    }

    if (isReceived) {
      return GestureDetector(
        onTap: widget.onStatusTap,
        child: const Icon(
          Icons.done,
          size: 16,
          color: Colors.grey,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onStatusTap,
      child: const Icon(
        Icons.check,
        size: 16,
        color: Colors.grey,
      ),
    );
  }

  /// Format message time
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }

  /// Get current message status for debugging
  String _getStatusDebugInfo() {
    if (_messageStatus != null) {
      return 'Enhanced: Seen=${_messageStatus!.isSeen}, Received=${_messageStatus!.isReceived}, Read=${_messageStatus!.isRead}';
    }

    return 'Fallback: Seen=${widget.message.isSeen}, Received=${widget.message.isReceived}, Read=${widget.message.isRead}';
  }
}
