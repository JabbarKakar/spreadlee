import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/presence_provider.dart';

class UserStatusIndicator extends StatelessWidget {
  final String userId;
  final String userName;
  final double size;
  final bool showName;
  final bool showStatus;
  final bool showLastSeen;

  const UserStatusIndicator({
    Key? key,
    required this.userId,
    this.userName = '',
    this.size = 40,
    this.showName = false,
    this.showStatus = false,
    this.showLastSeen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, child) {
        final presence = presenceProvider.getUserPresence(userId);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(presence?.status),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getStatusIcon(presence?.status),
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
            ),
            if (showName || showStatus || showLastSeen) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showName && userName.isNotEmpty)
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  if (showStatus)
                    Text(
                      presence?.statusDisplay ?? 'Offline',
                      style: TextStyle(
                        color: _getStatusColor(presence?.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (showLastSeen && presence?.isOffline == true)
                    Text(
                      presence!.lastSeenText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'online':
        return Icons.circle;
      case 'away':
        return Icons.access_time;
      case 'offline':
        return Icons.circle_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

/// Compact version for chat lists
class CompactUserStatusIndicator extends StatelessWidget {
  final String userId;
  final double size;

  const CompactUserStatusIndicator({
    Key? key,
    required this.userId,
    this.size = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, child) {
        final presence = presenceProvider.getUserPresence(userId);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(presence?.status),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// Status text widget
class UserStatusText extends StatelessWidget {
  final String userId;
  final TextStyle? style;

  const UserStatusText({
    Key? key,
    required this.userId,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, child) {
        final presence = presenceProvider.getUserPresence(userId);
        final statusText = presence?.statusDisplay ?? 'Offline';
        final statusColor = _getStatusColor(presence?.status);

        return Text(
          statusText,
          style: style?.copyWith(color: statusColor) ??
              TextStyle(color: statusColor, fontSize: 12),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
