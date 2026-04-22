# 📚 Exemplos de Integração - Configuração de API

## Índice
1. [Integração em DatabaseHelper](#integração-em-databasehelper)
2. [Integração em AdminService](#integração-em-adminservice)
3. [Testes com AppConfig](#testes-com-appconfig)
4. [Endpoints Customizados](#endpoints-customizados)

---

## Integração em DatabaseHelper

### ✅ Uso Atual (Correto)

```dart
class DatabaseHelper {
  // String get _baseUrl => AppConfig.apiBaseUrl;
  // ✅ Automaticamente detecta o host/porta das variáveis de ambiente

  Future<Response> loginUser(String email, String password) {
    return http.post(
      Uri.parse('$_baseUrl/login'),
      // ✅ Se --dart-define=API_HOST=192.168.1.10
      //    Conecta a: http://192.168.1.10:3000/api/login
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> searchUtilizador(String email) {
    return http.get(
      Uri.parse('$_baseUrl/utilizadores/pesquisar/$encoded'),
      // ✅ Usa baseUrl dinâmico
      headers: _headers(),
    );
  }

  Future<Response> getUserTheme(int userId) {
    return http.get(
      Uri.parse('$_baseUrl/utilizadores/$userId/tema'),
      headers: _headers(),
    );
  }

  Future<Response> updateUserTheme(int userId, bool darkTheme) {
    return http.put(
      Uri.parse('$_baseUrl/utilizadores/$userId/tema'),
      body: jsonEncode({'tema_escuro': darkTheme}),
      headers: _headers(),
    );
  }

  Future<Response> getProjects(int userId) {
    return http.get(
      Uri.parse('$_baseUrl/projetos/$userId'),
      headers: _headers(),
    );
  }

  Future<Response> createProject(String nome, String descricao, int criadoPor) {
    return http.post(
      Uri.parse('$_baseUrl/projetos'),
      body: jsonEncode({
        'nome': nome,
        'descricao': descricao,
        'criado_por': criadoPor,
      }),
      headers: _headers(),
    );
  }

  Future<Response> deleteProject(int projectId) {
    return http.delete(
      Uri.parse('$_baseUrl/projetos/$projectId'),
      headers: _headers(),
    );
  }

  Future<Response> getNos(int projectId, {int? paiId}) {
    final paiParam = paiId != null ? '?pai_id=$paiId' : '';
    return http.get(
      Uri.parse('$_baseUrl/nos/$projectId$paiParam'),
      headers: _headers(),
    );
  }

  Future<Response> createNo(int projectId, String nome, {int? paiId}) {
    return http.post(
      Uri.parse('$_baseUrl/nos'),
      body: jsonEncode({
        'projeto_id': projectId,
        'pai_id': paiId,
        'nome': nome,
      }),
      headers: _headers(),
    );
  }

  Future<Response> deleteNo(int noId) {
    return http.delete(
      Uri.parse('$_baseUrl/nos/$noId'),
      headers: _headers(),
    );
  }

  Future<Response> getAncestors(int noId) {
    return http.get(
      Uri.parse('$_baseUrl/nos/$noId/ancestrais'),
      headers: _headers(),
    );
  }

  Map<String, String> _headers() {
    final token = Session.getTokenSync() ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
```

### Exemplo de Uso

```dart
// Sem flags: http://localhost:3000/api
final db = DatabaseHelper();
await db.loginUser('user@example.com', 'password');

// Com flags:
// flutter run --dart-define=API_HOST=192.168.1.10
// Conecta a: http://192.168.1.10:3000/api
await db.loginUser('user@example.com', 'password');
```

---

## Integração em AdminService

### ✅ Uso Atual (Correto)

```dart
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  // ✅ Usa AppConfig.adminApiBaseUrl (que é igual a apiBaseUrl)
  String get _baseUrl => AppConfig.adminApiBaseUrl;
  // Exemplo com emulator: http://10.0.2.2:3000/api

  Future<Map<String, String>> _headers() async {
    final token = await Session.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/utilizadores'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['utilizadores'] ?? [];
    } else {
      throw Exception('Erro ao carregar utilizadores');
    }
  }

  Future<dynamic> createUser(
    String nome,
    String email,
    String password,
    String perfil,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/utilizadores'),
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'password': password,
        'perfil': perfil,
      }),
      headers: await _headers(),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['utilizador'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erro ao criar utilizador');
    }
  }

  Future<bool> updateUserPassword(int id, String newPassword) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/utilizadores/$id/senha'),
      body: jsonEncode({'password': newPassword}),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }

  Future<bool> updateUser(
    int id,
    String nome,
    String email,
    String perfil,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/utilizadores/$id'),
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'perfil': perfil,
      }),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/utilizadores/$id'),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }
}
```

### Exemplo de Uso

```dart
// Android Emulator
// flutter run --dart-define=API_HOST=10.0.2.2
final adminService = AdminService.instance;
final users = await adminService.getAllUsers();
// Conecta a: http://10.0.2.2:3000/api/utilizadores

// Rede local
// flutter run --dart-define=API_HOST=192.168.1.20 --dart-define=API_PORT=3000
final users = await adminService.getAllUsers();
// Conecta a: http://192.168.1.20:3000/api/utilizadores

// Produção
// flutter build apk --dart-define=API_HOST=api.foeng.pt --dart-define=API_PORT=443
final users = await adminService.getAllUsers();
// Conecta a: https://api.foeng.pt/api/utilizadores
```

---

## Testes com AppConfig

### Widget de Debug

```dart
class AppConfigDebugWidget extends StatelessWidget {
  const AppConfigDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração da API')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigItem('Host', AppConfig.host),
            _buildConfigItem('Porta', '${AppConfig.port}'),
            _buildConfigItem('Scheme', AppConfig._scheme),
            _buildConfigItem('API Base URL', AppConfig.apiBaseUrl),
            _buildConfigItem('Server URL', AppConfig.serverBaseUrl),
            const SizedBox(height: 24),
            _buildTestButton('Testar Conexão', () => _testConnection()),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Future<void> _testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.serverBaseUrl}/api/health'),
      );

      if (response.statusCode == 200) {
        print('✅ Conexão bem-sucedida!');
      } else {
        print('❌ Erro: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro de conexão: $e');
    }
  }
}
```

### Uso no main()

```dart
void main() {
  // Imprimir configuração atual
  AppConfig.printConfig();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controlo de Qualidade',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppConfigDebugWidget(),  // Para debug
      // home: const LoginScreen(),  // Para produção
    );
  }
}
```

---

## Endpoints Customizados

### Usar AppConfig.endpoint()

```dart
// Exemplo 1: Endpoint simples
String loginUrl = AppConfig.endpoint('login');
// Resultado: http://localhost:3000/api/login

// Exemplo 2: Endpoint com ID
String projectUrl = AppConfig.endpoint('projetos/123');
// Resultado: http://localhost:3000/api/projetos/123

// Exemplo 3: Endpoint com query string
String searchUrl = '${AppConfig.endpoint('utilizadores/pesquisar')}?q=test';
// Resultado: http://localhost:3000/api/utilizadores/pesquisar?q=test

// Exemplo 4: Usar com http
final response = await http.get(
  Uri.parse(AppConfig.endpoint('utilizadores/1')),
  headers: {'Authorization': 'Bearer $token'},
);
```

### Usar AppConfig.endpointWithPath()

```dart
// Para APIs com múltiplos caminhos
String v1Endpoint = AppConfig.endpointWithPath('v1', 'login');
// Resultado: http://localhost:3000/v1/login

String v2Endpoint = AppConfig.endpointWithPath('v2', 'utilizadores');
// Resultado: http://localhost:3000/v2/utilizadores
```

---

## 🧪 Testando Localmente

### Setup Recomendado

```bash
# Terminal 1: Backend Node.js
cd ControleQualidade_API
npm start
# API roda em: http://localhost:3000

# Terminal 2: App Flutter (sem flags - usa localhost)
cd controle_qualidadev2
flutter run
# Conecta automaticamente a: http://localhost:3000/api

# Terminal 3 (opcional): Testar com rede local
flutter run --dart-define=API_HOST=192.168.1.10
# Conecta a: http://192.168.1.10:3000/api
```

### Verificar Logs

```dart
void main() {
  // Habilitar logs de config
  AppConfig.printConfig();  // Imprime no console
  
  // Também verificar no app
  http.Client().get(Uri.parse(AppConfig.endpoint('health')))
    .then((response) => print('API Status: ${response.statusCode}'));
  
  runApp(const MyApp());
}
```

---

**Exemplos de Integração Completos!** ✅

Data: 22 de Abril de 2026
