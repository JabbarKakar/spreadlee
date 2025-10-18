import 'package:flutter/material.dart';

// ignore: constant_identifier_names
enum LanguageType { ENGLISH, ARABIC }

// ignore: constant_identifier_names
const String ARABIC = "ar";
// ignore: constant_identifier_names
const String ENGLISH = "en";
// ignore: constant_identifier_names
const Locale ARABIC_LOCALE = Locale("ar","SA");
// ignore: constant_identifier_names
const Locale ENGLISH_LOCALE = Locale("en","US");
// ignore: constant_identifier_names
const String ASSET_PATH_LOCALE = 'assets/localization';
extension LanguageTypeExtension on LanguageType {
  String getValue() {
    switch (this) {
      case LanguageType.ENGLISH:
        return ENGLISH;
      case LanguageType.ARABIC:
        return ARABIC;
    }
  }
}
