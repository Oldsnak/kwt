import 'package:flutter/services.dart';

class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit total digits to 11
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      formatted += digits[i];

      // after 4 digits → insert dash
      if (i == 3 && digits.length > 4) {
        formatted += '-';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
