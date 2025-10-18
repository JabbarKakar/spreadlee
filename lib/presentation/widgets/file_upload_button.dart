import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'custom_button.dart';

class FileUploadButton extends StatelessWidget {
  final String label;
  final Function(String) onFileSelected;

  const FileUploadButton({
    Key? key,
    required this.label,
    required this.onFileSelected,
  }) : super(key: key);

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      onFileSelected(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: label,
      onPressed: _pickFile,
    );
  }
}
