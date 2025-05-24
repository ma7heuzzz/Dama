import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:xdama/services/websocket_service.dart';

class VideoService {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  final WebSocketService _webSocketService = WebSocketService();
  final Logger _logger = Logger();

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _localStreamId;
  bool _isVideoEnabled = true;
  bool _isInitialized = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _remoteSocketId;

  // Streams
  final _localStreamController = StreamController<MediaStream?>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _videoStatusController = StreamController<bool>.broadcast();

  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<bool> get videoStatusStream => _videoStatusController.stream;

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
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String? get localStreamId => _localStreamId;

  // Inicializar o serviço
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.d('Inicializando VideoService');

    try {
      // Configurar listeners para eventos WebRTC
      _setupWebSocketListeners();

      // Inicializar stream de vídeo local
      await _initLocalStream();

      _isInitialized = true;
      _logger.d('VideoService inicializado com sucesso');
    } catch (e) {
      _logger.e('Erro ao inicializar VideoService: $e');
      throw Exception('Falha ao inicializar VideoService: $e');
    }
  }

  // Configurar listeners para eventos WebRTC
  void _setupWebSocketListeners() {
    // Usar streams em vez do método 'on'
    _webSocketService.videoOfferStream.listen((data) async {
      _logger.d('Oferta de vídeo recebida: $data');
      
      try {
        // Verificar se a oferta não é do próprio usuário
        if (data['from'] != _webSocketService.nickname) {
          _remoteSocketId = data['from'];
          
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
          _sendVideoAnswer(answer);
        }
      } catch (e) {
        _logger.e('Erro ao processar oferta de vídeo: $e');
      }
    });

    _webSocketService.videoAnswerStream.listen((data) async {
      _logger.d('Resposta de vídeo recebida: $data');
      
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
          _logger.d('Conexão de vídeo estabelecida');
        }
      } catch (e) {
        _logger.e('Erro ao processar resposta de vídeo: $e');
      }
    });

    _webSocketService.iceStream.listen((data) async {
      _logger.d('Candidato ICE de vídeo recebido: $data');
      
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
        _logger.e('Erro ao processar candidato ICE de vídeo: $e');
      }
    });
  }

  // Inicializar stream de vídeo local
  Future<void> _initLocalStream() async {
    _logger.d('Inicializando stream de vídeo local');
    
    try {
      final mediaConstraints = {
        'audio': false,  // Áudio gerenciado pelo AudioService
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 320},
          'height': {'ideal': 240}
        }
      };
      
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStreamId = _localStream?.id;
      _localStreamController.add(_localStream);
      
      _isVideoEnabled = true;
      _videoStatusController.add(_isVideoEnabled);
      
      _logger.d('Stream de vídeo local inicializado com sucesso: $_localStreamId');
    } catch (e) {
      _logger.e('Erro ao inicializar stream de vídeo local: $e');
      _isVideoEnabled = false;
      _videoStatusController.add(_isVideoEnabled);
      throw Exception('Falha ao inicializar stream de vídeo local: $e');
    }
  }

  // Criar conexão peer
  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) {
      await _closePeerConnection();
    }
    
    _logger.d('Criando conexão peer para vídeo');
    
    try {
      _peerConnection = await createPeerConnection(_rtcConfig);
      
      // Adicionar tracks de vídeo
      if (_localStream != null) {
        _localStream!.getVideoTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }
      
      // Configurar handlers de eventos
      _peerConnection!.onIceCandidate = _handleIceCandidate;
      _peerConnection!.onConnectionState = _handleConnectionStateChange;
      _peerConnection!.onIceConnectionState = _handleIceConnectionStateChange;
      
      // Configurar handler para streams remotos
      _peerConnection!.onAddStream = (MediaStream stream) {
        _logger.d('Stream remoto recebido: ${stream.id}');
        _remoteStreamController.add(stream);
      };
      
      _logger.d('Conexão peer para vídeo criada com sucesso');
    } catch (e) {
      _logger.e('Erro ao criar conexão peer para vídeo: $e');
      throw Exception('Falha ao criar conexão peer para vídeo: $e');
    }
  }

  // Iniciar chamada de vídeo
  Future<void> startVideoCall() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isConnecting || _isConnected) {
      _logger.d('Chamada de vídeo já em andamento');
      return;
    }
    
    _logger.d('Iniciando chamada de vídeo');
    _isConnecting = true;
    
    try {
      await _createPeerConnection();
      
      // Criar oferta
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      // Enviar oferta
      _sendVideoOffer(offer);
      
      _logger.d('Oferta de vídeo enviada');
    } catch (e) {
      _isConnecting = false;
      _logger.e('Erro ao iniciar chamada de vídeo: $e');
      throw Exception('Falha ao iniciar chamada de vídeo: $e');
    }
  }

  // Enviar oferta de vídeo
  void _sendVideoOffer(RTCSessionDescription offer) {
    _logger.d('Enviando oferta de vídeo');
    
    final data = {
      'type': offer.type,
      'sdp': offer.sdp,
      'from': _webSocketService.nickname,
      'roomCode': _webSocketService.currentRoomCode,
    };
    
    _webSocketService.emitEvent('videoOffer', data);
  }

  // Enviar resposta de vídeo
  void _sendVideoAnswer(RTCSessionDescription answer) {
    _logger.d('Enviando resposta de vídeo');
    
    final data = {
      'type': answer.type,
      'sdp': answer.sdp,
      'from': _webSocketService.nickname,
      'roomCode': _webSocketService.currentRoomCode,
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
      'roomCode': _webSocketService.currentRoomCode,
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
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _isConnected = false;
        _isConnecting = false;
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
        _sendVideoOffer(offer);
        
        _logger.d('ICE reiniciado com sucesso');
      }
    } catch (e) {
      _logger.e('Erro ao reiniciar ICE: $e');
    }
  }

  // Reconectar após falha
  Future<void> _reconnect() async {
    _logger.d('Tentando reconectar vídeo');
    
    if (_isConnecting) return;
    
    _isConnecting = true;
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      await startVideoCall();
    } catch (e) {
      _isConnecting = false;
      _logger.e('Erro ao reconectar vídeo: $e');
    }
  }

  // Alternar estado do vídeo (ativar/desativar)
  Future<void> toggleVideo() async {
    _logger.d('Alternando estado do vídeo');
    
    if (_localStream == null) {
      _logger.d('Stream local não inicializado');
      return;
    }
    
    try {
      final videoTracks = _localStream!.getVideoTracks();
      
      for (final track in videoTracks) {
        track.enabled = !track.enabled;
      }
      
      _isVideoEnabled = videoTracks.isNotEmpty ? videoTracks.first.enabled : false;
      _videoStatusController.add(_isVideoEnabled);
      
      _logger.d('Estado do vídeo alternado para: $_isVideoEnabled');
    } catch (e) {
      _logger.e('Erro ao alternar estado do vídeo: $e');
    }
  }

  // Fechar conexão peer
  Future<void> _closePeerConnection() async {
    _logger.d('Fechando conexão peer de vídeo');
    
    try {
      await _peerConnection?.close();
      _peerConnection = null;
      _isConnected = false;
      _isConnecting = false;
      
      _logger.d('Conexão peer de vídeo fechada com sucesso');
    } catch (e) {
      _logger.e('Erro ao fechar conexão peer de vídeo: $e');
    }
  }

  // Liberar recursos
  Future<void> dispose() async {
    _logger.d('Liberando recursos do VideoService');
    
    try {
      // Fechar conexão peer
      await _closePeerConnection();
      
      // Parar stream local
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream = null;
      
      // Fechar controllers
      _localStreamController.close();
      _remoteStreamController.close();
      _videoStatusController.close();
      
      _isInitialized = false;
      _logger.d('Recursos do VideoService liberados com sucesso');
    } catch (e) {
      _logger.e('Erro ao liberar recursos do VideoService: $e');
    }
  }
}
