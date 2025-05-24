class GameModeModel {
  final String id;
  final String name;
  final String description;
  final String rulesetType; // standard, international, brazilian, etc.
  final bool hasTimeLimit;
  final int? timeLimit; // em segundos, null se não tiver limite
  final int? timeIncrement; // incremento por jogada em segundos
  final bool allowSpectators;
  final bool isRanked;
  final int minEloRating; // requisito mínimo de ELO para participar
  final Map<String, dynamic> specialRules; // regras especiais específicas do modo
  final bool isActive; // se o modo está ativo no sistema
  
  GameModeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.rulesetType,
    required this.hasTimeLimit,
    this.timeLimit,
    this.timeIncrement,
    required this.allowSpectators,
    required this.isRanked,
    required this.minEloRating,
    required this.specialRules,
    required this.isActive,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rulesetType': rulesetType,
      'hasTimeLimit': hasTimeLimit,
      'timeLimit': timeLimit,
      'timeIncrement': timeIncrement,
      'allowSpectators': allowSpectators,
      'isRanked': isRanked,
      'minEloRating': minEloRating,
      'specialRules': specialRules,
      'isActive': isActive,
    };
  }
  
  // Método para criar a partir de JSON
  factory GameModeModel.fromJson(Map<String, dynamic> json) {
    return GameModeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rulesetType: json['rulesetType'] as String,
      hasTimeLimit: json['hasTimeLimit'] as bool,
      timeLimit: json['timeLimit'] as int?,
      timeIncrement: json['timeIncrement'] as int?,
      allowSpectators: json['allowSpectators'] as bool,
      isRanked: json['isRanked'] as bool,
      minEloRating: json['minEloRating'] as int,
      specialRules: json['specialRules'] as Map<String, dynamic>,
      isActive: json['isActive'] as bool,
    );
  }
  
  // Modos de jogo pré-definidos
  static GameModeModel standardMode() {
    return GameModeModel(
      id: 'standard',
      name: 'Padrão',
      description: 'Modo clássico de damas brasileiras sem limite de tempo',
      rulesetType: 'brazilian',
      hasTimeLimit: false,
      timeLimit: null,
      timeIncrement: null,
      allowSpectators: true,
      isRanked: true,
      minEloRating: 0,
      specialRules: {},
      isActive: true,
    );
  }
  
  static GameModeModel blitzMode() {
    return GameModeModel(
      id: 'blitz',
      name: 'Blitz',
      description: 'Partida rápida com 5 minutos por jogador',
      rulesetType: 'brazilian',
      hasTimeLimit: true,
      timeLimit: 300, // 5 minutos
      timeIncrement: 2, // 2 segundos por jogada
      allowSpectators: true,
      isRanked: true,
      minEloRating: 800,
      specialRules: {},
      isActive: true,
    );
  }
  
  static GameModeModel internationalMode() {
    return GameModeModel(
      id: 'international',
      name: 'Internacional',
      description: 'Damas no estilo internacional com tabuleiro 10x10',
      rulesetType: 'international',
      hasTimeLimit: false,
      timeLimit: null,
      timeIncrement: null,
      allowSpectators: true,
      isRanked: true,
      minEloRating: 1200,
      specialRules: {
        'boardSize': 10,
        'flyingKings': true,
      },
      isActive: true,
    );
  }
  
  static GameModeModel tournamentMode() {
    return GameModeModel(
      id: 'tournament',
      name: 'Torneio',
      description: 'Modo oficial para torneios com regras estritas',
      rulesetType: 'brazilian',
      hasTimeLimit: true,
      timeLimit: 1200, // 20 minutos
      timeIncrement: 10, // 10 segundos por jogada
      allowSpectators: true,
      isRanked: true,
      minEloRating: 1500,
      specialRules: {
        'strictRules': true,
        'drawAfterMoves': 50, // empate após 50 movimentos sem captura
      },
      isActive: true,
    );
  }
  
  static GameModeModel casualMode() {
    return GameModeModel(
      id: 'casual',
      name: 'Casual',
      description: 'Modo descontraído sem impacto no ranking',
      rulesetType: 'brazilian',
      hasTimeLimit: false,
      timeLimit: null,
      timeIncrement: null,
      allowSpectators: true,
      isRanked: false,
      minEloRating: 0,
      specialRules: {},
      isActive: true,
    );
  }
  
  static GameModeModel dailyChallengeMode() {
    return GameModeModel(
      id: 'daily_challenge',
      name: 'Desafio Diário',
      description: 'Desafio especial com configuração única diária',
      rulesetType: 'brazilian',
      hasTimeLimit: true,
      timeLimit: 600, // 10 minutos
      timeIncrement: 0,
      allowSpectators: false,
      isRanked: false,
      minEloRating: 0,
      specialRules: {
        'predefinedBoard': true, // tabuleiro com configuração pré-definida
        'dailyReward': true, // recompensa por completar o desafio
      },
      isActive: true,
    );
  }
}
