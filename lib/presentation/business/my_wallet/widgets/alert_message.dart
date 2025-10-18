import 'package:flutter/material.dart';
import '../../../resources/color_manager.dart';

class AlertMessage extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onDismiss;

  const AlertMessage({
    Key? key,
    required this.message,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: ColorManager.gray200,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20.0),
              color: ColorManager.gray400,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
