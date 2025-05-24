import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdama/models/game_piece.dart';
import 'package:xdama/providers/game_provider.dart';
import 'package:xdama/services/sound_effects_service.dart';
import 'package:xdama/services/websocket_service.dart';
import 'package:xdama/utils/constants.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({Key? key}) : super(key: key);

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final SoundEffectsService _soundEffectsService = SoundEffectsService();
  Position? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _soundEffectsService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final row = index ~/ 8;
            final col = index % 8;
            final isBlackSquare = (row + col) % 2 == 1;
            final piece = gameProvider.board.isNotEmpty && row < gameProvider.board.length && col < gameProvider.board[row].length
                ? gameProvider.board[row][col]
                : null;

            // Verificar se é a vez do jogador
            final isMyTurn = (gameProvider.playerColor == 'white' && gameProvider.isWhiteTurn) ||
                (gameProvider.playerColor == 'black' && !gameProvider.isWhiteTurn);

            // Verificar se a peça está selecionada
            final isSelected = _selectedPosition != null &&
                _selectedPosition!.row == row &&
                _selectedPosition!.col == col;

            // Verificar se a posição é um movimento possível
            final isPossibleMove = _selectedPosition != null &&
                _selectedPosition!.row != row &&
                _selectedPosition!.col != col &&
                _canMoveTo(gameProvider, row, col);

            return GestureDetector(
              onTap: () {
                if (!gameProvider.gameStarted || !isMyTurn) return;

                if (piece != null && piece.isWhite == gameProvider.isWhiteTurn) {
                  // Selecionar peça
                  setState(() {
                    _selectedPosition = Position(row: row, col: col);
                  });
                  _soundEffectsService.playPieceSelect();
                } else if (_selectedPosition != null) {
                  // Mover peça
                  if (_isCapture(gameProvider, row, col)) {
                    _soundEffectsService.playCapture();
                  } else {
                    _soundEffectsService.playMove();
                  }
                  
                  _movePiece(gameProvider, row, col);
                  setState(() {
                    _selectedPosition = null;
                  });
                }
              },
              child: Container(
                color: isBlackSquare 
                    ? (isSelected 
                        ? Colors.blue.shade800 
                        : (isPossibleMove 
                            ? Colors.blue.shade600 
                            : Colors.brown.shade800))
                    : Colors.brown.shade200,
                child: piece != null
                    ? _buildPiece(piece, gameProvider)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPiece(GamePiece piece, GameProvider gameProvider) {
    final isInMultiCapture = gameProvider.isInMultiCapture && 
        _selectedPosition != null && 
        piece.position.row == _selectedPosition!.row && 
        piece.position.col == _selectedPosition!.col;

    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: piece.isWhite ? Colors.white : Colors.black,
          shape: BoxShape.circle,
          border: Border.all(
            color: isInMultiCapture ? Colors.red : Colors.grey,
            width: isInMultiCapture ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: piece.isKing
            ? Center(
                child: Icon(
                  Icons.star,
                  color: piece.isWhite ? Colors.black : Colors.white,
                  size: 18,
                ),
              )
            : null,
      ),
    );
  }

  bool _canMoveTo(GameProvider gameProvider, int row, int col) {
    if (_selectedPosition == null) return false;
    
    final fromRow = _selectedPosition!.row;
    final fromCol = _selectedPosition!.col;
    final piece = gameProvider.board[fromRow][fromCol];
    
    if (piece == null) return false;
    
    // Verificar se é um movimento diagonal
    final rowDiff = (row - fromRow).abs();
    final colDiff = (col - fromCol).abs();
    
    if (rowDiff != colDiff) return false;
    
    // Verificar se o destino está vazio
    if (gameProvider.board[row][col] != null) return false;
    
    // Verificar direção do movimento (peças normais só podem mover para frente)
    if (!piece.isKing) {
      if (piece.isWhite && row <= fromRow) return false;
      if (!piece.isWhite && row >= fromRow) return false;
    }
    
    // Movimento simples (1 casa)
    if (rowDiff == 1) return true;
    
    // Movimento de captura (2 casas)
    if (rowDiff == 2) {
      final capturedRow = (fromRow + row) ~/ 2;
      final capturedCol = (fromCol + col) ~/ 2;
      final capturedPiece = gameProvider.board[capturedRow][capturedCol];
      
      // Verificar se há uma peça adversária para capturar
      return capturedPiece != null && capturedPiece.isWhite != piece.isWhite;
    }
    
    return false;
  }

  bool _isCapture(GameProvider gameProvider, int row, int col) {
    if (_selectedPosition == null) return false;
    
    final fromRow = _selectedPosition!.row;
    final fromCol = _selectedPosition!.col;
    
    // Verificar se é um movimento de 2 casas (captura)
    return (row - fromRow).abs() == 2 && (col - fromCol).abs() == 2;
  }

  void _movePiece(GameProvider gameProvider, int row, int col) {
    if (_selectedPosition == null) return;
    
    final fromRow = _selectedPosition!.row;
    final fromCol = _selectedPosition!.col;
    
    // Enviar movimento para o servidor usando WebSocketService
    final WebSocketService webSocketService = WebSocketService();
    final from = Position(row: fromRow, col: fromCol);
    final to = Position(row: row, col: col);
    
    webSocketService.sendMove(from, to);
  }
}
