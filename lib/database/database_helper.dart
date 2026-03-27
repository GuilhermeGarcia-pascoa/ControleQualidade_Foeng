import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/session.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

bool islocalhost = true;

String get baseUrl {

   String serverIp = "";

  if(islocalhost) {
    serverIp = 'localhost';
  } else {
    serverIp = '192.168.1.246';
  }

    if (kIsWeb) return 'http://$serverIp:3000/api';
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://$serverIp:3000/api';
      case TargetPlatform.iOS:
        return 'http://$serverIp:3000/api';
      default:
        return 'http://$serverIp:3000/api';
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

  Future<List<Map<String, dynamic>>> procurarUtilizadoresPorTexto(String texto) async {
  try {
    final encoded = Uri.encodeComponent(texto);
    final response = await http.get(Uri.parse('$baseUrl/utilizadores/pesquisar/$encoded'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['utilizadores']);
    }
    return [];
  } catch (e) {
    print("❌ ERRO procurarUtilizadoresPorTexto: $e");
    return [];
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

  Future<Map<String, dynamic>> getContagemProjeto(int projetoId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/projetos/$projetoId/contagem'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'total_nos': 0, 'total_registos': 0};
  } catch (e) {
    print("❌ ERRO getContagemProjeto: $e");
    return {'total_nos': 0, 'total_registos': 0};
  }
}

Future<bool> apagarProjeto(int projetoId) async {
  try {
    final response = await http.delete(Uri.parse('$baseUrl/projetos/$projetoId'));
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO apagarProjeto: $e");
    return false;
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

  // ─── ACESSO A NÓS ─────────────────────────────────────────
Future<bool> darAcessoNo(int utilizadorId, int noId) async {
  try {
    // 1. Dar acesso à pasta
    final responseNo = await http.post(
      Uri.parse('$baseUrl/utilizador_no'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'utilizador_id': utilizadorId, 'no_id': noId}),
    );
    if (responseNo.statusCode != 200) return false;

    // 2. Buscar o projeto_id do nó
    final responseNos = await http.get(Uri.parse('$baseUrl/nos/info/$noId'));
    if (responseNos.statusCode != 200) return false;
    final data = jsonDecode(responseNos.body);
    final projetoId = data['projeto_id'];

    // 3. Adicionar ao projeto automaticamente (se ainda não for membro)
    await http.post(
      Uri.parse('$baseUrl/utilizador_projeto'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'utilizador_id': utilizadorId, 'projeto_id': projetoId}),
    );

    return true;
  } catch (e) {
    print("❌ ERRO darAcessoNo: $e");
    return false;
  }
}

Future<bool> removerAcessoNo(int utilizadorId, int noId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/utilizador_no/$noId/$utilizadorId'),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO removerAcessoNo: $e");
    return false;
  }
}

Future<List<Map<String, dynamic>>> getMembrosNo(int noId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/utilizador_no/$noId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['membros']);
    }
    return [];
  } catch (e) {
    print("❌ ERRO getMembrosNo: $e");
    return [];
  }
}

Future<List<int>> getNosComAcesso(int projetoId) async {
  try {
    final userId = await Session.getUserId();
    final response = await http.get(
      Uri.parse('$baseUrl/nos/$projetoId/acesso/$userId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<int>.from(data['nos_com_acesso']);
    }
    return [];
  } catch (e) {
    print("❌ ERRO getNosComAcesso: $e");
    return [];
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

Future<bool> inserirRegisto(Map<String, dynamic> dados) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ CORREÇÃO: Removido o '/api' pois o baseUrl já o tem
    final uri = Uri.parse('$baseUrl/registos'); 
    
    final utilizadorId = prefs.getInt('utilizador_id') ?? 1;
    final noId = dados['no_id'];
    final dadosFormulario = Map<String, dynamic>.from(dados['dados']);

    final Map<String, String> fotos = {};
    final Map<String, dynamic> dadosSemFotos = {};

    for (final entry in dadosFormulario.entries) {
      final valor = entry.value;
      if (valor is String && valor.startsWith('base64:')) {
        fotos[entry.key] = valor;
      } else {
        dadosSemFotos[entry.key] = valor;
      }
    }

    // Criar request multipart usando a 'uri' definida acima
    final request = http.MultipartRequest('POST', uri);

    request.fields['no_id'] = noId.toString();
    request.fields['utilizador_id'] = utilizadorId.toString();
    request.fields['dados_json'] = jsonEncode(dadosSemFotos);

    for (final entry in fotos.entries) {
      final nomeCampo = entry.key;
      final base64Str = entry.value.replaceFirst('base64:', '');
      final bytes = base64Decode(base64Str);

      request.files.add(http.MultipartFile.fromBytes(
        nomeCampo,
        bytes,
        filename: '${nomeCampo}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    print('📤 ENVIANDO REGISTO PARA: $uri');

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    final json = jsonDecode(response.body);
    return json['success'] == true;
  } catch (e) {
    print('❌ Erro inserirRegisto: $e');
    return false;
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
    
    // ─── DIAGNÓSTICO DO BACKEND ───
    print('📥 POST /utilizador_projeto');
    print('📥 Status Code: ${response.statusCode}');
    print('📥 Resposta: ${response.body}');
    // ──────────────────────────────

    // Aceita tanto 200 (OK) como 201 (Created)
    return response.statusCode == 200 || response.statusCode == 201;
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

// ─── RENOMEAR ─────────────────────────────────────────────
Future<bool> renomearProjeto(int id, String nome, String descricao) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/projetos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'descricao': descricao}),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO renomearProjeto: $e");
    return false;
  }
}

Future<bool> renomearNo(int id, String nome) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/nos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome}),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO renomearNo: $e");
    return false;
  }
}

// ─── MOVER NÓ ─────────────────────────────────────────────
Future<bool> moverNo(int noId, {int? novoPaiId}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/nos/$noId/mover'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pai_id': novoPaiId}),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO moverNo: $e");
    return false;
  }
}

// ─── COPIAR NÓ ────────────────────────────────────────────
Future<bool> copiarNo(int noId, {int? novoPaiId, int? novoProjetoId, required bool incluirRegistos}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/nos/$noId/copiar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'novo_pai_id': novoPaiId,
        'novo_projeto_id': novoProjetoId,
        'incluir_registos': incluirRegistos,
      }),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO copiarNo: $e");
    return false;
  }
}

// ─── COPIAR PROJETO ───────────────────────────────────────
Future<bool> copiarProjeto(int projetoId, String novoNome) async {
  try {
    final userId = await Session.getUserId();
    final response = await http.post(
      Uri.parse('$baseUrl/projetos/$projetoId/copiar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': novoNome, 'criado_por': userId}),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("❌ ERRO copiarProjeto: $e");
    return false;
  }
}

// ─── TODOS OS NÓS DE UM PROJETO (para seletor) ────────────
Future<List<No>> getTodosNos(int projetoId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/nos/$projetoId/todos'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['nos'] as List).map((n) => No.fromMap(n)).toList();
    }
    return [];
  } catch (e) {
    print("❌ ERRO getTodosNos: $e");
    return [];
  }
}

}