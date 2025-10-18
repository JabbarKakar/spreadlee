import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:easy_localization/easy_localization.dart';

class GalleryCamRemoveWidget extends StatefulWidget {
  final String? currentPhotoUrl;
  final Function(String) onPhotoSelected;
  final Function() onPhotoRemoved;

  const GalleryCamRemoveWidget({
    super.key,
    this.currentPhotoUrl,
    required this.onPhotoSelected,
    required this.onPhotoRemoved,
  });

  @override
  State<GalleryCamRemoveWidget> createState() => _GalleryCamRemoveWidgetState();
}

class _GalleryCamRemoveWidgetState extends State<GalleryCamRemoveWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        widget.onPhotoSelected(pickedFile.path);
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error picking image'),
            backgroundColor: ColorManager.lightError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 110.0,
      decoration: BoxDecoration(
        color: ColorManager.secondaryBackground,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Gallery Option
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(
                    Icons.photo_library,
                    color: ColorManager.blueLight800,
                    size: 28.0,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(56.0),
                      side: BorderSide(
                        color: ColorManager.blueLight800,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(14.0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Gallery'.tr(),
                  style: getRegularStyle(
                    color: ColorManager.gray500,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16.0),
            // Camera Option
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(
                    Icons.camera_alt,
                    color: ColorManager.blueLight800,
                    size: 28.0,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(56.0),
                      side: BorderSide(
                        color: ColorManager.blueLight800,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(14.0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Camera'.tr(),
                  style: getRegularStyle(
                    color: ColorManager.gray500,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
            // Remove Option (only shown if there's a current photo)
            if (widget.currentPhotoUrl != null &&
                widget.currentPhotoUrl!.isNotEmpty) ...[
              const SizedBox(width: 16.0),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Photo'.tr()),
                          content: Text(
                              'Are you sure you want to delete your profile photo?'
                                  .tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('No'.tr()),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.onPhotoRemoved();
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Yes'.tr(),
                                style:
                                    TextStyle(color: ColorManager.blueLight800),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.delete,
                      color: ColorManager.blueLight800,
                      size: 28.0,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(56.0),
                        side: BorderSide(
                          color: ColorManager.blueLight800,
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(14.0),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Delete'.tr(),
                    style: getRegularStyle(
                      color: ColorManager.blueLight800,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
