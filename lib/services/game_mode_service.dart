import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xdama/models/game_mode_model.dart';
import 'package:xdama/services/auth_service.dart';

class GameModeService {
  static const String baseUrl = 'https://api.xdama.com/game-modes';
  final AuthService _authService;
  
  GameModeService(this._authService);
  
  // Obter todos os modos de jogo disponíveis
  Future<List<GameModeModel>> getAllGameModes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['gameModes'];
        return data.map((mode) => GameModeModel.fromJson(mode)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter modos de jogo';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter modos de jogo: $e');
      return [
        // Retornar modos padrão em caso de erro
        GameModeModel.standardMode(),
        GameModeModel.blitzMode(),
        GameModeModel.casualMode(),
      ];
    }
  }
  
  // Obter detalhes de um modo de jogo específico
  Future<GameModeModel?> getGameModeDetails(String modeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mode/$modeId'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GameModeModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter detalhes do modo de jogo';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter detalhes do modo de jogo: $e');
      
      // Retornar modo padrão em caso de erro
      switch (modeId) {
        case 'standard':
          return GameModeModel.standardMode();
        case 'blitz':
          return GameModeModel.blitzMode();
        case 'international':
          return GameModeModel.internationalMode();
        case 'tournament':
          return GameModeModel.tournamentMode();
        case 'casual':
          return GameModeModel.casualMode();
        case 'daily_challenge':
          return GameModeModel.dailyChallengeMode();
        default:
          return GameModeModel.standardMode();
      }
    }
  }
  
  // Obter modos de jogo disponíveis para o usuário atual
  Future<List<GameModeModel>> getAvailableGameModes() async {
    if (!_authService.isAuthenticated) {
      // Se não estiver autenticado, retornar apenas modos básicos
      return [
        GameModeModel.standardMode(),
        GameModeModel.casualMode(),
      ];
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/available'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['gameModes'];
        return data.map((mode) => GameModeModel.fromJson(mode)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter modos de jogo disponíveis';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter modos de jogo disponíveis: $e');
      // Retornar modos padrão em caso de erro
      return [
        GameModeModel.standardMode(),
        GameModeModel.blitzMode(),
        GameModeModel.casualMode(),
      ];
    }
  }
  
  // Obter o desafio diário
  Future<GameModeModel?> getDailyChallenge() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-challenge'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GameModeModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter desafio diário';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter desafio diário: $e');
      return GameModeModel.dailyChallengeMode();
    }
  }
  
  // Verificar se o usuário tem acesso a um modo de jogo específico
  Future<bool> checkGameModeAccess(String modeId) async {
    if (!_authService.isAuthenticated) {
      // Se não estiver autenticado, verificar se é um modo básico
      return modeId == 'standard' || modeId == 'casual';
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/access/$modeId'),
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
      print('Erro ao verificar acesso ao modo de jogo: $e');
      // Em caso de erro, permitir acesso apenas aos modos básicos
      return modeId == 'standard' || modeId == 'casual';
    }
  }
}
