import 'package:flutter/material.dart';
import 'package:xdama/utils/constants.dart';

class AudioPlaceholderWidget extends StatelessWidget {
  final String roomCode;

  const AudioPlaceholderWidget({
    Key? key,
    required this.roomCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic_off,
            color: AppColors.lightGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Áudio não disponível nesta versão',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}
