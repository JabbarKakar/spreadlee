import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// Represents a selected file with its metadata
class SelectedFile {
  const SelectedFile({
    this.storagePath = '',
    this.filePath,
    required this.bytes,
    this.dimensions,
    this.blurHash,
  });

  /// The storage path for the file (useful for uploads)
  final String storagePath;

  /// The local file path
  final String? filePath;

  /// The file bytes
  final Uint8List bytes;

  /// Media dimensions (width and height)
  final MediaDimensions? dimensions;

  /// Blur hash for images (not used for videos)
  final String? blurHash;
}

/// Represents media dimensions
class MediaDimensions {
  const MediaDimensions({
    this.height,
    this.width,
  });

  final double? height;
  final double? width;
}

/// Available media sources
enum MediaSource {
  photoGallery,
  videoGallery,
  camera,
}

/// A custom video picker that mimics WeChat picker functionality
/// without FlutterFlow and Firebase dependencies.
///
/// This picker provides:
/// - Gallery-only video selection (no camera)
/// - Platform-specific permission handling
/// - File size validation (50MB limit)
/// - File format validation
/// - Video duration limits (5 minutes)
/// - No video compression (original quality preserved)
/// - Error dialogs for size limits and permissions
/// - Exact API match with original WeChat picker
///
/// Usage example:
/// ```dart
/// List<SelectedFile>? selectedMedia = await CustomVideoPicker
///     .selectMediaWithWeChatPicker(
///   context,
///   isVideo: true,
///   mediaSource: MediaSource.videoGallery,
///   multiImage: false,
/// );
///
/// if (selectedMedia != null && selectedMedia.isNotEmpty) {
///   final selectedFile = selectedMedia.first;
///   // Use selectedFile.filePath for the video path
///   // Use selectedFile.bytes for the video data
/// }
/// ```
class CustomVideoPicker {
  /// Maximum video file size in bytes (50MB)
  static const int maxVideoSizeBytes = 50 * 1024 * 1024;

  /// Maximum video duration (5 minutes)
  static const Duration maxVideoDuration = Duration(minutes: 5);

  /// Shows a bottom sheet to select video source (gallery only)
  ///
  /// This method displays a modal bottom sheet with options to choose
  /// between gallery and camera for video selection.
  ///
  /// Parameters:
  /// - [context]: The build context
  /// - [storageFolderPath]: Optional storage path prefix
  /// - [maxWidth]: Maximum width for video processing
  /// - [maxHeight]: Maximum height for video processing
  /// - [imageQuality]: Image quality for processing
  /// - [pickerFontFamily]: Font family for the picker UI
  /// - [textColor]: Text color for the picker UI
  /// - [backgroundColor]: Background color for the picker UI
  /// - [includeDimensions]: Whether to include video dimensions
  /// - [includeBlurHash]: Whether to include blur hash (not used for videos)
  ///
  /// Returns a list of [SelectedFile] objects or null if cancelled.
  static Future<List<SelectedFile>?> selectVideoWithSourceBottomSheet({
    required BuildContext context,
    String? storageFolderPath,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    String pickerFontFamily = 'Roboto',
    Color textColor = const Color(0xFF111417),
    Color backgroundColor = const Color(0xFFF5F5F5),
    bool includeDimensions = false,
    bool includeBlurHash = false,
  }) async {
    // Directly select from gallery without showing bottom sheet
    return selectVideo(
      storageFolderPath: storageFolderPath,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      mediaSource: MediaSource.videoGallery, // Always use gallery
      includeDimensions: includeDimensions,
      includeBlurHash: includeBlurHash,
    );
  }

  /// Selects video using the specified media source
  ///
  /// This method handles the actual video selection process including
  /// permission requests, file validation, and metadata extraction.
  ///
  /// Parameters:
  /// - [storageFolderPath]: Optional storage path prefix
  /// - [maxWidth]: Maximum width for video processing (ignored for videos)
  /// - [maxHeight]: Maximum height for video processing (ignored for videos)
  /// - [imageQuality]: Image quality for processing (ignored for videos)
  /// - [mediaSource]: The source to use (gallery or camera)
  /// - [includeDimensions]: Whether to include video dimensions
  /// - [includeBlurHash]: Whether to include blur hash (not used for videos)
  ///
  /// Returns a list of [SelectedFile] objects or null if cancelled.
  static Future<List<SelectedFile>?> selectVideo({
    String? storageFolderPath,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    MediaSource mediaSource = MediaSource.videoGallery,
    bool includeDimensions = false,
    bool includeBlurHash = false,
  }) async {
    final picker = ImagePicker();

    try {
      // Request permission first
      final hasPermission = await _requestVideoPermission();
      if (!hasPermission) {
        return null;
      }

      // Always use gallery source, ignore mediaSource parameter
      final XFile? videoFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxVideoDuration,
        // Remove compression by not specifying quality parameters
      );

      if (videoFile == null) {
        return null;
      }

      // Validate file size
      final file = File(videoFile.path);
      final fileSize = await file.length();

      if (fileSize > maxVideoSizeBytes) {
        throw Exception('Video size must be no more than 50 MB');
      }

      // Validate file format
      final mimeType = lookupMimeType(videoFile.path);
      if (mimeType == null || !mimeType.startsWith('video/')) {
        throw Exception('Invalid video file format');
      }

      // Read file bytes
      final mediaBytes = await videoFile.readAsBytes();

      // Get file name and path
      final name = videoFile.name;
      final filePath = videoFile.path;

      // Generate storage path
      final path = _getStoragePath(storageFolderPath, name, true);

      // Get video dimensions if requested
      final dimensions =
          includeDimensions ? await _getVideoDimensions(filePath) : null;

      return [
        SelectedFile(
          storagePath: path,
          filePath: filePath,
          bytes: mediaBytes,
          dimensions: dimensions,
        ),
      ];
    } catch (e) {
      debugPrint('Error selecting video: $e');
      rethrow;
    }
  }

  /// Request video permission based on platform
  ///
  /// Handles platform-specific permission requests for video access.
  /// Only requests gallery permissions since we only use gallery source.
  static Future<bool> _requestVideoPermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        // For Android, we only need storage permission for gallery access
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting video permission: $e');
      return false;
    }
  }

  /// Get video dimensions using video_player
  ///
  /// Extracts video dimensions using the video_player package.
  /// Returns a [MediaDimensions] object with width and height.
  static Future<MediaDimensions> _getVideoDimensions(String path) async {
    try {
      final VideoPlayerController videoPlayerController =
          VideoPlayerController.file(File(path));
      await videoPlayerController.initialize();
      final size = videoPlayerController.value.size;
      await videoPlayerController.dispose();
      return MediaDimensions(width: size.width, height: size.height);
    } catch (e) {
      debugPrint('Error getting video dimensions: $e');
      return const MediaDimensions();
    }
  }

  /// Generate storage path for the file
  ///
  /// Creates a unique storage path for the file using timestamp and extension.
  static String _getStoragePath(
    String? pathPrefix,
    String fileName,
    bool isVideo, [
    int? index,
  ]) {
    pathPrefix ??= 'uploads';
    pathPrefix = _removeTrailingSlash(pathPrefix);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final ext = isVideo ? 'mp4' : fileName.split('.').last;
    final indexStr = index != null ? '_$index' : '';
    return '$pathPrefix/$timestamp$indexStr.$ext';
  }

  /// Remove trailing slash from path
  static String? _removeTrailingSlash(String? path) =>
      path != null && path.endsWith('/')
          ? path.substring(0, path.length - 1)
          : path;

  /// Show error dialog for file size limit
  ///
  /// Displays an alert dialog when the selected video exceeds the size limit.
  static Future<void> showFileSizeErrorDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: const Text('Error!'),
          content: const Text('Video size must be no more than 50 MB.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  /// Show error dialog for file size exceeding server limit
  ///
  /// Displays an alert dialog when the selected file exceeds the server's maximum allowed size.
  static Future<void> showServerFileSizeErrorDialog(
      BuildContext context) async {
    await showDialog(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: const Text('File Too Large'),
          content: const Text(
            'The selected file exceeds the server\'s maximum allowed size of 65 MB. '
            'Please choose a smaller file or compress the video before sending.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show permission denied dialog
  ///
  /// Displays an alert dialog when permissions are denied with an option
  /// to open app settings.
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Camera and storage permissions are required to select videos. '
            'Please enable them in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(alertDialogContext);
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Select media with WeChat picker interface (exact API match)
  ///
  /// This method provides the same interface as the original WeChat picker
  /// but without FlutterFlow and Firebase dependencies.
  ///
  /// Parameters:
  /// - [context]: The build context
  /// - [isVideo]: Whether to select video (true) or image (false)
  /// - [mediaSource]: The media source (always videoGallery for videos)
  /// - [multiImage]: Whether to allow multiple selection (ignored for videos)
  /// - [storageFolderPath]: Optional storage path prefix
  /// - [maxWidth]: Maximum width for processing (ignored for videos)
  /// - [maxHeight]: Maximum height for processing (ignored for videos)
  /// - [imageQuality]: Image quality for processing (ignored for videos)
  /// - [includeDimensions]: Whether to include video dimensions
  /// - [includeBlurHash]: Whether to include blur hash (not used for videos)
  ///
  /// Returns a list of [SelectedFile] objects or null if cancelled.
  static Future<List<SelectedFile>?> selectMediaWithWeChatPicker(
    BuildContext context, {
    String? storageFolderPath,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool isVideo = false,
    MediaSource mediaSource = MediaSource.camera,
    bool multiImage = false,
    bool includeDimensions = false,
    bool includeBlurHash = false,
  }) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: multiImage ? 9 : 1,
        requestType: isVideo ? RequestType.video : RequestType.image,
      ),
    );

    if (result == null || result.isEmpty) {
      return null;
    }

    final List<SelectedFile> files = [];
    for (final asset in result) {
      final file = await asset.loadFile(isOrigin: true, withSubtype: true);
      if (file == null) continue;
      final name = file.path.split('/').last;
      final filePath = file.path;
      final mediaBytes = await file.readAsBytes();

      final path = _getStoragePath(storageFolderPath, name, isVideo);
      final dimensions = includeDimensions
          ? isVideo
              ? await _getVideoDimensions(filePath)
              : await _getImageDimensions(mediaBytes)
          : null;

      files.add(SelectedFile(
        storagePath: path,
        filePath: filePath,
        bytes: mediaBytes,
        dimensions: dimensions,
      ));
    }
    return files;
  }

  static Future<MediaDimensions> _getImageDimensions(
      Uint8List mediaBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(mediaBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      return MediaDimensions(
        width: image.width.toDouble(),
        height: image.height.toDouble(),
      );
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return const MediaDimensions();
    }
  }
}
