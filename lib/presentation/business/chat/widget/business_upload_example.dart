import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/business/chat/provider/chat_provider.dart';
import 'package:spreadlee/presentation/business/chat/widget/business_file_upload_helper.dart';

/// Example widget showing how to use the new upload functionality in business chat
class BusinessUploadExample extends StatelessWidget {
  final String chatId;
  final String userRole;
  final ChatProvider chatProvider;

  const BusinessUploadExample({
    Key? key,
    required this.chatId,
    required this.userRole,
    required this.chatProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business File Upload Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Business File Upload Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Image Upload Example
            ElevatedButton.icon(
              onPressed: () => _uploadImage(context),
              icon: const Icon(Icons.photo),
              label: const Text('Upload Image'),
            ),
            const SizedBox(height: 10),

            // Document Upload Example
            ElevatedButton.icon(
              onPressed: () => _uploadDocument(context),
              icon: const Icon(Icons.description),
              label: const Text('Upload Document'),
            ),
            const SizedBox(height: 10),

            // Video Upload Example
            ElevatedButton.icon(
              onPressed: () => _uploadVideo(context),
              icon: const Icon(Icons.videocam),
              label: const Text('Upload Video'),
            ),
            const SizedBox(height: 10),

            // Show Upload Options Bottom Sheet
            ElevatedButton.icon(
              onPressed: () => _showUploadOptions(context),
              icon: const Icon(Icons.attach_file),
              label: const Text('Show Upload Options'),
            ),
            const SizedBox(height: 20),

            const Text(
              'How to use in your business chat:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            const Text(
              '1. Import BusinessFileUploadHelper\n'
              '2. Call pickAndUploadImage/Document/Video with chatId and userRole\n'
              '3. Use sendMessageWithFile to send the uploaded file\n'
              '4. Or use showBusinessUploadOptions for a complete UI',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload image
      final imageUrl = await BusinessFileUploadHelper.pickAndUploadImage(
        chatId,
        userRole,
        onProgress: (progress, status) {
          print('Image upload progress: $progress - $status');
        },
      );

      // Hide loading dialog
      Navigator.pop(context);

      if (imageUrl != null) {
        // Send message with uploaded image
        await BusinessFileUploadHelper.sendMessageWithFile(
          chatProvider,
          imageUrl,
          'image',
          messageText: 'Check out this image!',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image uploaded and sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading dialog
      
    }
  }

  Future<void> _uploadDocument(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final documentUrl = await BusinessFileUploadHelper.pickAndUploadDocument(
        chatId,
        userRole,
        onProgress: (progress, status) {
          print('Document upload progress: $progress - $status');
        },
      );

      Navigator.pop(context);

      if (documentUrl != null) {
        await BusinessFileUploadHelper.sendMessageWithFile(
          chatProvider,
          documentUrl,
          'file',
          messageText: 'Here is the document you requested.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Document uploaded and sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
     
    }
  }

  Future<void> _uploadVideo(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final videoUrl = await BusinessFileUploadHelper.pickAndUploadVideo(
        chatId,
        userRole,
        onProgress: (progress, status) {
          print('Video upload progress: $progress - $status');
        },
      );

      Navigator.pop(context);

      if (videoUrl != null) {
        await BusinessFileUploadHelper.sendMessageWithFile(
          chatProvider,
          videoUrl,
          'video',
          messageText: 'Check out this video!',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Video uploaded and sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload video')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      // ScaffoldMessenger.of(context).showSnackBar(
      // const  SnackBar(content: Text('Error: Connection Error')),
      // );
    }
  }

  Future<void> _showUploadOptions(BuildContext context) async {
    await BusinessFileUploadHelper.showBusinessUploadOptions(
      context,
      chatId,
      userRole,
      chatProvider,
      onProgress: (progress, status) {
        print('Upload progress: $progress - $status');
      },
    );
  }
}
