import 'package:flutter/material.dart';

import '../colors.dart';

class SAppBarTheme {
  SAppBarTheme._();

  static final lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: SColors.textPrimary, size: 24),
    actionsIconTheme: IconThemeData(color: SColors.textPrimary, size: 24),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: SColors.textPrimary,
    ),
  );

  static final darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: SColors.darkSecondary,
    surfaceTintColor: Colors.transparent,
    iconTheme: const IconThemeData(color: SColors.textWhite, size: 24),
    actionsIconTheme: const IconThemeData(color: SColors.textWhite, size: 24),
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: SColors.textWhite,
    ),
  );
}
