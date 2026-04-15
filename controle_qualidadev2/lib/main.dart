import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/session.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Exibir configuração da aplicação
  AppConfig.printConfig();

  final user = await Session.getUser();

  // Carrega o tema da API só se houver sessão ativa
  if (user != null) {
    await AppTheme.loadTheme();
  }

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
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E),
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
