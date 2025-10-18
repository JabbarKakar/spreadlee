import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CustomFilePicker extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final void Function(String)? onFileSelected;

  const CustomFilePicker({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    this.onFileSelected,
  }) : super(key: key);

  Future<void> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? filePath = result.files.single.path; // Get full file path

      if (filePath != null) {
        controller.text = filePath; // Store full path in controller
        if (onFileSelected != null) {
          onFileSelected!(filePath); // Pass full path to callback
        }
      } else {
        controller.text = "Invalid file selected";
      }
    } else {
      controller.text = "No file selected";
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: true, // Prevent manual input
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey[100], 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none, // No border color
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: () => _pickFile(context), // Open file picker
        ),
      ),
    );
  }
}
