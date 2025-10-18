import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:spreadlee/core/di.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/domain/services/media_cache_service.dart';
import 'package:spreadlee/presentation/business/chat/widget/messages/view_pdf.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'dart:io';
import '../../view/chat_screen.dart';

class DocumentMessageCustomerWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final Function(String)? onDocumentTap;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;

  const DocumentMessageCustomerWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    this.onDocumentTap,
    required this.chatId,
    required this.currentUserId,
    this.onMessageVisible,
  }) : super(key: key);

  @override
  State<DocumentMessageCustomerWidget> createState() =>
      _DocumentMessageCustomerWidgetState();
}

class _DocumentMessageCustomerWidgetState
    extends State<DocumentMessageCustomerWidget> {
  late final MediaCacheService _mediaCacheService;
  String? _cachedDocumentPath;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _mediaCacheService = instance<MediaCacheService>();
    _initializeDocument();
  }

  Future<void> _initializeDocument() async {
    if (widget.message.messageDocument == null) return;

    print('Initializing document: ${widget.message.messageDocument}');

    try {
      // Clean the URL by removing square brackets
      final cleanUrl = widget.message.messageDocument!
          .replaceAll('[', '')
          .replaceAll(']', '');

      final cachedPath = await _mediaCacheService.getCachedMediaPath(
        cleanUrl,
        MediaType.document,
      );

      print('Cached path result: $cachedPath');

      if (cachedPath != null) {
        setState(() {
          _cachedDocumentPath = cachedPath;
        });
        print('Document initialized with cached path: $_cachedDocumentPath');
      } else {
        print('No cached path found, downloading document...');
        await _downloadAndCacheDocument();
      }
    } catch (e) {
      print('Error initializing document: $e');
    }
  }

  Future<void> _downloadAndCacheDocument() async {
    if (widget.message.messageDocument == null) return;

    print('Downloading document: ${widget.message.messageDocument}');

    try {
      setState(() {
        _downloadProgress = 0;
      });

      // Clean the URL by removing square brackets
      final cleanUrl = widget.message.messageDocument!
          .replaceAll('[', '')
          .replaceAll(']', '');
      String? cachedPath;

      if (cleanUrl.startsWith('http')) {
        print('Downloading from URL: $cleanUrl');
        cachedPath = await _mediaCacheService.cacheMedia(
          cleanUrl,
          MediaType.document,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
            });
          },
        );
      } else {
        print('Document is not a URL, using local path: $cleanUrl');
        // For local files, check if they exist
        final file = File(cleanUrl);
        if (await file.exists()) {
          cachedPath = cleanUrl;
        } else {
          print('Local file does not exist: $cleanUrl');
        }
      }

      print('Download result - cached path: $cachedPath');

      if (cachedPath != null) {
        setState(() {
          _cachedDocumentPath = cachedPath;
          _downloadProgress = null;
        });
        print('Document downloaded successfully: $_cachedDocumentPath');
      } else {
        setState(() {
          _downloadProgress = null;
        });
        print('Failed to download document');
      }
    } catch (e) {
      print('Error downloading document: $e');
      setState(() {
        _downloadProgress = null;
      });
    }
  }

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
    // Get status from provider instead of directly from message
    Map<String, dynamic>? currentStatus;
    try {
      final provider = ChatProviderInherited.of(context);
      currentStatus = provider.getMessageStatus(widget.message.id);
    } catch (e) {
      // ChatProviderInherited not available in this context, use message status only
      if (kDebugMode) {
        print(
            'DocumentMessageCustomerWidget: ChatProviderInherited not available: $e');
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
    final shouldShowStatus = widget.isFromUser;

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
                constraints: const BoxConstraints(
                  maxWidth: 270,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                            horizontal: 8, vertical: 4),
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
                            fontSize: 11,
                            color: ColorManager.primary,
                          ),
                        ),
                      ),
                    // Compact file row for document
                    GestureDetector(
                      onTap: () async {
                        try {
                          if (_cachedDocumentPath != null) {
                            final file = File(_cachedDocumentPath!);
                            if (!await file.exists()) {
                              await _downloadAndCacheDocument();
                              return;
                            }
                            if (widget.message.messageDocument
                                    ?.toLowerCase()
                                    .endsWith('.pdf') ??
                                false) {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewPdf(
                                      messageDocument: _cachedDocumentPath!,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (widget.onDocumentTap != null) {
                                widget.onDocumentTap!(_cachedDocumentPath!);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Document viewer not available'),
                                    ),
                                  );
                                }
                              }
                            }
                          } else {
                            await _downloadAndCacheDocument();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error opening document'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 0),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ColorManager.gray500,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: ColorManager.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.insert_drive_file,
                                color: ColorManager.blueLight800,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.message.messageDocument
                                            ?.split('/')
                                            .last ??
                                        'Document',
                                    style: getMediumStyle(
                                      fontSize: 11,
                                      color: ColorManager.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _cachedDocumentPath != null
                                        ? 'Tap to view document'
                                        : 'Tap to download',
                                    style: getRegularStyle(
                                      fontSize: 8,
                                      color:
                                          ColorManager.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: ColorManager.white.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_downloadProgress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: _downloadProgress! / 100,
                                strokeWidth: 2.5,
                                color: ColorManager.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_downloadProgress!.toStringAsFixed(1)}%',
                              style: getRegularStyle(
                                fontSize: 12,
                                color: ColorManager.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            .withOpacity(0.7)//color for read
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
