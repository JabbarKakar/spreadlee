import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class FileDownloader {
  static Future<String> downloadFile(String url, String? customFileName) async {
    if (url.isEmpty) {
      return 'Invalid URL';
    }

    String? ext = url.split(".").last;
    String? extension = ext.split("?").first;

    Dio dio = Dio();

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return 'Storage permission denied';
          }
        }
      }

      // Fetch the file
      Response response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode != 200) {
        return 'Failed to download file: ${response.statusCode}';
      }

      // Get the download directory path
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        return 'Could not access download directory';
      }

      // Generate a unique file name
      String fileName;
      if (customFileName == null || customFileName.isEmpty) {
        fileName =
            'downloaded_file_${DateTime.now().millisecondsSinceEpoch.toString()}.$extension';
      } else {
        fileName = '$customFileName.$extension';
      }

      // Create the file path
      String filePath = '${downloadDir.path}/$fileName';

      // Write the file
      File file = File(filePath);
      await file.writeAsBytes(response.data, flush: true);

      // Verify the file was written
      if (await file.exists()) {
        // Open the file after download
        final result = await OpenFile.open(filePath);
        if (result.type == ResultType.done) {
          return 'Download successfully completed!';
        } else {
          return 'File downloaded but could not be opened: ${result.message}';
        }
      } else {
        return 'File download failed: File not found after download';
      }
    } catch (e) {
      print('Error downloading file: $e');
      return 'Error downloading file: ${e.toString()}';
    }
  }

  static Future<XFile?> downloadFileAsXFile(
      String url, String? customFileName) async {
    if (url.isEmpty) {
      return null;
    }

    String? ext = url.split(".").last;
    String? extension = ext.split("?").first;

    Dio dio = Dio();

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return null;
          }
        }
      }

      // Fetch the file
      Response response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      // Get the download directory path
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        return null;
      }

      // Generate a unique file name
      String fileName;
      if (customFileName == null || customFileName.isEmpty) {
        fileName =
            'downloaded_file_${DateTime.now().millisecondsSinceEpoch.toString()}.$extension';
      } else {
        fileName = '$customFileName.$extension';
      }

      // Create the file path
      String filePath = '${downloadDir.path}/$fileName';

      // Write the file
      File file = File(filePath);
      await file.writeAsBytes(response.data, flush: true);

      // Verify the file was written
      if (await file.exists()) {
        return XFile(filePath);
      } else {
        return null;
      }
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }
}
