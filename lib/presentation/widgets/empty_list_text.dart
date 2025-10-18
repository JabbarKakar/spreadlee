import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';

class EmptyListText extends StatelessWidget {
  final String text;
  final bool grey400;

  const EmptyListText({
    super.key,
    required this.text,
    this.grey400 = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: getRegularStyle(
          color: grey400 ? ColorManager.grey400 : ColorManager.primaryText,
          fontSize: 16.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
