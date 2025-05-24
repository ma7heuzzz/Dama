import 'package:flutter/material.dart';
import 'package:xdama/models/user_model.dart';
import 'package:xdama/services/user_service.dart';
import 'package:xdama/services/websocket_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  final UserService _userService = UserService();
  final WebSocketService _webSocketService = WebSocketService();
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get nickname => _currentUser?.nickname;

  // Inicializar o provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasUser = await _userService.hasUser();
      if (hasUser) {
        _currentUser = await _userService.getUser();
        // Sincronizar nickname com WebSocketService
        if (_currentUser != null && _currentUser!.nickname.isNotEmpty) {
          _webSocketService.connect(_currentUser!.nickname);
        }
      }
    } catch (e) {
      print('Erro ao inicializar UserProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Salvar usuário
  Future<bool> saveUser(String nickname) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = UserModel(
        nickname: nickname,
      );

      final success = await _userService.saveUser(user);
      if (success) {
        _currentUser = user;
        // Sincronizar nickname com WebSocketService
        _webSocketService.connect(nickname);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao salvar usuário: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualizar usuário
  Future<bool> updateUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _userService.saveUser(user);
      if (success) {
        final oldNickname = _currentUser?.nickname;
        _currentUser = user;
        
        // Se o nickname mudou, atualizar no WebSocketService
        if (oldNickname != user.nickname) {
          print('Nickname alterado de $oldNickname para ${user.nickname}');
          _webSocketService.updateNickname(user.nickname);
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}
