import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/session.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      default:
        return 'http://localhost:3000/api';
    }
  }

  // ─── LOGIN ───────────────────────────────────────────────
  Future<Utilizador?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return Utilizador.fromMap(data['user']);
      }
      return null;
    } catch (e) {
      print("❌ ERRO login: $e");
      return null;
    }
  }

  // ─── PROJETOS ─────────────────────────────────────────────
  Future<List<Projeto>> getProjetos() async {
    try {
      final userId = await Session.getUserId();
      final response = await http.get(Uri.parse('$baseUrl/projetos/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['projetos'] as List).map((p) => Projeto.fromMap(p)).toList();
      }
      return [];
    } catch (e) {
      print("❌ ERRO getProjetos: $e");
      return [];
    }
  }

  Future<int> criarProjeto(Map<String, dynamic> projeto) async {
    try {
      final userId = await Session.getUserId();
      final response = await http.post(
        Uri.parse('$baseUrl/projetos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': projeto['nome'],
          'descricao': projeto['descricao'],
          'criado_por': userId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? 0;
      }
      return 0;
    } catch (e) {
      print("❌ ERRO criarProjeto: $e");
      return 0;
    }
  }

  // ─── NÓS ──────────────────────────────────────────────────
  Future<List<No>> getNos(int projetoId, {int? paiId}) async {
    try {
      final paiParam = paiId != null ? '?pai_id=$paiId' : '?pai_id=null';
      final response = await http.get(Uri.parse('$baseUrl/nos/$projetoId$paiParam'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['nos'] as List).map((n) => No.fromMap(n)).toList();
      }
      return [];
    } catch (e) {
      print("❌ ERRO getNos: $e");
      return [];
    }
  }

  Future<int> criarNo(int projetoId, {int? paiId, required String nome}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projeto_id': projetoId,
          'pai_id': paiId,
          'nome': nome,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? 0;
      }
      return 0;
    } catch (e) {
      print("❌ ERRO criarNo: $e");
      return 0;
    }
  }

  Future<void> apagarNo(int noId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/nos/$noId'));
    } catch (e) {
      print("❌ ERRO apagarNo: $e");
    }
  }

  // ─── CAMPOS ───────────────────────────────────────────────
  Future<List<CampoDinamico>> getCampos(int noId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/campos/$noId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['campos'] as List).map((c) => CampoDinamico.fromMap(c)).toList();
      }
      return [];
    } catch (e) {
      print("❌ ERRO getCampos: $e");
      return [];
    }
  }

  Future<void> criarCampo(Map<String, dynamic> campo) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/campos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(campo),
      );
    } catch (e) {
      print("❌ ERRO criarCampo: $e");
    }
  }

  // ─── REGISTOS ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRegistos(int noId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/registos/$noId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['registos']);
      }
      return [];
    } catch (e) {
      print("❌ ERRO getRegistos: $e");
      return [];
    }
  }

  Future<void> inserirRegisto(Map<String, dynamic> registo) async {
    try {
      final userId = await Session.getUserId();
      await http.post(
        Uri.parse('$baseUrl/registos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'no_id': registo['no_id'],
          'utilizador_id': userId,
          'dados': registo['dados'],
        }),
      );
    } catch (e) {
      print("❌ ERRO inserirRegisto: $e");
    }
  }
  // ─── UTILIZADOR_PROJETO ───────────────────────────────────
Future<List<Projeto>> getProjetosTrabalhador() async {
  try {
    final userId = await Session.getUserId();
    final response = await http.get(Uri.parse('$baseUrl/projetos/trabalhador/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['projetos'] as List).map((p) => Projeto.fromMap(p)).toList();
    }
    return [];
  } catch (e) {
    print("❌ ERRO getProjetosTrabalhador: $e");
    return [];
  }
}

Future<Map<String, dynamic>?> procurarUtilizadorPorEmail(String email) async {
  try {
    final encoded = Uri.encodeComponent(email);
    final response = await http.get(Uri.parse('$baseUrl/utilizadores/email/$encoded'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['utilizador'];
    }
    return null;
  } catch (e) {
    print("❌ ERRO procurarUtilizador: $e");
    return null;
  }
}

Future<bool> adicionarMembroAoProjeto(int utilizadorId, int projetoId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/utilizador_projeto'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'utilizador_id': utilizadorId, 'projeto_id': projetoId}),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO adicionarMembro: $e");
    return false;
  }
}

Future<bool> removerMembroDoProjeto(int utilizadorId, int projetoId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/utilizador_projeto/$projetoId/$utilizadorId'),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO removerMembro: $e");
    return false;
  }
}

Future<List<Map<String, dynamic>>> getMembros(int projetoId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/utilizador_projeto/$projetoId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['membros']);
    }
    return [];
  } catch (e) {
    print("❌ ERRO getMembros: $e");
    return [];
  }
}
}