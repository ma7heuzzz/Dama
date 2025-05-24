import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:xdama/models/game_piece.dart';
import 'package:xdama/models/room_model.dart';
import 'package:xdama/services/websocket_service.dart';
import 'package:xdama/services/audio_service.dart';

class GameProvider extends ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  final AudioService _audioService = AudioService();
  final Logger _logger = Logger();
  
  List<List<GamePiece?>> _board = [];
  GamePiece? _selectedPiece;
  List<Position> _possibleMoves = [];
  List<GamePiece> _piecesWithCaptures = [];
  bool _isWhiteTurn = true;
  bool _gameStarted = false;
  String? _statusMessage;
  bool _isConnected = false;
  String? _error;
  String? _currentRoomCode;
  String? _playerColor;
  String? _opponentNickname;
  String? _playerNickname;
  
  // Variáveis para controle de captura múltipla
  bool _isInMultiCapture = false;
  List<Map<String, dynamic>> _captureSequence = [];
  
  // Variáveis para controle de vitória
  bool _showVictoryAnimation = false;
  String? _winnerColor;
  
  // Getters
  List<List<GamePiece?>> get board => _board;
  GamePiece? get selectedPiece => _selectedPiece;
  List<Position> get possibleMoves => _possibleMoves;
  bool get isWhiteTurn => _isWhiteTurn;
  bool get gameStarted => _gameStarted;
  String? get statusMessage => _statusMessage;
  bool get isConnected => _isConnected;
  String? get error => _error;
  String? get playerColor => _playerColor;
  String? get opponentNickname => _opponentNickname;
  bool get isInMultiCapture => _isInMultiCapture;
  bool get showVictoryAnimation => _showVictoryAnimation;
  String? get winnerColor => _winnerColor;
  
  // Inicializar o jogo
  void initializeGame(String roomCode, {String? nickname}) {
    _currentRoomCode = roomCode;
    _playerNickname = nickname;
    _initializeBoard();
    _connectToRoom(roomCode);
  }
  
  // Inicializar o tabuleiro
  void _initializeBoard() {
    _logger.i('Inicializando tabuleiro');
    
    // Inicializa o tabuleiro 8x8 vazio
    _board = List.generate(
      8,
      (row) => List.generate(
        8,
        (col) => null,
      ),
    );

    // Adiciona as peças iniciais
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        // Apenas posições de casas pretas (soma de índices ímpar)
        if ((row + col) % 2 == 1) {
          // Peças brancas nas 3 primeiras linhas
          if (row < 3) {
            _board[row][col] = GamePiece(
              position: Position(row: row, col: col),
              isWhite: true,
            );
          }
          // Peças pretas nas 3 últimas linhas
          else if (row > 4) {
            _board[row][col] = GamePiece(
              position: Position(row: row, col: col),
              isWhite: false,
            );
          }
        }
      }
    }
    
    _gameStarted = false; // Inicialmente falso até que dois jogadores entrem
    _isWhiteTurn = true;
    _statusMessage = "Aguardando oponente...";
    _showVictoryAnimation = false;
    _winnerColor = null;
    notifyListeners();
  }
  
  // Conectar à sala
  Future<void> _connectToRoom(String roomCode) async {
    try {
      _logger.i('Conectando à sala $roomCode com nickname $_playerNickname');
      
      // Obter nickname do UserProvider ou usar o fornecido
      if (_playerNickname == null || _playerNickname!.isEmpty) {
        _playerNickname = 'Jogador'; // Valor padrão, deve ser substituído pelo nickname real
      }
      
      final connected = await _webSocketService.connect(_playerNickname ?? 'Jogador');
      
      if (connected) {
        _isConnected = true;
        _error = null;
        
        // Entrar na sala específica
        _webSocketService.joinRoom(roomCode);
        
        // Iniciar áudio
        _audioService.connectToPeer(roomCode);
        
        // Escutar atualizações do tabuleiro
        _webSocketService.boardUpdateStream.listen(_handleBoardUpdate);
        
        // Escutar atualizações da sala
        _webSocketService.roomUpdateStream.listen((room) {
          _handleRoomUpdate(room);
        });
        
        // Escutar erros
        _webSocketService.errorStream.listen(_handleError);
        
        // Escutar fechamento da sala
        _webSocketService.roomClosedStream.listen((data) {
          if (data['roomCode'] == _currentRoomCode) {
            _error = 'A sala foi encerrada pelo criador';
            notifyListeners();
          }
        });
        
        // Escutar eventos de vitória através do boardUpdateStream
        // Já que não existe gameOverStream específico
        _webSocketService.boardUpdateStream.listen((data) {
          if (data['event'] == 'game_over' && data['roomCode'] == _currentRoomCode) {
            _handleGameOver(data);
          }
        });
      } else {
        _error = 'Não foi possível conectar à sala';
      }
    } catch (e) {
      _error = 'Erro ao conectar à sala: $e';
      _logger.e('Erro ao conectar à sala: $e');
    }
    
    notifyListeners();
  }
  
  // Processar atualizações do tabuleiro
  void _handleBoardUpdate(Map<String, dynamic> data) {
    _logger.i('Recebida atualização do tabuleiro: $data');
    
    // Processar movimento simples
    if (data.containsKey('from') && data.containsKey('to') && data.containsKey('playerNickname')) {
      final fromData = data['from'] as Map<String, dynamic>;
      final toData = data['to'] as Map<String, dynamic>;
      final playerNickname = data['playerNickname'] as String;
      
      _logger.d('Movimento de $playerNickname, jogador atual: $_playerNickname');
      
      // Se o movimento foi feito pelo oponente, processá-lo
      if (playerNickname != _playerNickname) {
        final fromRow = fromData['row'] as int;
        final fromCol = fromData['col'] as int;
        final toRow = toData['row'] as int;
        final toCol = toData['col'] as int;
        
        _logger.i('Processando movimento do oponente: ($fromRow,$fromCol) -> ($toRow,$toCol)');
        _processOpponentMove(fromRow, fromCol, toRow, toCol);
      }
    }
    
    // Processar sequência de capturas
    if (data.containsKey('captureSequence') && data.containsKey('playerNickname')) {
      final playerNickname = data['playerNickname'] as String;
      
      // Se a sequência foi feita pelo oponente, processá-la
      if (playerNickname != _playerNickname) {
        final captureSequence = data['captureSequence'] as List<dynamic>;
        _logger.i('Processando sequência de capturas do oponente: ${captureSequence.length} movimentos');
        
        // Processar cada movimento da sequência
        for (var move in captureSequence) {
          final fromData = move['from'] as Map<String, dynamic>;
          final toData = move['to'] as Map<String, dynamic>;
          
          final fromRow = fromData['row'] as int;
          final fromCol = fromData['col'] as int;
          final toRow = toData['row'] as int;
          final toCol = toData['col'] as int;
          
          _processOpponentMove(fromRow, fromCol, toRow, toCol, isPartOfSequence: true);
        }
        
        // Após processar toda a sequência, atualizar o turno
        if (data.containsKey('currentTurn')) {
          final currentTurn = data['currentTurn'] as String;
          _isWhiteTurn = currentTurn == 'white';
          _logger.d('Turno atualizado após sequência: ${_isWhiteTurn ? "brancas" : "pretas"}');
        }
      }
    } else if (data.containsKey('currentTurn')) {
      // Atualizar turno para movimento simples
      final currentTurn = data['currentTurn'] as String;
      _isWhiteTurn = currentTurn == 'white';
      _logger.d('Turno atualizado: ${_isWhiteTurn ? "brancas" : "pretas"}');
    }
    
    // Atualizar mensagem de status baseado em quem deve jogar
    _updateStatusMessage();
    
    // Verificar capturas obrigatórias após atualização do turno
    _checkForForcedCaptures();
    
    // Verificar condições de vitória
    _checkForVictory();
    
    notifyListeners();
  }
  
  // Verificar condições de vitória
  void _checkForVictory() {
    // Contar peças de cada cor
    int whitePieces = 0;
    int blackPieces = 0;
    
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = _board[row][col];
        if (piece != null) {
          if (piece.isWhite) {
            whitePieces++;
          } else {
            blackPieces++;
          }
        }
      }
    }
    
    // Verificar se algum jogador ficou sem peças
    if (whitePieces == 0) {
      _triggerVictoryAnimation('black');
    } else if (blackPieces == 0) {
      _triggerVictoryAnimation('white');
    }
    
    // Verificar se algum jogador não tem movimentos possíveis
    bool whiteHasMoves = false;
    bool blackHasMoves = false;
    
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = _board[row][col];
        if (piece != null) {
          final moves = _calculateMovesForPiece(piece);
          final captures = _calculateCapturesForPiece(piece);
          
          if (piece.isWhite && (moves.isNotEmpty || captures.isNotEmpty)) {
            whiteHasMoves = true;
          } else if (!piece.isWhite && (moves.isNotEmpty || captures.isNotEmpty)) {
            blackHasMoves = true;
          }
        }
      }
    }
    
    // Se um jogador não tem movimentos possíveis e é a vez dele, o outro jogador vence
    if (_isWhiteTurn && !whiteHasMoves && whitePieces > 0) {
      _triggerVictoryAnimation('black');
    } else if (!_isWhiteTurn && !blackHasMoves && blackPieces > 0) {
      _triggerVictoryAnimation('white');
    }
  }
  
  // Acionar animação de vitória
  void _triggerVictoryAnimation(String winnerColor) {
    if (!_showVictoryAnimation) {
      _logger.i('Vitória das peças $winnerColor!');
      _winnerColor = winnerColor;
      _showVictoryAnimation = true;
      
      // Enviar evento de vitória para o servidor
      if (_currentRoomCode != null) {
        // Usar emitEvent em vez de sendGameOver que não existe
        _webSocketService.emitEvent('game_over', {
          'roomCode': _currentRoomCode,
          'winnerColor': winnerColor,
        });
      }
      
      notifyListeners();
    }
  }
  
  // Processar evento de fim de jogo
  void _handleGameOver(Map<String, dynamic> data) {
    final winnerColor = data['winnerColor'] as String;
    _logger.i('Recebido evento de fim de jogo: vitória das peças $winnerColor');
    
    _winnerColor = winnerColor;
    _showVictoryAnimation = true;
    
    notifyListeners();
  }
  
  // Fechar animação de vitória
  void closeVictoryAnimation() {
    _showVictoryAnimation = false;
    notifyListeners();
  }
  
  // Atualizar mensagem de status
  void _updateStatusMessage() {
    final bool isMyTurn = (_playerColor == 'white' && _isWhiteTurn) || 
                          (_playerColor == 'black' && !_isWhiteTurn);
    
    if (_isInMultiCapture) {
      _statusMessage = "Continue a captura com a mesma peça!";
    } else if (_piecesWithCaptures.isNotEmpty && isMyTurn) {
      _statusMessage = "Captura obrigatória! Selecione uma peça destacada.";
    } else if (isMyTurn) {
      _statusMessage = "Sua vez de jogar";
    } else {
      _statusMessage = "Vez do oponente";
    }
    
    _logger.d('Status atualizado: $_statusMessage');
  }
  
  // Processar atualizações da sala
  void _handleRoomUpdate(RoomModel room) {
    _logger.i('Recebida atualização da sala: ${room.roomCode}');
    
    // Determinar a cor do jogador baseado na ordem de entrada na sala
    final players = room.players;
    
    if (players.isNotEmpty) {
      // Verificar se o jogador atual está na sala
      final playerInRoom = players.any((player) => player.nickname == _playerNickname);
      
      if (!playerInRoom) {
        // Se o jogador não está na sala, algo está errado
        _error = 'Você não está na sala';
        _logger.w('Jogador $_playerNickname não está na sala ${room.roomCode}');
        notifyListeners();
        return;
      }
      
      // O criador da sala (primeiro jogador) sempre é branco
      if (room.creator == _playerNickname) {
        _playerColor = 'white';
        _logger.d('Jogador $_playerNickname é o criador, cor: brancas');
        
        // Se houver outro jogador, ele é o oponente
        if (players.length >= 2) {
          // Encontrar o jogador que não é o atual
          for (var player in players) {
            if (player.nickname != _playerNickname) {
              _opponentNickname = player.nickname;
              _logger.d('Oponente encontrado: $_opponentNickname');
              break;
            }
          }
        }
      } 
      // Se não for o criador e estiver na sala, é preto
      else {
        _playerColor = 'black';
        _opponentNickname = room.creator;
        _logger.d('Jogador $_playerNickname não é o criador, cor: pretas, oponente: $_opponentNickname');
      }
    }
    
    // Atualizar status do jogo
    _gameStarted = players.length >= 2;
    
    // Atualizar mensagem de status
    if (_gameStarted) {
      _logger.i('Jogo iniciado com ${players.length} jogadores');
      _updateStatusMessage();
      // Verificar capturas obrigatórias no início do jogo
      _checkForForcedCaptures();
    } else {
      _statusMessage = "Aguardando oponente...";
      _logger.d('Aguardando oponente, jogadores na sala: ${players.length}');
    }
    
    notifyListeners();
  }
  
  // Processar erros
  void _handleError(String errorMessage) {
    _error = errorMessage;
    _logger.e('Erro recebido: $errorMessage');
    notifyListeners();
  }
  
  // Processar movimento do oponente
  void _processOpponentMove(int fromRow, int fromCol, int toRow, int toCol, {bool isPartOfSequence = false}) {
    final piece = _board[fromRow][fromCol];
    if (piece == null) {
      _logger.w('Tentativa de mover peça inexistente: ($fromRow,$fromCol)');
      return;
    }
    
    // Verificar se é um movimento de captura
    final bool isCapture = (toRow - fromRow).abs() == 2;
    
    // Criar nova peça na posição de destino
    final newPiece = GamePiece(
      position: Position(row: toRow, col: toCol),
      isWhite: piece.isWhite,
      isKing: piece.isKing || (piece.isWhite && toRow == 7) || (!piece.isWhite && toRow == 0),
    );
    
    // Remover peça da posição original
    _board[fromRow][fromCol] = null;
    
    // Colocar peça na nova posição
    _board[toRow][toCol] = newPiece;
    
    _logger.d('Peça movida de ($fromRow,$fromCol) para ($toRow,$toCol), captura: $isCapture');
    
    // Se for captura, remover a peça capturada
    if (isCapture) {
      final int capturedRow = (fromRow + toRow) ~/ 2;
      final int capturedCol = (fromCol + toCol) ~/ 2;
      _board[capturedRow][capturedCol] = null;
      _logger.d('Peça capturada em ($capturedRow,$capturedCol)');
    }
    
    // Se não for parte de uma sequência, trocar o turno
    if (!isPartOfSequence) {
      _isWhiteTurn = !_isWhiteTurn;
      _logger.d('Turno trocado para: ${_isWhiteTurn ? "brancas" : "pretas"}');
    }
  }
  
  // Verificar se há capturas obrigatórias
  void _checkForForcedCaptures() {
    _piecesWithCaptures = [];
    
    // Verificar todas as peças da cor atual
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = _board[row][col];
        if (piece != null && piece.isWhite == _isWhiteTurn) {
          final captures = _calculateCapturesForPiece(piece);
          if (captures.isNotEmpty) {
            _piecesWithCaptures.add(piece);
          }
        }
      }
    }
    
    // Se houver capturas obrigatórias, atualizar mensagem
    if (_piecesWithCaptures.isNotEmpty) {
      _logger.d('Capturas obrigatórias encontradas: ${_piecesWithCaptures.length}');
      final bool isMyTurn = (_playerColor == 'white' && _isWhiteTurn) || 
                            (_playerColor == 'black' && !_isWhiteTurn);
      if (isMyTurn) {
        _statusMessage = "Captura obrigatória! Selecione uma peça destacada.";
      }
    }
    
    notifyListeners();
  }
  
  // Calcular capturas possíveis para uma peça
  List<Position> _calculateCapturesForPiece(GamePiece piece) {
    final List<Position> captures = [];
    final int row = piece.position.row;
    final int col = piece.position.col;
    final bool isWhite = piece.isWhite;
    final bool isKing = piece.isKing;
    
    // Direções de movimento (diagonal)
    final List<List<int>> directions = isKing
        ? [[-1, -1], [-1, 1], [1, -1], [1, 1]] // Rei pode mover em todas as direções
        : isWhite
            ? [[1, -1], [1, 1]] // Peças brancas movem para baixo
            : [[-1, -1], [-1, 1]]; // Peças pretas movem para cima
    
    // Verificar cada direção
    for (final direction in directions) {
      final int dr = direction[0];
      final int dc = direction[1];
      
      // Posição do oponente
      final int opponentRow = row + dr;
      final int opponentCol = col + dc;
      
      // Posição após o oponente
      final int targetRow = row + 2 * dr;
      final int targetCol = col + 2 * dc;
      
      // Verificar se a posição do oponente está dentro do tabuleiro
      if (opponentRow >= 0 && opponentRow < 8 && opponentCol >= 0 && opponentCol < 8) {
        // Verificar se há uma peça oponente
        final opponentPiece = _board[opponentRow][opponentCol];
        if (opponentPiece != null && opponentPiece.isWhite != isWhite) {
          // Verificar se a posição após o oponente está dentro do tabuleiro
          if (targetRow >= 0 && targetRow < 8 && targetCol >= 0 && targetCol < 8) {
            // Verificar se a posição após o oponente está vazia
            if (_board[targetRow][targetCol] == null) {
              captures.add(Position(row: targetRow, col: targetCol));
            }
          }
        }
      }
    }
    
    return captures;
  }
  
  // Calcular movimentos possíveis para uma peça
  List<Position> _calculateMovesForPiece(GamePiece piece) {
    final List<Position> moves = [];
    final int row = piece.position.row;
    final int col = piece.position.col;
    final bool isWhite = piece.isWhite;
    final bool isKing = piece.isKing;
    
    // Direções de movimento (diagonal)
    final List<List<int>> directions = isKing
        ? [[-1, -1], [-1, 1], [1, -1], [1, 1]] // Rei pode mover em todas as direções
        : isWhite
            ? [[1, -1], [1, 1]] // Peças brancas movem para baixo
            : [[-1, -1], [-1, 1]]; // Peças pretas movem para cima
    
    // Verificar cada direção
    for (final direction in directions) {
      final int dr = direction[0];
      final int dc = direction[1];
      
      // Nova posição
      final int newRow = row + dr;
      final int newCol = col + dc;
      
      // Verificar se a nova posição está dentro do tabuleiro
      if (newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8) {
        // Verificar se a nova posição está vazia
        if (_board[newRow][newCol] == null) {
          moves.add(Position(row: newRow, col: newCol));
        }
      }
    }
    
    return moves;
  }
  
  // Verificar se uma peça pode ser selecionada
  bool _canSelectPiece(GamePiece piece) {
    // Verificar se é a vez do jogador
    final bool isMyTurn = (_playerColor == 'white' && _isWhiteTurn) || 
                          (_playerColor == 'black' && !_isWhiteTurn);
    
    // Verificar se a peça é da cor do jogador atual
    final bool isMyPiece = (piece.isWhite && _playerColor == 'white') || 
                           (!piece.isWhite && _playerColor == 'black');
    
    // Se não for a vez do jogador ou não for uma peça do jogador, não pode selecionar
    if (!isMyTurn || !isMyPiece) {
      return false;
    }
    
    // Se estiver em captura múltipla, só pode selecionar a mesma peça
    if (_isInMultiCapture && _selectedPiece != null) {
      return piece.position.row == _selectedPiece!.position.row && 
             piece.position.col == _selectedPiece!.position.col;
    }
    
    // Se houver capturas obrigatórias, só pode selecionar peças com capturas
    if (_piecesWithCaptures.isNotEmpty) {
      return _piecesWithCaptures.any((p) => 
        p.position.row == piece.position.row && 
        p.position.col == piece.position.col
      );
    }
    
    // Caso contrário, pode selecionar qualquer peça da cor do jogador atual
    return true;
  }
  
  // Verificar se uma peça está em captura múltipla
  bool isPieceInMultiCapture(int row, int col) {
    return _isInMultiCapture && 
           _selectedPiece != null && 
           _selectedPiece!.position.row == row && 
           _selectedPiece!.position.col == col;
  }
  
  // Selecionar uma posição no tabuleiro
  void selectTile(int row, int col) {
    // Verificar se o jogo já começou
    if (!_gameStarted) {
      _logger.w('Tentativa de selecionar posição antes do início do jogo');
      return;
    }
    
    // Verificar se é a vez do jogador
    final bool isMyTurn = (_playerColor == 'white' && _isWhiteTurn) || 
                          (_playerColor == 'black' && !_isWhiteTurn);
    
    if (!isMyTurn) {
      _logger.w('Tentativa de selecionar posição fora do turno');
      return;
    }
    
    // Obter a peça na posição selecionada
    final piece = _board[row][col];
    
    // Se já há uma peça selecionada
    if (_selectedPiece != null) {
      // Verificar se a posição selecionada é um movimento possível
      final bool isValidMove = _possibleMoves.any(
        (pos) => pos.row == row && pos.col == col
      );
      
      if (isValidMove) {
        // Executar o movimento
        _makeMove(_selectedPiece!.position.row, _selectedPiece!.position.col, row, col);
      } else if (piece != null && _canSelectPiece(piece)) {
        // Selecionar outra peça
        _selectPiece(piece);
      } else {
        // Desselecionar a peça atual
        _selectedPiece = null;
        _possibleMoves = [];
        notifyListeners();
      }
    } 
    // Se não há peça selecionada e há uma peça na posição
    else if (piece != null && _canSelectPiece(piece)) {
      _selectPiece(piece);
    }
  }
  
  // Selecionar uma peça
  void _selectPiece(GamePiece piece) {
    _selectedPiece = piece;
    
    // Calcular movimentos possíveis
    _possibleMoves = [];
    
    // Se houver capturas obrigatórias, só mostrar capturas
    if (_piecesWithCaptures.isNotEmpty) {
      _possibleMoves = _calculateCapturesForPiece(piece);
    } else {
      // Caso contrário, mostrar todos os movimentos possíveis
      _possibleMoves = [
        ..._calculateMovesForPiece(piece),
        ..._calculateCapturesForPiece(piece),
      ];
    }
    
    notifyListeners();
  }
  
  // Executar um movimento
  void _makeMove(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = _board[fromRow][fromCol];
    if (piece == null) return;
    
    // Verificar se é um movimento de captura
    final bool isCapture = (toRow - fromRow).abs() == 2;
    
    // Criar nova peça na posição de destino
    final newPiece = GamePiece(
      position: Position(row: toRow, col: toCol),
      isWhite: piece.isWhite,
      isKing: piece.isKing || (piece.isWhite && toRow == 7) || (!piece.isWhite && toRow == 0),
    );
    
    // Remover peça da posição original
    _board[fromRow][fromCol] = null;
    
    // Colocar peça na nova posição
    _board[toRow][toCol] = newPiece;
    
    // Se for captura, remover a peça capturada
    if (isCapture) {
      final int capturedRow = (fromRow + toRow) ~/ 2;
      final int capturedCol = (fromCol + toCol) ~/ 2;
      _board[capturedRow][capturedCol] = null;
      
      // Adicionar movimento à sequência de capturas
      _captureSequence.add({
        'from': {'row': fromRow, 'col': fromCol},
        'to': {'row': toRow, 'col': toCol},
      });
      
      // Verificar se há mais capturas possíveis com a mesma peça
      final moreCapturesPossible = _calculateCapturesForPiece(newPiece).isNotEmpty;
      
      if (moreCapturesPossible) {
        // Continuar a captura múltipla
        _isInMultiCapture = true;
        _selectedPiece = newPiece;
        _possibleMoves = _calculateCapturesForPiece(newPiece);
        _statusMessage = "Continue a captura com a mesma peça!";
        notifyListeners();
        return;
      } else {
        // Finalizar a sequência de capturas
        _sendCaptureSequence();
      }
    } else {
      // Movimento simples
      _sendMove(fromRow, fromCol, toRow, toCol);
    }
    
    // Resetar seleção
    _selectedPiece = null;
    _possibleMoves = [];
    _isInMultiCapture = false;
    _captureSequence = [];
    
    notifyListeners();
  }
  
  // Enviar movimento para o servidor
  void _sendMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (_currentRoomCode != null) {
      // Criar objetos Position para from e to
      final from = Position(row: fromRow, col: fromCol);
      final to = Position(row: toRow, col: toCol);
      
      // Chamar o método makeMove com a assinatura correta
      _webSocketService.makeMove(_currentRoomCode!, from, to);
      
      // Trocar o turno localmente
      _isWhiteTurn = !_isWhiteTurn;
      _updateStatusMessage();
    }
  }
  
  // Enviar sequência de capturas para o servidor
  void _sendCaptureSequence() {
    if (_currentRoomCode != null && _captureSequence.isNotEmpty) {
      // Chamar o método sendCaptureSequence com a assinatura correta
      _webSocketService.sendCaptureSequence(
        _captureSequence,
        _currentRoomCode!,
        _playerNickname ?? 'Jogador'
      );
      
      // Trocar o turno localmente após a sequência completa
      _isWhiteTurn = !_isWhiteTurn;
      _updateStatusMessage();
      
      // Limpar a sequência
      _captureSequence = [];
    }
  }
  
  // Sair da sala
  Future<void> leaveRoom() async {
    if (_currentRoomCode != null) {
      await _webSocketService.leaveRoom(_currentRoomCode!);
      _audioService.disconnect();
    }
    
    _currentRoomCode = null;
    _playerColor = null;
    _opponentNickname = null;
    _isConnected = false;
    _gameStarted = false;
    _selectedPiece = null;
    _possibleMoves = [];
    _isInMultiCapture = false;
    _captureSequence = [];
    _showVictoryAnimation = false;
    _winnerColor = null;
    
    notifyListeners();
  }
  
  // Limpar recursos
  void dispose() {
    _webSocketService.disconnect();
    _audioService.dispose();
    super.dispose();
  }
}
