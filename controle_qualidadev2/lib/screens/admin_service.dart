import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/session.dart';

// ── Modelo ────────────────────────────────────────────────────────────────────

class UtilizadorAdmin {
  final int id;
  final String nome;
  final String email;
  final String role;

  const UtilizadorAdmin({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
  });

  factory UtilizadorAdmin.fromJson(Map<String, dynamic> json) {
    return UtilizadorAdmin(
      id:    json['id']    as int,
      nome:  json['nome']  as String,
      email: json['email'] as String,
      role:  (json['role'] ?? json['perfil']) as String,
    );
  }

  String get iniciais {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
  }
}

// ── Excepção personalizada ────────────────────────────────────────────────────

class AdminServiceException implements Exception {
  final String mensagem;
  const AdminServiceException(this.mensagem);

  @override
  String toString() => mensagem;
}

// ── Serviço ───────────────────────────────────────────────────────────────────

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  // Altera este valor conforme o ambiente (dev/prod).
  // Em Android Emulator usa 10.0.2.2; em dispositivo físico usa o IP da máquina.
  static const String baseUrl = 'http://192.168.1.63:3000';

  // ── Headers com JWT ──────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final token = await Session.getToken(); // ajusta se usares outro método
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Trata a resposta e lança excepção com a mensagem do backend ───────────────
  Map<String, dynamic> _tratar(http.Response r) {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final erro = body['erro'] as String?
        ?? body['error'] as String?
        ?? body['message'] as String?
        ?? 'Erro ${r.statusCode}';
    throw AdminServiceException(erro);
  }

  // ── GET /api/utilizadores ──────────────────────────────────────────────
  Future<List<UtilizadorAdmin>> getUtilizadores() async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/utilizadores'),
      headers: await _headers(),
    );
    final body = _tratar(r);
    final lista = body['utilizadores'] as List<dynamic>;
    return lista.map((e) => UtilizadorAdmin.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── POST /api/utilizadores ─────────────────────────────────────────────
  Future<UtilizadorAdmin> criarUtilizador({
    required String nome,
    required String email,
    required String password,
    required String role,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/utilizadores'),
      headers: await _headers(),
      body: jsonEncode({'nome': nome, 'email': email, 'password': password, 'perfil': role}),
    );
    final body = _tratar(r);
    return UtilizadorAdmin.fromJson(body['utilizador'] as Map<String, dynamic>);
  }

  // ── PUT /api/utilizadores/:id/senha ────────────────────────────────────
  Future<void> alterarSenha({required int id, required String password}) async {
    final r = await http.put(
      Uri.parse('$baseUrl/api/utilizadores/$id/senha'),
      headers: await _headers(),
      body: jsonEncode({'password': password}),
    );
    _tratar(r);
  }

  // ── PUT /api/utilizadores/:id ────────────────────────────────────────
  Future<UtilizadorAdmin> editarUtilizador(
    int id, {
    required String nome,
    required String email,
    required String role,
  }) async {
    final r = await http.put(
      Uri.parse('$baseUrl/api/utilizadores/$id'),
      headers: await _headers(),
      body: jsonEncode({'nome': nome, 'email': email, 'perfil': role}),
    );
    final body = _tratar(r);
    return UtilizadorAdmin.fromJson(body['utilizador'] as Map<String, dynamic>);
  }

  // ── DELETE /api/utilizadores/:id ───────────────────────────────────────
  Future<void> apagarUtilizador(int id) async {
    final r = await http.delete(
      Uri.parse('$baseUrl/api/utilizadores/$id'),
      headers: await _headers(),
    );
    _tratar(r);
  }
}