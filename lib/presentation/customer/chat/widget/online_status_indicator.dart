import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:spreadlee/providers/presence_provider.dart';

class OnlineStatusIndicator extends StatefulWidget {
  final String chatId;
  final String userId;
  const OnlineStatusIndicator(
      {Key? key, required this.chatId, required this.userId})
      : super(key: key);

  @override
  State<OnlineStatusIndicator> createState() => _OnlineStatusIndicatorState();
}

class _OnlineStatusIndicatorState extends State<OnlineStatusIndicator> {
  bool _hasRequestedPresence = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, child) {
        // Get presence data for the user
        final presence = presenceProvider.getUserPresence(widget.userId);
        bool isOnline = presence?.isOnline ?? false;

        // Request presence data only once per widget instance
        if (presence == null &&
            widget.userId.isNotEmpty &&
            !_hasRequestedPresence) {
          _hasRequestedPresence = true;
          presenceProvider.requestPresenceForUsers([widget.userId]);
        }

        // Only log in debug mode and reduce frequency
        if (kDebugMode && presence != null) {
          // print('=== OnlineStatusIndicator Debug ===');
          // print('Chat ID: ${widget.chatId}');
          // print('User ID: ${widget.userId}');
          // print('Is Online: $isOnline');
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}
