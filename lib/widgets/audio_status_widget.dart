import 'package:flutter/material.dart';
import 'package:xdama/utils/constants.dart';

class AudioStatusWidget extends StatefulWidget {
  final String roomCode;

  const AudioStatusWidget({Key? key, required this.roomCode}) : super(key: key);

  @override
  State<AudioStatusWidget> createState() => _AudioStatusWidgetState();
}

class _AudioStatusWidgetState extends State<AudioStatusWidget> {
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Áudio da Partida',
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
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Conectado',
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
    setState(() {
      _isMuted = !_isMuted;
    });
    // Aqui você chamaria o serviço de áudio real para mutar/desmutar
  }
}
