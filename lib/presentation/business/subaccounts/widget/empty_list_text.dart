import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';

class EmptyListText extends StatelessWidget {
  final String text;
  final bool grey400;

  const EmptyListText({
    super.key,
    required this.text,
    this.grey400 = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: grey400 ? ColorManager.gray400 : ColorManager.gray500,
        ),
      ),
    );
  }
}
