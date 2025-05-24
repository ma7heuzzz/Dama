import 'package:flutter/material.dart';

class ResponsiveSplashLayout extends StatelessWidget {
  final Widget child;
  
  const ResponsiveSplashLayout({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obter o tamanho da tela
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 900;
    
    // Ajustar o tamanho do logo com base no tamanho da tela
    double logoSize = isSmallScreen ? 150 : (isMediumScreen ? 200 : 250);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: logoSize,
          height: logoSize,
          child: child,
        ),
      ),
    );
  }
}
