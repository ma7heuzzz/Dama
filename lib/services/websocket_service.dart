import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/room_model.dart';
import '../models/game_piece.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // URL do servidor que será exposto publicamente
  //final String serverUrl = 'http://localhost:8765';
  //final String serverUrl = 'wss://nr1.lat';
  final String serverUrl = 'https://nr1.lat';

  IO.Socket? _socket;
  String? _nickname;
  String? _currentRoomCode;
  bool _isConnected = false;
  bool _isDebug = true;

  final _roomListController = StreamController<List<RoomModel>>.broadcast();
  final _roomUpdateController = StreamController<RoomModel>.broadcast();
  final _joinedRoomController = StreamController<RoomModel>.broadcast(); // Novo controller para joinedRoom
  final _boardUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _roomClosedController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Streams para vídeo
  final _videoOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _videoAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _iceController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<RoomModel>> get roomListStream => _roomListController.stream;
  Stream<RoomModel> get roomUpdateStream => _roomUpdateController.stream;
  Stream<RoomModel> get joinedRoomStream => _joinedRoomController.stream; // Novo getter para joinedRoom
  Stream<Map<String, dynamic>> get boardUpdateStream => _boardUpdateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Map<String, dynamic>> get roomClosedStream => _roomClosedController.stream;
  
  // Getters para streams de vídeo
  Stream<Map<String, dynamic>> get videoOfferStream => _videoOfferController.stream;
  Stream<Map<String, dynamic>> get videoAnswerStream => _videoAnswerController.stream;
  Stream<Map<String, dynamic>> get iceStream => _iceController.stream;

  bool get isConnected => _isConnected;
  String? get currentRoomCode => _currentRoomCode;
  String? get nickname => _nickname;
  
  // Método público para emitir eventos para o servidor
  void emitEvent(String event, [dynamic data]) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      _log('Socket não inicializado ou não conectado ao tentar emitir evento: $event');
    }
  }

  void _log(String message) {
    if (_isDebug) {
      print('[WebSocketService] $message');
    }
  }

  // Verificar e reconectar se necessário
  Future<bool> ensureConnected(String nickname) async {
    if (_socket == null || !_isConnected) {
      return await connect(nickname);
    } else if (_nickname != nickname) {
      _nickname = nickname;
      _socket!.emit('setNickname', nickname);
      _log('Nickname atualizado para: $nickname');
    }
    return true;
  }

  // Conectar ao servidor
  Future<bool> connect(String nickname) async {
    if (_isConnected) {
      // Se já estiver conectado mas com nickname diferente, atualizar
      if (_nickname != nickname) {
        _nickname = nickname;
        _socket!.emit('setNickname', nickname);
        _log('Nickname atualizado para: $nickname');
      }
      return true;
    }
    
    _nickname = nickname;
    
    _log('Tentando conectar a: $serverUrl');
    
    try {
      _socket = IO.io(serverUrl, {
        'transports': ['websocket', 'polling'],
        'autoConnect': false,
        'forceNew': true,
      });

      _socket!.onConnect((_) {
        _log('Conectado ao servidor');
        _isConnected = true;
        
        // Enviar nickname para o servidor
        _socket!.emit('setNickname', nickname);
        
        // Solicitar lista de salas
        _socket!.emit('getRooms');
      });

      _socket!.onConnectError((error) {
        _log('Erro de conexão: $error');
        _errorController.add('Erro de conexão: $error');
      });

      _socket!.onError((error) {
        _log('Erro: $error');
        _errorController.add('Erro: $error');
      });
      
      _socket!.onDisconnect((_) {
        _log('Desconectado do servidor');
        _isConnected = false;
      });

      _socket!.on('roomList', (data) {
        _log('Lista de salas recebida: $data');
        try {
          final rooms = (data as List)
              .map((room) => RoomModel.fromJson(room))
              .toList();
          _roomListController.add(rooms);
        } catch (e) {
          _log('Erro ao processar lista de salas: $e');
        }
      });

      _socket!.on('joinedRoom', (data) {
        _log('Entrou na sala: $data');
        try {
          final room = RoomModel.fromJson(data);
          _currentRoomCode = room.roomCode;
          _joinedRoomController.add(room); // Usar o novo controller
        } catch (e) {
          _log('Erro ao processar entrada na sala: $e');
        }
      });

      _socket!.on('roomUpdate', (data) {
        _log('Atualização da sala: $data');
        try {
          final room = RoomModel.fromJson(data);
          _roomUpdateController.add(room); // Manter este para atualizações
        } catch (e) {
          _log('Erro ao processar atualização de sala: $e');
        }
      });

      _socket!.on('boardUpdate', (data) {
        _log('Atualização do tabuleiro recebida: $data');
        try {
          // CORREÇÃO: Não sobrescrever o playerNickname, usar o valor do servidor
          // Verificar se o playerId está presente
          if (data['playerId'] != null) {
            // Buscar o nickname do jogador na sala
            final Map<String, dynamic> updatedData = Map<String, dynamic>.from(data);
            
            // Adicionar o nickname do jogador que fez o movimento
            // Se o playerId for diferente do socket atual, é o oponente
            if (data['playerId'] != _socket!.id) {
              // Buscar o nickname do oponente na sala
              _log('Movimento do oponente detectado, playerId: ${data['playerId']}');
              
              // Usar o nickname do oponente que veio do servidor
              if (data['playerNickname'] != null) {
                updatedData['playerNickname'] = data['playerNickname'];
              } else {
                // Fallback caso o servidor não envie o nickname
                updatedData['playerNickname'] = 'Oponente';
              }
            } else {
              // É o próprio jogador
              _log('Movimento próprio detectado');
              updatedData['playerNickname'] = _nickname;
            }
            
            _log('Enviando atualização do tabuleiro para o GameProvider: $updatedData');
            _boardUpdateController.add(updatedData);
          } else {
            // Se não tiver playerId, apenas repassar os dados
            _boardUpdateController.add(Map<String, dynamic>.from(data));
          }
        } catch (e) {
          _log('Erro ao processar atualização de tabuleiro: $e');
        }
      });

      _socket!.on('roomClosed', (data) {
        _log('Sala encerrada: $data');
        try {
          _roomClosedController.add(Map<String, dynamic>.from(data));
          
          // Se for a sala atual, limpar a referência
          if (data['roomCode'] == _currentRoomCode) {
            _currentRoomCode = null;
          }
          
          // Solicitar lista atualizada de salas
          _socket!.emit('getRooms');
        } catch (e) {
          _log('Erro ao processar encerramento de sala: $e');
        }
      });

      _socket!.on('error', (data) {
        _log('Erro recebido do servidor: $data');
        _errorController.add(data.toString());
      });
      
      // Eventos para vídeo
      _socket!.on('videoOffer', (data) {
        _log('Oferta de vídeo recebida: $data');
        try {
          _videoOfferController.add(Map<String, dynamic>.from(data));
        } catch (e) {
          _log('Erro ao processar oferta de vídeo: $e');
        }
      });
      
      _socket!.on('videoAnswer', (data) {
        _log('Resposta de vídeo recebida: $data');
        try {
          _videoAnswerController.add(Map<String, dynamic>.from(data));
        } catch (e) {
          _log('Erro ao processar resposta de vídeo: $e');
        }
      });
      
      _socket!.on('iceCandidate', (data) {
        _log('Candidato ICE recebido: $data');
        try {
          _iceController.add(Map<String, dynamic>.from(data));
        } catch (e) {
          _log('Erro ao processar candidato ICE: $e');
        }
      });

      // Conectar explicitamente
      _socket!.connect();
      
      return true;
    } catch (e) {
      _log('Erro ao conectar: $e');
      _errorController.add('Erro ao conectar: $e');
      return false;
    }
  }

  // Atualizar nickname
  void updateNickname(String newNickname) {
    _nickname = newNickname;
    if (_socket != null && _isConnected) {
      _log('Atualizando nickname para: $newNickname');
      _socket!.emit('setNickname', newNickname);
      
      // Solicitar lista atualizada de salas para refletir o novo nickname
      _socket!.emit('getRooms');
    }
  }

  // Criar uma sala
  void createRoom(String roomCode) {
    if (!_isConnected) {
      _log('Socket não conectado ao tentar criar sala');
      ensureConnected(_nickname ?? 'Jogador').then((_) {
        createRoom(roomCode);
      });
      return;
    }
    
    _log('Criando sala: $roomCode');
    _socket!.emit('createRoom', roomCode);
  }

  // Entrar em uma sala
  void joinRoom(String roomCode) {
    if (!_isConnected) {
      _log('Socket não conectado ao tentar entrar na sala');
      ensureConnected(_nickname ?? 'Jogador').then((_) {
        joinRoom(roomCode);
      });
      return;
    }
    
    _log('Entrando na sala: $roomCode');
    _socket!.emit('joinRoom', roomCode);
  }

  // Sair de uma sala
  Future<bool> leaveRoom(String roomCode) async {
    if (_socket == null) {
      _log('Socket não inicializado ao tentar sair da sala');
      return false;
    }
    
    _log('Saindo da sala: $roomCode');
    
    // Implementar evento de saída de sala no servidor
    _socket!.emit('leaveRoom', roomCode);
    
    // Limpar referência à sala atual
    if (_currentRoomCode == roomCode) {
      _currentRoomCode = null;
    }
    
    // Solicitar lista atualizada de salas
    _socket!.emit('getRooms');
    
    return true;
  }

  // Encerrar uma sala (apenas para o criador)
  void closeRoom(String roomCode) {
    if (_socket == null) {
      _log('Socket não inicializado ao tentar encerrar sala');
      return;
    }
    
    _log('Encerrando sala: $roomCode');
    _socket!.emit('closeRoom', roomCode);
  }

  // Fazer um movimento
  void makeMove(String roomCode, Position from, Position to) {
    if (_socket == null) {
      _log('Socket não inicializado ao tentar fazer movimento');
      return;
    }
    
    final moveData = {
      'roomCode': roomCode,
      'from': {'row': from.row, 'col': from.col},
      'to': {'row': to.row, 'col': to.col},
      'playerNickname': _nickname,
    };
    
    _log('Enviando movimento: $moveData');
    _socket!.emit('makeMove', moveData);
  }
  
  // Método para compatibilidade com o código existente
  void sendMove(Position from, Position to) {
    if (_currentRoomCode != null) {
      makeMove(_currentRoomCode!, from, to);
    }
  }
  
  // Método para enviar sequência de capturas
  void sendCaptureSequence(List<Map<String, dynamic>> captureSequence, String roomCode, String playerNickname) {
    if (_socket == null) {
      _log('Socket não inicializado ao tentar enviar sequência de capturas');
      return;
    }
    
    final data = {
      'roomCode': roomCode,
      'captureSequence': captureSequence,
      'playerNickname': playerNickname,
    };
    
    _log('Enviando sequência de capturas: $data');
    _socket!.emit('captureSequence', data);
  }
  
  // Verificar se o usuário é o criador da sala
  bool isRoomCreator(String roomCode) {
    // Implementação simplificada - na prática, isso seria verificado com base nos dados da sala
    return _currentRoomCode == roomCode && _nickname != null;
  }
  
  // Métodos para vídeo
  void sendVideoOffer(Map<String, dynamic> data) {
    if (_socket == null) {
      _log('Socket não inicializado ao tentar enviar oferta de vídeo');
      return;
    }
    
    _log('Enviando oferta de vídeo: $data');
    _socket!.emit('videoOffer', data);
  }
  
  void sendVideoAnswer(Map<String, dynamic> data) {
    if (_socket == null) {
      _log('Socket não inicializado ao tentar enviar resposta de vídeo');
      return;
    }
    
    _log('Enviando resposta de vídeo: $data');
    _socket!.emit('videoAnswer', data);
  }
  
  void sendIceCandidate(Map<String, dynamic> data) {
    if (_socket == null) {
      _log('Socket não inicializado ao tentar enviar candidato ICE');
      return;
    }
    
    _log('Enviando candidato ICE: $data');
    _socket!.emit('iceCandidate', data);
  }

  // Desconectar
  void disconnect() {
    if (_socket != null) {
      _log('Desconectando');
      _socket!.disconnect();
      _socket = null;
    }
    _isConnected = false;
    _currentRoomCode = null;
  }

  // Liberar recursos
  void dispose() {
    disconnect();
    _roomListController.close();
    _roomUpdateController.close();
    _joinedRoomController.close(); // Fechar o novo controller
    _boardUpdateController.close();
    _errorController.close();
    _roomClosedController.close();
    _videoOfferController.close();
    _videoAnswerController.close();
    _iceController.close();
  }
}
