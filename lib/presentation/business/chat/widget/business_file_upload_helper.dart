import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadlee/services/chat_service.dart';
import 'package:spreadlee/presentation/business/chat/provider/chat_provider.dart';

/// Business-specific helper class for handling file uploads in chat
class BusinessFileUploadHelper {
  static final ChatService _chatService = ChatService();

  /// Pick and upload an image for business chat
  static Future<String?> pickAndUploadImage(
    String chatId,
    String userRole, {
    ImageSource source = ImageSource.gallery,
    ProgressCallback? onProgress,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      final File imageFile = File(image.path);

      return await _chatService.uploadImageMessage(
        imageFile,
        chatId,
        userRole: userRole,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error picking and uploading image: $e');
      return null;
    }
  }

  /// Pick and upload a document for business chat
  static Future<String?> pickAndUploadDocument(
    String chatId,
    String userRole, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final File documentFile = File(result.files.first.path!);

      return await _chatService.uploadDocumentMessage(
        documentFile,
        chatId,
        userRole: userRole,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error picking and uploading document: $e');
      return null;
    }
  }

  /// Pick and upload a video for business chat
  static Future<String?> pickAndUploadVideo(
    String chatId,
    String userRole, {
    ImageSource source = ImageSource.gallery,
    ProgressCallback? onProgress,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );

      if (video == null) return null;

      final File videoFile = File(video.path);

      return await _chatService.uploadVideoMessage(
        videoFile,
        chatId,
        userRole: userRole,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error picking and uploading video: $e');
      return null;
    }
  }

  /// Send a message with uploaded file using business chat provider
  static Future<void> sendMessageWithFile(
    ChatProvider chatProvider,
    String fileUrl,
    String fileType, {
    String? messageText,
  }) async {
    try {
      switch (fileType) {
        case 'image':
          await chatProvider.sendMessage(
            messageText: messageText ?? '[IMAGE]',
            photoPaths: [fileUrl],
          );
          break;
        case 'video':
          await chatProvider.sendMessage(
            messageText: messageText ?? '[VIDEO]',
            videoPath: [fileUrl],
          );
          break;
        case 'file':
          await chatProvider.sendMessage(
            messageText: messageText ?? '[Document]',
            documents: [
              {
                'url': fileUrl,
                'name': 'document',
                'size': 0,
                'extension': 'pdf',
              }
            ],
          );
          break;
        default:
          debugPrint('Unknown file type: $fileType');
      }
    } catch (e) {
      debugPrint('Error sending message with file: $e');
    }
  }

  /// Show a bottom sheet with upload options for business chat
  static Future<void> showBusinessUploadOptions(
    BuildContext context,
    String chatId,
    String userRole,
    ChatProvider chatProvider, {
    ProgressCallback? onProgress,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Choose File Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(
                  context,
                  icon: Icons.photo,
                  label: 'Image',
                  onTap: () async {
                    Navigator.pop(context);
                    final url = await pickAndUploadImage(
                      chatId,
                      userRole,
                      onProgress: onProgress,
                    );
                    if (url != null) {
                      await sendMessageWithFile(
                        chatProvider,
                        url,
                        'image',
                      );
                    }
                  },
                ),
                _buildUploadOption(
                  context,
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () async {
                    Navigator.pop(context);
                    final url = await pickAndUploadVideo(
                      chatId,
                      userRole,
                      onProgress: onProgress,
                    );
                    if (url != null) {
                      await sendMessageWithFile(
                        chatProvider,
                        url,
                        'video',
                      );
                    }
                  },
                ),
                _buildUploadOption(
                  context,
                  icon: Icons.description,
                  label: 'Document',
                  onTap: () async {
                    Navigator.pop(context);
                    final url = await pickAndUploadDocument(
                      chatId,
                      userRole,
                      onProgress: onProgress,
                    );
                    if (url != null) {
                      await sendMessageWithFile(
                        chatProvider,
                        url,
                        'file',
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildUploadOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
