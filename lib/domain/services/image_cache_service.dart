import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static const String _cacheKey = 'image_cache';
  late SharedPreferences _prefs;
  final Dio _dio = Dio();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String?> getCachedImagePath(String imageUrl) async {
    return _prefs.getString('$_cacheKey:$imageUrl');
  }

  Future<String> cacheImage(String imageUrl) async {
    // Check if image is already cached
    final cachedPath = await getCachedImagePath(imageUrl);
    if (cachedPath != null && File(cachedPath).existsSync()) {
      return cachedPath;
    }

    try {
      // Get app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageUrl.split('/').last}';
      final savePath = '${appDocDir.path}/$fileName';

      // Download the image
      await _dio.download(
        imageUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // You can implement progress tracking here if needed
            final progress = (received / total * 100);
            print('Download progress: $progress%');
          }
        },
      );

      // Save the path to shared preferences
      await _prefs.setString('$_cacheKey:$imageUrl', savePath);
      return savePath;
    } catch (e) {
      print('Error caching image: $e');
      rethrow;
    }
  }

  Future<void> clearCache() async {
    // Delete all cached files
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('$_cacheKey:')) {
        final path = _prefs.getString(key);
        if (path != null) {
          try {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('Error deleting cached file: $e');
          }
        }
      }
    }
    // Clear the shared preferences
    await _prefs.clear();
  }

  Future<void> removeCachedImage(String imageUrl) async {
    final path = await getCachedImagePath(imageUrl);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting cached file: $e');
      }
    }
    await _prefs.remove('$_cacheKey:$imageUrl');
  }
}
