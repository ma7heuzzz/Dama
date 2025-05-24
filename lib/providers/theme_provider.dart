import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdama/models/theme_model.dart';
import 'package:xdama/services/theme_service.dart';
import 'package:xdama/utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService;
  
  ThemeModel _currentTheme = ThemeModel.classicTheme();
  List<ThemeModel> _availableThemes = [ThemeModel.classicTheme()];
  bool _isLoading = false;
  String? _errorMessage;
  
  ThemeProvider(this._themeService) {
    _initializeThemes();
  }
  
  // Getters
  ThemeModel get currentTheme => _currentTheme;
  List<ThemeModel> get availableThemes => _availableThemes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Inicializar temas
  Future<void> _initializeThemes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Carregar tema atual
      final currentTheme = await _themeService.getCurrentTheme();
      if (currentTheme != null) {
        _currentTheme = currentTheme;
      }
      
      // Carregar temas disponíveis
      final themes = await _themeService.getUserThemes();
      if (themes.isNotEmpty) {
        _availableThemes = themes;
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar temas: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Atualizar tema atual
  Future<bool> setCurrentTheme(String themeId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Verificar se o tema está disponível
      final themeExists = _availableThemes.any((theme) => theme.id == themeId);
      if (!themeExists) {
        throw Exception('Tema não disponível');
      }
      
      // Atualizar no servidor
      final success = await _themeService.setCurrentTheme(themeId);
      if (success) {
        // Atualizar localmente
        final theme = _availableThemes.firstWhere((theme) => theme.id == themeId);
        _currentTheme = theme;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        throw Exception('Falha ao atualizar tema');
      }
    } catch (e) {
      _errorMessage = 'Erro ao atualizar tema: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Comprar um novo tema
  Future<bool> purchaseTheme(String themeId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Verificar se o tema já está disponível
      final themeExists = _availableThemes.any((theme) => theme.id == themeId);
      if (themeExists) {
        throw Exception('Tema já adquirido');
      }
      
      // Comprar no servidor
      final success = await _themeService.purchaseTheme(themeId);
      if (success) {
        // Atualizar lista de temas disponíveis
        await refreshAvailableThemes();
        _errorMessage = null;
        return true;
      } else {
        throw Exception('Falha ao comprar tema');
      }
    } catch (e) {
      _errorMessage = 'Erro ao comprar tema: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Atualizar lista de temas disponíveis
  Future<void> refreshAvailableThemes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Carregar temas disponíveis
      final themes = await _themeService.getUserThemes();
      if (themes.isNotEmpty) {
        _availableThemes = themes;
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar temas disponíveis: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Verificar se um tema está desbloqueado
  bool isThemeUnlocked(String themeId) {
    return _availableThemes.any((theme) => theme.id == themeId && theme.isUnlocked);
  }
  
  // Obter cores do tema atual
  Color getBoardLightColor() {
    final colorHex = _currentTheme.themeData['boardColors']['light'] as String;
    return _hexToColor(colorHex);
  }
  
  Color getBoardDarkColor() {
    final colorHex = _currentTheme.themeData['boardColors']['dark'] as String;
    return _hexToColor(colorHex);
  }
  
  Color getWhitePieceColor() {
    final colorHex = _currentTheme.themeData['pieceColors']['white'] as String;
    return _hexToColor(colorHex);
  }
  
  Color getBlackPieceColor() {
    final colorHex = _currentTheme.themeData['pieceColors']['black'] as String;
    return _hexToColor(colorHex);
  }
  
  Color getHighlightColor() {
    final colorHex = _currentTheme.themeData['highlightColor'] as String;
    return _hexToColor(colorHex);
  }
  
  // Converter hex para Color
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
