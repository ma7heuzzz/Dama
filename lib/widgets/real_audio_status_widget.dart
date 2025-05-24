import 'package:flutter/material.dart';
import 'package:xdama/services/audio_service.dart';

class RealAudioStatusWidget extends StatefulWidget {
  final AudioService audioService;
  final bool initialMuteState;
  final Function(bool) onMuteToggle;

  const RealAudioStatusWidget({
    Key? key,
    required this.audioService,
    this.initialMuteState = false,
    required this.onMuteToggle,
  }) : super(key: key);

  @override
  State<RealAudioStatusWidget> createState() => _RealAudioStatusWidgetState();
}

class _RealAudioStatusWidgetState extends State<RealAudioStatusWidget> {
  late bool _isMuted;
  // Usar o tipo correto para o status de áudio
  late AudioStatus _audioStatus;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuteState;
    _audioStatus = AudioStatus.initialized;
    
    // Escutar mudanças de status do áudio usando o stream correto
    widget.audioService.audioStatusEnumStream.listen((status) {
      if (mounted) {
        setState(() {
          _audioStatus = status;
          
          // Atualizar estado de mudo se o status for muted/unmuted
          if (status == AudioStatus.muted) {
            _isMuted = true;
          } else if (status == AudioStatus.unmuted) {
            _isMuted = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Áudio',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.white,
                ),
                onPressed: _toggleMute,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleMute() {
    widget.audioService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
    widget.onMuteToggle(_isMuted);
  }

  Color _getStatusColor() {
    switch (_audioStatus) {
      case AudioStatus.connected:
        return Colors.green;
      case AudioStatus.connecting:
        return Colors.orange;
      case AudioStatus.disconnected:
      case AudioStatus.error:
        return Colors.red;
      case AudioStatus.muted:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (_audioStatus) {
      case AudioStatus.connected:
        return 'Conectado';
      case AudioStatus.connecting:
        return 'Conectando...';
      case AudioStatus.disconnected:
        return 'Desconectado';
      case AudioStatus.error:
        return 'Erro';
      case AudioStatus.muted:
        return 'Mudo';
      case AudioStatus.unmuted:
        return 'Ativo';
      default:
        return 'Inicializado';
    }
  }
}
