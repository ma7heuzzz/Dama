import 'package:flutter/material.dart';
import 'package:xdama/utils/constants.dart';

class AppTheme {
  // Fontes personalizadas
  static const String primaryFontFamily = 'Montserrat';
  static const String secondaryFontFamily = 'Roboto';
  
  // Ícones vetoriais comuns
  static const IconData iconHome = Icons.home;
  static const IconData iconPlay = Icons.play_arrow;
  static const IconData iconSettings = Icons.settings;
  static const IconData iconMic = Icons.mic;
  static const IconData iconMicOff = Icons.mic_off;
  static const IconData iconPlus = Icons.add;
  static const IconData iconRefresh = Icons.refresh;
  static const IconData iconLogout = Icons.exit_to_app;
  static const IconData iconUser = Icons.person;
  static const IconData iconUsers = Icons.people;
  static const IconData iconCheck = Icons.check;
  static const IconData iconX = Icons.close;
  static const IconData iconStar = Icons.star;
  static const IconData iconAward = Icons.emoji_events; // Substituído crown por emoji_events
  
  // Tema claro
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: Colors.grey[100],
      fontFamily: primaryFontFamily,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
          letterSpacing: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
          letterSpacing: 1.0,
        ),
        bodyLarge: TextStyle(
          fontFamily: secondaryFontFamily,
          fontSize: 16,
          color: AppColors.black,
        ),
        bodyMedium: TextStyle(
          fontFamily: secondaryFontFamily,
          fontSize: 14,
          color: AppColors.black,
        ),
        labelLarge: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: AppColors.white,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accent.withOpacity(0.7),
        surface: Colors.white,
        background: Colors.grey[100]!,
      ),
    );
  }
  
  // Tema escuro (usado no app)
  static ThemeData darkTheme() {
    return ThemeData(
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: primaryFontFamily,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
          letterSpacing: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
          letterSpacing: 1.0,
        ),
        bodyLarge: TextStyle(
          fontFamily: secondaryFontFamily,
          fontSize: 16,
          color: AppColors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: secondaryFontFamily,
          fontSize: 14,
          color: AppColors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: AppColors.white,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent.withOpacity(0.7),
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
