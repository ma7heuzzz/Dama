import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xdama/models/game_history_model.dart';
import 'package:xdama/services/auth_service.dart';

class GameHistoryService {
  static const String baseUrl = 'https://api.xdama.com/history';
  final AuthService _authService;
  
  GameHistoryService(this._authService);
  
  // Obter histórico de partidas do usuário atual
  Future<List<GameHistoryModel>> getUserGameHistory({int limit = 20, int offset = 0}) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['games'];
        return data.map((game) => GameHistoryModel.fromJson(game)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter histórico';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter histórico de partidas: $e');
      return [];
    }
  }
  
  // Obter detalhes de uma partida específica
  Future<GameHistoryModel?> getGameDetails(String gameId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/game/$gameId'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GameHistoryModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter detalhes da partida';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter detalhes da partida: $e');
      return null;
    }
  }
  
  // Salvar uma nova partida no histórico
  Future<bool> saveGameToHistory(GameHistoryModel game) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(game.toJson()),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao salvar partida no histórico: $e');
      return false;
    }
  }
  
  // Obter estatísticas de jogo do usuário
  Future<Map<String, dynamic>?> getUserGameStats() async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter estatísticas';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter estatísticas de jogo: $e');
      return null;
    }
  }
  
  // Obter replay de uma partida
  Future<List<GameMoveModel>?> getGameReplay(String gameId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/replay/$gameId'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['moves'];
        return data.map((move) => GameMoveModel.fromJson(move)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter replay';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter replay da partida: $e');
      return null;
    }
  }
}
