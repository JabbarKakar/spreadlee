import 'package:flutter/material.dart';
import '/presentation/resources/color_manager.dart';
import '/presentation/resources/style_manager.dart';

class SettingsContactCardsWidget extends StatefulWidget {
  const SettingsContactCardsWidget({
    super.key,
    required this.icon,
    required this.text,
  });

  final Icon icon;
  final String text;

  @override
  State<SettingsContactCardsWidget> createState() =>
      _SettingsContactCardsWidgetState();
}

class _SettingsContactCardsWidgetState
    extends State<SettingsContactCardsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: ColorManager.blueLight800,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            widget.icon,
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                widget.text,
                style: getMediumStyle(
                  fontSize: 14.0,
                  color: ColorManager.primaryText,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ColorManager.blueLight800,
              size: 24.0,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsContactCardsModel {
  /// Initialization and disposal methods.
  void initState(BuildContext context) {}
  void dispose() {}
}
