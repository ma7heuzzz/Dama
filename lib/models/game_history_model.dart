class GameHistoryModel {
  final String id;
  final String roomCode;
  final String whitePlayerId;
  final String blackPlayerId;
  final String winnerPlayerId; // null para empate
  final DateTime startTime;
  final DateTime endTime;
  final int movesCount;
  final List<GameMoveModel> moves;
  final Map<String, dynamic> gameSettings;
  final List<String> spectatorIds;
  
  GameHistoryModel({
    required this.id,
    required this.roomCode,
    required this.whitePlayerId,
    required this.blackPlayerId,
    required this.winnerPlayerId,
    required this.startTime,
    required this.endTime,
    required this.movesCount,
    required this.moves,
    required this.gameSettings,
    required this.spectatorIds,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': roomCode,
      'whitePlayerId': whitePlayerId,
      'blackPlayerId': blackPlayerId,
      'winnerPlayerId': winnerPlayerId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'movesCount': movesCount,
      'moves': moves.map((move) => move.toJson()).toList(),
      'gameSettings': gameSettings,
      'spectatorIds': spectatorIds,
    };
  }
  
  // Método para criar a partir de JSON
  factory GameHistoryModel.fromJson(Map<String, dynamic> json) {
    return GameHistoryModel(
      id: json['id'] as String,
      roomCode: json['roomCode'] as String,
      whitePlayerId: json['whitePlayerId'] as String,
      blackPlayerId: json['blackPlayerId'] as String,
      winnerPlayerId: json['winnerPlayerId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      movesCount: json['movesCount'] as int,
      moves: (json['moves'] as List<dynamic>)
          .map((e) => GameMoveModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      gameSettings: json['gameSettings'] as Map<String, dynamic>,
      spectatorIds: (json['spectatorIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

class GameMoveModel {
  final String playerId;
  final int moveNumber;
  final Map<String, dynamic> fromPosition;
  final Map<String, dynamic> toPosition;
  final bool isCapture;
  final bool isPromotion;
  final DateTime timestamp;
  
  GameMoveModel({
    required this.playerId,
    required this.moveNumber,
    required this.fromPosition,
    required this.toPosition,
    required this.isCapture,
    required this.isPromotion,
    required this.timestamp,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'moveNumber': moveNumber,
      'fromPosition': fromPosition,
      'toPosition': toPosition,
      'isCapture': isCapture,
      'isPromotion': isPromotion,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  // Método para criar a partir de JSON
  factory GameMoveModel.fromJson(Map<String, dynamic> json) {
    return GameMoveModel(
      playerId: json['playerId'] as String,
      moveNumber: json['moveNumber'] as int,
      fromPosition: json['fromPosition'] as Map<String, dynamic>,
      toPosition: json['toPosition'] as Map<String, dynamic>,
      isCapture: json['isCapture'] as bool,
      isPromotion: json['isPromotion'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
