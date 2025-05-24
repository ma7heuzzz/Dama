import 'dart:async';
import 'package:xdama/models/room_model.dart';
import 'package:xdama/services/user_service.dart';
import 'package:xdama/services/websocket_service.dart';

class RoomService {
  final UserService _userService = UserService();
  final WebSocketService _webSocketService = WebSocketService();
  
  // Stream controllers para salas e erros
  final _roomsController = StreamController<List<RoomModel>>.broadcast();
  final _currentRoomController = StreamController<RoomModel?>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // Streams públicos
  Stream<List<RoomModel>> get roomsStream => _roomsController.stream;
  Stream<RoomModel?> get currentRoomStream => _currentRoomController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  // Armazenamento local da lista de salas atual
  List<RoomModel> _currentRooms = [];
  RoomModel? _currentRoom;
  
  // Subscrições
  StreamSubscription? _roomListSubscription;
  StreamSubscription? _roomUpdateSubscription;
  StreamSubscription? _joinedRoomSubscription; // Nova subscrição para joinedRoom
  StreamSubscription? _errorSubscription;
  
  RoomService() {
    _initListeners();
  }
  
  void _initListeners() {
    // Inscrever-se no stream de lista de salas
    _roomListSubscription = _webSocketService.roomListStream.listen((rooms) {
      _currentRooms = rooms;
      _roomsController.add(rooms);
    });
    
    // Inscrever-se no stream de joinedRoom
    _joinedRoomSubscription = _webSocketService.joinedRoomStream.listen((room) {
      _currentRoom = room;
      _currentRoomController.add(room);
    });
    
    // Inscrever-se no stream de atualização de sala
    _roomUpdateSubscription = _webSocketService.roomUpdateStream.listen((room) {
      _currentRoom = room;
      _currentRoomController.add(room);
    });
    
    // Inscrever-se no stream de erros
    _errorSubscription = _webSocketService.errorStream.listen((error) {
      _errorController.add(error);
    });
  }
  
  // Obter lista de salas disponíveis
  Future<List<RoomModel>> getRooms() async {
    try {
      // Garantir que estamos conectados
      final user = await _userService.getUser();
      if (user != null) {
        await _webSocketService.ensureConnected(user.nickname);
      }
      
      // Solicitar lista de salas ao servidor
      _webSocketService.emitEvent('getRooms');
      
      // Retornar a lista atual (será atualizada pelo listener)
      return _currentRooms;
    } catch (e) {
      print('Erro ao obter salas: $e');
      return [];
    }
  }
  
  // Obter sala atual
  RoomModel? getCurrentRoom() {
    return _currentRoom;
  }
  
  // Criar uma nova sala
  Future<RoomModel?> createRoom() async {
    try {
      final user = await _userService.getUser();
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }
      
      // Garantir que estamos conectados
      await _webSocketService.ensureConnected(user.nickname);
      
      // Gerar código de sala aleatório
      final roomCode = _generateRoomCode();
      
      // Criar sala no servidor via WebSocket
      _webSocketService.createRoom(roomCode);
      
      // Aguardar resposta do servidor (joinedRoom event)
      final completer = Completer<RoomModel?>();
      
      // Ouvir evento joinedRoom por 15 segundos (aumentado de 5 para 15)
      final subscription = _webSocketService.joinedRoomStream.listen((room) {
        if (room.roomCode == roomCode && !completer.isCompleted) {
          completer.complete(room);
        }
      });
      
      // Ouvir erros
      final errorSubscription = _webSocketService.errorStream.listen((error) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      // Timeout após 15 segundos (aumentado de 5 para 15)
      Future.delayed(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      // Aguardar resultado
      final result = await completer.future;
      
      // Cancelar subscrições
      subscription.cancel();
      errorSubscription.cancel();
      
      return result;
    } catch (e) {
      print('Erro ao criar sala: $e');
      return null;
    }
  }
  
  // Entrar em uma sala existente
  Future<bool> joinRoom(String roomCode) async {
    try {
      final user = await _userService.getUser();
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }
      
      // Garantir que estamos conectados
      await _webSocketService.ensureConnected(user.nickname);
      
      // Entrar na sala via WebSocket
      _webSocketService.joinRoom(roomCode);
      
      // Aguardar resposta do servidor (joinedRoom event)
      final completer = Completer<bool>();
      
      // Ouvir evento joinedRoom por 15 segundos (aumentado de 5 para 15)
      final subscription = _webSocketService.joinedRoomStream.listen((room) {
        if (room.roomCode == roomCode && !completer.isCompleted) {
          completer.complete(true);
        }
      });
      
      // Ouvir erros
      final errorSubscription = _webSocketService.errorStream.listen((error) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      // Timeout após 15 segundos (aumentado de 5 para 15)
      Future.delayed(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      // Aguardar resultado
      final result = await completer.future;
      
      // Cancelar subscrições
      subscription.cancel();
      errorSubscription.cancel();
      
      return result;
    } catch (e) {
      print('Erro ao entrar na sala: $e');
      return false;
    }
  }
  
  // Gerar código de sala aleatório
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    String result = '';
    int value = random;
    
    for (int i = 0; i < 4; i++) {
      result += chars[value % chars.length];
      value = (value ~/ chars.length);
    }
    
    return result;
  }
  
  // Liberar recursos
  void dispose() {
    _roomListSubscription?.cancel();
    _roomUpdateSubscription?.cancel();
    _joinedRoomSubscription?.cancel(); // Cancelar a nova subscrição
    _errorSubscription?.cancel();
    _roomsController.close();
    _currentRoomController.close();
    _errorController.close();
  }
}
