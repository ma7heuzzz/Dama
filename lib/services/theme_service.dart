import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xdama/models/theme_model.dart';
import 'package:xdama/services/auth_service.dart';

class ThemeService {
  static const String baseUrl = 'https://api.xdama.com/themes';
  final AuthService _authService;
  
  ThemeService(this._authService);
  
  // Obter todos os temas disponíveis
  Future<List<ThemeModel>> getAllThemes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['themes'];
        return data.map((theme) => ThemeModel.fromJson(theme)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter temas';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter temas: $e');
      // Retornar temas padrão em caso de erro
      return [
        ThemeModel.classicTheme(),
        ThemeModel.woodTheme(),
        ThemeModel.neonTheme(),
        ThemeModel.medievalTheme(),
        ThemeModel.pixelArtTheme(),
      ];
    }
  }
  
  // Obter temas desbloqueados pelo usuário
  Future<List<ThemeModel>> getUserThemes() async {
    if (!_authService.isAuthenticated) {
      // Se não estiver autenticado, retornar apenas o tema clássico
      return [ThemeModel.classicTheme()];
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['themes'];
        return data.map((theme) => ThemeModel.fromJson(theme)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter temas do usuário';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter temas do usuário: $e');
      // Retornar tema clássico em caso de erro
      return [ThemeModel.classicTheme()];
    }
  }
  
  // Obter detalhes de um tema específico
  Future<ThemeModel?> getThemeDetails(String themeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/theme/$themeId'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ThemeModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter detalhes do tema';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter detalhes do tema: $e');
      
      // Retornar tema padrão em caso de erro
      switch (themeId) {
        case 'classic':
          return ThemeModel.classicTheme();
        case 'wood':
          return ThemeModel.woodTheme();
        case 'neon':
          return ThemeModel.neonTheme();
        case 'medieval':
          return ThemeModel.medievalTheme();
        case 'pixel_art':
          return ThemeModel.pixelArtTheme();
        default:
          return ThemeModel.classicTheme();
      }
    }
  }
  
  // Definir tema atual do usuário
  Future<bool> setCurrentTheme(String themeId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/set-current'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'themeId': themeId}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao definir tema atual: $e');
      return false;
    }
  }
  
  // Comprar um tema
  Future<bool> purchaseTheme(String themeId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchase'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'themeId': themeId}),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao comprar tema';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao comprar tema: $e');
      return false;
    }
  }
  
  // Verificar se o usuário tem acesso a um tema específico
  Future<bool> checkThemeAccess(String themeId) async {
    if (!_authService.isAuthenticated) {
      // Se não estiver autenticado, verificar se é o tema clássico
      return themeId == 'classic';
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/access/$themeId'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasAccess'] as bool;
      } else {
        return false;
      }
    } catch (e) {
      print('Erro ao verificar acesso ao tema: $e');
      // Em caso de erro, permitir acesso apenas ao tema clássico
      return themeId == 'classic';
    }
  }
  
  // Obter tema atual do usuário
  Future<ThemeModel?> getCurrentTheme() async {
    if (!_authService.isAuthenticated) {
      return ThemeModel.classicTheme();
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/current'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ThemeModel.fromJson(data);
      } else {
        return ThemeModel.classicTheme();
      }
    } catch (e) {
      print('Erro ao obter tema atual: $e');
      return ThemeModel.classicTheme();
    }
  }
}
