import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../resources/color_manager.dart';
import '../../bloc/business/setting/setting_cubit.dart';

class ReplaceFileScreen extends StatefulWidget {
  const ReplaceFileScreen({super.key});

  @override
  State<ReplaceFileScreen> createState() => _ReplaceFileScreenState();
}

class _ReplaceFileScreenState extends State<ReplaceFileScreen> {
  bool isUploading = false;
  String? uploadedFileUrl;
  int uploadProgress = 0;

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'png',
          'jpg',
          'jpeg'
        ],
      );

      if (result != null) {
        setState(() {
          isUploading = true;
          uploadProgress = 0;
        });

        // Get the file path
        final filePath = result.files.single.path;
        if (filePath != null) {
          // Create MultipartFile from the file
          final file = await MultipartFile.fromFile(
            filePath,
            filename: result.files.single.name,
          );

          // Create a Dio instance for upload with progress tracking
          final dio = Dio();

          // Call editPricingDetails from SettingCubit with progress tracking
          await context.read<SettingCubit>().editPricingDetails(
                pricingDetails: file,
                onSendProgress: (int sent, int total) {
                  if (total != -1) {
                    setState(() {
                      uploadProgress = ((sent / total) * 100).round();
                      // Cap progress at 99% until complete
                      if (uploadProgress > 99) uploadProgress = 99;
                    });
                  }
                },
              );

          if (mounted) {
            setState(() {
              isUploading = false;
              uploadProgress = 100;
              uploadedFileUrl = filePath;
            });

            // Close the dialog
            Navigator.pop(context, uploadedFileUrl);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploading = false;
          uploadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
            content: Text('Error uploading file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.4, // Limit height to 40% of screen
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 24.0,
                        ),
                        Icon(
                          Icons.upload_file,
                          color: ColorManager.blueLight800,
                          size: 40.0,
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 18.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Are you sure you want to Replace the Pricing Details?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.normal,
                          ),
                    ),
                    const SizedBox(height: 20.0),
                    if (isUploading) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          children: [
                            Text(
                              'Uploading: $uploadProgress%',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorManager.blueLight800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: uploadProgress / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorManager.blueLight800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 14.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  isUploading ? null : _pickAndUploadFile,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ColorManager.blueLight800,
                                side: BorderSide(
                                    color: ColorManager.blueLight800),
                                minimumSize: const Size(double.infinity, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Yes',
                                      style: TextStyle(fontSize: 14),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.blueLight800,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text(
                                'No',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
