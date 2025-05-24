# xDama - Documentação

## Visão Geral

xDama é um jogo de damas multiplayer com chat de voz e vídeo, desenvolvido em Flutter para web e dispositivos móveis. Esta documentação descreve as funcionalidades implementadas, arquitetura e instruções de uso.

## Índice

1. [Arquitetura](#arquitetura)
2. [Servidor WebSocket](#servidor-websocket)
3. [Cliente Flutter](#cliente-flutter)
4. [Funcionalidades](#funcionalidades)
5. [Instruções de Uso](#instruções-de-uso)
6. [Configuração para Produção](#configuração-para-produção)
7. [Solução de Problemas](#solução-de-problemas)

## Arquitetura

O sistema é composto por duas partes principais:

1. **Servidor WebSocket (Node.js)**: Gerencia salas, jogadores, comunicação em tempo real e sincronização do jogo.
2. **Cliente Flutter**: Interface de usuário e lógica do jogo, com comunicação via WebSocket.

### Diagrama de Comunicação

```
+----------------+       WebSocket       +----------------+
|                |<-------------------->|                |
|  Cliente       |    (Socket.IO)       |  Servidor      |
|  Flutter       |                      |  Node.js       |
|                |<-------------------->|                |
+----------------+                      +----------------+
       ^                                        ^
       |                                        |
       v                                        v
+----------------+       WebRTC         +----------------+
|  Áudio/Vídeo   |<-------------------->|  Áudio/Vídeo   |
|  Peer A        |    (P2P direto)      |  Peer B        |
+----------------+                      +----------------+
```

## Servidor WebSocket

O servidor WebSocket é implementado em Node.js com Socket.IO e gerencia:

- Criação e listagem de salas
- Entrada e saída de jogadores
- Sincronização de movimentos
- Sinalização para conexões WebRTC (áudio/vídeo)
- Limpeza automática de salas antigas

### Endpoints REST

- `GET /status`: Retorna o status do servidor e lista de salas
- `GET /reset`: Limpa todas as salas (uso administrativo)
- `GET /remove-room/:roomCode`: Remove uma sala específica

### Eventos Socket.IO

| Evento | Descrição |
|--------|-----------|
| `setNickname` | Define o nickname do jogador |
| `getRooms` | Solicita lista de salas disponíveis |
| `createRoom` | Cria uma nova sala |
| `joinRoom` | Entra em uma sala existente |
| `makeMove` | Realiza um movimento no tabuleiro |
| `closeRoom` | Encerra uma sala (apenas o criador) |
| `audio_ready` | Sinaliza que o cliente está pronto para áudio |
| `video_ready` | Sinaliza que o cliente está pronto para vídeo |

## Cliente Flutter

O cliente Flutter é organizado em:

- **Models**: Estruturas de dados (RoomModel, GamePiece)
- **Providers**: Gerenciamento de estado (GameProvider, RoomProvider)
- **Services**: Comunicação (WebSocketService, AudioService, VideoService)
- **Screens**: Telas da aplicação (LobbyScreen, GameScreen)
- **Widgets**: Componentes reutilizáveis (RoomCard, GameBoard, VideoCallWidget)

### Serviços Principais

- **WebSocketService**: Comunicação com o servidor
- **AudioService**: Gerencia conexões de áudio P2P via WebRTC
- **VideoService**: Gerencia conexões de vídeo P2P via WebRTC
- **RoomService**: Gerencia operações relacionadas a salas

## Funcionalidades

### Gerenciamento de Mesas

- Criação de novas mesas
- Listagem de mesas disponíveis
- Encerramento de mesas pelo criador
- Limpeza automática de mesas antigas (após 24 horas)
- Pesquisa de mesas por código ou nickname

### Jogo de Damas

- Tabuleiro 8x8 com peças brancas e pretas
- Movimentos alternados entre jogadores
- Regras oficiais de damas, incluindo:
  - Captura obrigatória
  - Promoção a dama ao atingir o lado oposto
  - Movimentos diagonais
  - Capturas múltiplas

### Comunicação em Tempo Real

- Áudio P2P via WebRTC
- Vídeo P2P via WebRTC
- Controles para ativar/desativar áudio e vídeo
- Indicadores de status de conexão

### Interface

- Layout responsivo para desktop e mobile
- Lobby com 2 mesas por linha para melhor visualização
- Campo de pesquisa para encontrar mesas
- Layout da mesa de jogo com área para câmera
- Indicadores visuais de turno e status do jogo

## Instruções de Uso

### Iniciar o Servidor

```bash
cd xdama_server
npm install
node server_production.js
```

### Configurar o Cliente

1. Abra o arquivo `lib/services/websocket_service.dart`
2. Ajuste a URL do servidor:
   ```dart
   // Para testes locais: 'http://localhost:8765'
   // Para rede local: 'http://SEU_IP_LOCAL:8765'
   // Para produção: 'http://SEU_DOMINIO:8765'
   final String serverUrl = 'http://localhost:8765';
   ```

### Compilar o Cliente

```bash
cd xdama_final_test
flutter pub get
flutter build web --release --no-tree-shake-icons
```

### Fluxo de Uso

1. **Entrada**: Usuário define seu nickname
2. **Lobby**: Visualiza mesas disponíveis ou cria uma nova
3. **Jogo**: Entra em uma mesa e joga contra outro jogador
4. **Comunicação**: Utiliza áudio e vídeo para interagir com o oponente

## Configuração para Produção

### Servidor

Para manter o servidor rodando permanentemente em produção:

```bash
npm install -g pm2
pm2 start server_production.js --name xdama-server
pm2 save
pm2 startup
```

### Cliente Web

Para hospedar o cliente web em um servidor HTTP:

1. Compile o projeto Flutter para web:
   ```bash
   flutter build web --release --no-tree-shake-icons
   ```

2. Copie os arquivos da pasta `build/web` para seu servidor web (Apache, Nginx, IIS, etc.)

3. Configure HTTPS para permitir acesso à câmera e microfone

### Firewall e Portas

- Porta 8765: Socket.IO (TCP)
- Portas STUN/TURN: Para WebRTC (UDP/TCP)

## Solução de Problemas

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Servidor não inicia | Verifique se a porta 8765 está disponível |
| Clientes não conectam | Verifique firewall e configuração de URL |
| Áudio/vídeo não funciona | Verifique permissões do navegador e HTTPS |
| Salas não aparecem | Reinicie o servidor com `/reset` |

### Logs

- **Servidor**: Verifique o console onde o servidor está rodando
- **Cliente**: Abra o console do navegador (F12) para ver logs detalhados

### Reiniciar o Servidor

Para limpar todas as salas e reiniciar o estado do servidor:
```
http://seu-servidor:8765/reset
```

## Próximos Passos e Melhorias Futuras

- Implementação de sistema de contas de usuário
- Histórico de partidas
- Ranking de jogadores
- Modos de jogo adicionais
- Suporte para mais de 2 jogadores por sala (espectadores)
- Personalização de tabuleiro e peças
