import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://192.168.1.66:3000/api'; // <- muda para o teu URL

  // ─── LOGIN ────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro de login');
    }
  }

  // ─── REGISTO ──────────────────────────────────────────
  static Future<Map<String, dynamic>> registar({
    required String nome,
    required String email,
    required String password,
    String perfil = 'utilizador',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/utilizadores/registar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'password': password,
        'perfil': perfil,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erro no registo');
    }
  }
}