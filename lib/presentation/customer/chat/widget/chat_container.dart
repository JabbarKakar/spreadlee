import 'package:flutter/material.dart';
import '../../../resources/color_manager.dart';
import 'package:spreadlee/presentation/customer/chat/widget/online_status_indicator.dart';

class ChatCustomerContainer extends StatelessWidget {
  final String companyName;
  final String commercialName;
  final String publicName;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final String chatId;
  final String userId;

  const ChatCustomerContainer({
    super.key,
    required this.companyName,
    required this.commercialName,
    required this.publicName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.isOnline = false,
    required this.onTap,
    required this.onDelete,
    required this.onClose,
    required this.chatId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: double.infinity,
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
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: ColorManager.primaryunderreview,
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  companyName.isEmpty && publicName.isEmpty
                                      ? 'Company'
                                      : (publicName.isNotEmpty
                                          ? publicName
                                          : companyName),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OnlineStatusIndicator(
                                  chatId: chatId, userId: userId),
                            ],
                          ),
                          Text(
                            'Commercial Name: ${commercialName.isEmpty ? 'Account Deleted' : commercialName}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8.0,
                                    color: ColorManager.gray500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                  vertical: 2.0,
                                ),
                                decoration: const BoxDecoration(
                                  color: ColorManager.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 10.0,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              lastMessageTime,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: ColorManager.gray500,
                                fontSize: 8.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: onClose,
                              child: Container(
                                width: 25.0,
                                height: 25.0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorManager.blueLight800,
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: ColorManager.blueLight800,
                                  size: 12.0,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            InkWell(
                              onTap: onDelete,
                              child: Container(
                                width: 25.0,
                                height: 25.0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorManager.error,
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: ColorManager.error,
                                  size: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
