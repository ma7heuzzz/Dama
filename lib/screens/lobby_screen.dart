import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdama/providers/room_provider.dart';
import 'package:xdama/providers/user_provider.dart';
import 'package:xdama/services/sound_effects_service.dart';
import 'package:xdama/utils/constants.dart';
import 'package:xdama/widgets/join_room_dialog.dart';
import 'package:xdama/widgets/room_card.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final SoundEffectsService _soundEffectsService = SoundEffectsService();
  bool _isLoading = false;
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _initSoundEffects();
  }

  Future<void> _initSoundEffects() async {
    await _soundEffectsService.initialize();
    await _soundEffectsService.startLobbyMusic();
    setState(() {
      _isMusicPlaying = true;
    });
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<RoomProvider>(context, listen: false).loadRooms();
    } catch (e) {
      // Tratar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar salas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final room = await roomProvider.createRoom();
      
      if (room != null) {
        // Navegar para a sala usando o formato correto de rota
        if (mounted) {
          Navigator.of(context).pushNamed('/game/${room.roomCode}');
        }
      } else {
        // Mostrar erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao criar sala. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Tratar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar sala: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinRoom(String roomCode) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await Provider.of<RoomProvider>(context, listen: false).joinRoom(roomCode);
      if (success) {
        // Navegar para a sala usando o formato correto de rota
        if (mounted) {
          Navigator.of(context).pushNamed('/game/$roomCode');
        }
      } else {
        // Mostrar erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sala não encontrada ou cheia'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao entrar na sala: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showJoinRoomDialog([String? roomCode]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => JoinRoomDialog(roomCode: roomCode),
    );

    if (result == true) {
      // O usuário entrou em uma sala com sucesso
      // A navegação já é tratada no diálogo
    }
  }

  void _toggleLobbyMusic() {
    if (_isMusicPlaying) {
      _soundEffectsService.stopLobbyMusic();
    } else {
      _soundEffectsService.startLobbyMusic();
    }
    setState(() {
      _isMusicPlaying = !_isMusicPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final roomProvider = Provider.of<RoomProvider>(context);
    final rooms = roomProvider.rooms;
    
    // Verificar se nickname é nulo antes de acessar propriedades
    final String nickname = userProvider.nickname ?? '';
    final String firstLetter = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'xDama - Lobby',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Botão para alternar música do lobby
          IconButton(
            icon: Icon(
              _isMusicPlaying ? Icons.music_note : Icons.music_off,
              color: AppColors.white,
            ),
            onPressed: _toggleLobbyMusic,
            tooltip: _isMusicPlaying ? 'Desativar música' : 'Ativar música',
          ),
          // Botão para atualizar lista de salas
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _isLoading ? null : _loadRooms,
            tooltip: 'Atualizar salas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho com informações do usuário
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $nickname!',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Escolha uma sala para jogar ou crie uma nova',
                        style: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Criar Sala'),
                ),
              ],
            ),
          ),
          // Lista de salas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  )
                : rooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.meeting_room_outlined,
                              size: 64,
                              color: AppColors.lightGrey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhuma sala disponível',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Crie uma nova sala ou entre com um código',
                              style: TextStyle(
                                color: AppColors.lightGrey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _createRoom,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Criar Sala'),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: () => _showJoinRoomDialog(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: const BorderSide(
                                      color: AppColors.accent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.login),
                                  label: const Text('Entrar com Código'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRooms,
                        color: AppColors.accent,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return RoomCard(
                              room: room,
                              onJoin: () => _joinRoom(room.roomCode),
                              onCopy: () => _showJoinRoomDialog(room.roomCode),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showJoinRoomDialog(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.login, color: AppColors.white),
        tooltip: 'Entrar com código',
      ),
    );
  }

  @override
  void dispose() {
    _soundEffectsService.stopLobbyMusic();
    super.dispose();
  }
}
