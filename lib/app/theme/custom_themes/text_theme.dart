import 'package:flutter/material.dart';

import '../colors.dart';

class STextTheme {
  STextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: SColors.black),
    headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: SColors.black),
    headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SColors.black),

    titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SColors.black),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: SColors.black),
    titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: SColors.black),

    bodyLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: SColors.black),
    bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: SColors.black),
    bodySmall: const TextStyle(fontSize: 14, color: SColors.black),

    labelLarge: const TextStyle(fontSize: 12, color: SColors.black),
    labelMedium: const TextStyle(fontSize: 12, color: SColors.black),
  );

  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: SColors.white),
    headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: SColors.white),
    headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SColors.white),

    titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SColors.white),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: SColors.white),
    titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: SColors.white),

    bodyLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: SColors.white),
    bodyMedium: const TextStyle(fontSize: 14, color: SColors.white),
    bodySmall: const TextStyle(fontSize: 14, color: SColors.white),

    labelLarge: const TextStyle(fontSize: 12, color: SColors.white),
    labelMedium: const TextStyle(fontSize: 12, color: SColors.white),
  );
}
