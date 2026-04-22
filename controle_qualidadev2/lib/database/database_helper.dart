import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/session.dart';
import '../config/app_config.dart';
import '../main.dart'; // para aceder ao navigatorKey

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  // URL DA API — CONFIGURADA EM lib/config/app_config.dart
  String get _baseUrl => AppConfig.apiBaseUrl;

  // ─── HEADERS COM AUTH ─────────────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final token = await Session.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ─── TRATAR RESPOSTA (inclui redirect 401) ───────────────────
  Future<T?> _handleResponse<T>(
    http.Response response,
    T? Function(Map<String, dynamic>) onSuccess,
  ) async {
    if (response.statusCode == 401) {
      await Session.logout();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/', (route) => false);
      return null;
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return onSuccess(data);
    }
    return null;
  }

  // ─── LOGIN ───────────────────────────────────────────────
  Future<Utilizador?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['token'] != null) {
            await Session.saveToken(data['token'] as String);
          }
          return Utilizador.fromMap(data['user']);
        }
      }
      return null;
    } catch (e) {
      print("❌ ERRO login: $e");
      return null;
    }
  }

  // ─── PESQUISAR UTILIZADORES ───────────────────────────
  Future<List<Map<String, dynamic>>> procurarUtilizadoresPorTexto(
      String texto) async {
    try {
      final encoded = Uri.encodeComponent(texto);
      final response = await http.get(
        Uri.parse('$_baseUrl/utilizadores/pesquisar/$encoded'),
        headers: await _authHeaders(),
      );
      return await _handleResponse(
            response,
            (data) => List<Map<String, dynamic>>.from(data['utilizadores']),
          ) ??
          [];
    } catch (e) {
      print("❌ ERRO procurarUtilizadoresPorTexto: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> procurarUtilizadorPorEmail(String email) async {
    try {
      final encoded = Uri.encodeComponent(email);
      final response = await http.get(
        Uri.parse('$_baseUrl/utilizadores/email/$encoded'),
        headers: await _authHeaders(),
      );
      return await _handleResponse(response, (data) => data['utilizador']);
    } catch (e) {
      print("❌ ERRO procurarUtilizadorPorEmail: $e");
      return null;
    }
  }

  // ─── TEMA ─────────────────────────────────────────────
  Future<bool> obterTemaPorUsuario(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/utilizadores/$userId/tema'),
        headers: await _authHeaders(), // ✅ CORRIGIDO — antes não tinha token
      );
      return await _handleResponse(
            response,
            (data) => data['tema_escuro'] as bool? ?? false,
          ) ??
          false;
    } catch (e) {
      print("❌ ERRO obterTemaPorUsuario: $e");
      return false;
    }
  }

  Future<bool> atualizarTemaUsuario(int userId, bool temEscuro) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/utilizadores/$userId/tema'),
        headers: await _authHeaders(),
        body: jsonEncode({'tema_escuro': temEscuro}),
      );
      if (response.statusCode == 401) {
        await Session.logout();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/', (route) => false);
        return false;
      }
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO atualizarTemaUsuario: $e");
      return false;
    }
  }

  // ─── PROJETOS ─────────────────────────────────────────────
  Future<List<Projeto>> getProjetos() async {
    try {
      final userId = await Session.getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/projetos/$userId'),
        headers: await _authHeaders(),
      );
      return await _handleResponse(
            response,
            (data) => (data['projetos'] as List)
                .map((p) => Projeto.fromMap(p))
                .toList(),
          ) ??
          [];
    } catch (e) {
      print("❌ ERRO getProjetos: $e");
      return [];
    }
  }

  Future<List<Projeto>> getProjetosTrabalhador() async {
    try {
      final userId = await Session.getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/projetos/trabalhador/$userId'),
        headers: await _authHeaders(),
      );
      return await _handleResponse(
            response,
            (data) => (data['projetos'] as List)
                .map((p) => Projeto.fromMap(p))
                .toList(),
          ) ??
          [];
    } catch (e) {
      print("❌ ERRO getProjetosTrabalhador: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getContagemProjeto(int projetoId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/projetos/$projetoId/contagem'),
        headers: await _authHeaders(),
      );
      return await _handleResponse(response, (data) => data) ??
          {'total_nos': 0, 'total_registos': 0};
    } catch (e) {
      print("❌ ERRO getContagemProjeto: $e");
      return {'total_nos': 0, 'total_registos': 0};
    }
  }

  Future<int> criarProjeto(Map<String, dynamic> projeto) async {
    try {
      final userId = await Session.getUserId();
      final response = await http.post(
        Uri.parse('$_baseUrl/projetos'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'nome': projeto['nome'],
          'descricao': projeto['descricao'],
          'criado_por': userId,
        }),
      );
      return await _handleResponse(response, (data) => data['id'] as int? ?? 0) ?? 0;
    } catch (e) {
      print("❌ ERRO criarProjeto: $e");
      return 0;
    }
  }

  Future<bool> renomearProjeto(int id, String nome, String descricao) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/projetos/$id'),
        headers: await _authHeaders(),
        body: jsonEncode({'nome': nome, 'descricao': descricao}),
      );
      if (response.statusCode == 401) {
        await Session.logout();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/', (route) => false);
        return false;
      }
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO renomearProjeto: $e");
      return false;
    }
  }

  Future<bool> apagarProjeto(int projetoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/projetos/$projetoId'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 401) {
        await Session.logout();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/', (route) => false);
        return false;
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ ERRO apagarProjeto: $e");
      return false;
    }
  }

  Future<bool> copiarProjeto(int projetoId, String novoNome) async {
    try {
      final userId = await Session.getUserId();
      final response = await http.post(
        Uri.parse('$_baseUrl/projetos/$projetoId/copiar'),
        headers: await _authHeaders(),
        body: jsonEncode({'nome': novoNome, 'criado_por': userId}),
      );
      if (response.statusCode == 401) {
        await Session.logout();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/', (route) => false);
        return false;
      }
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO copiarProjeto: $e");
      return false;
    }
  }

  // ─── NÓS ──────────────────────────────────────────────────
  Future<List<No>> getNos(int projetoId, {int? paiId}) async {
    try {
      final paiParam = paiId != null ? '?pai_id=$paiId' : '?pai_id=null';
      final response =
          await http.get(Uri.parse('$_baseUrl/nos/$projetoId$paiParam'));
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

  Future<No?> obterNoPorId(int noId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/nos/info/$noId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return No.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      print("❌ ERRO obterNoPorId: $e");
      return null;
    }
  }

  Future<int> criarNo(int projetoId, {int? paiId, required String nome}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/nos'),
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

  Future<bool> renomearNo(int id, String nome) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/nos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO renomearNo: $e");
      return false;
    }
  }

  Future<bool> moverNo(int noId, {int? novoPaiId}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/nos/$noId/mover'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pai_id': novoPaiId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO moverNo: $e");
      return false;
    }
  }

  Future<void> apagarNo(int noId) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/nos/$noId'));
    } catch (e) {
      print("❌ ERRO apagarNo: $e");
    }
  }

  Future<List<No>> getAncestoresNo(int noId) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/nos/$noId/ancestrais'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['ancestrais'] as List).map((n) => No.fromMap(n)).toList();
      }
      return [];
    } catch (e) {
      print("❌ ERRO getAncestoresNo: $e");
      return [];
    }
  }

  Future<List<No>> getDescendentesNo(int noId) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/nos/$noId/descendentes'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['descendentes'] as List)
            .map((n) => No.fromMap(n))
            .toList();
      }
      return [];
    } catch (e) {
      print("❌ ERRO getDescendentesNo: $e");
      return [];
    }
  }

  Future<bool> copiarNo(int noId,
      {int? novoPaiId,
      int? novoProjetoId,
      required bool incluirRegistos}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/nos/$noId/copiar'),
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

  Future<List<NoPartilhado>> getNosPartilhados() async {
    try {
      final userId = await Session.getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/nos/partilhados/$userId'),
        headers: await _authHeaders(),
      );
      return await _handleResponse(
            response,
            (data) => (data['nos'] as List)
                .map((n) => NoPartilhado.fromMap(n))
                .toList(),
          ) ??
          [];
    } catch (e) {
      print("❌ ERRO getNosPartilhados: $e");
      return [];
    }
  }

  Future<List<int>> getNosComAcesso(int projetoId) async {
    try {
      final userId = await Session.getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/nos/$projetoId/acesso/$userId'),
        headers: await _authHeaders(),
      );
      return await _handleResponse(
            response,
            (data) => List<int>.from(data['nos_com_acesso']),
          ) ??
          [];
    } catch (e) {
      print("❌ ERRO getNosComAcesso: $e");
      return [];
    }
  }

  // ─── CAMPOS DINÂMICOS ──────────────────────────────────────
  Future<List<CampoDinamico>> getCampos(int noId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/campos/$noId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['campos'] as List)
            .map((c) => CampoDinamico.fromMap(c))
            .toList();
      }
      return [];
    } catch (e) {
      print("❌ ERRO getCampos: $e");
      return [];
    }
  }

  Future<bool> criarCampo(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/campos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dados),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ ERRO criarCampo: $e");
      return false;
    }
  }

  Future<bool> atualizarCampo(
    int id, {
    required String nomeCampo,
    required String tipoCampo,
    String? opcoes,
    required bool obrigatorio,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/campos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome_campo': nomeCampo,
          'tipo_campo': tipoCampo,
          'opcoes': opcoes,
          'obrigatorio': obrigatorio,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO atualizarCampo: $e");
      return false;
    }
  }

  Future<bool> atualizarOrdemCampo(int campoId, int novaOrdem) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/campos/$campoId/ordem'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ordem': novaOrdem}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO atualizarOrdemCampo: $e");
      return false;
    }
  }

  Future<bool> apagarCampo(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/campos/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO apagarCampo: $e");
      return false;
    }
  }

  // ─── REGISTOS ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getRegistos(int noId, {
    int page = 1,
    int limit = 30,
    String? search,
    String? filtroColuna,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/registos/$noId').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (filtroColuna != null) 'filtroColuna': filtroColuna,
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'registos': List<Map<String, dynamic>>.from(data['registos']),
          'total': (data['total'] as num?)?.toInt() ?? 0,
          'page': (data['page'] as num?)?.toInt() ?? 1,
          'limit': (data['limit'] as num?)?.toInt() ?? 50,
          'totalPages': (data['totalPages'] as num?)?.toInt() ?? 1,
        };
      }
      return {
        'registos': [],
        'total': 0,
        'page': 1,
        'limit': 50,
        'totalPages': 1,
      };
    } catch (e) {
      print("❌ ERRO getRegistos: $e");
      return {
        'registos': [],
        'total': 0,
        'page': 1,
        'limit': 50,
        'totalPages': 1,
      };
    }
  }

  Future<bool> inserirRegisto(Map<String, dynamic> dados) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri.parse('$_baseUrl/registos');
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

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);
      return json['success'] == true;
    } catch (e) {
      print('❌ Erro inserirRegisto: $e');
      return false;
    }
  }

  // ─── UTILIZADOR - PROJETO ──────────────────────────────────
  Future<List<Map<String, dynamic>>> getMembros(int projetoId) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/utilizador_projeto/$projetoId'));
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

  Future<bool> adicionarMembroAoProjeto(int utilizadorId, int projetoId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/utilizador_projeto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'utilizador_id': utilizadorId, 'projeto_id': projetoId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ ERRO adicionarMembroAoProjeto: $e");
      return false;
    }
  }

  Future<bool> removerMembroDoProjeto(int utilizadorId, int projetoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/utilizador_projeto/$projetoId/$utilizadorId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO removerMembroDoProjeto: $e");
      return false;
    }
  }

  // ─── UTILIZADOR - NÓ ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMembrosNo(int noId) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/utilizador_no/$noId'));
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

  Future<bool> darAcessoNo(int utilizadorId, int noId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/utilizador_no'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'utilizador_id': utilizadorId, 'no_id': noId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO darAcessoNo: $e");
      return false;
    }
  }

  Future<bool> removerAcessoNo(int utilizadorId, int noId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/utilizador_no/$noId/$utilizadorId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO removerAcessoNo: $e");
      return false;
    }
  }

  Future<bool> verificarAcesoNo(int noId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/utilizador_no/$noId/acesso/$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['temAcesso'] ?? false;
      }
      return false;
    } catch (e) {
      print("❌ ERRO verificarAcesoNo: $e");
      return false;
    }
  }

  // ─── BASE DE DADOS - LIMPEZA ───────────────────────────────
  Future<int> verificarOrfaoscamposDinamicos() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/database/cleanup/orphaned-campos'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orphanedCount'] as int;
      }
      return 0;
    } catch (e) {
      print("❌ ERRO verificarOrfaoscamposDinamicos: $e");
      return 0;
    }
  }

  Future<Map<String, dynamic>> limparCamposDinamicosOrfaos() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/database/cleanup/orphaned-campos'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': 'Status code: ${response.statusCode}'};
    } catch (e) {
      print("❌ ERRO limparCamposDinamicosOrfaos: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> auditoriaCamposPorNo() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/database/audit/campos-por-no'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['auditoria'] ?? []);
      }
      return [];
    } catch (e) {
      print("❌ ERRO auditoriaCamposPorNo: $e");
      return [];
    }
  }

  // ─── MÉTODOS ADICIONAIS ────────────────────────────────────
  Future<List<No>> getTodosNos(int projetoId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/nos/$projetoId'));
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

  Future<bool> duplicarNo(
    int noId, {
    int? novoPaiId,
    required int projetoId,
    required bool incluirSubpastas,
    required bool incluirCampos,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/nos/$noId/duplicar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'novo_pai_id': novoPaiId,
          'projeto_id': projetoId,
          'incluir_subpastas': incluirSubpastas,
          'incluir_campos': incluirCampos,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO duplicarNo: $e");
      return false;
    }
  }

  Future<bool> editarCampo(
    int id, {
    required String nome,
    required String tipo,
    String? opcoes,
    required bool obrigatorio,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/campos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome_campo': nome,
          'tipo_campo': tipo,
          'opcoes': opcoes,
          'obrigatorio': obrigatorio,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERRO editarCampo: $e");
      return false;
    }
  }
}