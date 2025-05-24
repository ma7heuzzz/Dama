import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:xdama/services/websocket_service.dart';

// Enum para status de áudio
enum AudioStatus {
  initialized,
  connecting,
  connected,
  disconnected,
  muted,
  unmuted,
  error
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final WebSocketService _webSocketService = WebSocketService();
  final Logger _logger = Logger();

  // Estado
  bool _isAudioEnabled = true;
  bool _isInitialized = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _currentRoomCode;

  // Streams
  final _audioStatusController = StreamController<bool>.broadcast();
  Stream<bool> get audioStatusStream => _audioStatusController.stream;
  
  // Stream para status de áudio (enum)
  final _audioStatusEnumController = StreamController<AudioStatus>.broadcast();
  Stream<AudioStatus> get audioStatusEnumStream => _audioStatusEnumController.stream;

  // Getters
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;

  // Inicializar o serviço
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.d('Inicializando AudioService');
    _audioStatusEnumController.add(AudioStatus.initialized);

    try {
      // Versão simplificada para web e mobile
      _isInitialized = true;
      _audioStatusController.add(_isAudioEnabled);
      _audioStatusEnumController.add(AudioStatus.unmuted);
      
      _logger.d('AudioService inicializado com sucesso');
    } catch (e) {
      _audioStatusEnumController.add(AudioStatus.error);
      _logger.e('Erro ao inicializar AudioService: $e');
    }
  }

  // Método para compatibilidade com GameProvider
  Future<void> connectToPeer(String roomCode) async {
    _currentRoomCode = roomCode;
    await startAudioCall();
  }

  // Método para compatibilidade com GameProvider
  Future<void> disconnect() async {
    await dispose();
  }

  // Iniciar chamada de áudio (simulada)
  Future<void> startAudioCall() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isConnecting || _isConnected) {
      _logger.d('Chamada de áudio já em andamento');
      return;
    }
    
    _logger.d('Iniciando chamada de áudio');
    _isConnecting = true;
    _audioStatusEnumController.add(AudioStatus.connecting);
    
    try {
      // Simular conexão bem-sucedida após um pequeno delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isConnected = true;
      _isConnecting = false;
      _audioStatusEnumController.add(AudioStatus.connected);
      
      _logger.d('Chamada de áudio conectada com sucesso');
    } catch (e) {
      _isConnecting = false;
      _audioStatusEnumController.add(AudioStatus.error);
      _logger.e('Erro ao iniciar chamada de áudio: $e');
    }
  }

  // Alternar estado do áudio (mute/unmute)
  Future<void> toggleMute() async {
    _logger.d('Alternando estado do áudio');
    
    try {
      _isAudioEnabled = !_isAudioEnabled;
      _audioStatusController.add(_isAudioEnabled);
      
      // Atualizar status enum
      if (_isAudioEnabled) {
        _audioStatusEnumController.add(AudioStatus.unmuted);
      } else {
        _audioStatusEnumController.add(AudioStatus.muted);
      }
      
      _logger.d('Estado do áudio alternado para: $_isAudioEnabled');
    } catch (e) {
      _logger.e('Erro ao alternar estado do áudio: $e');
    }
  }

  // Liberar recursos
  Future<void> dispose() async {
    _logger.d('Liberando recursos do AudioService');
    
    try {
      // Fechar controllers
      if (!_audioStatusController.isClosed) {
        _audioStatusController.add(false);
      }
      
      if (!_audioStatusEnumController.isClosed) {
        _audioStatusEnumController.add(AudioStatus.disconnected);
      }
      
      _isInitialized = false;
      _isConnected = false;
      _logger.d('Recursos do AudioService liberados com sucesso');
    } catch (e) {
      _logger.e('Erro ao liberar recursos do AudioService: $e');
    }
  }
}
