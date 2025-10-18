import 'package:flutter/material.dart';
import '../../../resources/color_manager.dart';

class EmptyListText extends StatelessWidget {
  final String text;

  const EmptyListText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48.0,
            color: ColorManager.gray400,
          ),
          const SizedBox(height: 16.0),
          Text(
            text,
            style: const TextStyle(
              color: ColorManager.gray600,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
