import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xdama/models/ranking_model.dart';
import 'package:xdama/services/auth_service.dart';

class RankingService {
  static const String baseUrl = 'https://api.xdama.com/ranking';
  final AuthService _authService;
  
  RankingService(this._authService);
  
  // Obter ranking global de jogadores
  Future<List<RankingModel>> getGlobalRanking({int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/global?limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['rankings'];
        return data.map((rank) => RankingModel.fromJson(rank)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter ranking global';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter ranking global: $e');
      return [];
    }
  }
  
  // Obter ranking do usuário atual
  Future<RankingModel?> getUserRanking() async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
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
        final data = jsonDecode(response.body);
        return RankingModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter ranking do usuário';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter ranking do usuário: $e');
      return null;
    }
  }
  
  // Obter ranking por tier (bronze, silver, gold, etc.)
  Future<List<RankingModel>> getRankingByTier(String tier, {int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tier/$tier?limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['rankings'];
        return data.map((rank) => RankingModel.fromJson(rank)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter ranking por tier';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter ranking por tier: $e');
      return [];
    }
  }
  
  // Obter ranking de amigos
  Future<List<RankingModel>> getFriendsRanking() async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['rankings'];
        return data.map((rank) => RankingModel.fromJson(rank)).toList();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter ranking de amigos';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter ranking de amigos: $e');
      return [];
    }
  }
  
  // Obter informações da temporada atual
  Future<Map<String, dynamic>?> getCurrentSeason() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/season/current'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.isAuthenticated) 'Authorization': 'Bearer ${_authService.token}',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao obter informações da temporada';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao obter informações da temporada: $e');
      return null;
    }
  }
  
  // Calcular pontuação ELO após uma partida
  Future<Map<String, dynamic>?> calculateEloChange(String winnerId, String loserId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculate-elo'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'winnerId': winnerId,
          'loserId': loserId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Erro ao calcular pontuação ELO';
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao calcular pontuação ELO: $e');
      return null;
    }
  }
}
