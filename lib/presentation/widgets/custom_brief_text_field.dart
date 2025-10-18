import 'package:flutter/material.dart';
import '../resources/value_manager.dart';

class CustomBriefTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType keyboardType;
  final String labelText;

  const CustomBriefTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    required this.keyboardType,
    required this.labelText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.s8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16,
          vertical: AppPadding.p12,
        ),
      ),
    );
  }
}
