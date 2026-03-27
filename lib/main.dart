import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart'; // O nosso AppTheme está definido aqui!
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
    // Envolvemos toda a app para escutar as mudanças de tema
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Controle Qualidade FOENG',
          debugShowCheckedModeBanner: false,
          
          // 1. Diz ao Flutter qual é o modo atual (claro ou escuro)
          themeMode: currentMode, 
          
          // 2. Definição do TEMA CLARO (usando as tuas cores originais)
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E), 
              secondary: const Color(0xFFFF6F00),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          
          // 3. Definição do TEMA ESCURO
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E), 
              secondary: const Color(0xFFFF6F00),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          
          home: initialUser == null 
              ? const LoginScreen() 
              : DashboardScreen(perfil: initialUser!['perfil']),
        );
      },
    );
  }
}