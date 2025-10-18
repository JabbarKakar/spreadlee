import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../resources/color_manager.dart';

class CustomBriefTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType keyboardType;
  final String labelText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final double fontSize;
  final double borderRadius;
  final double borderWidth;
  final double padding;
  final double height;

  const CustomBriefTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    required this.keyboardType,
    required this.labelText,
    this.onChanged,
    this.validator,
    this.fontSize = 12.0,
    this.borderRadius = 12.0,
    this.borderWidth = 3.0,
    this.padding = 16.0,
    this.height = 200.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: padding),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(borderRadius),
              border: isFocused
                  ? Border.all(color: ColorManager.blueLight800, width: 1.5)
                  : null,
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: keyboardType,
              onChanged: onChanged,
              validator: validator,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: labelText.tr(),
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.greycard,
                  letterSpacing: 2.0,
                ),
                border: InputBorder.none,
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                contentPadding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              ),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
