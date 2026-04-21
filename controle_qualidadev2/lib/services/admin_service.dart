import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
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
    final idValue = json['id'];
    final id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '') ??
            (throw FormatException('ID inválido no utilizador'));

    final perfil = json['role'] ?? json['perfil'];
    return UtilizadorAdmin(
      id: id,
      nome: json['nome'] as String,
      email: json['email'] as String,
      role: perfil is String ? perfil : perfil?.toString() ?? 'utilizador',
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

  // ── Obter a URL base a partir da configuração ──────────────────────────────────
  // Em Android Emulator redirection: 10.0.2.2
  // Em dispositivo físico: IP da máquina conforme AppConfig.adminHost
  String get _baseUrl => AppConfig.adminApiBaseUrl;

  // ── Headers com JWT ──────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final token = await Session.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Trata a resposta e lança excepção com a mensagem do backend ───────────────
  Map<String, dynamic> _tratar(http.Response r) {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final erro = body['erro'] as String? ??
        body['error'] as String? ??
        body['message'] as String? ??
        'Erro ${r.statusCode}';
    throw AdminServiceException(erro);
  }

  // ── GET /api/utilizadores ──────────────────────────────────────────────
  Future<List<UtilizadorAdmin>> getUtilizadores() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/utilizadores'),
      headers: await _headers(),
    );
    final body = _tratar(r);
    final lista = body['utilizadores'] as List<dynamic>;
    return lista
        .map((e) => UtilizadorAdmin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── POST /api/utilizadores ─────────────────────────────────────────────
  Future<UtilizadorAdmin> criarUtilizador({
    required String nome,
    required String email,
    required String password,
    required String role,
  }) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/utilizadores'),
      headers: await _headers(),
      body: jsonEncode(
          {'nome': nome, 'email': email, 'password': password, 'perfil': role}),
    );
    final body = _tratar(r);
    return UtilizadorAdmin.fromJson(body['utilizador'] as Map<String, dynamic>);
  }

  // ── PUT /api/utilizadores/:id/senha ────────────────────────────────────
  Future<void> alterarSenha({required int id, required String password}) async {
    final r = await http.put(
      Uri.parse('$_baseUrl/utilizadores/$id/senha'),
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
      Uri.parse('$_baseUrl/utilizadores/$id'),
      headers: await _headers(),
      body: jsonEncode({'nome': nome, 'email': email, 'perfil': role}),
    );
    try {
      final body = _tratar(r);
      return UtilizadorAdmin.fromJson(
          body['utilizador'] as Map<String, dynamic>);
    } catch (e) {
      throw AdminServiceException('Erro ao guardar utilizador: $e');
    }
  }

  // ── DELETE /api/utilizadores/:id ───────────────────────────────────────
  Future<void> apagarUtilizador(int id) async {
    final r = await http.delete(
      Uri.parse('$_baseUrl/utilizadores/$id'),
      headers: await _headers(),
    );
    _tratar(r);
  }
}
