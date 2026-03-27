import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart'; 
import 'utils/session.dart';
import 'theme/app_theme.dart'; // <--- CORRIGIDO: Se o ficheiro está na pasta lib, o import é assim

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. CARREGA O TEMA (Isto é o que faltava funcionar)
  await AppTheme.loadTheme(); 
  
  final user = await Session.getUser();
  runApp(MyApp(initialUser: user));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialUser;
  const MyApp({Key? key, this.initialUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Controle Qualidade FOENG',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode, // <--- Aqui ele aplica o que foi carregado
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: initialUser == null ? const LoginScreen() : DashboardScreen(perfil: initialUser!['perfil']),
        );
      },
    );
  }
}