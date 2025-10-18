import 'package:flutter/material.dart';
import '../resources/color_manager.dart';

/// Clean and efficient chat container widget
class ChatContainerWidget extends StatelessWidget {
  final String companyName;
  final String commercialName;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final String chatId;
  final String userId;

  const ChatContainerWidget({
    super.key,
    required this.companyName,
    required this.commercialName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    required this.isTyping,
    required this.onTap,
    required this.onDelete,
    required this.onClose,
    required this.chatId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 8),
                      _buildLastMessage(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildRightSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build avatar with online indicator
  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ColorManager.blueLight800.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              _getInitials(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorManager.blueLight800,
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: ColorManager.success,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// Build header with company name and actions
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName.isNotEmpty ? companyName : 'Unknown Company',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (commercialName.isNotEmpty)
                Text(
                  commercialName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onClose,
          icon: Icon(
            Icons.close,
            size: 20,
            color: Colors.grey[600],
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 20,
            color: ColorManager.lightError,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }

  /// Build last message section
  Widget _buildLastMessage() {
    return Row(
      children: [
        Expanded(
          child: Text(
            isTyping ? 'Typing...' : lastMessage,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isTyping
                  ? ColorManager.blueLight800
                  : (unreadCount > 0 ? ColorManager.black : Colors.grey[600]),
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isTyping)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(left: 8),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(ColorManager.blueLight800),
            ),
          ),
      ],
    );
  }

  /// Build right section with time and unread count
  Widget _buildRightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          lastMessageTime,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        if (unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorManager.blueLight800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// Get initials from company name
  String _getInitials() {
    if (companyName.isEmpty) return '?';

    final words = companyName.trim().split(' ');
    if (words.length == 1) {
      return companyName.substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }
}
