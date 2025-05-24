import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xdama/models/game_piece.dart';
import 'package:xdama/providers/game_provider.dart';
import 'package:xdama/services/audio_service.dart';
import 'package:xdama/services/sound_effects_service.dart';
import 'package:xdama/services/video_service.dart';
import 'package:xdama/utils/constants.dart';
import 'package:xdama/widgets/video_call_widget.dart';
import 'package:xdama/widgets/victory_animation.dart';

import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  final String roomCode;
  final String nickname;

  const GameScreen({
    Key? key,
    required this.roomCode,
    required this.nickname,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AudioService _audioService = AudioService();
  final VideoService _videoService = VideoService();
  final SoundEffectsService _soundEffectsService = SoundEffectsService();
  bool _isAudioEnabled = true;
  bool _isVideoEnabled = true;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Inicializar serviços de áudio e vídeo
    await _audioService.initialize();
    await _videoService.initialize();
    await _soundEffectsService.initialize();
    
    // Iniciar chamada de áudio e vídeo
    await _audioService.startAudioCall();
    await _videoService.startVideoCall();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.initializeGame(widget.roomCode, nickname: widget.nickname);
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    _videoService.dispose();
    _soundEffectsService.dispose();
    super.dispose();
  }

  void _toggleAudio() {
    _audioService.toggleMute();
  }

  void _toggleVideo() {
    _videoService.toggleVideo();
  }

  @override
  Widget build(BuildContext context) {
    // Obter o tamanho da tela e orientação
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    return WillPopScope(
      onWillPop: () async {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        await gameProvider.leaveRoom();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            if (gameProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Erro',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      gameProvider.error!,
                      style: TextStyle(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Voltar ao Lobby',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      // Barra superior com botão de voltar, título e controles de áudio/vídeo
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: AppColors.surface,
                        child: Row(
                          children: [
                            // Botão de voltar
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: AppColors.white),
                              onPressed: () async {
                                await gameProvider.leaveRoom();
                                Navigator.pop(context);
                              },
                            ),
                            
                            // Título da sala
                            Expanded(
                              child: Text(
                                'MESA #${widget.roomCode}',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            // Controles de áudio e vídeo
                            StreamBuilder<bool>(
                              stream: _audioService.audioStatusStream,
                              initialData: _isAudioEnabled,
                              builder: (context, snapshot) {
                                final isEnabled = snapshot.data ?? true;
                                return IconButton(
                                  icon: Icon(
                                    isEnabled ? Icons.mic : Icons.mic_off,
                                    color: isEnabled ? AppColors.white : Colors.red,
                                  ),
                                  onPressed: _toggleAudio,
                                  tooltip: isEnabled ? 'Desativar microfone' : 'Ativar microfone',
                                );
                              },
                            ),
                            StreamBuilder<bool>(
                              stream: _videoService.videoStatusStream,
                              initialData: _isVideoEnabled,
                              builder: (context, snapshot) {
                                final isEnabled = snapshot.data ?? true;
                                return IconButton(
                                  icon: Icon(
                                    isEnabled ? Icons.videocam : Icons.videocam_off,
                                    color: isEnabled ? AppColors.white : Colors.red,
                                  ),
                                  onPressed: _toggleVideo,
                                  tooltip: isEnabled ? 'Desativar câmera' : 'Ativar câmera',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Área principal do jogo
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Altura disponível para todo o conteúdo
                            final availableHeight = constraints.maxHeight;
                            final availableWidth = constraints.maxWidth;
                            
                            // Ajustar proporções com base na orientação e tamanho da tela
                            final topRowHeight = isPortrait 
                                ? availableHeight * 0.25  // Em modo retrato, linha superior menor
                                : availableHeight * 0.3;  // Em modo paisagem, linha superior maior
                            
                            // Calcular o tamanho ideal do tabuleiro (quadrado)
                            final boardSize = isPortrait
                                ? availableWidth - 16  // Em modo retrato, quase toda a largura
                                : (availableHeight - topRowHeight - 80);  // Em modo paisagem, altura disponível
                            
                            return Column(
                              children: [
                                // LINHA SUPERIOR: Duas colunas (informações e câmera)
                                Container(
                                  height: topRowHeight,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // COLUNA 1: Informações (lado esquerdo)
                                      Expanded(
                                        flex: 7, // Proporção 70%
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildInfoBox(
                                              'Eu sou: ${gameProvider.playerColor == 'white' ? 'BRANCA' : 'PRETA'}',
                                              AppColors.surface,
                                            ),
                                            _buildInfoBox(
                                              'É vez das: ${gameProvider.isWhiteTurn ? 'BRANCAS' : 'PRETAS'}',
                                              AppColors.surface,
                                            ),
                                            _buildInfoBox(
                                              gameProvider.statusMessage ?? 'Informações',
                                              AppColors.surface,
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // COLUNA 2: Câmera (lado direito)
                                      Expanded(
                                        flex: 3, // Proporção 30%
                                        child: Container(
                                          margin: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: VideoCallWidget(
                                              videoService: _videoService,
                                              audioService: _audioService,
                                              isCameraEnabled: _isVideoEnabled,
                                              opponentNickname: gameProvider.opponentNickname,
                                              onCameraToggle: (enabled) {
                                                setState(() {
                                                  _isVideoEnabled = enabled;
                                                });
                                              },
                                              onMicToggle: (enabled) {
                                                setState(() {
                                                  _isAudioEnabled = enabled;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // LINHA INFERIOR: Tabuleiro ocupando toda a largura
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Tabuleiro centralizado
                                      Expanded(
                                        child: Center(
                                          child: Container(
                                            width: boardSize,
                                            height: boardSize,
                                            margin: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.white, width: 2),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: _buildGameBoard(gameProvider),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Informações adicionais (clicável para sair)
                                      GestureDetector(
                                        onTap: () async {
                                          // Mostrar diálogo de confirmação
                                          final shouldExit = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: AppColors.surface,
                                              title: Text(
                                                'Sair da Mesa',
                                                style: TextStyle(color: AppColors.white),
                                              ),
                                              content: Text(
                                                'Tem certeza que deseja sair desta mesa?',
                                                style: TextStyle(color: Colors.white70),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: Text(
                                                    'Cancelar',
                                                    style: TextStyle(color: AppColors.white),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: Text(
                                                    'Sair',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ) ?? false;
                                          
                                          if (shouldExit) {
                                            await gameProvider.leaveRoom();
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Clique para sair da mesa',
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Animação de vitória (sobreposta)
                if (gameProvider.showVictoryAnimation)
                  VictoryAnimation(
                    winnerColor: gameProvider.winnerColor ?? 'white',
                    isWinner: gameProvider.playerColor == gameProvider.winnerColor,
                    onAnimationComplete: () {
                      gameProvider.closeVictoryAnimation();
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGameBoard(GameProvider gameProvider) {
    return const GameBoard();
  }
}
