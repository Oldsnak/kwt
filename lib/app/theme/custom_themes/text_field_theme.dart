import 'package:flutter/material.dart';
import '../colors.dart';

class STextFormFieldTheme {
  STextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    prefixIconColor: SColors.primary,
    suffixIconColor: SColors.primary,
    labelStyle: const TextStyle(fontSize: 14, color: SColors.textPrimary),
    hintStyle: const TextStyle(fontSize: 14, color: SColors.textSecondary),
    floatingLabelStyle: const TextStyle(color: SColors.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: SColors.borderPrimary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: SColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: SColors.error),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    prefixIconColor: SColors.primary,
    suffixIconColor: SColors.primary,
    labelStyle: const TextStyle(fontSize: 14, color: SColors.textWhite),
    hintStyle: const TextStyle(fontSize: 14, color: SColors.darkGrey),
    floatingLabelStyle: const TextStyle(color: SColors.accent),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: SColors.buttonSecondary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: SColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: SColors.error),
    ),
  );
}
