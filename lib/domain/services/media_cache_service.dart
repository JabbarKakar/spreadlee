import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

enum MediaType {
  image,
  video,
  document,
}

class MediaCacheService {
  static const String _cacheKey = 'media_cache';
  late SharedPreferences _prefs;
  final Dio _dio = Dio();

  String _cleanUrl(String url) {
    // Remove square brackets and any whitespace
    return url.replaceAll('[', '').replaceAll(']', '').trim();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Map<String, dynamic>? _parseCacheData(String? data) {
    if (data == null) return null;

    try {
      // Parse JSON string to Map<String, dynamic>
      final Map<String, dynamic> cacheData = jsonDecode(data);
      return cacheData;
    } catch (e) {
      print('Error parsing cache data: $e');
      return null;
    }
  }

  Future<String?> getCachedMediaPath(String mediaUrl, MediaType type) async {
    final cleanUrl = _cleanUrl(mediaUrl);
    final cacheDataJson = _prefs.getString('$_cacheKey:$cleanUrl');
    final cacheData = _parseCacheData(cacheDataJson);

    if (cacheData != null &&
        cacheData['type'] == type.toString() &&
        File(cacheData['path']).existsSync()) {
      return cacheData['path'];
    }
    return null;
  }

  Future<String> cacheMedia(String mediaUrl, MediaType type,
      {Function(double)? onProgress}) async {
    final cleanUrl = _cleanUrl(mediaUrl);

    // Only download if it's a remote URL
    if (!cleanUrl.startsWith('http')) {
      throw Exception('cacheMedia called with a non-remote URL: $mediaUrl');
    }

    // Check if media is already cached
    final cachedPath = await getCachedMediaPath(cleanUrl, type);
    if (cachedPath != null) {
      return cachedPath;
    }

    try {
      // Get app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final extension = cleanUrl.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${cleanUrl.split('/').last}';
      final savePath = '${appDocDir.path}/$fileName';

      // Download the media
      await _dio.download(
        cleanUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = (received / total * 100);
            onProgress(progress);
          }
        },
      );

      // Create cache data map
      final cacheData = {
        'path': savePath,
        'type': type.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save the path and type to shared preferences
      await _prefs.setString('$_cacheKey:$cleanUrl', jsonEncode(cacheData));

      return savePath;
    } catch (e) {
      print('Error caching media: $e');
      rethrow;
    }
  }

  Future<void> clearCache({MediaType? type}) async {
    if (type == null) {
      // Clear all cached files
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('$_cacheKey:')) {
          final cacheDataJson = _prefs.getString(key);
          if (cacheDataJson != null) {
            final cacheData = _parseCacheData(cacheDataJson);
            if (cacheData != null) {
              try {
                final file = File(cacheData['path']);
                if (await file.exists()) {
                  await file.delete();
                }
              } catch (e) {
                print('Error deleting cached file: $e');
              }
            }
          }
        }
      }
      await _prefs.clear();
    } else {
      // Clear only specific type
      final keysToDelete = <String>[];
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('$_cacheKey:')) {
          final cacheDataJson = _prefs.getString(key);
          if (cacheDataJson != null) {
            final cacheData = _parseCacheData(cacheDataJson);
            if (cacheData != null && cacheData['type'] == type.toString()) {
              try {
                final file = File(cacheData['path']);
                if (await file.exists()) {
                  await file.delete();
                }
                keysToDelete.add(key);
              } catch (e) {
                print('Error deleting cached file: $e');
              }
            }
          }
        }
      }
      for (final key in keysToDelete) {
        await _prefs.remove(key);
      }
    }
  }

  Future<void> removeCachedMedia(String mediaUrl) async {
    final cleanUrl = _cleanUrl(mediaUrl);
    final cacheDataJson = _prefs.getString('$_cacheKey:$cleanUrl');
    final cacheData = _parseCacheData(cacheDataJson);
    if (cacheData != null) {
      try {
        final file = File(cacheData['path']);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting cached file: $e');
      }
    }
    await _prefs.remove('$_cacheKey:$cleanUrl');
  }

  Future<void> clearOldCache(
      {Duration maxAge = const Duration(days: 7)}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <String>[];

    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('$_cacheKey:')) {
        final cacheDataJson = _prefs.getString(key);
        if (cacheDataJson != null) {
          final cacheData = _parseCacheData(cacheDataJson);
          if (cacheData != null) {
            final timestamp = cacheData['timestamp'] as int;
            if (now - timestamp > maxAge.inMilliseconds) {
              try {
                final file = File(cacheData['path']);
                if (await file.exists()) {
                  await file.delete();
                }
                keysToDelete.add(key);
              } catch (e) {
                print('Error deleting old cached file: $e');
              }
            }
          }
        }
      }
    }

    for (final key in keysToDelete) {
      await _prefs.remove(key);
    }
  }

  /// Save a local file to the app's cache directory and register it in Hive.
  Future<String> saveLocalFileToCache(
      String localFilePath, MediaType type) async {
    final file = File(localFilePath);
    if (!await file.exists()) {
      throw Exception('Local file does not exist: $localFilePath');
    }

    // Get app documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final extension = localFilePath.split('.').last;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${localFilePath.split('/').last}';
    final savePath = '${appDocDir.path}/$fileName';

    // Copy the file to the cache directory
    await file.copy(savePath);

    // Use the savePath as the cache key (to avoid collisions with remote URLs)
    final cacheKey = savePath;

    // Create cache data map
    final cacheData = {
      'path': savePath,
      'type': type.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Save the path and type to Hive
    await _prefs.setString('$_cacheKey:$cacheKey', jsonEncode(cacheData));

    return savePath;
  }

  /// Register a mapping from a remote URL to a local file path for sent images.
  Future<void> registerLocalPathForRemoteUrl(
      String remoteUrl, String localFilePath) async {
    final key = 'local_for_$remoteUrl';
    await _prefs.setString(key, localFilePath);
  }

  /// Retrieve the local file path for a given remote URL if it exists and the file is present.
  Future<String?> getLocalPathForRemoteUrl(String remoteUrl) async {
    final key = 'local_for_$remoteUrl';
    final localPath = _prefs.getString(key);
    if (localPath != null && await File(localPath).exists()) {
      return localPath;
    }
    return null;
  }
}
