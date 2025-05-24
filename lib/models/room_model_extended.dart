import 'game_mode_model.dart';

class RoomModelExtended {
  final String id;
  final String roomCode;
  final String hostId;
  final String hostNickname;
  final List<PlayerInRoom> players;
  final List<SpectatorInRoom> spectators;
  final int maxPlayers;
  final int maxSpectators;
  final String currentTurn;
  final String gameState; // waiting, playing, finished
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? winnerId;
  final String gameModeId;
  final GameModeModel? gameMode;
  final Map<String, dynamic> settings;
  final List<ChatMessage> chatMessages;
  final bool isPrivate;
  final String? password; // Hash da senha se for sala privada
  
  RoomModelExtended({
    required this.id,
    required this.roomCode,
    required this.hostId,
    required this.hostNickname,
    required this.players,
    this.spectators = const [],
    this.maxPlayers = 2,
    this.maxSpectators = 10,
    required this.currentTurn,
    required this.gameState,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.winnerId,
    required this.gameModeId,
    this.gameMode,
    required this.settings,
    this.chatMessages = const [],
    this.isPrivate = false,
    this.password,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': roomCode,
      'hostId': hostId,
      'hostNickname': hostNickname,
      'players': players.map((player) => player.toJson()).toList(),
      'spectators': spectators.map((spectator) => spectator.toJson()).toList(),
      'maxPlayers': maxPlayers,
      'maxSpectators': maxSpectators,
      'currentTurn': currentTurn,
      'gameState': gameState,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'winnerId': winnerId,
      'gameModeId': gameModeId,
      'gameMode': gameMode?.toJson(),
      'settings': settings,
      'chatMessages': chatMessages.map((message) => message.toJson()).toList(),
      'isPrivate': isPrivate,
      'password': password,
    };
  }
  
  // Método para criar a partir de JSON
  factory RoomModelExtended.fromJson(Map<String, dynamic> json) {
    return RoomModelExtended(
      id: json['id'] as String,
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      hostNickname: json['hostNickname'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => PlayerInRoom.fromJson(e as Map<String, dynamic>))
          .toList(),
      spectators: json['spectators'] != null
          ? (json['spectators'] as List<dynamic>)
              .map((e) => SpectatorInRoom.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      maxPlayers: json['maxPlayers'] as int? ?? 2,
      maxSpectators: json['maxSpectators'] as int? ?? 10,
      currentTurn: json['currentTurn'] as String,
      gameState: json['gameState'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      winnerId: json['winnerId'] as String?,
      gameModeId: json['gameModeId'] as String,
      gameMode: json['gameMode'] != null
          ? GameModeModel.fromJson(json['gameMode'] as Map<String, dynamic>)
          : null,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      chatMessages: json['chatMessages'] != null
          ? (json['chatMessages'] as List<dynamic>)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      isPrivate: json['isPrivate'] as bool? ?? false,
      password: json['password'] as String?,
    );
  }
  
  // Verificar se a sala está cheia
  bool get isFull => players.length >= maxPlayers;
  
  // Verificar se a sala de espectadores está cheia
  bool get isSpectatorsFull => spectators.length >= maxSpectators;
  
  // Verificar se o jogo está em andamento
  bool get isPlaying => gameState == 'playing';
  
  // Verificar se o jogo terminou
  bool get isFinished => gameState == 'finished';
  
  // Obter contagem de jogadores
  int get playerCount => players.length;
  
  // Obter contagem de espectadores
  int get spectatorCount => spectators.length;
  
  // Método para criar uma cópia com alterações
  RoomModelExtended copyWith({
    String? id,
    String? roomCode,
    String? hostId,
    String? hostNickname,
    List<PlayerInRoom>? players,
    List<SpectatorInRoom>? spectators,
    int? maxPlayers,
    int? maxSpectators,
    String? currentTurn,
    String? gameState,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    String? winnerId,
    String? gameModeId,
    GameModeModel? gameMode,
    Map<String, dynamic>? settings,
    List<ChatMessage>? chatMessages,
    bool? isPrivate,
    String? password,
  }) {
    return RoomModelExtended(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostNickname: hostNickname ?? this.hostNickname,
      players: players ?? this.players,
      spectators: spectators ?? this.spectators,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      maxSpectators: maxSpectators ?? this.maxSpectators,
      currentTurn: currentTurn ?? this.currentTurn,
      gameState: gameState ?? this.gameState,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      winnerId: winnerId ?? this.winnerId,
      gameModeId: gameModeId ?? this.gameModeId,
      gameMode: gameMode ?? this.gameMode,
      settings: settings ?? this.settings,
      chatMessages: chatMessages ?? this.chatMessages,
      isPrivate: isPrivate ?? this.isPrivate,
      password: password ?? this.password,
    );
  }
}

class PlayerInRoom {
  final String id;
  final String nickname;
  final String color; // white, black
  final bool isReady;
  final DateTime joinedAt;
  final int? eloRating;
  final String? avatarUrl;
  
  PlayerInRoom({
    required this.id,
    required this.nickname,
    required this.color,
    required this.isReady,
    required this.joinedAt,
    this.eloRating,
    this.avatarUrl,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'color': color,
      'isReady': isReady,
      'joinedAt': joinedAt.toIso8601String(),
      'eloRating': eloRating,
      'avatarUrl': avatarUrl,
    };
  }
  
  // Método para criar a partir de JSON
  factory PlayerInRoom.fromJson(Map<String, dynamic> json) {
    return PlayerInRoom(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      color: json['color'] as String,
      isReady: json['isReady'] as bool,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      eloRating: json['eloRating'] as int?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class SpectatorInRoom {
  final String id;
  final String nickname;
  final DateTime joinedAt;
  final String? avatarUrl;
  
  SpectatorInRoom({
    required this.id,
    required this.nickname,
    required this.joinedAt,
    this.avatarUrl,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'joinedAt': joinedAt.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }
  
  // Método para criar a partir de JSON
  factory SpectatorInRoom.fromJson(Map<String, dynamic> json) {
    return SpectatorInRoom(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderNickname;
  final String message;
  final DateTime timestamp;
  final String messageType; // normal, system, private
  final String? targetId; // ID do destinatário se for mensagem privada
  
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.message,
    required this.timestamp,
    required this.messageType,
    this.targetId,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
      'targetId': targetId,
    };
  }
  
  // Método para criar a partir de JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderNickname: json['senderNickname'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      messageType: json['messageType'] as String,
      targetId: json['targetId'] as String?,
    );
  }
}
