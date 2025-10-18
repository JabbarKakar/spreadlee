import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';

class CustomFilePicker extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final Function(String) onFileSelected;
  final bool pdfOnly;
  final String? errorMessage;

  const CustomFilePicker({
    Key? key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    required this.onFileSelected,
    this.pdfOnly = false,
    this.errorMessage,
  }) : super(key: key);

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: pdfOnly ? FileType.custom : FileType.any,
      allowedExtensions: pdfOnly ? ['pdf'] : null,
      allowMultiple: false,
    );

    if (result != null) {
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name.toLowerCase();

      // Validate PDF file if pdfOnly is true
      if (pdfOnly && !fileName.endsWith('.pdf')) {
        _showErrorDialog('Please select a PDF file only.');
        return;
      }

      onFileSelected(filePath);
    }
  }

  void _showErrorDialog(String message) {
    // This would need to be called with a context, but for now we'll handle it in the parent
    // The parent component should handle showing error messages
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: true,
          decoration: InputDecoration(
            labelText: labelText,
            suffixIcon: IconButton(
              icon: Icon(
                Icons.upload_file_rounded,
                color: ColorManager.blueLight800,
              ),
              onPressed: () => _pickFile(),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
        ),
        if (errorMessage != null && errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
