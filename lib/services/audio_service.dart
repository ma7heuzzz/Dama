import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isAudioEnabled = true;
  bool _isInitialized = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _remoteSocketId;
  String? _currentRoomCode;

  // Streams
  final _audioStatusController = StreamController<bool>.broadcast();
  Stream<bool> get audioStatusStream => _audioStatusController.stream;
  
  // Stream para status de áudio (enum)
  final _audioStatusEnumController = StreamController<AudioStatus>.broadcast();
  Stream<AudioStatus> get audioStatusEnumStream => _audioStatusEnumController.stream;

  // Configurações WebRTC
  final _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {
        'urls': 'turn:numb.viagenie.ca',
        'credential': 'muazkh',
        'username': 'webrtc@live.com'
      },
      {
        'urls': 'turn:turn.anyfirewall.com:443?transport=tcp',
        'credential': 'webrtc',
        'username': 'webrtc'
      }
    ],
    'sdpSemantics': 'unified-plan'
  };

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
      // Configurar listeners para eventos WebRTC
      _setupWebSocketListeners();

      // Inicializar stream de áudio local
      await _initLocalStream();

      _isInitialized = true;
      _logger.d('AudioService inicializado com sucesso');
    } catch (e) {
      _audioStatusEnumController.add(AudioStatus.error);
      _logger.e('Erro ao inicializar AudioService: $e');
      throw Exception('Falha ao inicializar AudioService: $e');
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

  // Configurar listeners para eventos WebRTC
  void _setupWebSocketListeners() {
    // Usar streams em vez do método 'on'
    _webSocketService.videoOfferStream.listen((data) async {
      _logger.d('Oferta de áudio recebida: $data');
      
      try {
        // Verificar se a oferta não é do próprio usuário
        if (data['from'] != _webSocketService.nickname) {
          _remoteSocketId = data['from'];
          _currentRoomCode = data['roomCode'];
          
          _audioStatusEnumController.add(AudioStatus.connecting);
          
          // Criar conexão peer se não existir
          await _createPeerConnection();
          
          // Definir descrição remota
          final rtcSessionDescription = RTCSessionDescription(
            data['sdp'],
            data['type'],
          );
          
          await _peerConnection!.setRemoteDescription(rtcSessionDescription);
          
          // Criar resposta
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          
          // Enviar resposta
          _sendAudioAnswer(answer);
        }
      } catch (e) {
        _audioStatusEnumController.add(AudioStatus.error);
        _logger.e('Erro ao processar oferta de áudio: $e');
      }
    });

    _webSocketService.videoAnswerStream.listen((data) async {
      _logger.d('Resposta de áudio recebida: $data');
      
      try {
        // Verificar se a resposta não é do próprio usuário
        if (data['from'] != _webSocketService.nickname) {
          _remoteSocketId = data['from'];
          
          // Definir descrição remota
          final rtcSessionDescription = RTCSessionDescription(
            data['sdp'],
            data['type'],
          );
          
          await _peerConnection?.setRemoteDescription(rtcSessionDescription);
          _isConnected = true;
          _audioStatusEnumController.add(AudioStatus.connected);
          _logger.d('Conexão de áudio estabelecida');
        }
      } catch (e) {
        _audioStatusEnumController.add(AudioStatus.error);
        _logger.e('Erro ao processar resposta de áudio: $e');
      }
    });

    _webSocketService.iceStream.listen((data) async {
      _logger.d('Candidato ICE de áudio recebido: $data');
      
      try {
        // Verificar se o candidato não é do próprio usuário
        if (data['from'] != _webSocketService.nickname) {
          _remoteSocketId = data['from'];
          
          // Adicionar candidato ICE
          if (_peerConnection != null && data['candidate'] != null) {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            
            await _peerConnection!.addCandidate(candidate);
          }
        }
      } catch (e) {
        _logger.e('Erro ao processar candidato ICE de áudio: $e');
      }
    });
  }

  // Inicializar stream de áudio local
  Future<void> _initLocalStream() async {
    _logger.d('Inicializando stream de áudio local');
    
    try {
      final mediaConstraints = {
        'audio': true,
        'video': false
      };
      
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _isAudioEnabled = true;
      _audioStatusController.add(_isAudioEnabled);
      _audioStatusEnumController.add(AudioStatus.unmuted);
      
      _logger.d('Stream de áudio local inicializado com sucesso');
    } catch (e) {
      _logger.e('Erro ao inicializar stream de áudio local: $e');
      _isAudioEnabled = false;
      _audioStatusController.add(_isAudioEnabled);
      _audioStatusEnumController.add(AudioStatus.error);
      throw Exception('Falha ao inicializar stream de áudio local: $e');
    }
  }

  // Criar conexão peer
  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) {
      await _closePeerConnection();
    }
    
    _logger.d('Criando conexão peer para áudio');
    
    try {
      _peerConnection = await createPeerConnection(_rtcConfig);
      
      // Adicionar tracks de áudio
      if (_localStream != null) {
        _localStream!.getAudioTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }
      
      // Configurar handlers de eventos
      _peerConnection!.onIceCandidate = _handleIceCandidate;
      _peerConnection!.onConnectionState = _handleConnectionStateChange;
      _peerConnection!.onIceConnectionState = _handleIceConnectionStateChange;
      
      // Configurar handler para tracks remotos
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        _logger.d('Track remoto recebido: ${event.track.kind}');
        
        if (event.track.kind == 'audio') {
          _logger.d('Track de áudio remoto recebido');
        }
      };
      
      _logger.d('Conexão peer para áudio criada com sucesso');
    } catch (e) {
      _audioStatusEnumController.add(AudioStatus.error);
      _logger.e('Erro ao criar conexão peer para áudio: $e');
      throw Exception('Falha ao criar conexão peer para áudio: $e');
    }
  }

  // Iniciar chamada de áudio
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
      await _createPeerConnection();
      
      // Criar oferta
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      // Enviar oferta
      _sendAudioOffer(offer);
      
      _logger.d('Oferta de áudio enviada');
    } catch (e) {
      _isConnecting = false;
      _audioStatusEnumController.add(AudioStatus.error);
      _logger.e('Erro ao iniciar chamada de áudio: $e');
      throw Exception('Falha ao iniciar chamada de áudio: $e');
    }
  }

  // Enviar oferta de áudio
  void _sendAudioOffer(RTCSessionDescription offer) {
    _logger.d('Enviando oferta de áudio');
    
    final data = {
      'type': offer.type,
      'sdp': offer.sdp,
      'from': _webSocketService.nickname,
      'roomCode': _currentRoomCode ?? _webSocketService.currentRoomCode,
    };
    
    _webSocketService.emitEvent('videoOffer', data);
  }

  // Enviar resposta de áudio
  void _sendAudioAnswer(RTCSessionDescription answer) {
    _logger.d('Enviando resposta de áudio');
    
    final data = {
      'type': answer.type,
      'sdp': answer.sdp,
      'from': _webSocketService.nickname,
      'roomCode': _currentRoomCode ?? _webSocketService.currentRoomCode,
      'to': _remoteSocketId,
    };
    
    _webSocketService.emitEvent('videoAnswer', data);
  }

  // Handler para candidatos ICE
  void _handleIceCandidate(RTCIceCandidate candidate) {
    _logger.d('Candidato ICE gerado: ${candidate.candidate}');
    
    final data = {
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
      'from': _webSocketService.nickname,
      'roomCode': _currentRoomCode ?? _webSocketService.currentRoomCode,
      'to': _remoteSocketId,
    };
    
    _webSocketService.emitEvent('iceCandidate', data);
  }

  // Handler para mudanças de estado da conexão
  void _handleConnectionStateChange(RTCPeerConnectionState state) {
    _logger.d('Estado da conexão alterado: $state');
    
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _isConnected = true;
        _isConnecting = false;
        _audioStatusEnumController.add(AudioStatus.connected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _isConnected = false;
        _isConnecting = false;
        _audioStatusEnumController.add(AudioStatus.error);
        // Tentar reconectar após falha
        _reconnect();
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _isConnected = false;
        _isConnecting = false;
        _audioStatusEnumController.add(AudioStatus.disconnected);
        // Tentar reconectar após falha
        _reconnect();
        break;
      default:
        break;
    }
  }

  // Handler para mudanças de estado da conexão ICE
  void _handleIceConnectionStateChange(RTCIceConnectionState state) {
    _logger.d('Estado da conexão ICE alterado: $state');
    
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        // Tentar reiniciar ICE
        _restartIce();
        break;
      default:
        break;
    }
  }

  // Reiniciar ICE
  Future<void> _restartIce() async {
    _logger.d('Reiniciando ICE');
    
    try {
      if (_peerConnection != null && _isConnecting) {
        // Criar nova oferta com restart ICE
        final offer = await _peerConnection!.createOffer({'iceRestart': true});
        await _peerConnection!.setLocalDescription(offer);
        
        // Enviar oferta
        _sendAudioOffer(offer);
        
        _logger.d('ICE reiniciado com sucesso');
      }
    } catch (e) {
      _logger.e('Erro ao reiniciar ICE: $e');
    }
  }

  // Reconectar após falha
  Future<void> _reconnect() async {
    _logger.d('Tentando reconectar áudio');
    
    if (_isConnecting) return;
    
    _isConnecting = true;
    _audioStatusEnumController.add(AudioStatus.connecting);
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      await startAudioCall();
    } catch (e) {
      _isConnecting = false;
      _audioStatusEnumController.add(AudioStatus.error);
      _logger.e('Erro ao reconectar áudio: $e');
    }
  }

  // Alternar estado do áudio (mute/unmute)
  Future<void> toggleMute() async {
    _logger.d('Alternando estado do áudio');
    
    if (_localStream == null) {
      _logger.d('Stream local não inicializado');
      return;
    }
    
    try {
      final audioTracks = _localStream!.getAudioTracks();
      
      for (final track in audioTracks) {
        track.enabled = !track.enabled;
      }
      
      _isAudioEnabled = audioTracks.isNotEmpty ? audioTracks.first.enabled : false;
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

  // Fechar conexão peer
  Future<void> _closePeerConnection() async {
    _logger.d('Fechando conexão peer de áudio');
    
    try {
      await _peerConnection?.close();
      _peerConnection = null;
      _isConnected = false;
      _isConnecting = false;
      _audioStatusEnumController.add(AudioStatus.disconnected);
      
      _logger.d('Conexão peer de áudio fechada com sucesso');
    } catch (e) {
      _logger.e('Erro ao fechar conexão peer de áudio: $e');
    }
  }

  // Liberar recursos
  Future<void> dispose() async {
    _logger.d('Liberando recursos do AudioService');
    
    try {
      // Fechar conexão peer
      await _closePeerConnection();
      
      // Parar stream local
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream = null;
      
      // Fechar controllers
      if (!_audioStatusController.isClosed) {
        _audioStatusController.add(false);
      }
      
      if (!_audioStatusEnumController.isClosed) {
        _audioStatusEnumController.add(AudioStatus.disconnected);
      }
      
      _isInitialized = false;
      _logger.d('Recursos do AudioService liberados com sucesso');
    } catch (e) {
      _logger.e('Erro ao liberar recursos do AudioService: $e');
    }
  }
}
