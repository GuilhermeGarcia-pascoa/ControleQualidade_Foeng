# 💡 Exemplos de Uso - Autenticação JWT

## 📚 Índice
1. [Exemplos com cURL](#exemplos-com-curl)
2. [Exemplos com JavaScript/Fetch](#exemplos-com-javascript)
3. [Exemplos com Flutter](#exemplos-com-flutter)
4. [Tratamento de Erros](#tratamento-de-erros)

---

## Exemplos com cURL

### 1. Login
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@foeng.com",
    "password": "senha123"
  }'
```

**Resposta**:
```json
{
  "success": true,
  "user": {
    "id": 1,
    "nome": "Administrador",
    "email": "admin@foeng.com",
    "perfil": "admin"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJhZG1pbkBmb2VuZy5jb20iLCJwZXJmaWwiOiJhZG1pbiIsImlhdCI6MTcxMzY4NzYwMCwiZXhwIjoxNzEzNzE3NjAwfQ.vX...",
  "expiresIn": "8h"
}
```

### 2. Acesso Protegido com Token
```bash
# Guardar token em variável
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# GET - Listar utilizadores (requer admin)
curl -X GET http://localhost:3000/api/utilizadores \
  -H "Authorization: Bearer $TOKEN"

# POST - Criar novo projeto
curl -X POST http://localhost:3000/api/projetos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nome": "Projeto Novo",
    "descricao": "Descrição do projeto",
    "criado_por": 1
  }'

# PUT - Atualizar projeto
curl -X PUT http://localhost:3000/api/projetos/5 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nome": "Nome Atualizado",
    "descricao": "Nova descrição"
  }'

# DELETE - Eliminar projeto (requer admin)
curl -X DELETE http://localhost:3000/api/projetos/5 \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Operações com Nós
```bash
TOKEN="seu_token_aqui"

# Obter nós de um projeto
curl -X GET "http://localhost:3000/api/nos/1?pai_id=null" \
  -H "Authorization: Bearer $TOKEN"

# Criar nó
curl -X POST http://localhost:3000/api/nos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "projeto_id": 1,
    "pai_id": null,
    "nome": "Pasta Principal"
  }'

# Obter nós partilhados
curl -X GET http://localhost:3000/api/nos/partilhados/1 \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Operações com Registos
```bash
TOKEN="seu_token_aqui"

# Obter registos de um nó
curl -X GET http://localhost:3000/api/registos/1 \
  -H "Authorization: Bearer $TOKEN"

# Criar registo com arquivo
curl -X POST http://localhost:3000/api/registos \
  -H "Authorization: Bearer $TOKEN" \
  -F "no_id=1" \
  -F "utilizador_id=1" \
  -F "dados_json={\"campo1\":\"valor1\"}" \
  -F "arquivo=@/path/to/file.jpg"
```

---

## Exemplos com JavaScript

### 1. Função de Login
```javascript
async function login(email, password) {
  try {
    const response = await fetch('http://localhost:3000/api/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password })
    });

    if (!response.ok) {
      throw new Error('Login falhou');
    }

    const data = await response.json();
    
    // Guardar token
    localStorage.setItem('jwt_token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    
    return data;
  } catch (error) {
    console.error('Erro de login:', error);
    throw error;
  }
}

// Usar
login('admin@foeng.com', 'senha123')
  .then(data => console.log('Login bem-sucedido:', data))
  .catch(error => console.error(error));
```

### 2. Função para Requests Autenticadas
```javascript
async function apiRequest(endpoint, options = {}) {
  const token = localStorage.getItem('jwt_token');
  
  if (!token) {
    throw new Error('Token não encontrado. Faça login primeiro.');
  }

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
    ...options.headers
  };

  try {
    const response = await fetch(`http://localhost:3000/api${endpoint}`, {
      ...options,
      headers
    });

    if (response.status === 401) {
      // Token expirado ou inválido
      localStorage.removeItem('jwt_token');
      localStorage.removeItem('user');
      window.location.href = '/login';
      throw new Error('Sessão expirada. Faça login novamente.');
    }

    if (!response.ok) {
      throw new Error(`Erro ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    console.error('Erro na requisição:', error);
    throw error;
  }
}
```

### 3. Exemplos de Uso da Função
```javascript
// GET - Listar utilizadores
apiRequest('/utilizadores', {
  method: 'GET'
}).then(data => console.log(data));

// POST - Criar projeto
apiRequest('/projetos', {
  method: 'POST',
  body: JSON.stringify({
    nome: 'Novo Projeto',
    descricao: 'Descrição',
    criado_por: 1
  })
}).then(data => console.log('Projeto criado:', data));

// PUT - Atualizar nó
apiRequest('/nos/5', {
  method: 'PUT',
  body: JSON.stringify({
    nome: 'Nome Atualizado'
  })
}).then(() => console.log('Nó atualizado'));

// DELETE - Eliminar projeto
apiRequest('/projetos/5', {
  method: 'DELETE'
}).then(() => console.log('Projeto eliminado'));
```

### 4. Classe para Gerenciar Autenticação
```javascript
class AuthManager {
  constructor(apiUrl = 'http://localhost:3000/api') {
    this.apiUrl = apiUrl;
    this.token = localStorage.getItem('jwt_token');
    this.user = JSON.parse(localStorage.getItem('user') || 'null');
  }

  async login(email, password) {
    const response = await fetch(`${this.apiUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    const data = await response.json();
    
    if (data.success) {
      this.token = data.token;
      this.user = data.user;
      localStorage.setItem('jwt_token', this.token);
      localStorage.setItem('user', JSON.stringify(this.user));
    }

    return data;
  }

  logout() {
    this.token = null;
    this.user = null;
    localStorage.removeItem('jwt_token');
    localStorage.removeItem('user');
  }

  isAuthenticated() {
    return !!this.token;
  }

  isAdmin() {
    return this.user?.perfil === 'admin';
  }

  getAuthHeader() {
    return {
      'Authorization': `Bearer ${this.token}`
    };
  }

  async request(endpoint, options = {}) {
    if (!this.isAuthenticated()) {
      throw new Error('Não autenticado');
    }

    const headers = {
      'Content-Type': 'application/json',
      ...this.getAuthHeader(),
      ...options.headers
    };

    const response = await fetch(`${this.apiUrl}${endpoint}`, {
      ...options,
      headers
    });

    if (response.status === 401) {
      this.logout();
      throw new Error('Sessão expirada');
    }

    return response.json();
  }
}

// Usar
const auth = new AuthManager();

// Login
await auth.login('admin@foeng.com', 'senha123');

// Usar em requests
if (auth.isAuthenticated()) {
  const utilizadores = await auth.request('/utilizadores');
  console.log(utilizadores);
}

// Logout
auth.logout();
```

---

## Exemplos com Flutter

### 1. Serviço de Autenticação
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3000/api';
  final storage = const FlutterSecureStorage();

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Guardar token de forma segura
        await storage.write(
          key: 'jwt_token',
          value: data['token'],
        );
        await storage.write(
          key: 'user',
          value: jsonEncode(data['user']),
        );
        
        return data;
      } else {
        throw Exception('Falha no login');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user');
  }

  // Obter token
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // Request autenticado
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await getToken();
    
    if (token == null) {
      throw Exception('Token não encontrado');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl$endpoint');

    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(url, headers: headers, body: jsonEncode(body));
        break;
      case 'PUT':
        response = await http.put(url, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Método HTTP não suportado');
    }

    if (response.statusCode == 401) {
      // Token expirado
      await logout();
      throw Exception('Sessão expirada');
    }

    return response;
  }
}
```

### 2. Uso em Widgets
```dart
class ProjetosScreen extends StatefulWidget {
  @override
  State<ProjetosScreen> createState() => _ProjetosScreenState();
}

class _ProjetosScreenState extends State<ProjetosScreen> {
  late AuthService _authService;
  late Future<List<dynamic>> _projetos;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _projetos = _carregarProjetos();
  }

  Future<List<dynamic>> _carregarProjetos() async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/projetos/1', // userId
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['projetos'] ?? [];
      } else {
        throw Exception('Falha ao carregar projetos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
      return [];
    }
  }

  Future<void> _criarProjeto() async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/projetos',
        body: {
          'nome': 'Novo Projeto',
          'descricao': 'Descrição do projeto',
          'criado_por': 1,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _projetos = _carregarProjetos();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projeto criado com sucesso')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _projetos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final projetos = snapshot.data ?? [];
          
          return ListView.builder(
            itemCount: projetos.length,
            itemBuilder: (context, index) {
              final projeto = projetos[index];
              return ListTile(
                title: Text(projeto['nome']),
                subtitle: Text(projeto['descricao'] ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _criarProjeto,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## Tratamento de Erros

### Códigos de Resposta Comuns

| Código | Significado | Ação |
|--------|-------------|------|
| 200 | OK | Sucesso |
| 201 | Created | Recurso criado com sucesso |
| 400 | Bad Request | Dados inválidos |
| 401 | Unauthorized | Token ausente ou inválido |
| 403 | Forbidden | Sem permissão (não é admin) |
| 404 | Not Found | Recurso não encontrado |
| 500 | Server Error | Erro no servidor |

### Exemplo de Tratamento Completo
```javascript
async function handleApiError(error, response) {
  switch (response.status) {
    case 401:
      console.error('Não autenticado - Redirecionando para login');
      localStorage.removeItem('jwt_token');
      window.location.href = '/login';
      break;
    
    case 403:
      console.error('Sem permissão para esta ação');
      alert('Você não tem permissão para executar esta ação');
      break;
    
    case 404:
      console.error('Recurso não encontrado');
      alert('O recurso solicitado não foi encontrado');
      break;
    
    case 500:
      console.error('Erro no servidor');
      alert('Ocorreu um erro no servidor. Tente novamente mais tarde.');
      break;
    
    default:
      console.error('Erro desconhecido:', response.status);
      alert('Erro: ' + error.message);
  }
}
```

---

## 🔒 Dicas de Segurança

✅ Sempre use HTTPS em produção  
✅ Nunca guarde o token em localStorage (use httpOnly cookies)  
✅ Implemente logout automático após inatividade  
✅ Valide o token no backend para cada requisição  
✅ Use CORS corretamente  
✅ Sanitize entradas do utilizador  
✅ Implemente rate limiting para login  

---

**Última Atualização**: 21 de Abril de 2026
