// app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color white = Colors.white;
  static const Color darkGray = Color(0xFF333333);
  static const Color redPink = Color(0xFFD53A47);
  static const String fontFamily = 'Lato';

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: white,
    primaryColor: redPink,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: redPink,
      onPrimary: white,
      secondary: darkGray,
      onSecondary: white,
      error: Colors.red,
      onError: white,
      surface: white,
      onSurface: darkGray,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: redPink,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkGray),
      bodyMedium: TextStyle(color: darkGray),
      titleLarge: TextStyle(
        color: darkGray,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: redPink,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: redPink,
          width: 2,
        ),
      ),
    ),
  );
}