import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xdama/models/user_model.dart';

class UserService {
  static const String _userKey = 'user_data';
  static UserModel? _cachedUser;
  
  // Salvar dados do usuário
  Future<bool> saveUser(UserModel user) async {
    try {
      // Salvar em cache
      _cachedUser = user;
      
      // Salvar em armazenamento persistente
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonEncode({
        'nickname': user.nickname,
      });
      
      await prefs.setString(_userKey, userData);
      print('Usuário salvo localmente: ${user.nickname}');
      return true;
    } catch (e) {
      print('Erro ao salvar usuário: $e');
      return false;
    }
  }
  
  // Verificar se o usuário já existe
  Future<bool> hasUser() async {
    if (_cachedUser != null) {
      return true;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userKey);
    } catch (e) {
      print('Erro ao verificar usuário: $e');
      return false;
    }
  }
  
  // Obter dados do usuário
  Future<UserModel?> getUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      
      if (userData != null) {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        _cachedUser = UserModel(
          nickname: userMap['nickname'],
        );
        return _cachedUser;
      }
      
      return null;
    } catch (e) {
      print('Erro ao obter usuário: $e');
      return null;
    }
  }
  
  // Limpar dados do usuário
  Future<bool> clearUser() async {
    try {
      _cachedUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      return true;
    } catch (e) {
      print('Erro ao limpar usuário: $e');
      return false;
    }
  }
}
