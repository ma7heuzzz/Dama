import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class SoundEffectsService {
  static final SoundEffectsService _instance = SoundEffectsService._internal();
  factory SoundEffectsService() => _instance;
  SoundEffectsService._internal();
  
  final _logger = print; // Simplificado para usar print diretamente
  
  // Mapa de players de áudio para web
  final Map<String, html.AudioElement> _audioElements = {};
  
  // Estado
  bool _isSoundEnabled = true;
  bool _isLobbyMusicPlaying = false;
  double _volume = 0.7;
  bool _isInitialized = false;
  
  // Getters
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isLobbyMusicPlaying => _isLobbyMusicPlaying;
  double get volume => _volume;
  
  // Inicializar o serviço
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger('Inicializando SoundEffectsService');
      
      // Pré-carregar sons para web
      if (kIsWeb) {
        _preloadAudio('sounds/move.mp3', 'move');
        _preloadAudio('sounds/capture.mp3', 'capture');
        _preloadAudio('sounds/promotion.mp3', 'promotion');
        _preloadAudio('sounds/victory.mp3', 'victory');
        _preloadAudio('sounds/defeat.mp3', 'defeat');
        _preloadAudio('sounds/lobby_background.mp3', 'lobby', loop: true);
      }
      
      _isInitialized = true;
      _logger('SoundEffectsService inicializado com sucesso');
    } catch (e) {
      _logger('Erro ao inicializar SoundEffectsService: $e');
    }
  }
  
  // Pré-carregar áudio para web
  void _preloadAudio(String path, String id, {bool loop = false}) {
    if (!kIsWeb) return;
    
    try {
      final audioElement = html.AudioElement();
      audioElement.src = path;
      audioElement.preload = 'auto';
      audioElement.volume = _volume;
      audioElement.loop = loop;
      _audioElements[id] = audioElement;
    } catch (e) {
      _logger('Erro ao pré-carregar áudio $id: $e');
    }
  }
  
  // Reproduzir som via web
  Future<void> _playWebSound(String id) async {
    if (!kIsWeb || !_isSoundEnabled) return;
    
    try {
      final audioElement = _audioElements[id];
      if (audioElement != null) {
        audioElement.currentTime = 0;
        await audioElement.play();
      }
    } catch (e) {
      _logger('Erro ao reproduzir som web $id: $e');
    }
  }
  
  // Parar som via web
  Future<void> _stopWebSound(String id) async {
    if (!kIsWeb) return;
    
    try {
      final audioElement = _audioElements[id];
      if (audioElement != null) {
        audioElement.pause();
        audioElement.currentTime = 0;
      }
    } catch (e) {
      _logger('Erro ao parar som web $id: $e');
    }
  }
  
  // Reproduzir som de movimento - métodos com nomes compatíveis com game_screen.dart
  Future<void> playMove() async {
    await playMoveSound();
  }
  
  Future<void> playMoveSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      if (kIsWeb) {
        await _playWebSound('move');
      }
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
      if (kIsWeb) {
        await _playWebSound('capture');
      }
      _logger('Som de captura reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de captura: $e');
    }
  }
  
  // Reproduzir som de seleção de peça
  Future<void> playPieceSelect() async {
    if (!_isSoundEnabled) return;
    
    try {
      if (kIsWeb) {
        // Usar o mesmo som de movimento com volume mais baixo
        final moveElement = _audioElements['move'];
        if (moveElement != null) {
          final originalVolume = moveElement.volume;
          moveElement.volume = _volume * 0.3;
          await _playWebSound('move');
          moveElement.volume = originalVolume;
        }
      }
      _logger('Som de seleção de peça reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de seleção de peça: $e');
    }
  }
  
  // Reproduzir som de promoção
  Future<void> playPromotionSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      if (kIsWeb) {
        await _playWebSound('promotion');
      }
      _logger('Som de promoção reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de promoção: $e');
    }
  }
  
  // Reproduzir som de vitória
  Future<void> playVictorySound() async {
    if (!_isSoundEnabled) return;
    
    try {
      if (kIsWeb) {
        await _playWebSound('victory');
      }
      _logger('Som de vitória reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de vitória: $e');
    }
  }
  
  // Reproduzir som de derrota
  Future<void> playDefeatSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      if (kIsWeb) {
        await _playWebSound('defeat');
      }
      _logger('Som de derrota reproduzido');
    } catch (e) {
      _logger('Erro ao reproduzir som de derrota: $e');
    }
  }
  
  // Iniciar música do lobby
  Future<void> startLobbyMusic() async {
    if (!_isSoundEnabled || _isLobbyMusicPlaying) return;
    
    try {
      if (kIsWeb) {
        await _playWebSound('lobby');
      }
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
      if (kIsWeb) {
        await _stopWebSound('lobby');
      }
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
      if (kIsWeb) {
        // Atualizar volume de todos os elementos de áudio
        _audioElements.forEach((id, element) {
          element.volume = id == 'lobby' ? _volume * 0.5 : _volume;
        });
      }
      
      _logger('Volume ajustado para $_volume');
    } catch (e) {
      _logger('Erro ao ajustar volume: $e');
    }
  }
  
  // Liberar recursos
  void dispose() {
    if (kIsWeb) {
      // Parar e remover todos os elementos de áudio
      _audioElements.forEach((id, element) {
        element.pause();
        element.remove();
      });
      _audioElements.clear();
    }
    
    _logger('SoundEffectsService liberado');
  }
}
