import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../resources/color_manager.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType keyboardType;
  final String labelText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    required this.keyboardType,
    required this.labelText,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: false,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText.tr(), // Supports localization
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          color: ColorManager.greycard,
          letterSpacing: 1.2,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: InputBorder.none,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorManager.blueLight800,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }
}
