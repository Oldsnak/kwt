import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../core/utils/helpers.dart';

class GlossySnackBar {
  static void show(
      BuildContext context, {
        required String message,
        Color? textColor,
        Duration duration = const Duration(seconds: 3),
        bool isError = false,
      }) {
    final bool isDarkMode = SHelperFunctions.isDarkMode(context);

    // Background color & gradient
    final backgroundColor = isError
        ? (isDarkMode
        ? Colors.redAccent.withOpacity(0.15)
        : Colors.redAccent.withOpacity(0.3))
        : (isDarkMode
        ? SColors.darkPrimaryContainer.withOpacity(0.2)
        : SColors.lightPrimaryContainer.withOpacity(0.5));

    final gradientColors = isError
        ? [Colors.red.withOpacity(0.4), Colors.redAccent.withOpacity(0.2)]
        : isDarkMode
        ? [
      SColors.darkPrimaryContainer.withOpacity(0.6),
      SColors.darkSecondaryContainer.withOpacity(0.3),
    ]
        : [
      Colors.white.withOpacity(0.8),
      SColors.lightPrimaryContainer.withOpacity(0.6),
    ];

    final borderColor = isError
        ? Colors.redAccent.withOpacity(0.5)
        : (isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.withOpacity(0.3));

    // Build the custom snackbar
    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.3),
              offset: const Offset(3, 3),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: const Offset(-3, -3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : Colors.greenAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor ??
                      (isDarkMode ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Show it
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
