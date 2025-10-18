import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/presentation/widgets/photo_cache_widget.dart';
import 'package:spreadlee/presentation/widgets/image_viewer_widget.dart';
import 'dart:io';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../customer/chat/view/chat_screen.dart';

class PhotoMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final Function(String)? onPhotoTap;
  final Function(String)? onPhotoLongPress;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;

  const PhotoMessageWidget({
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
  State<PhotoMessageWidget> createState() => _PhotoMessageWidgetState();
}

class _PhotoMessageWidgetState extends State<PhotoMessageWidget> {
  // Map to store the correct image paths for each photo URL
  final Map<String, String> _imagePaths = {};

  @override
  Widget build(BuildContext context) {
    // Determine sender role - prioritize messageCreatorRole over messageCreator.role
    // This handles cases where messageCreator object might be incorrect but messageCreatorRole is correct
    final senderRole = widget.message.messageCreatorRole?.toLowerCase() ??
        (widget.message.messageCreator?.role.toLowerCase() ?? '');
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

    // If message is temporary (pending upload), show local photos if available
    if (widget.message.isTemp == true &&
        widget.message.messagePhotos != null &&
        widget.message.messagePhotos!.isNotEmpty &&
        widget.isFromUser) {
      // Show the local photo(s) directly
      return Column(
        crossAxisAlignment: widget.isFromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (senderRole.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1),
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
                              color: ColorManager.primary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (widget.message.messagePhotos!.length == 1)
                        _buildSinglePhoto(
                            context, widget.message.messagePhotos!.first)
                      else
                        _buildPhotoGrid(context),
                      const SizedBox(height: 4),
                    ],
                  ),
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
                  _formatMessageTime(
                      widget.message.messageDate ?? DateTime.now()),
                  style: getRegularStyle(
                    fontSize: 12,
                    color: ColorManager.black.withOpacity(0.7),
                  ),
                ),
                if (widget.isFromUser && widget.message.isTemp != true)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      _getMessageStatusIcon(widget.message, context),
                      size: 16,
                      color: _getMessageStatusColor(widget.message, context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // Don't render photo messages if no photos available
    if (widget.message.messagePhotos == null ||
        widget.message.messagePhotos!.isEmpty) {
      return const SizedBox.shrink();
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (senderRole.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
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
                            color: ColorManager.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (widget.message.messagePhotos!.length == 1)
                      _buildSinglePhoto(
                          context, widget.message.messagePhotos!.first)
                    else
                      _buildPhotoGrid(context),
                    const SizedBox(height: 4),
                  ],
                ),
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
                _formatMessageTime(
                    widget.message.messageDate ?? DateTime.now()),
                style: getRegularStyle(
                  fontSize: 12,
                  color: ColorManager.black.withOpacity(0.7),
                ),
              ),
              if (widget.isFromUser && widget.message.isTemp != true)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    _getMessageStatusIcon(widget.message, context),
                    size: 16,
                    color: _getMessageStatusColor(widget.message, context),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSinglePhoto(BuildContext context, String photoUrl) {
    // Calculate appropriate size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth =
        (screenWidth * 0.6).clamp(150.0, 300.0); // Between 150-300px

    // For sent images (file-like interface), use smaller height
    final maxHeight = widget.isFromUser ? 60.0 : 250.0;

    return PhotoCache(
      key:
          ValueKey('${photoUrl}_${widget.message.isTemp}_${widget.isFromUser}'),
      photoUrl: photoUrl,
      width: maxWidth,
      height: maxHeight,
      isFromUser: widget.isFromUser,
      onTap: () => _handlePhotoTap(context, photoUrl),
      onLongPress: () => _handlePhotoLongPress(context, photoUrl),
      onImagePathReady: (String imagePath) {
        // Store the correct image path
        setState(() {
          _imagePaths[photoUrl] = imagePath;
        });
      },
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    final photos = widget.message.messagePhotos!;
    final crossAxisCount = photos.length <= 2 ? 2 : 3;

    // Calculate appropriate size based on screen width and number of photos
    final screenWidth = MediaQuery.of(context).size.width;
    final maxGridWidth =
        (screenWidth * 0.6).clamp(200.0, 350.0); // Between 200-350px
    const spacing = 4.0;
    final totalSpacing = (crossAxisCount - 1) * spacing;
    final photoSize = (maxGridWidth - totalSpacing) / crossAxisCount;

    // For sent images (file-like interface), use smaller height
    final photoHeight = widget.isFromUser ? 60.0 : photoSize;

    // Adjust aspect ratio based on number of photos
    final aspectRatio = photos.length <= 2 ? 1.2 : 1.0;

    return SizedBox(
      width: maxGridWidth,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: widget.isFromUser
              ? 3.0
              : aspectRatio, // Wider aspect ratio for file-like interface
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photoUrl = photos[index];
          return PhotoCache(
            key: ValueKey(
                '${photoUrl}_${widget.message.isTemp}_${widget.isFromUser}_$index'),
            photoUrl: photoUrl,
            width: photoSize,
            height: photoHeight,
            isFromUser: widget.isFromUser,
            onTap: () => _handlePhotoTap(context, photoUrl),
            onLongPress: () => _handlePhotoLongPress(context, photoUrl),
            onImagePathReady: (String imagePath) {
              // Store the correct image path
              setState(() {
                _imagePaths[photoUrl] = imagePath;
              });
            },
          );
        },
      ),
    );
  }

  void _handlePhotoTap(BuildContext context, String photoUrl) async {
    // Get the ScaffoldMessenger reference before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    String imagePath = photoUrl;

    // If it's a local file, check if it exists
    if (!photoUrl.startsWith('http')) {
      final file = File(photoUrl);
      if (!await file.exists()) {
        // Try to use the remote URL if available
        final remoteUrl = widget.message.messagePhotos?.firstWhere(
          (url) => url.startsWith('http'),
          orElse: () => '',
        );
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          imagePath = remoteUrl;
        } else {
          // Show error or return
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Image file not found.')),
          );
          return;
        }
      }
    }

    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (context) => ImageViewerWidget(
          imageUrl: imagePath,
          title: 'Photo',
        ),
      ),
    );
  }

  void _handlePhotoLongPress(BuildContext context, String photoUrl) {
    if (widget.onPhotoLongPress != null) {
      widget.onPhotoLongPress!(photoUrl);
    } else {
      // For sent messages, use the server response URL, not the local path
      String imagePath;
      if (widget.isFromUser) {
        // Use the original photoUrl from the message (server response)
        imagePath = photoUrl;
      } else {
        // For received messages, use cached path if available
        imagePath = _imagePaths[photoUrl] ?? photoUrl;
      }

      // Default behavior: show options
      _showPhotoOptions(context, imagePath);
    }
  }

  void _showPhotoOptions(BuildContext context, String photoUrl) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.visibility,
                color: ColorManager.blueLight800,
              ),
              title: Text(
                'View',
                style: TextStyle(
                  color: ColorManager.blueLight800,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ImageViewerWidget(
                      imageUrl: photoUrl,
                      title: 'Photo',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.save,
                color: ColorManager.blueLight800,
              ),
              title: Text(
                'Save to Gallery',
                style: TextStyle(
                  color: ColorManager.blueLight800,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveToGallery(context, photoUrl);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: ColorManager.blueLight800,
              ),
              title: Text(
                'Share',
                style: TextStyle(
                  color: ColorManager.blueLight800,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sharePhoto(context, photoUrl);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery(BuildContext context, String photoUrl) async {
    // Get the ScaffoldMessenger reference before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Saving to gallery...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      String imagePath = photoUrl;

      // If it's a remote URL, download it first
      if (photoUrl.startsWith('http')) {
        final dio = Dio();
        final appDocDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_image.jpg';
        final tempPath = '${appDocDir.path}/$fileName';

        await dio.download(photoUrl, tempPath);
        imagePath = tempPath;
      }

      // Check if the file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveFile(imagePath);

      if (!mounted) return;
      if (result['isSuccess'] == true) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save image to gallery');
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error saving image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePhoto(BuildContext context, String photoUrl) async {
    // Get the ScaffoldMessenger reference before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Preparing to share...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      String imagePath = photoUrl;

      // If it's a remote URL, download it first
      if (photoUrl.startsWith('http')) {
        final dio = Dio();
        final appDocDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_image.jpg';
        final tempPath = '${appDocDir.path}/$fileName';

        await dio.download(photoUrl, tempPath);
        imagePath = tempPath;
      }

      // Check if the file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      // Share the image
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out this image!',
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error sharing image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  IconData _getMessageStatusIcon(ChatMessage message, BuildContext context) {
    // Try to get status from provider, but handle case where it's not available
    Map<String, dynamic>? currentStatus;
    try {
      final provider = ChatProviderInherited.of(context);
      currentStatus = provider.getMessageStatus(message.id);
    } catch (e) {
      // ChatProviderInherited not available in this context, use message status only
      currentStatus = null;
    }

    // Get status values from message object first, then fall back to provider status
    final isSeen = message.isSeen ?? currentStatus?['isSeen'] ?? false;
    final isReceived =
        message.isReceived ?? currentStatus?['isReceived'] ?? false;
    final isRead = message.isRead ?? currentStatus?['isRead'] ?? false;
    final isDelivered =
        message.isDelivered ?? currentStatus?['isDelivered'] ?? false;

    // Determine message status based on proper progression: sent → delivered → read
    if (isRead || isSeen) {
      return Icons.done_all; // Blue double check - message has been read
    } else if (isReceived && isDelivered) {
      return Icons
          .done_all; // Gray double check - message delivered but not read
    } else if (isReceived) {
      return Icons.check; // Gray single check - message sent to server
    } else {
      return Icons.check; // Single check for pending messages
    }
  }

  Color _getMessageStatusColor(ChatMessage message, BuildContext context) {
    // Try to get status from provider, but handle case where it's not available
    Map<String, dynamic>? currentStatus;
    try {
      final provider = ChatProviderInherited.of(context);
      currentStatus = provider.getMessageStatus(message.id);
    } catch (e) {
      // ChatProviderInherited not available in this context, use message status only
      currentStatus = null;
    }

    // Get status values from message object first, then fall back to provider status
    final isSeen = message.isSeen ?? currentStatus?['isSeen'] ?? false;
    final isRead = message.isRead ?? currentStatus?['isRead'] ?? false;

    // Determine color based on status
    if (isRead || isSeen) {
      return ColorManager.black.withOpacity(0.7);
    } else {
      return ColorManager.black
          .withOpacity(0.7); // Gray color for sent/delivered
    }
  }
}
