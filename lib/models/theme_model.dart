class ThemeModel {
  final String id;
  final String name;
  final String description;
  final String previewImageUrl;
  final String type; // board, pieces, complete
  final bool isPremium;
  final int price; // em moedas virtuais, 0 se for gratuito
  final String rarity; // common, rare, epic, legendary
  final bool isDefault;
  final bool isUnlocked;
  final String? unlockCondition; // descrição de como desbloquear
  final Map<String, dynamic> themeData;
  
  ThemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.previewImageUrl,
    required this.type,
    required this.isPremium,
    required this.price,
    required this.rarity,
    required this.isDefault,
    required this.isUnlocked,
    this.unlockCondition,
    required this.themeData,
  });
  
  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'previewImageUrl': previewImageUrl,
      'type': type,
      'isPremium': isPremium,
      'price': price,
      'rarity': rarity,
      'isDefault': isDefault,
      'isUnlocked': isUnlocked,
      'unlockCondition': unlockCondition,
      'themeData': themeData,
    };
  }
  
  // Método para criar a partir de JSON
  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      previewImageUrl: json['previewImageUrl'] as String,
      type: json['type'] as String,
      isPremium: json['isPremium'] as bool,
      price: json['price'] as int,
      rarity: json['rarity'] as String,
      isDefault: json['isDefault'] as bool,
      isUnlocked: json['isUnlocked'] as bool,
      unlockCondition: json['unlockCondition'] as String?,
      themeData: json['themeData'] as Map<String, dynamic>,
    );
  }
  
  // Temas pré-definidos
  static ThemeModel classicTheme() {
    return ThemeModel(
      id: 'classic',
      name: 'Clássico',
      description: 'O tema tradicional de damas com tabuleiro preto e branco',
      previewImageUrl: 'assets/themes/classic_preview.png',
      type: 'complete',
      isPremium: false,
      price: 0,
      rarity: 'common',
      isDefault: true,
      isUnlocked: true,
      themeData: {
        'boardColors': {
          'light': '#FFFFFF',
          'dark': '#000000',
        },
        'pieceColors': {
          'white': '#FFFFFF',
          'black': '#000000',
          'whiteKing': '#FFDD00',
          'blackKing': '#FF0000',
        },
        'borderColor': '#8B4513',
        'highlightColor': '#4CAF50',
        'possibleMoveColor': '#2196F3',
        'captureHighlightColor': '#F44336',
      },
    );
  }
  
  static ThemeModel woodTheme() {
    return ThemeModel(
      id: 'wood',
      name: 'Madeira',
      description: 'Tabuleiro e peças com aparência de madeira natural',
      previewImageUrl: 'assets/themes/wood_preview.png',
      type: 'complete',
      isPremium: true,
      price: 500,
      rarity: 'rare',
      isDefault: false,
      isUnlocked: false,
      unlockCondition: 'Compre na loja ou vença 10 partidas',
      themeData: {
        'boardColors': {
          'light': '#E8C39E',
          'dark': '#8B4513',
        },
        'pieceColors': {
          'white': '#F5F5DC',
          'black': '#4A2511',
          'whiteKing': '#F5F5DC',
          'blackKing': '#4A2511',
        },
        'borderColor': '#5D4037',
        'highlightColor': '#81C784',
        'possibleMoveColor': '#64B5F6',
        'captureHighlightColor': '#E57373',
        'textureImages': {
          'board': 'assets/themes/wood_board_texture.png',
          'whitePiece': 'assets/themes/wood_white_piece.png',
          'blackPiece': 'assets/themes/wood_black_piece.png',
        },
      },
    );
  }
  
  static ThemeModel neonTheme() {
    return ThemeModel(
      id: 'neon',
      name: 'Neon',
      description: 'Tema futurista com cores neon brilhantes',
      previewImageUrl: 'assets/themes/neon_preview.png',
      type: 'complete',
      isPremium: true,
      price: 1000,
      rarity: 'epic',
      isDefault: false,
      isUnlocked: false,
      unlockCondition: 'Compre na loja ou alcance o nível Diamante no ranking',
      themeData: {
        'boardColors': {
          'light': '#1A1A1A',
          'dark': '#000000',
        },
        'pieceColors': {
          'white': '#00FFFF',
          'black': '#FF00FF',
          'whiteKing': '#00FFFF',
          'blackKing': '#FF00FF',
        },
        'borderColor': '#333333',
        'highlightColor': '#00FF00',
        'possibleMoveColor': '#FFFF00',
        'captureHighlightColor': '#FF0000',
        'glowEffects': true,
        'animations': {
          'moveAnimation': 'glow',
          'captureAnimation': 'explosion',
        },
      },
    );
  }
  
  static ThemeModel medievalTheme() {
    return ThemeModel(
      id: 'medieval',
      name: 'Medieval',
      description: 'Tema inspirado em tabuleiros medievais com peças estilizadas',
      previewImageUrl: 'assets/themes/medieval_preview.png',
      type: 'complete',
      isPremium: true,
      price: 800,
      rarity: 'rare',
      isDefault: false,
      isUnlocked: false,
      unlockCondition: 'Compre na loja ou vença 50 partidas',
      themeData: {
        'boardColors': {
          'light': '#D2B48C',
          'dark': '#8B4513',
        },
        'pieceColors': {
          'white': '#F5F5DC',
          'black': '#4A2511',
          'whiteKing': '#FFD700',
          'blackKing': '#8B0000',
        },
        'borderColor': '#5D4037',
        'highlightColor': '#81C784',
        'possibleMoveColor': '#64B5F6',
        'captureHighlightColor': '#E57373',
        'textureImages': {
          'board': 'assets/themes/medieval_board_texture.png',
          'whitePiece': 'assets/themes/medieval_white_piece.png',
          'blackPiece': 'assets/themes/medieval_black_piece.png',
          'whiteKing': 'assets/themes/medieval_white_king.png',
          'blackKing': 'assets/themes/medieval_black_king.png',
        },
      },
    );
  }
  
  static ThemeModel pixelArtTheme() {
    return ThemeModel(
      id: 'pixel_art',
      name: 'Pixel Art',
      description: 'Tema retrô com visual de pixel art dos anos 80',
      previewImageUrl: 'assets/themes/pixel_art_preview.png',
      type: 'complete',
      isPremium: true,
      price: 750,
      rarity: 'epic',
      isDefault: false,
      isUnlocked: false,
      unlockCondition: 'Compre na loja ou jogue 100 partidas',
      themeData: {
        'boardColors': {
          'light': '#AAAAAA',
          'dark': '#555555',
        },
        'pieceColors': {
          'white': '#FFFFFF',
          'black': '#000000',
          'whiteKing': '#FFFF00',
          'blackKing': '#FF0000',
        },
        'borderColor': '#333333',
        'highlightColor': '#00FF00',
        'possibleMoveColor': '#0000FF',
        'captureHighlightColor': '#FF0000',
        'pixelated': true,
        'textureImages': {
          'whitePiece': 'assets/themes/pixel_white_piece.png',
          'blackPiece': 'assets/themes/pixel_black_piece.png',
          'whiteKing': 'assets/themes/pixel_white_king.png',
          'blackKing': 'assets/themes/pixel_black_king.png',
        },
        'soundEffects': {
          'move': 'assets/sounds/pixel_move.mp3',
          'capture': 'assets/sounds/pixel_capture.mp3',
        },
      },
    );
  }
}
