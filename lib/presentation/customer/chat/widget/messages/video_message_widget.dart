import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'package:spreadlee/core/di.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/domain/services/media_cache_service.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../../view/chat_screen.dart';

class VideoMessageCustomerWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final Function(String)? onVideoTap;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;

  const VideoMessageCustomerWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    this.onVideoTap,
    required this.chatId,
    required this.currentUserId,
    this.onMessageVisible,
  }) : super(key: key);

  @override
  State<VideoMessageCustomerWidget> createState() =>
      _VideoMessageCustomerWidgetState();
}

class _VideoMessageCustomerWidgetState
    extends State<VideoMessageCustomerWidget> {
  late final MediaCacheService _mediaCacheService;
  String? _videoFilePath;
  final double _progress = 0.0;
  String? _videoSize;
  final _dio = Dio();
  bool _isInitialized = false;
  bool _isFetchingSize = false;
  Timer? _tempMessageCheckTimer;

  @override
  void initState() {
    super.initState();

    _mediaCacheService = instance<MediaCacheService>();

    // For temporary messages with local video files, show immediately
    if (widget.message.isTemp == true && _hasLocalVideoFile()) {
      print('🔵 Temporary message with local video file - showing immediately');
      _tryGetLocalFileSize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
      return;
    }

    // Always try to initialize if we have a video URL, regardless of temp status
    if (widget.message.messageVideo != null) {
      _initializeVideo();
    } else {
      // For temporary messages, set initialized to true to show the UI
      if (widget.message.isTemp == true) {
        setState(() {
          _isInitialized = true;
        });
        // Start periodic check for temporary messages
        _startTempMessageCheck();
      }
    }

    // If we have a local video file, try to get its size immediately
    if (_hasLocalVideoFile()) {
      _tryGetLocalFileSize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }

    // Add fallback timer for temporary messages
    if (widget.message.isTemp == true) {
      _tempMessageCheckTimer =
          Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted &&
            widget.message.messageVideo != null &&
            widget.message.messageVideo!.isNotEmpty &&
            widget.message.messageVideo!.startsWith('http')) {
          print('🔵 Video URL updated to server URL, reinitializing...');
          _initializeVideo();
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _tempMessageCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoMessageCustomerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if video URL has changed (e.g., from local path to server URL)
    if (oldWidget.message.messageVideo != widget.message.messageVideo) {
      print(
          '🔵 Video URL changed from ${oldWidget.message.messageVideo} to ${widget.message.messageVideo}');

      // If we now have a server URL, reinitialize
      if (widget.message.messageVideo != null &&
          widget.message.messageVideo!.isNotEmpty &&
          widget.message.messageVideo!.startsWith('http')) {
        print('🔵 Reinitializing video with new server URL...');
        _initializeVideo();
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.message.messageVideo == null) {
      print('❌ No video URL available for initialization');
      // For temporary messages, still mark as initialized to show the UI
      if (widget.message.isTemp == true) {
        setState(() {
          _isInitialized = true;
        });
      }
      return;
    }

    if (_isFetchingSize) {
      print('⏳ Already fetching video size, skipping...');
      return;
    }

    try {
      _isFetchingSize = true;
      await _fetchVideoSize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isFetchingSize = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true; // Set to true even on error to stop loading
          _isFetchingSize = false;
          // For temporary messages, try to get size from local file if available
          if (widget.message.isTemp == true &&
              widget.message.messageVideo != null) {
            _tryGetLocalFileSize();
          } else {
            _videoSize =
                'Unknown size'; // Default size if we can't get the actual size
          }
        });
      }
    }
  }

  // Enhanced error handling for temporary messages
  void _setDefaultSizeForTempMessage() {
    if (widget.message.isTemp == true && mounted) {
      setState(() {
        _videoSize = '2.3 MB';
        _isInitialized = true; // Ensure temp messages are always initialized
      });
    }
  }

  // Helper method to try getting size from local file for temporary messages
  Future<void> _tryGetLocalFileSize() async {
    if (widget.message.messageVideo == null) return;

    try {
      final file = File(widget.message.messageVideo!);
      if (await file.exists()) {
        final fileSize = await file.length();
        final sizeInMB = fileSize / (1024 * 1024);
        if (mounted) {
          print('📏 Local file size: ${sizeInMB.toStringAsFixed(1)} MB');
          setState(() {
            _videoSize = '${sizeInMB.toStringAsFixed(1)} MB';
          });
        }
      } else {
        print('⚠️ Local file does not exist, using default size');
        if (mounted) {
          setState(() {
            _videoSize = '2.3 MB';
          });
        }
      }
    } catch (e) {
      print('❌ Error getting local file size: $e');
      if (mounted) {
        setState(() {
          _videoSize = '2.3 MB';
        });
      }
    }
  }

  // Method to handle when temporary message becomes permanent
  void _handleTempToPermanentTransition() {
    if (widget.message.isTemp != true && widget.message.messageVideo != null) {
      print(
          '🔄 Message transitioned from temp to permanent, reinitializing...');
      setState(() {
        _isInitialized = false;
        _videoSize = null;
      });
      _initializeVideo();
    }
  }

  // Force initialization for temporary messages that might be stuck
  void _forceInitializeTempMessage() {
    if (widget.message.isTemp == true &&
        widget.message.messageVideo != null &&
        !_isInitialized) {
      print('🔧 Force initializing temporary message...');

      // If it's a local file, get size immediately
      if (_hasLocalVideoFile()) {
        _tryGetLocalFileSize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            print(
                '🔧 Temporary message with local file force initialized successfully');
          }
        }).catchError((e) {
          print('🔧 Error in force initialization, setting default size: $e');
          if (mounted) {
            _setDefaultSizeForTempMessage();
          }
        });
      } else {
        // For other temporary messages, just set default
        if (mounted) {
          _setDefaultSizeForTempMessage();
        }
      }
    }
  }

  // Start periodic check for temporary messages
  void _startTempMessageCheck() {
    if (widget.message.isTemp == true) {
      _tempMessageCheckTimer =
          Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && widget.message.messageVideo != null) {
          print(
              '⏰ Video URL became available for temp message, initializing...');
          timer.cancel();
          _initializeVideo();
        } else if (!mounted || widget.message.isTemp != true) {
          print(
              '⏰ Stopping temp message check (message no longer temp or widget disposed)');
          timer.cancel();
        } else {
          print('⏰ Still waiting for video URL...');
        }
      });
    }
  }

  // Check if we have a local video file that we can get size from immediately
  bool _hasLocalVideoFile() {
    return widget.message.messageVideo != null &&
        !widget.message.messageVideo!.startsWith('http') &&
        widget.message.isTemp == true &&
        widget.message.messageVideo!.isNotEmpty;
  }

  Future<void> _fetchVideoSize() async {
    if (widget.message.messageVideo == null) return;

    print('📏 Fetching video size...');
    print('📏 - URL: ${widget.message.messageVideo}');

    // Check if this is a local file or remote URL
    final isLocalFile = !widget.message.messageVideo!.startsWith('http');

    if (isLocalFile) {
      print('📏 Local file detected, getting file size directly...');
      try {
        final file = File(widget.message.messageVideo!);
        if (await file.exists()) {
          final fileSize = await file.length();
          final sizeInMB = fileSize / (1024 * 1024);
          if (mounted) {
            print('📏 Local file size: ${sizeInMB.toStringAsFixed(1)} MB');
            setState(() {
              _videoSize = '${sizeInMB.toStringAsFixed(1)} MB';
            });
          }
        } else {
          print('⚠️ Local file does not exist, using default size');
          if (mounted) {
            setState(() {
              _videoSize = '2.3 MB';
            });
          }
        }
      } catch (e) {
        print('❌ Error getting local file size: $e');
        if (mounted) {
          setState(() {
            _videoSize = '2.3 MB';
          });
        }
      }
      return;
    }

    // Handle remote URL
    try {
      final response = await _dio.head(
        widget.message.messageVideo!,
        options: Options(
          validateStatus: (status) => status! < 500,
          headers: {
            'Accept': '*/*',
            'Connection': 'keep-alive',
          },
        ),
      );

      print('📏 Response status: ${response.statusCode}');
      print('📏 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final contentLength = response.headers.value('content-length');
        if (contentLength != null) {
          final sizeInBytes = int.parse(contentLength);
          final sizeInMB = sizeInBytes / (1024 * 1024);
          if (mounted) {
            print('📏 Video size fetched: ${sizeInMB.toStringAsFixed(1)} MB');
            setState(() {
              _videoSize = '${sizeInMB.toStringAsFixed(1)} MB';
            });
          }
        } else {
          print('⚠️ No content-length header found, using default size');
          if (mounted) {
            setState(() {
              _videoSize =
                  '2.3 MB'; // Default size if we can't get the actual size
            });
          }
        }
      } else {
        print(
            '⚠️ Non-200 response: ${response.statusCode}, using default size');
        if (mounted) {
          setState(() {
            _videoSize = '2.3 MB'; // Default size on error
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching video size: $e');
      if (mounted) {
        setState(() {
          _videoSize = '2.3 MB'; // Default size on error
        });
      }
      rethrow;
    }
  }

  String get videoFileName {
    try {
      final uri = Uri.parse(widget.message.messageVideo ?? '');
      final fileName = uri.pathSegments.last;
      print('📝 Getting video filename: $fileName');

      if (fileName.endsWith('.mp4')) {
        final nameWithoutExtension = fileName.substring(0, fileName.length - 4);
        if (nameWithoutExtension.length > 8) {
          final truncatedName =
              '...${nameWithoutExtension.substring(nameWithoutExtension.length - 8)}.mp4';
          print('📝 Truncated filename: $truncatedName');
          return truncatedName;
        }
      }
      print('📝 Using original filename: $fileName');
      return fileName;
    } catch (e) {
      print('❌ Error getting video filename: $e');
      return 'Video';
    }
  }

  Future<void> _showVideoOptions() async {
    print('🔍 Showing video options menu');
    print('🔍 - Video URL: ${widget.message.messageVideo}');
    print('🔍 - Video Size: $_videoSize');

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.save_alt,
                color: ColorManager.blueLight800,
              ),
              title: Text(
                'Save Video',
                style: TextStyle(
                  color: ColorManager.blueLight800,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _saveVideo();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: ColorManager.blueLight800,
              ),
              title: Text(
                'Share Video',
                style: TextStyle(
                  color: ColorManager.blueLight800,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _shareVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVideo() async {
    if (widget.message.messageVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video available to save'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
              Text('Saving video to gallery...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      String videoPath = widget.message.messageVideo!;

      // If it's a remote URL, download it first
      if (videoPath.startsWith('http')) {
        final dio = Dio();
        final appDocDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_video.mp4';
        final tempPath = '${appDocDir.path}/$fileName';

        await dio.download(videoPath, tempPath);
        videoPath = tempPath;
      }

      // Check if the file exists
      final file = File(videoPath);
      if (!await file.exists()) {
        throw Exception('Video file not found');
      }

      // Save to gallery
      final result = await ImageGallerySaver.saveFile(videoPath);

      if (!mounted) return;
      if (result['isSuccess'] == true) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Video saved to gallery successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save video to gallery');
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error saving video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareVideo() async {
    if (widget.message.messageVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video available to share'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

      String videoPath = widget.message.messageVideo!;

      // If it's a remote URL, download it first
      if (videoPath.startsWith('http')) {
        final dio = Dio();
        final appDocDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_video.mp4';
        final tempPath = '${appDocDir.path}/$fileName';

        await dio.download(videoPath, tempPath);
        videoPath = tempPath;
      }

      // Check if the file exists
      final file = File(videoPath);
      if (!await file.exists()) {
        throw Exception('Video file not found');
      }

      // Share the video
      await Share.shareXFiles(
        [XFile(videoPath)],
        text: 'Check out this video!',
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error sharing video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 VideoMessageWidget Build');
    print('🎨 - Message ID: ${widget.message.id}');
    print('🎨 - messageVideo: ${widget.message.messageVideo}');
    print('🎨 - isInitialized: $_isInitialized');
    print('🎨 - videoSize: $_videoSize');
    print('🎨 - isFetchingSize: $_isFetchingSize');
    print('🎨 - isFromUser: ${widget.isFromUser}');

    // Get status from provider instead of directly from message
    Map<String, dynamic>? currentStatus;
    try {
      final provider = ChatProviderInherited.of(context);
      currentStatus = provider.getMessageStatus(widget.message.id);
    } catch (e) {
      // ChatProviderInherited not available in this context, use message status only
      if (kDebugMode) {
        print(
            'VideoMessageCustomerWidget: ChatProviderInherited not available: $e');
      }
      currentStatus = null;
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
    final shouldShowStatus = widget.isFromUser && widget.message.isTemp != true;

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

    // If message is temporary (pending upload), show local video if available
    if (widget.message.isTemp == true &&
        widget.message.messageVideo != null &&
        widget.isFromUser &&
        !widget.message.messageVideo!.startsWith('http')) {
      // Force initialization if needed
      if (!_isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _forceInitializeTempMessage();
        });
      }

      // Show the local video file with same UI as final message
      print(
          '🔵 Showing temporary video message with local file: ${widget.message.messageVideo}');
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
                child: GestureDetector(
                  onLongPress: _isInitialized ? _showVideoOptions : null,
                  onTap: () {
                    if (_isInitialized && widget.message.messageVideo != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.transparent,
                              leading: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            body: Center(
                              child: LocalChewieVideoPlayer(
                                file: File(widget.message.messageVideo!),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 200,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: ColorManager.gray200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.video_collection_outlined,
                                    color: ColorManager.blueLight800,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      videoFileName,
                                      style: getRegularStyle(
                                        fontSize: 10,
                                        color: ColorManager.blueLight800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Show video size if available
                        if (_videoSize != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Text(
                              _videoSize!,
                              style: getRegularStyle(
                                fontSize: 10,
                                color: ColorManager.blueLight800,
                              ),
                            ),
                          ),
                        // Show loading indicator if still initializing
                        if (_videoSize == null && !_isInitialized)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorManager.blueLight800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
                  _formatMessageTime(widget.message.messageDate),
                  style: getRegularStyle(
                    fontSize: 12,
                    color: widget.isFromUser
                        ? ColorManager.black.withOpacity(0.7)
                        : ColorManager.black,
                  ),
                ),
                if (shouldShowStatus && messageStatus != 'pending')
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
                          ? Colors.blue // Blue color for read
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

    final showLoading = !_isInitialized || _isFetchingSize;

    if (showLoading) {
      print('⏳ Showing loading state...');
    } else {
      print(
          '✅ Showing video info: $videoFileName (${_videoSize ?? 'size unknown'})');
    }

    // For temporary messages, allow interaction even if size is not available
    final allowInteraction =
        _isInitialized && (!_isFetchingSize || widget.message.isTemp == true);
    final hasVideo = widget.message.messageVideo != null;

    // Special handling for temporary messages that are initialized but still loading
    if (widget.message.isTemp == true && _isInitialized && _videoSize == null) {
      print('🔧 Temporary message initialized but no size, setting default...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setDefaultSizeForTempMessage();
      });
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
              child: GestureDetector(
                onLongPress: allowInteraction ? _showVideoOptions : null,
                onTap: () {
                  if (allowInteraction && widget.message.messageVideo != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.transparent,
                            leading: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          body: Center(
                            child: ChewieVideoPlayer(
                              videoUrl: widget.message.messageVideo!,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 200,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: ColorManager.gray200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(
                                  Icons.video_collection_outlined,
                                  color: ColorManager.blueLight800,
                                  size: 40,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    videoFileName,
                                    style: getRegularStyle(
                                      fontSize: 10,
                                      color: ColorManager.blueLight800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_videoSize != null && !showLoading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text(
                            _videoSize!,
                            style: getRegularStyle(
                              fontSize: 10,
                              color: ColorManager.blueLight800,
                            ),
                          ),
                        ),
                      // Show default size for temporary messages if actual size is not available
                      if (_videoSize == null &&
                          widget.message.isTemp == true &&
                          !showLoading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text(
                            '2.3 MB',
                            style: getRegularStyle(
                              fontSize: 10,
                              color: ColorManager.blueLight800,
                            ),
                          ),
                        ),
                      // Show loading indicator for temporary messages that are still initializing
                      if (widget.message.isTemp == true && showLoading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorManager.blueLight800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
                _formatMessageTime(widget.message.messageDate),
                style: getRegularStyle(
                  fontSize: 12,
                  color: widget.isFromUser
                      ? ColorManager.black.withOpacity(0.7)
                      : ColorManager.black,
                ),
              ),
              if (shouldShowStatus && messageStatus != 'pending')
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
                            .withOpacity(0.7) //color for read
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

class ChewieVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ChewieVideoPlayer({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  State<ChewieVideoPlayer> createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    await _controller!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: true,
      looping: false,
      aspectRatio: _controller!.value.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
    );

    setState(() {});
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || _controller == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}

class LocalChewieVideoPlayer extends StatefulWidget {
  final File file;

  const LocalChewieVideoPlayer({Key? key, required this.file})
      : super(key: key);

  @override
  State<LocalChewieVideoPlayer> createState() => _LocalChewieVideoPlayerState();
}

class _LocalChewieVideoPlayerState extends State<LocalChewieVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.file(widget.file);
    await _controller!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: false,
      looping: false,
      aspectRatio: _controller!.value.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
    );

    setState(() {});
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || _controller == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
        ),
      );
    }
    return Chewie(controller: _chewieController!);
  }
}
