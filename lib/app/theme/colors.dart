import 'package:flutter/material.dart';

class SColors {
  SColors._();

  // 🌿 App Basic Colors
  static const Color primary = Color(0xFF3FA46A); // Fresh green (main brand color)
  static const Color secondary = Color(0xFFFFC857); // Warm amber accent
  static const Color accent = Color(0xFF7ED9A0); // Soft mint accent

  // 🌈 Gradient Colors
  static const Gradient linerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3FA46A),
      Color(0xFF7ED9A0),
      Color(0xFFE8F5E9),
    ],
  );

  // 🖋️ Text Colors
  static const Color textPrimary = Color(0xFF1B4332); // Deep forest green
  static const Color textSecondary = Color(0xFF3C6E47); // Softer green-gray
  static const Color textWhite = Color(0xFFFFFFFF);

  // 🌑 Dark Mode Placeholder (for later dark theme)
  static const Color darkPrimary = Color(0xFF121212);
  static const Color darkSecondary = Color(0xFF1E1E1E);
  static const Color darkOptional = Color(0xFF2C2C2C);

  // 🪴 Background Colors
  static const Color light = Color(0xFFFDFDFB); // Soft white
  static const Color dark = Color(0xFF1E1E1E);
  static const Color primaryBackground = Color(0xFFF3F9F5); // Gentle greenish tint

  // 🧺 Container Backgrounds
  static const Color lightContainer = Color(0xFFF9FAF8);
  static Color darkContainer = SColors.white.withAlpha((0.08 * 255).round());

  // 🔘 Button Colors
  static const Color buttonPrimary = Color(0xFF3FA46A);
  static const Color buttonSecondary = Color(0xFFB7C9A9);
  static const Color buttonDisabled = Color(0xFFDADADA);

  // 📏 Border Colors
  static const Color borderPrimary = Color(0xFFE3E8E5);
  static const Color borderSecondary = Color(0xFFE9EDEA);

  // ⚠️ Status Colors
  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF3FA46A);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF2196F3);

  // ⚫ Neutral Shades
  static const Color black = Color(0xFF1A1A1A);
  static const Color darkerGrey = Color(0xFF3D3D3D);
  static const Color darkGrey = Color(0xFF707070);
  static const Color grey = Color(0xFFDADADA);
  static const Color softGrey = Color(0xFFF1F3F2);
  static const Color lightGrey = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);

  // Light theme container colors
  static const Color lightPrimaryContainer = Color(0xFFE8F5E9);   // very light green tint – for cards, highlights
  static const Color lightSecondaryContainer = Color(0xFFF3F9F5); // subtle greenish background – for secondary panels
  static const Color lightOptionalContainer = Color(0xFFF9FAF8);  // near-white neutral – for general surfaces

  // Dark theme container colors
  static const Color darkPrimaryContainer = Color(0xFF2C2C2C);   // deep neutral grey – main card color
  static const Color darkSecondaryContainer = Color(0xFF1E1E1E); // base scaffold background
  static const Color darkOptionalContainer = Color(0xFF121212);  // darker layer for elevated contrast

}
