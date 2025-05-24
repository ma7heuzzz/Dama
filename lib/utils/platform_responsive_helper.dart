import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:xdama/utils/constants.dart';

class PlatformResponsiveHelper {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  static bool get isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS || 
                                          defaultTargetPlatform == TargetPlatform.windows || 
                                          defaultTargetPlatform == TargetPlatform.linux);
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // Retorna o tamanho adequado para elementos baseado na plataforma
  static double getResponsiveSize(BuildContext context, double size) {
    if (isWeb) {
      // Ajuste para web
      return size * 1.2;
    } else if (isIOS) {
      // Ajuste para iOS
      return size * 1.1;
    } else {
      // Android e outros
      return size;
    }
  }

  // Retorna o padding adequado baseado na plataforma
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isWeb) {
      // Mais espaço para web
      return const EdgeInsets.all(AppDimensions.paddingLarge);
    } else if (isDesktop) {
      // Mais espaço para desktop
      return const EdgeInsets.all(AppDimensions.paddingLarge);
    } else {
      // Mobile (Android e iOS)
      return const EdgeInsets.all(AppDimensions.paddingMedium);
    }
  }

  // Verifica se o dispositivo tem suporte a áudio
  static bool hasAudioSupport() {
    if (kIsWeb) {
      // WebRTC tem limitações em alguns navegadores
      return true; // Idealmente, verificaríamos o navegador específico
    } else {
      return true; // Dispositivos móveis geralmente têm suporte
    }
  }

  // Ajusta o layout baseado na orientação e tamanho da tela
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  // Retorna o tamanho adequado para o tabuleiro baseado no tamanho da tela
  static double getBoardSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Usar o menor valor entre largura e altura, com margem
    final availableSpace = screenWidth < screenHeight 
        ? screenWidth - (AppDimensions.paddingMedium * 2)
        : screenHeight - (AppDimensions.paddingMedium * 2) - 200; // Espaço para outros elementos
    
    return availableSpace;
  }
}
