import 'package:flutter/material.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:intl/intl.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart';
import 'package:spreadlee/presentation/business/chat/widget/location_view_widget.dart';
import 'package:spreadlee/config/maps_config.dart';

class LocationMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;

  const LocationMessageWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    required this.chatId,
    required this.currentUserId,
    this.onMessageVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.location == null) return const SizedBox.shrink();

    final double latitude = message.location!['latitude'] ?? 0.0;
    final double longitude = message.location!['longitude'] ?? 0.0;
    final String? address = message.location!['address'];

    final location = GeocodedLocation.latLng(latitude, longitude);

    // Get status values from message
    final isSeen = message.isSeen ?? false;
    final isReceived = message.isReceived ?? false;
    final isRead = message.isRead ?? false;
    final isDelivered = message.isDelivered ?? false;

    // Determine message status based on proper progression: sent → delivered → read
    String? messageStatus;
    if (isFromUser) {
      if (isRead || isSeen) {
        messageStatus = 'read'; // Blue double check - message has been read
      } else if (isReceived && isDelivered) {
        messageStatus =
            'delivered'; // Gray double check - message delivered but not read
      } else {
        messageStatus =
            'sent'; // Gray single check - message sent but not delivered
      }
    }

    return Column(
      crossAxisAlignment:
          isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFromUser ? ColorManager.gray200 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  children: [
                    StaticMap(
                      googleApiKey: MapsConfig.webApiKey,
                      width: 200,
                      height: 200,
                      markers: [
                        Marker(
                          locations: [location],
                        )
                      ],
                      center: location,
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationViewWidget(
                                  name: 'Location',
                                  latitude: latitude,
                                  longitude: longitude,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                _formatMessageTime(message.messageDate),
                style: getRegularStyle(
                  fontSize: 12,
                  color: isFromUser
                      ? ColorManager.black.withOpacity(0.7)
                      : ColorManager.black,
                ),
              ),
              if (isFromUser && messageStatus != 'pending' )
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    messageStatus == 'read' || messageStatus == 'delivered' || message.isDelivered == true || message.isRead == true
                        ? Icons.done_all // Double check for delivered/read
                        : Icons.check, // Single check for sent
                    size: 16,
                    color: messageStatus == 'read' || message.isSeen == true || message.isRead == true
                        ? ColorManager.black
                            .withOpacity(0.7)
                        : ColorManager.black
                            .withOpacity(0.7), // Gray for sent/delivered
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
