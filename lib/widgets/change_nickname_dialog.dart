import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdama/providers/user_provider.dart';

class ChangeNicknameDialog extends StatefulWidget {
  const ChangeNicknameDialog({Key? key}) : super(key: key);

  @override
  State<ChangeNicknameDialog> createState() => _ChangeNicknameDialogState();
}

class _ChangeNicknameDialogState extends State<ChangeNicknameDialog> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Preencher o campo com o nickname atual
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      _nicknameController.text = userProvider.currentUser!.nickname;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    
    if (nickname.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite seu nickname';
      });
      return;
    }
    
    if (nickname.length < 3) {
      setState(() {
        _errorMessage = 'Nickname deve ter pelo menos 3 caracteres';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.saveUser(nickname);
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          
          // Mostrar confirmação
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nickname alterado para: $nickname'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Erro ao salvar nickname. Tente novamente.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro. Tente novamente.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Alterar Nickname',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nicknameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Novo nickname',
              hintText: 'Digite seu novo nickname',
              labelStyle: TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[800],
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveNickname(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TextStyle(fontSize: 15),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isLoading ? null : _saveNickname,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Salvar',
                  style: TextStyle(fontSize: 15),
                ),
        ),
      ],
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      buttonPadding: EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
