import 'package:flutter/material.dart';



import 'font_manager.dart';

TextStyle _getTextStyle(double fontSize, FontWeight fontWeight, Color color,) {
  return TextStyle(
    fontSize: fontSize, fontFamily: 'Tajawal',
    color: color,
    fontWeight: fontWeight,
  );
}

// get regular style

TextStyle getRegularStyle(
    {double fontSize = FontSize.s12, required Color color}) {
  return _getTextStyle(fontSize, FontManager.regular, color);
}

// get medium style

TextStyle getMediumStyle(
    {double fontSize = FontSize.s12, required Color color }) {
  return _getTextStyle(fontSize, FontManager.medium, color ,);
}

// get semiBold style

TextStyle getSemiBoldStyle(
    {double fontSize = FontSize.s12, required Color color }) {
  return _getTextStyle(fontSize, FontManager.semiBold, color);
}
// get medium style

TextStyle getBoldStyle(
    {double fontSize = FontSize.s12, required Color color}) {
  return _getTextStyle(fontSize, FontManager.bold, color);
}

