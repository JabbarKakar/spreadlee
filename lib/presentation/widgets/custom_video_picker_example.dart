import 'package:flutter/material.dart';
import 'custom_video_picker.dart';

/// Example widget demonstrating how to use the CustomVideoPicker
class CustomVideoPickerExample extends StatefulWidget {
  const CustomVideoPickerExample({super.key});

  @override
  State<CustomVideoPickerExample> createState() =>
      _CustomVideoPickerExampleState();
}

class _CustomVideoPickerExampleState extends State<CustomVideoPickerExample> {
  String? selectedVideoPath;
  String? selectedVideoName;
  int? selectedVideoSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Video Picker Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickVideo,
              child: const Text('Pick Video'),
            ),
            const SizedBox(height: 20),
            if (selectedVideoPath != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Video:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Name: $selectedVideoName'),
                      Text('Path: $selectedVideoPath'),
                      if (selectedVideoSize != null)
                        Text(
                            'Size: ${(selectedVideoSize! / 1024 / 1024).toStringAsFixed(2)} MB'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No video selected'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Gallery-only video selection'),
            const Text('• Platform-specific permission handling'),
            const Text('• File size validation (50MB limit)'),
            const Text('• File format validation'),
            const Text('• Video duration limits (5 minutes)'),
            const Text('• No video compression (original quality)'),
            const Text('• Error dialogs for size limits and permissions'),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      // Use the CustomVideoPicker with WeChat picker API
      List<SelectedFile>? selectedMedia =
          await CustomVideoPicker.selectMediaWithWeChatPicker(
        context,
        isVideo: true,
        mediaSource: MediaSource.videoGallery,
        multiImage: false,
      );

      if (selectedMedia != null && selectedMedia.isNotEmpty) {
        final selectedFile = selectedMedia.first;

        // Check file size (50MB limit)
        if (selectedFile.bytes.length > 50 * 1024 * 1024) {
          await CustomVideoPicker.showFileSizeErrorDialog(context);
          return;
        }

        setState(() {
          selectedVideoPath = selectedFile.filePath;
          selectedVideoName = selectedFile.filePath?.split('/').last;
          selectedVideoSize = selectedFile.bytes.length;
        });

        // You can now use the selected video:
        // - selectedFile.filePath for the local file path
        // - selectedFile.bytes for the video data
        // - selectedFile.dimensions for video dimensions (if requested)
        // - selectedFile.storagePath for upload purposes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error picking video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Alternative usage example with direct video selection
class DirectVideoPickerExample extends StatelessWidget {
  const DirectVideoPickerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Video Picker Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _pickFromGallery(context),
              child: const Text('Pick from Gallery'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Only gallery selection is available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      List<SelectedFile>? selectedMedia =
          await CustomVideoPicker.selectMediaWithWeChatPicker(
        context,
        isVideo: true,
        mediaSource: MediaSource.videoGallery,
        multiImage: false,
        includeDimensions: true, // Get video dimensions
      );

      if (selectedMedia != null && selectedMedia.isNotEmpty) {
        final selectedFile = selectedMedia.first;
        _handleSelectedVideo(context, selectedFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking video')),
        );
      }
    }
  }

  void _handleSelectedVideo(BuildContext context, SelectedFile selectedFile) {
    final dimensions = selectedFile.dimensions;
    final sizeInMB = selectedFile.bytes.length / 1024 / 1024;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Selected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${selectedFile.filePath}'),
            Text('Size: ${sizeInMB.toStringAsFixed(2)} MB'),
            if (dimensions != null) ...[
              Text('Width: ${dimensions.width?.toInt()}'),
              Text('Height: ${dimensions.height?.toInt()}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
