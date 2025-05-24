// Arquivo de integração para autenticação e gerenciamento de usuários
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xdama/models/user_model_extended.dart';

class AuthService {
  static const String baseUrl = 'https://api.xdama.com/auth'; // URL base para API de autenticação
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Token JWT atual
  String? _token;
  // Usuário atual
  UserModel? _currentUser;
  
  // Getters
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;
  
  // Inicializar o serviço
  Future<void> initialize() async {
    await _loadStoredAuth();
  }
  
  // Carregar autenticação armazenada localmente
  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(tokenKey);
      final storedUserJson = prefs.getString(userKey);
      
      if (storedToken != null && storedUserJson != null) {
        _token = storedToken;
        _currentUser = UserModel.fromJson(jsonDecode(storedUserJson));
        
        // Verificar se o token ainda é válido
        final isValid = await _validateToken();
        if (!isValid) {
          await logout();
        }
      }
    } catch (e) {
      print('Erro ao carregar autenticação: $e');
      await logout();
    }
  }
  
  // Validar token atual
  Future<bool> _validateToken() async {
    if (_token == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/validate'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao validar token: $e');
      return false;
    }
  }
  
  // Registrar novo usuário
  Future<UserModel?> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'nickname': nickname,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        
        // Salvar localmente
        await _saveAuth();
        
        return _currentUser;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao registrar';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao registrar: $e');
      return null;
    }
  }
  
  // Login com email e senha
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        
        // Salvar localmente
        await _saveAuth();
        
        return _currentUser;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao fazer login';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      return null;
    }
  }
  
  // Logout
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);
    } catch (e) {
      print('Erro ao limpar dados de autenticação: $e');
    }
  }
  
  // Recuperar senha
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao solicitar recuperação de senha: $e');
      return false;
    }
  }
  
  // Atualizar perfil do usuário
  Future<UserModel?> updateProfile({
    String? nickname,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    if (_token == null || _currentUser == null) return null;
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nickname': nickname,
          'avatarUrl': avatarUrl,
          'preferences': preferences,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserModel.fromJson(data['user']);
        
        // Atualizar dados locais
        await _saveAuth();
        
        return _currentUser;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao atualizar perfil';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      return null;
    }
  }
  
  // Alterar senha
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null) return false;
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao alterar senha: $e');
      return false;
    }
  }
  
  // Salvar dados de autenticação localmente
  Future<void> _saveAuth() async {
    if (_token == null || _currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, _token!);
      await prefs.setString(userKey, jsonEncode(_currentUser!.toJson()));
    } catch (e) {
      print('Erro ao salvar dados de autenticação: $e');
    }
  }
}
