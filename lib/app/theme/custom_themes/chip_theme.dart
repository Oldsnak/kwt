import 'package:flutter/material.dart';
import '../colors.dart';

class SChipTheme {
  SChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    disabledColor: SColors.softGrey,
    labelStyle: const TextStyle(color: SColors.textPrimary),
    selectedColor: SColors.accent,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    checkmarkColor: SColors.textWhite,
    backgroundColor: SColors.primaryBackground,
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
    disabledColor: SColors.darkGrey,
    labelStyle: const TextStyle(color: SColors.textWhite),
    selectedColor: SColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    checkmarkColor: SColors.textWhite,
    backgroundColor: SColors.darkOptional,
  );
}
