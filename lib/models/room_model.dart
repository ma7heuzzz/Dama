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
    return RoomModel(
      id: json['id'] as String,
      creator: json['creator'] as String,
      players: (json['players'] as List<dynamic>)
          .map((player) => Player.fromJson(player as Map<String, dynamic>))
          .toList(),
      board: json['board'],
      currentTurn: json['currentTurn'] as String? ?? 'white',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator': creator,
      'players': players.map((player) => player.toJson()).toList(),
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
