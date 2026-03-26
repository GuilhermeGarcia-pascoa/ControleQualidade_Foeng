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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), secondary: const Color(0xFFFF6F00)),
        useMaterial3: true,
      ),
      home: initialUser == null ? const LoginScreen() : DashboardScreen(perfil: initialUser!['perfil']),
    );
  }
}   