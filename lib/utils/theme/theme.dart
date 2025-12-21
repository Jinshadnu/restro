import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFD62128);
  static const Color primaryLight = Color(0xFFF7722F);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondaryColor = Color(0xFFEC4899);
  static const Color tertiaryColor = Color(0xFF1488A6);
  static const kAccentColor = Color(0xFFFBDA10);
  static const Color primaryRed = Color(0xFFD62128);
  static const Color yellow = Color(0xFFFED51F);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color cardShadow = Colors.black12;

  static const List<Color> primaryGradient = [primaryColor, primaryLight];

  static const Color backGroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF1E2938);
  static const Color textSecondary = Color(0xFF647488);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData get lightTheme {
    return ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backGroundColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: tertiaryColor,
          surface: surfaceColor,
          error: error,
        ),
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
            displayLarge: TextStyle(
                color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(
                color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(
              color: textPrimary,
              fontSize: 16,
            ),
            bodyMedium: TextStyle(
              color: textSecondary,
              fontSize: 14,
            )));
  }
}
