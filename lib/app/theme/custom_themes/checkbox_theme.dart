import 'package:flutter/material.dart';

import '../colors.dart';

class SCheckboxTheme {
  SCheckboxTheme._();

  static CheckboxThemeData lightCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    checkColor: WidgetStateProperty.all(SColors.textWhite),
    fillColor: WidgetStateProperty.resolveWith((states) =>
    states.contains(WidgetState.selected)
        ? SColors.primary
        : Colors.transparent),
  );

  static CheckboxThemeData darkCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    checkColor: WidgetStateProperty.all(SColors.textPrimary),
    fillColor: WidgetStateProperty.resolveWith((states) =>
    states.contains(WidgetState.selected)
        ? SColors.accent
        : Colors.transparent),
  );
}
