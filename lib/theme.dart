import 'package:flutter/material.dart';

/// Dark-gold theme matching the desktop radio_player.py / radio-widget.html look.
class AppColors {
  static const background = Color(0xFF111110);
  static const panel = Color(0xFF1A1A18);
  static const border = Color(0xFF2C2C28);
  static const gold = Color(0xFFC8A96E);
  static const goldLight = Color(0xFFE8C97A);
  static const text = Color(0xFFE4E0D8);
  static const textMuted = Color(0xFF5C5A54);
  static const live = Color(0xFF4CAF7D);
  static const error = Color(0xFFE05252);
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.gold,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldLight,
      surface: AppColors.panel,
      error: AppColors.error,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.panel,
      foregroundColor: AppColors.text,
      elevation: 0,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.gold,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.gold,
      overlayColor: Color(0x22C8A96E),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text),
      bodySmall: TextStyle(color: AppColors.textMuted),
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
    dividerColor: AppColors.border,
  );
}
