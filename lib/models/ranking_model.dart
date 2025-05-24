class RankingModel {
  final String id;
  final String userId;
  final String nickname;
  final int eloRating;
  final int rank;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int winStreak;
  final int bestWinStreak;
  final String tier; // bronze, silver, gold, platinum, diamond, master
  final int tierPoints;
  final DateTime lastGameDate;
  final DateTime seasonStartDate;
  final bool isActive; // jogador ativo na temporada atual
  
  RankingModel({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.eloRating,
    required this.rank,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.gamesLost,
    required this.winStreak,
    required this.bestWinStreak,
    required this.tier,
    required this.tierPoints,
    required this.lastGameDate,
    required this.seasonStartDate,
    required this.isActive,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'nickname': nickname,
      'eloRating': eloRating,
      'rank': rank,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'gamesLost': gamesLost,
      'winStreak': winStreak,
      'bestWinStreak': bestWinStreak,
      'tier': tier,
      'tierPoints': tierPoints,
      'lastGameDate': lastGameDate.toIso8601String(),
      'seasonStartDate': seasonStartDate.toIso8601String(),
      'isActive': isActive,
    };
  }
  
  // Método para criar a partir de JSON
  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      eloRating: json['eloRating'] as int,
      rank: json['rank'] as int,
      gamesPlayed: json['gamesPlayed'] as int,
      gamesWon: json['gamesWon'] as int,
      gamesLost: json['gamesLost'] as int,
      winStreak: json['winStreak'] as int,
      bestWinStreak: json['bestWinStreak'] as int,
      tier: json['tier'] as String,
      tierPoints: json['tierPoints'] as int,
      lastGameDate: DateTime.parse(json['lastGameDate'] as String),
      seasonStartDate: DateTime.parse(json['seasonStartDate'] as String),
      isActive: json['isActive'] as bool,
    );
  }
  
  // Método para calcular a taxa de vitórias
  double get winRate {
    if (gamesPlayed == 0) return 0.0;
    return (gamesWon / gamesPlayed) * 100;
  }
  
  // Método para criar uma cópia com alterações
  RankingModel copyWith({
    String? id,
    String? userId,
    String? nickname,
    int? eloRating,
    int? rank,
    int? gamesPlayed,
    int? gamesWon,
    int? gamesLost,
    int? winStreak,
    int? bestWinStreak,
    String? tier,
    int? tierPoints,
    DateTime? lastGameDate,
    DateTime? seasonStartDate,
    bool? isActive,
  }) {
    return RankingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      eloRating: eloRating ?? this.eloRating,
      rank: rank ?? this.rank,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      winStreak: winStreak ?? this.winStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      tier: tier ?? this.tier,
      tierPoints: tierPoints ?? this.tierPoints,
      lastGameDate: lastGameDate ?? this.lastGameDate,
      seasonStartDate: seasonStartDate ?? this.seasonStartDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
