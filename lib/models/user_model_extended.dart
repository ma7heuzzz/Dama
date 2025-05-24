class UserModel {
  final String id;
  final String nickname;
  final String email;
  final String? avatarUrl;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int eloRating;
  final List<String> achievements;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  UserModel({
    required this.id,
    required this.nickname,
    required this.email,
    this.avatarUrl,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.eloRating = 1000,
    this.achievements = const [],
    this.preferences = const {},
    required this.createdAt,
    required this.lastLoginAt,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'email': email,
      'avatarUrl': avatarUrl,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'gamesLost': gamesLost,
      'eloRating': eloRating,
      'achievements': achievements,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }
  
  // Método para criar a partir de JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      gamesLost: json['gamesLost'] as int? ?? 0,
      eloRating: json['eloRating'] as int? ?? 1000,
      achievements: (json['achievements'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String) 
          : DateTime.now(),
    );
  }
  
  // Método para criar uma cópia com alterações
  UserModel copyWith({
    String? id,
    String? nickname,
    String? email,
    String? avatarUrl,
    int? gamesPlayed,
    int? gamesWon,
    int? gamesLost,
    int? eloRating,
    List<String>? achievements,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      eloRating: eloRating ?? this.eloRating,
      achievements: achievements ?? this.achievements,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
