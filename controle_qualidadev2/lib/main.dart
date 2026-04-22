import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/session.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';

// ✅ CHAVE GLOBAL — usada pelo DatabaseHelper para redirecionar ao login quando token expira
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.printConfig();
  await AppTheme.loadTheme();
  final user = await Session.getUser();
  runApp(MyApp(initialUser: user));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'FOENG · Controlo de Qualidade',
          navigatorKey: navigatorKey, // ✅ OBRIGATÓRIO — liga ao DatabaseHelper
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routes: {
            '/': (_) => const LoginScreen(),
          },
          home: initialUser == null
              ? const LoginScreen()
              : DashboardScreen(perfil: initialUser!['perfil']),
        );
      },
    );
  }
}
