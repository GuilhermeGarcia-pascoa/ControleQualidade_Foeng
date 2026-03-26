import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final user = await Session.getUser();
  runApp(MyApp(initialUser: user));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialUser;
  const MyApp({Key? key, this.initialUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Qualidade FOENG',
      debugShowCheckedModeBanner: false,
      
      // 1. Define o tema escuro como padrão
      theme: ThemeData(
        brightness: Brightness.dark, // <--- Força as cores escuras
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.dark, // <--- Garante que o esquema de cores seja escuro
          secondary: const Color(0xFFFF6F00),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // Um preto/cinza muito escuro
        useMaterial3: true,
      ),
      
      // 2. Força a app a usar sempre este tema, ignorando o sistema do telemóvel
      themeMode: ThemeMode.dark, 

      home: initialUser == null 
          ? const LoginScreen() 
          : DashboardScreen(perfil: initialUser!['perfil']),
    );
  }
}