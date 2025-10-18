import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';

class PhotoCache extends StatefulWidget {
  const PhotoCache({
    super.key,
    this.width,
    this.height,
    required this.photoUrl,
    this.onTap,
    this.onLongPress,
    this.isFromUser = false,
    this.onImagePathReady,
  });

  final double? width;
  final double? height;
  final String photoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isFromUser;
  final Function(String)? onImagePathReady;

  @override
  State<PhotoCache> createState() => _PhotoCacheState();
}

class _PhotoCacheState extends State<PhotoCache>
    with AutomaticKeepAliveClientMixin {
  late final Dio dio;
  double _progress = 0.0;
  String? _photoFilePath;
  String? photoSize = '';
  bool _isDownloading = false;
  bool _isInitialized = false;
  String? _lastPhotoUrl; // Track the last URL to detect changes
  late SharedPreferences _prefs;

  String get photoFileName {
    try {
      final uri = Uri.parse(widget.photoUrl);
      final fileName = uri.pathSegments.last;
      print('📝 Getting photo filename: $fileName');

      if (fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.gif') ||
          fileName.endsWith('.webp')) {
        final extension = fileName.split('.').last;
        final nameWithoutExtension =
            fileName.substring(0, fileName.length - extension.length - 1);
        if (nameWithoutExtension.length > 8) {
          final truncatedName =
              '...${nameWithoutExtension.substring(nameWithoutExtension.length - 8)}.$extension';
          print('📝 Truncated filename: $truncatedName');
          return truncatedName;
        }
      }
      print('📝 Using original filename: $fileName');
      return fileName;
    } catch (e) {
      print('❌ Error getting photo filename: $e');
      return 'Photo';
    }
  }

  @override
  void initState() {
    super.initState();
    dio = Dio();
    _lastPhotoUrl = widget.photoUrl;
    _initializeSharedPreferences();
    _fetchPhotoSize();
  }

  @override
  void didUpdateWidget(PhotoCache oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the photo URL has changed (e.g., from local to remote after upload)
    if (oldWidget.photoUrl != widget.photoUrl) {
      print(
          '🔄 Photo URL changed from ${oldWidget.photoUrl} to ${widget.photoUrl}');
      _lastPhotoUrl = widget.photoUrl;
      _photoFilePath = null; // Reset cached path
      _isInitialized = false; // Reinitialize
      _initializeSharedPreferences();
      _fetchPhotoSize();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchPhotoSize() async {
    if (widget.photoUrl.startsWith('http')) {
      photoSize = await getFileSize(widget.photoUrl, 2);
      if (mounted) {
        setState(() {});
      }
    } else {
      // For local files, get the file size directly
      try {
        final file = File(widget.photoUrl);
        if (await file.exists()) {
          final fileSize = await file.length();
          photoSize = _formatFileSize(fileSize, 2);
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        print('Error getting local file size: $e');
      }
    }
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final cachedPath = _prefs.getString(widget.photoUrl);

    if (cachedPath != null && await File(cachedPath).exists()) {
      if (mounted) {
        setState(() {
          _photoFilePath = cachedPath;
          _isInitialized = true;
        });
        // Notify parent of the correct image path
        widget.onImagePathReady?.call(cachedPath);
      }
    } else {
      // If it's a local file path, use it directly
      if (!widget.photoUrl.startsWith('http') &&
          await File(widget.photoUrl).exists()) {
        if (mounted) {
          setState(() {
            _photoFilePath = widget.photoUrl;
            _isInitialized = true;
          });
          // Notify parent of the correct image path
          widget.onImagePathReady?.call(widget.photoUrl);
          // Fetch the file size for local files
          _fetchPhotoSize();
        }
      } else {
        // For sent images with remote URLs, automatically cache them
        if (widget.isFromUser && widget.photoUrl.startsWith('http')) {
          print('🔄 Auto-caching sent image: ${widget.photoUrl}');
          _downloadAndSavePhoto(); // Auto-cache sent images
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          // For remote URLs, pass the original URL initially
          // This will be updated when caching completes
          widget.onImagePathReady?.call(widget.photoUrl);
        }
      }
    }
  }

  Future<void> _downloadAndSavePhoto() async {
    if (!widget.photoUrl.startsWith('http')) {
      return; // Don't download local files
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$photoFileName';
      String savePath = '${appDocDir.path}/Media/$fileName';

      // Ensure Media directory exists
      Directory mediaDir = Directory('${appDocDir.path}/Media');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      await dio.download(
        widget.photoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total * 100);
            if (mounted) {
              setState(() {
                _progress = progress;
              });
            }
          }
        },
      );

      // Save the file path to SharedPreferences
      await _prefs.setString(widget.photoUrl, savePath);

      if (mounted) {
        setState(() {
          _photoFilePath = savePath;
          _isDownloading = false;
          _progress = 0.0;
        });
        // Notify parent of the cached image path
        widget.onImagePathReady?.call(savePath);
      }

      // Only show the SnackBar if the user is NOT the sender
      if (!widget.isFromUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo cached successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error downloading photo');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _progress = 0.0;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
          content: Text('Error caching photo'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> getFileSize(String url, int decimalPlaces) async {
    try {
      final response = await dio.head(url);
      final contentLength = response.headers.value('content-length');
      if (contentLength != null) {
        final sizeInBytes = int.parse(contentLength);
        return _formatFileSize(sizeInBytes, decimalPlaces);
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return null;
  }

  String _formatFileSize(int bytes, int decimalPlaces) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimalPlaces)} ${suffixes[i]}';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // If the user is the sender, always show the file-like interface or image immediately
    if (widget.isFromUser) {
      if (_photoFilePath != null && _photoFilePath!.isNotEmpty) {
        // File-like interface for sent images
        return GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Container(
            width: widget.width ?? 200,
            height: 60, // Fixed smaller height for file-like interface
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: ColorManager.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo,
                  color: ColorManager.blueLight800,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          photoFileName,
                          style: getRegularStyle(
                            fontSize: 12,
                            color: ColorManager.blueLight800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (photoSize != null && photoSize!.isNotEmpty)
                        Text(
                          photoSize!,
                          style: getRegularStyle(
                            fontSize: 10,
                            color: ColorManager.blueLight800.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Placeholder for sent images if no file path yet
        return GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Container(
            width: widget.width ?? 200,
            height: 60, // Fixed smaller height for placeholder
            decoration: BoxDecoration(
              color: ColorManager.gray200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo,
                  size: 24,
                  color: ColorManager.blueLight800,
                ),
                const SizedBox(width: 8),
                Text(
                  photoFileName,
                  style: getRegularStyle(
                    fontSize: 12,
                    color: ColorManager.blueLight800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
    }

    // For received images, show loading spinner if not initialized
    if (!_isInitialized) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          width: widget.width ?? 200,
          height: widget.height ?? 200,
          color: ColorManager.gray200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Show download progress only for received images
    if (_isDownloading && !widget.isFromUser) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          width: widget.width ?? 200,
          height: widget.height ?? 200,
          color: ColorManager.gray200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LinearProgressIndicator(
                value: _progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                '${_progress.toStringAsFixed(1)}%',
                style: getRegularStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show cached photo if available (for received images only)
    if (_photoFilePath != null &&
        _photoFilePath!.isNotEmpty &&
        !widget.isFromUser) {
      // Show file-like interface for received images (same as sender)
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          width: widget.width ?? 200,
          height: 60, // Fixed smaller height for file-like interface
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: ColorManager.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.photo,
                color: ColorManager.blueLight800,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        photoFileName,
                        style: getRegularStyle(
                          fontSize: 12,
                          color: ColorManager.blueLight800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (photoSize != null && photoSize!.isNotEmpty)
                      Text(
                        photoSize!,
                        style: getRegularStyle(
                          fontSize: 10,
                          color: ColorManager.blueLight800.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show placeholder with download button for remote URLs (only for received images)
    if (widget.photoUrl.startsWith('http') && !widget.isFromUser) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          width: widget.width ?? 200,
          height: widget.height ?? 200,
          decoration: BoxDecoration(
            color: ColorManager.gray200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo,
                size: 48,
                color: ColorManager.blueLight800,
              ),
              const SizedBox(height: 8),
              Text(
                photoFileName,
                style: getRegularStyle(
                  fontSize: 12,
                  color: ColorManager.blueLight800,
                ),
                textAlign: TextAlign.center,
              ),
              if (photoSize != null && photoSize!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  photoSize!,
                  style: getRegularStyle(
                    fontSize: 10,
                    color: ColorManager.blueLight800,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              IconButton(
                onPressed: _downloadAndSavePhoto,
                icon: Icon(Icons.cloud_download_outlined,
                    color: ColorManager.blueLight800, size: 28),
                tooltip: 'Download',
              ),
            ],
          ),
        ),
      );
    }

    // Show placeholder for local files that don't exist
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: widget.width ?? 200,
        height: widget.height ?? 200,
        decoration: BoxDecoration(
          color: ColorManager.gray200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.error, color: Colors.grey),
        ),
      ),
    );
  }
}
