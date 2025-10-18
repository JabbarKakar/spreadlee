import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spreadlee/presentation/business/chat/widget/permission.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io' show Platform;

class PhotoAttachmentWidget extends StatefulWidget {
  final Function(List<String> photoPaths) onPhotosSelected;
  final VoidCallback? onClose;

  const PhotoAttachmentWidget({
    super.key,
    required this.onPhotosSelected,
    this.onClose,
  });

  @override
  State<PhotoAttachmentWidget> createState() => _PhotoAttachmentWidgetState();
}

class _PhotoAttachmentWidgetState extends State<PhotoAttachmentWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  Future<bool> _requestPhotosPermission() async {
    try {
      if (Platform.isIOS) {
        return await getPermissionStatus(photoLibraryPermission);
      } else if (Platform.isAndroid) {
        await requestPermission(photoLibraryPermission);
        return await getPermissionStatus(photoLibraryPermission);
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to request photos permission'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _requestCameraPermission() async {
    try {
      await requestPermission(cameraPermission);
      return await getPermissionStatus(cameraPermission);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const  SnackBar(
            content:
                Text('Failed to request camera permission'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _pickFromGallery() async {
    if (!mounted) return;

    try {
      final hasPermission = await _requestPhotosPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission to access photos was denied'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (!mounted) return;

      if (image != null) {
        widget.onPhotosSelected([image.path]);
        Navigator.pop(context);
        widget.onClose?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
       const   SnackBar(
            content: Text('Error picking image'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (!mounted) return;

    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission to access camera was denied'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      debugPrint('Starting camera...');
      setState(() => _isLoading = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      debugPrint('Camera result: ${image?.path}');

      if (!mounted) return;

      if (image != null) {
        widget.onPhotosSelected([image.path]);
        Navigator.pop(context);
        widget.onClose?.call();
      }
    } catch (e) {
      debugPrint('Error in _pickFromCamera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const   SnackBar(
            content: Text('Error taking photo'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ColorManager.gray200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    'Add Photo',
                    style: TextStyle(
                      color: ColorManager.gray900,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onClose?.call();
                    },
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOption(
                      icon: FontAwesomeIcons.image,
                      label: 'Gallery',
                      onTap: _pickFromGallery,
                    ),
                    _buildOption(
                      icon: FontAwesomeIcons.camera,
                      label: 'Camera',
                      onTap: _pickFromCamera,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('Tapped $label option');
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ColorManager.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: ColorManager.blueLight800,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: ColorManager.gray700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
