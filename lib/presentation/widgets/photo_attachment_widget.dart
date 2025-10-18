import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (!status.isGranted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Permission Required'),
            content: Text(
              'Please allow ${permission == Permission.camera ? 'camera' : 'photo library'} access to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    await _requestPermission(Permission.photos);
    if (await Permission.photos.isGranted) {
      try {
        setState(() => _isLoading = true);
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );

        if (image != null) {
          widget.onPhotosSelected([image.path]);
          if (mounted) {
            Navigator.pop(context);
            widget.onClose?.call();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Error picking image')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickFromCamera() async {
    await _requestPermission(Permission.camera);
    if (await Permission.camera.isGranted) {
      try {
        setState(() => _isLoading = true);
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );

        if (image != null) {
          widget.onPhotosSelected([image.path]);
          if (mounted) {
            Navigator.pop(context);
            widget.onClose?.call();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const  SnackBar(content: Text('Error taking photo')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onClose?.call();
                    },
                    icon: const Icon(Icons.close),
                    color: ColorManager.gray500,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOption(
                    icon: FontAwesomeIcons.image,
                    label: 'Gallery',
                    onTap: _isLoading ? null : _pickFromGallery,
                  ),
                  _buildOption(
                    icon: FontAwesomeIcons.camera,
                    label: 'Camera',
                    onTap: _isLoading ? null : _pickFromCamera,
                  ),
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.0,
            height: 56.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorManager.blueLight800,
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              color: ColorManager.blueLight800,
              size: 28.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            label,
            style: const TextStyle(
              color: ColorManager.gray500,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
