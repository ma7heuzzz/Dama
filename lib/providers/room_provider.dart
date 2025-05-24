import 'package:flutter/material.dart';
import 'package:xdama/models/room_model.dart';
import 'package:xdama/services/room_service.dart';
import 'package:xdama/services/websocket_service.dart';

class RoomProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();
  final WebSocketService _webSocketService = WebSocketService();
  
  List<RoomModel> _rooms = [];
  RoomModel? _currentRoom;
  String? _errorMessage;
  bool _isLoading = false;
  
  List<RoomModel> get rooms => _rooms;
  RoomModel? get currentRoom => _currentRoom;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  RoomProvider() {
    _initListeners();
  }
  
  void _initListeners() {
    // Ouvir atualizações da lista de salas
    _roomService.roomsStream.listen((rooms) {
      _rooms = rooms;
      notifyListeners();
    });
    
    // Ouvir atualizações da sala atual
    _roomService.currentRoomStream.listen((room) {
      _currentRoom = room;
      notifyListeners();
    });
    
    // Ouvir erros
    _roomService.errorStream.listen((error) {
      _errorMessage = error;
      _isLoading = false;
      notifyListeners();
    });
  }
  
  // Carregar lista de salas
  Future<void> loadRooms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _rooms = await _roomService.getRooms();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Método refreshRooms como alias para loadRooms
  Future<void> refreshRooms() async {
    await loadRooms();
  }
  
  // Criar uma nova sala
  Future<RoomModel?> createRoom() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final room = await _roomService.createRoom();
      _isLoading = false;
      if (room != null) {
        _currentRoom = room;
      }
      notifyListeners();
      return room;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Entrar em uma sala
  Future<bool> joinRoom(String roomCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _roomService.joinRoom(roomCode);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Encerrar uma sala (método adicionado)
  Future<bool> closeRoom(String roomCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Emitir evento para encerrar a sala
      _webSocketService.emitEvent('closeRoom', roomCode);
      
      // Atualizar estado local
      _rooms = _rooms.where((room) => room.roomCode != roomCode).toList();
      
      // Se a sala atual for a encerrada, limpar referência
      if (_currentRoom?.roomCode == roomCode) {
        _currentRoom = null;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Sair da sala atual
  void leaveCurrentRoom() {
    if (_currentRoom != null) {
      _webSocketService.disconnect();
      _currentRoom = null;
      notifyListeners();
    }
  }
  
  // Limpar estado
  void reset() {
    _rooms = [];
    _currentRoom = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
