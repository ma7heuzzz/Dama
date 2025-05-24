import '../models/game_piece.dart';

class Player {
  final String id;
  final String nickname;

  Player({
    required this.id,
    required this.nickname,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
    };
  }
}

class RoomModel {
  final String id;
  final String creator;
  final List<Player> players;
  final dynamic board;
  final String currentTurn;

  RoomModel({
    required this.id,
    required this.creator,
    required this.players,
    this.board,
    this.currentTurn = 'white',
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Verificar se o campo 'players' existe e é uma lista
    List<Player> playersList = [];
    if (json['players'] != null && json['players'] is List) {
      playersList = (json['players'] as List<dynamic>)
          .map((player) => Player.fromJson(player as Map<String, dynamic>))
          .toList();
    }

    return RoomModel(
      id: json['id'] as String? ?? json['roomCode'] as String, // Aceitar ambos os campos
      creator: json['creator'] as String? ?? json['hostNickname'] as String? ?? '', // Aceitar ambos os campos
      players: playersList,
      board: json['board'],
      currentTurn: json['currentTurn'] as String? ?? 'white',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': id, // Adicionar para compatibilidade com o servidor
      'creator': creator,
      'hostNickname': hostNickname, // Adicionar para compatibilidade com o servidor
      'players': players.map((player) => player.toJson()).toList(),
      'playerCount': playerCount, // Adicionar para compatibilidade com o servidor
      'maxPlayers': maxPlayers, // Adicionar para compatibilidade com o servidor
      'board': board,
      'currentTurn': currentTurn,
    };
  }

  bool get isFull => players.length >= 2;
  
  // Compatibilidade com código existente
  String get roomCode => id;
  String get hostNickname => players.isNotEmpty ? players[0].nickname : '';
  int get playerCount => players.length;
  int get maxPlayers => 2;
  bool get isActive => true;
}
