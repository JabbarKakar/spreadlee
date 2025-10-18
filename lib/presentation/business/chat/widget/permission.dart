import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';


const kPermissionStateToBool = {
  PermissionStatus.granted: true,
  PermissionStatus.limited: true,
  PermissionStatus.denied: false,
  PermissionStatus.restricted: false,
  PermissionStatus.permanentlyDenied: false,
};

const cameraPermission = Permission.camera;
const photoLibraryPermission = Permission.photos;
const microphonePermission = Permission.microphone;
const locationPermission = Permission.location;

Future<bool> getPermissionStatus(Permission setting) async {
  final status = await setting.status;
  return kPermissionStateToBool[status]!;
}

Future<void> requestPermission(Permission setting) async {
  if (setting == Permission.photos && Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt <= 32) {
      await Permission.storage.request();
    } else {
      await Permission.photos.request();
    }
  }
  await setting.request();
}
