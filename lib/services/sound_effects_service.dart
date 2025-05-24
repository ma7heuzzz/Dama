import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundEffectsService {
  static final SoundEffectsService _instance = SoundEffectsService._internal();
  factory SoundEffectsService() => _instance;
  SoundEffectsService._internal();
  
  final _logger = print; // Simplificado para usar print diretamente
  
  // Players para diferentes efeitos sonoros
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _capturePlayer = AudioPlayer();
  final AudioPlayer _promotionPlayer = AudioPlayer();
  final AudioPlayer _victoryPlayer = AudioPlayer();
  final AudioPlayer _defeatPlayer = AudioPlayer();
  final AudioPlayer _lobbyMusicPlayer = AudioPlayer();
  final AudioPlayer _pieceSelectPlayer = AudioPlayer();
  
  // Estado
  bool _isSoundEnabled = true;
  bool _isLobbyMusicPlaying = false;
  double _volume = 0.7;
  
  // Getters
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isLobbyMusicPlaying => _isLobbyMusicPlaying;
  double get volume => _volume;
  
  // Inicializar o serviço
  Future<void> initialize() async {
    try {
      _logger('Inicializando SoundEffectsService');
      
      // Configurar volume inicial
      await _movePlayer.setVolume(_volume);
      await _capturePlayer.setVolume(_volume);
      await _promotionPlayer.setVolume(_volume);
      await _victoryPlayer.setVolume(_volume);
      await _defeatPlayer.setVolume(_volume);
      await _pieceSelectPlayer.setVolume(_volume);
      await _lobbyMusicPlayer.setVolume(_volume * 0.5); // Música de fundo mais baixa
      
      // Configurar loop para música do lobby
      await _lobbyMusicPlayer.setReleaseMode(ReleaseMode.loop);
      
      _logger('SoundEffectsService inicializado com sucesso');
    } catch (e) {
      _logger('Erro ao inicializar SoundEffectsService: $e');
    }
  }
  
  // Reproduzir som de movimento - métodos com nomes compatíveis com game_screen.dart
  Future<void> playMove() async {
    await playMoveSound();
  }
  
  Future<void> playMoveSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _movePlayer.stop();
      await _movePlayer.play(AssetSource('sounds/move.mp3'));
      _logger('Som de movimento reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de movimento: $e');
    }
  }
  
  // Reproduzir som de captura - métodos com nomes compatíveis com game_screen.dart
  Future<void> playCapture() async {
    await playCaptureSound();
  }
  
  Future<void> playCaptureSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _capturePlayer.stop();
      await _capturePlayer.play(AssetSource('sounds/capture.mp3'));
      _logger('Som de captura reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de captura: $e');
    }
  }
  
  // Reproduzir som de seleção de peça
  Future<void> playPieceSelect() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _pieceSelectPlayer.stop();
      await _pieceSelectPlayer.play(AssetSource('sounds/move.mp3'), volume: 0.3);
      _logger('Som de seleção de peça reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de seleção de peça: $e');
    }
  }
  
  // Reproduzir som de promoção
  Future<void> playPromotionSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _promotionPlayer.stop();
      await _promotionPlayer.play(AssetSource('sounds/promotion.mp3'));
      _logger('Som de promoção reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de promoção: $e');
    }
  }
  
  // Reproduzir som de vitória
  Future<void> playVictorySound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _victoryPlayer.stop();
      await _victoryPlayer.play(AssetSource('sounds/victory.mp3'));
      _logger('Som de vitória reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de vitória: $e');
    }
  }
  
  // Reproduzir som de derrota
  Future<void> playDefeatSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _defeatPlayer.stop();
      await _defeatPlayer.play(AssetSource('sounds/defeat.mp3'));
      _logger('Som de derrota reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de derrota: $e');
    }
  }
  
  // Iniciar música do lobby
  Future<void> startLobbyMusic() async {
    if (!_isSoundEnabled || _isLobbyMusicPlaying) return;
    
    try {
      await _lobbyMusicPlayer.stop();
      await _lobbyMusicPlayer.play(AssetSource('sounds/lobby_background.mp3'));
      _isLobbyMusicPlaying = true;
      _logger('Música do lobby iniciada');
    } catch (e) {
      _logger('Erro ao iniciar música do lobby: $e');
    }
  }
  
  // Parar música do lobby
  Future<void> stopLobbyMusic() async {
    if (!_isLobbyMusicPlaying) return;
    
    try {
      await _lobbyMusicPlayer.stop();
      _isLobbyMusicPlaying = false;
      _logger('Música do lobby parada');
    } catch (e) {
      _logger('Erro ao parar música do lobby: $e');
    }
  }
  
  // Alternar música do lobby
  Future<void> toggleLobbyMusic() async {
    if (_isLobbyMusicPlaying) {
      await stopLobbyMusic();
    } else {
      await startLobbyMusic();
    }
  }
  
  // Ativar/desativar sons
  void enableSound() {
    _isSoundEnabled = true;
    _logger('Sons ativados');
  }
  
  void disableSound() {
    _isSoundEnabled = false;
    stopLobbyMusic();
    _logger('Sons desativados');
  }
  
  void toggleSound() {
    if (_isSoundEnabled) {
      disableSound();
    } else {
      enableSound();
    }
  }
  
  // Ajustar volume
  Future<void> setVolume(double volume) async {
    if (volume < 0.0) volume = 0.0;
    if (volume > 1.0) volume = 1.0;
    
    _volume = volume;
    
    try {
      await _movePlayer.setVolume(_volume);
      await _capturePlayer.setVolume(_volume);
      await _promotionPlayer.setVolume(_volume);
      await _victoryPlayer.setVolume(_volume);
      await _defeatPlayer.setVolume(_volume);
      await _pieceSelectPlayer.setVolume(_volume);
      await _lobbyMusicPlayer.setVolume(_volume * 0.5); // Música de fundo mais baixa
      
      _logger('Volume ajustado para $_volume');
    } catch (e) {
      _logger('Erro ao ajustar volume: $e');
    }
  }
  
  // Liberar recursos
  void dispose() {
    _movePlayer.dispose();
    _capturePlayer.dispose();
    _promotionPlayer.dispose();
    _victoryPlayer.dispose();
    _defeatPlayer.dispose();
    _pieceSelectPlayer.dispose();
    _lobbyMusicPlayer.dispose();
    
    _logger('SoundEffectsService liberado');
  }
}
