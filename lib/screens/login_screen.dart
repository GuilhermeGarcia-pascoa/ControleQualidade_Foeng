import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/session.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController(text: 'admin@foeng.pt'); 
  final passC = TextEditingController(text: 'admin');

  void _login() async {
    final user = await DatabaseHelper.instance.login(emailC.text, passC.text);
    if (user != null) {
      await Session.saveUser(user.id!, user.perfil);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(perfil: user.perfil)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credenciais inválidas!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login - FOENG')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: passC, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: _login,
              child: const Text('ENTRAR'),
            ),
          ],
        ),
      ),
    );
  }
}