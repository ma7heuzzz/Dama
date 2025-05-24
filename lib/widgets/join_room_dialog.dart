import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdama/providers/room_provider.dart';
import 'package:xdama/utils/constants.dart';

class JoinRoomDialog extends StatefulWidget {
  final String? roomCode;
  
  const JoinRoomDialog({Key? key, this.roomCode}) : super(key: key);

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final TextEditingController _roomIdController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preencher o campo com o código da sala se fornecido
    if (widget.roomCode != null && widget.roomCode!.isNotEmpty) {
      _roomIdController.text = widget.roomCode!;
    }
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom(BuildContext context) async {
    final roomId = _roomIdController.text.trim().toUpperCase();
    
    if (roomId.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite o código da sala';
      });
      return;
    }
    
    if (roomId.length != 4) {
      setState(() {
        _errorMessage = 'O código da sala deve ter 4 caracteres';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final success = await roomProvider.joinRoom(roomId);
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true); // Retorna true para indicar sucesso
        }
      } else {
        setState(() {
          _errorMessage = 'Sala não encontrada ou cheia';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao entrar na sala: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Entrar em uma Sala',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              controller: _roomIdController,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: 'Digite o código da sala',
                hintStyle: TextStyle(color: AppColors.lightGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                counterText: '',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _joinRoom(context),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.lightGrey,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: TextStyle(fontSize: 15),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _joinRoom(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 3,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  'Entrar',
                  style: TextStyle(fontSize: 15),
                ),
        ),
      ],
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      buttonPadding: EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
