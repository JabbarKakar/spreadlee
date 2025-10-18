import 'package:flutter/material.dart';
import '../../../resources/color_manager.dart';

class IndicatePageTab extends StatelessWidget {
  final String text;
  final bool isActive;

  const IndicatePageTab({
    Key? key,
    required this.text,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? ColorManager.blueLight800 : Colors.transparent,
            width: 2.0,
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: isActive ? ColorManager.blueLight800 : ColorManager.gray600,
            fontSize: 12.0,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w300,
            fontFamily: 'Poppins'),
      ),
    );
  }
}
