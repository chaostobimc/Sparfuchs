import 'package:flutter/material.dart';

const canvasColor = Color(0xFFF6F7F4);
const surfaceColor = Color(0xFFFFFFFF);
const inkColor = Color(0xFF2F252A);
const mutedColor = Color(0xFF829087);
const lineColor = Color(0xFFE9EDE7);
const pinkColor = Color(0xFFBD416F);
const pinkStrongColor = Color(0xFF983657);
const pinkDarkColor = Color(0xFF5A243D);
const pinkLightColor = Color(0xFFF9EAF0);
const pinkTintColor = Color(0xFFF1DCE5);
const goldColor = Color(0xFFE7BD68);

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: pinkColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: pinkColor,
    onPrimary: Colors.white,
    secondary: pinkStrongColor,
    onSecondary: Colors.white,
    surface: surfaceColor,
    outline: lineColor,
    error: const Color(0xFFB65C4E),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: canvasColor,
    splashColor: pinkLightColor.withValues(alpha: 0.45),
    highlightColor: pinkLightColor.withValues(alpha: 0.3),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: const TextStyle(color: mutedColor, fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFFB0A8AC), fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: pinkColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD98979)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD98979), width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: pinkDarkColor,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
