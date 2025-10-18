import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionUtils {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, 'Camera');
      return false;
    } else {
      _showPermissionDeniedDialog(context, 'Camera');
      return false;
    }
  }

  static Future<bool> requestPhotosPermission(BuildContext context) async {
    if (Platform.isIOS) {
      // On iOS, we need to use mediaLibrary permission for photo access
      final status = await Permission.mediaLibrary.status;
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showSettingsDialog(context, 'Photos');
        return false;
      } else {
        final result = await Permission.mediaLibrary.request();
        if (!result.isGranted) {
          _showPermissionDeniedDialog(context, 'Photos');
          return false;
        }
        return true;
      }
    } else {
      // For Android
      if (await Permission.photos.isRestricted) {
        _showPermissionDeniedDialog(context, 'Photos');
        return false;
      }

      final status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showSettingsDialog(context, 'Photos');
        return false;
      } else {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          _showPermissionDeniedDialog(context, 'Photos');
          return false;
        }
        return true;
      }
    }
  }

  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, 'Microphone');
      return false;
    } else {
      _showPermissionDeniedDialog(context, 'Microphone');
      return false;
    }
  }

  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, 'Location');
      return false;
    } else {
      _showPermissionDeniedDialog(context, 'Location');
      return false;
    }
  }

  static void _showSettingsDialog(BuildContext context, String permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
            'Please enable $permission permission in your device settings to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static void _showPermissionDeniedDialog(
      BuildContext context, String permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('$permission Permission Denied'),
        content:
            Text('Please grant $permission permission to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  static Future<bool> checkAndRequestPermission(
      BuildContext context, Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, permission.toString().split('.').last);
      return false;
    } else {
      final result = await permission.request();
      return result.isGranted;
    }
  }
}
