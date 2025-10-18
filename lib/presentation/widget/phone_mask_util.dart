import 'package:flutter/services.dart';

String getMask(String countryCode) {
  switch (countryCode) {
    case "+91":
      return "##########"; // Indian phone number format
    case "+93":
      return "##-###-####";
    case "+358":
      return "(###)###-##-##";
    case "+355":
      return "(###)###-###";
    case "+213":
      return "##-###-####";
    case "+1":
      return "(###)###-####";
    case "+966":
      return "##-###-####";
    // ... (add all other cases from your list as needed)
    default:
      return "##-###-####";
  }
}

class MaskTextInputFormatterFF extends TextInputFormatter {
  final String mask;
  MaskTextInputFormatterFF({required this.mask});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String maskedText = '';
    int index = 0;
    for (int i = 0; i < mask.length; i++) {
      if (index >= newValue.text.length) break;
      if (mask[i] == '#') {
        maskedText += newValue.text[index];
        index++;
      } else {
        maskedText += mask[i];
      }
    }
    return TextEditingValue(
      text: maskedText,
      selection: TextSelection.collapsed(offset: maskedText.length),
    );
  }
}
