import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF212121);
  static const Color surface = Color(0xFF303030);
  static const Color cardBackground = Color(0xFF303030); // Adicionado para corrigir erro
  static const Color accent = Color(0xFF7C4DFF);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color lightGrey = Color(0xFFBDBDBD);
  static const Color darkGrey = Color(0xFF424242);
  static const Color error = Color(0xFFCF6679);
  
  // Cores adicionadas para corrigir erros de referência
  static const Color primary = Color(0xFF7C4DFF); // Mesma cor do accent
  static const Color success = Color(0xFF4CAF50); // Verde para indicar sucesso
  static const Color blackCell = Color(0xFF424242); // Para o tabuleiro
  static const Color whiteCell = Color(0xFFE0E0E0); // Para o tabuleiro
  static const Color selectedCell = Color(0xFF7C4DFF); // Mesma cor do accent
  static const Color validMoveCell = Color(0x667C4DFF); // Accent com transparência
  static const Color whitePiece = Colors.white;
  static const Color blackPiece = Color(0xFF212121);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 1.2,
  );
  
  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.8,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.white,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.lightGrey,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    color: AppColors.white,
  );
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
}
