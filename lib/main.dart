import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xdama/providers/user_provider.dart';
import 'package:xdama/providers/room_provider.dart';
import 'package:xdama/providers/game_provider.dart';
import 'package:xdama/screens/nickname_screen.dart';
import 'package:xdama/screens/lobby_screen.dart';
import 'package:xdama/screens/game_screen.dart';
import 'package:xdama/screens/splash_screen.dart';
import 'package:xdama/utils/constants.dart';

void main() async {
  // Garantir que o Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'xDama',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.accent,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            secondary: AppColors.accent,
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
          } else if (settings.name == '/lobby') {
            return MaterialPageRoute(
              builder: (context) => const LobbyScreen(),
            );
          } else if (settings.name!.startsWith('/game/')) {
            final roomCode = settings.name!.substring(6);
            return MaterialPageRoute(
              builder: (context) => GameScreen(
                roomCode: roomCode, 
                nickname: Provider.of<UserProvider>(context, listen: false).currentUser?.nickname ?? 'Jogador'
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
