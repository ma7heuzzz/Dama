import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:xdama/services/audio_service.dart';
import 'package:xdama/services/video_service.dart';
import 'package:xdama/utils/constants.dart';

class VideoCallWidget extends StatefulWidget {
  final VideoService videoService;
  final AudioService audioService;
  final bool isCameraEnabled;
  final String? opponentNickname;
  final Function(bool)? onCameraToggle;
  final Function(bool)? onMicToggle;

  const VideoCallWidget({
    Key? key,
    required this.videoService,
    required this.audioService,
    this.isCameraEnabled = true,
    this.opponentNickname,
    this.onCameraToggle,
    this.onMicToggle,
  }) : super(key: key);

  @override
  State<VideoCallWidget> createState() => _VideoCallWidgetState();
}

class _VideoCallWidgetState extends State<VideoCallWidget> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _rendererInitialized = false;
  bool _hasRemoteStream = false;
  String? _localStreamId;
  bool _isAudioMuted = false;
  bool _isVideoEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _initRenderer();
    
    // Inicializar o serviço de vídeo se ainda não estiver inicializado
    widget.videoService.initialize();
    widget.audioService.initialize();
    
    // Obter o ID do stream local para comparação
    widget.videoService.localStreamStream.listen((stream) {
      if (stream != null) {
        setState(() {
          _localStreamId = stream.id;
        });
        print('VideoCallWidget: ID do stream local armazenado: $_localStreamId');
      }
    });
    
    // Escutar apenas o stream remoto
    widget.videoService.remoteStreamStream.listen((stream) {
      if (stream != null && _rendererInitialized) {
        print('VideoCallWidget: Stream remoto recebido com ID: ${stream.id}');
        
        // Verificar se o stream recebido não é o stream local
        if (_localStreamId != null && stream.id == _localStreamId) {
          print('VideoCallWidget: ALERTA - Stream recebido é igual ao stream local, ignorando');
          return;
        }
        
        // Atribuir o stream remoto ao renderizador
        _remoteRenderer.srcObject = stream;
        
        // Verificar se o stream tem tracks de vídeo
        final videoTracks = stream.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          print('VideoCallWidget: Stream remoto tem ${videoTracks.length} tracks de vídeo');
          print('VideoCallWidget: Primeiro track remoto ativo: ${videoTracks.first.enabled}');
          
          // Garantir que o track de vídeo esteja ativado
          videoTracks.forEach((track) {
            track.enabled = true;
          });
          
          setState(() {
            _hasRemoteStream = true;
          });
        }
        
        // Verificar se o stream tem tracks de áudio
        final audioTracks = stream.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          print('VideoCallWidget: Stream remoto tem ${audioTracks.length} tracks de áudio');
          print('VideoCallWidget: Primeiro track de áudio remoto ativo: ${audioTracks.first.enabled}');
          
          // Garantir que o track de áudio esteja ativado
          audioTracks.forEach((track) {
            track.enabled = true;
          });
        }
      } else if (stream == null) {
        setState(() {
          _hasRemoteStream = false;
        });
      }
    });
    
    // Sincronizar estado inicial de áudio e vídeo
    _isAudioMuted = !widget.audioService.isAudioEnabled;
    _isVideoEnabled = widget.videoService.isVideoEnabled;
    
    // Escutar mudanças no estado de áudio
    widget.audioService.audioStatusStream.listen((enabled) {
      setState(() {
        _isAudioMuted = !enabled;
      });
    });
    
    // Escutar mudanças no estado de vídeo
    widget.videoService.videoStatusStream.listen((enabled) {
      setState(() {
        _isVideoEnabled = enabled;
      });
    });
  }
  
  Future<void> _initRenderer() async {
    try {
      await _remoteRenderer.initialize();
      setState(() {
        _rendererInitialized = true;
      });
      print('VideoCallWidget: Renderizador inicializado com sucesso');
    } catch (e) {
      print('VideoCallWidget: Erro ao inicializar renderizador: $e');
    }
  }

  void _toggleAudio() {
    widget.audioService.toggleMute();
    
    // Notificar o widget pai sobre a mudança
    if (widget.onMicToggle != null) {
      widget.onMicToggle!(!_isAudioMuted);
    }
    
    print('VideoCallWidget: Áudio ${_isAudioMuted ? "desativado" : "ativado"}');
  }

  void _toggleVideo() {
    widget.videoService.toggleVideo();
    
    // Notificar o widget pai sobre a mudança
    if (widget.onCameraToggle != null) {
      widget.onCameraToggle!(_isVideoEnabled);
    }
    
    print('VideoCallWidget: Vídeo ${_isVideoEnabled ? "ativado" : "desativado"}');
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Conteúdo principal: vídeo ou placeholder
          Center(
            child: _hasRemoteStream && _rendererInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: false, // Não espelhar o vídeo remoto
                    ),
                  )
                : Icon(Icons.person, size: 48, color: Colors.white54),
          ),
          
          // Controles de áudio e vídeo
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                // Botão de microfone
                GestureDetector(
                  onTap: _toggleAudio,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: _isAudioMuted ? Colors.red : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Botão de câmera
                GestureDetector(
                  onTap: _toggleVideo,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: _isVideoEnabled ? Colors.white : Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
