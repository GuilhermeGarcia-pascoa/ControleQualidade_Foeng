# 🔄 Fluxo de Requisições HTTP com AppConfig

## Diagrama: Como as Requisições Funcionam

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER APP                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  1️⃣ Screen (login_screen.dart)                                              │
│     ↓                                                                         │
│     await DatabaseHelper().loginUser(email, password)                       │
│                                                                               │
│  2️⃣ DatabaseHelper                                                           │
│     ↓                                                                         │
│     String get _baseUrl => AppConfig.apiBaseUrl;  ← PEGA URL AQUI           │
│     ↓                                                                         │
│     Uri.parse('$_baseUrl/login')  ← MONTA URL FINAL                        │
│                                                                               │
│  3️⃣ AppConfig.apiBaseUrl                                                    │
│     ├─ String host = API_HOST (default: 'localhost')                        │
│     ├─ int port = API_PORT (default: 3000)                                  │
│     ├─ String _scheme = detectado automaticamente                           │
│     │   ├─ Se port == 443 → 'https'                                         │
│     │   ├─ Se port == 8443 → 'https'                                        │
│     │   └─ Senão → 'http'                                                   │
│     └─ return '$_scheme://$host:$port/api'                                  │
│                                                                               │
│  4️⃣ Resultado Final                                                         │
│     └─ 'http://localhost:3000/api'  ← URL DINÂMICA                          │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                        REDE / INTERNET                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  http://localhost:3000/api/login                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                       NODE.JS BACKEND                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  POST /api/login                                                             │
│  ├─ Autenticação (JWT)                                                      │
│  ├─ Validação de dados                                                      │
│  └─ Resposta: { success: true, user: {...}, token: '...' }                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Exemplos Práticos

### Cenário 1: Desenvolvimento Local

```
Flutter App
    ↓
flutter run
    ↓ (sem --dart-define)
AppConfig.apiBaseUrl
    ├─ host: 'localhost'  (padrão)
    ├─ port: 3000  (padrão)
    ├─ _scheme: 'http'  (porta não é 443)
    └─ Resultado: 'http://localhost:3000/api'
    ↓
URI final: http://localhost:3000/api/login
    ↓
Node.js Backend (localhost:3000)
    ├─ ✅ Encontra rota /api/login
    ├─ ✅ Processa requisição
    └─ ✅ Retorna resposta
```

### Cenário 2: Android Emulator

```
Flutter App
    ↓
flutter run --dart-define=API_HOST=10.0.2.2
    ↓
AppConfig.apiBaseUrl
    ├─ host: '10.0.2.2'  (from --dart-define)
    ├─ port: 3000  (padrão)
    ├─ _scheme: 'http'  (porta não é 443)
    └─ Resultado: 'http://10.0.2.2:3000/api'
    ↓
URI final: http://10.0.2.2:3000/api/login
    ↓
Android Emulator Network
    ├─ 10.0.2.2 = alias para localhost do host machine
    ├─ ✅ Consegue aceder ao backend no PC
    └─ ✅ Requisição vai para Node.js local
```

### Cenário 3: Produção HTTPS

```
Flutter App
    ↓
flutter build apk \
  --dart-define=API_HOST=api.foeng.pt \
  --dart-define=API_PORT=443
    ↓
AppConfig.apiBaseUrl
    ├─ host: 'api.foeng.pt'  (from --dart-define)
    ├─ port: 443  (from --dart-define)
    ├─ _scheme: 'https'  ✅ (porta == 443!)
    └─ Resultado: 'https://api.foeng.pt/api'
    ↓
URI final: https://api.foeng.pt/api/login
    ↓
Internet
    ├─ ✅ HTTPS automático (porta 443)
    ├─ ✅ Certificado validado
    └─ ✅ Seguro para produção
```

---

## Tabela de Cenários

| Cenário | Comando | Host | Porta | Scheme | URL Final |
|---------|---------|------|-------|--------|-----------|
| **Dev Local** | `flutter run` | localhost | 3000 | http | http://localhost:3000/api |
| **Dev Local (porta alt)** | `--dart-define=API_PORT=8000` | localhost | 8000 | http | http://localhost:8000/api |
| **Rede Local** | `--dart-define=API_HOST=192.168.1.10` | 192.168.1.10 | 3000 | http | http://192.168.1.10:3000/api |
| **Android Emulator** | `--dart-define=API_HOST=10.0.2.2` | 10.0.2.2 | 3000 | http | http://10.0.2.2:3000/api |
| **iOS Simulator** | `--dart-define=API_HOST=127.0.0.1` | 127.0.0.1 | 3000 | http | http://127.0.0.1:3000/api |
| **Staging HTTP** | `--dart-define=API_HOST=staging-api.foeng.pt` | staging-api.foeng.pt | 3000 | http | http://staging-api.foeng.pt:3000/api |
| **Staging HTTPS** | `--dart-define=API_HOST=staging-api.foeng.pt --dart-define=API_PORT=443` | staging-api.foeng.pt | 443 | https | https://staging-api.foeng.pt/api |
| **Produção** | `--dart-define=API_HOST=api.foeng.pt --dart-define=API_PORT=443` | api.foeng.pt | 443 | https | https://api.foeng.pt/api |

---

## 📊 Fluxo de Requisição Completo

### 1. Usuário faz Login

```
┌──────────────────────────────────────┐
│     LoginScreen                      │
│  ┌──────────────────────────────┐    │
│  │ Email: user@example.com      │    │
│  │ Password: ••••••••           │    │
│  │ [Entrar]                     │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
           ↓ Clique em "Entrar"
```

### 2. DatabaseHelper faz a Requisição

```
DatabaseHelper.loginUser('user@example.com', 'password')
    ↓
_baseUrl = AppConfig.apiBaseUrl = 'http://localhost:3000/api'
    ↓
Uri.parse('$_baseUrl/login') = 'http://localhost:3000/api/login'
    ↓
http.post(
  Uri.parse('http://localhost:3000/api/login'),
  body: '{"email":"user@example.com","password":"password"}',
  headers: {'Content-Type': 'application/json'}
)
```

### 3. Backend Processa

```
Node.js Backend
    ↓
POST /api/login
    ├─ Recebe: email, password
    ├─ Valida email/password
    ├─ Gera JWT token
    └─ Retorna: { success: true, user: {...}, token: 'eyJ...' }
```

### 4. App Recebe Resposta

```
Response recebida:
{
  "success": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "nome": "João Silva",
    "perfil": "trabalhador"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "8h"
}
    ↓
Session.setToken(token)
    ↓
NavigatorPush(DashboardScreen)
```

### 5. Próximas Requisições Usam Token

```
Toda requisição GET/POST/PUT/DELETE:
    ↓
_headers() → {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'  ← Token do login
}
    ↓
Backend recebe Authorization header
    ↓
Middleware verifica JWT
    ├─ ✅ Token válido → Processa requisição
    └─ ❌ Token inválido → Retorna 401 Unauthorized
```

---

## 🔍 Onde AppConfig é Usado

```
AppConfig.apiBaseUrl (mais comum)
    ↓
DatabaseHelper._baseUrl
    ├─ loginUser()
    ├─ getProjects()
    ├─ getNos()
    ├─ createNo()
    ├─ deleteNo()
    └─ ... (todos os endpoints)

AppConfig.adminApiBaseUrl
    ↓
AdminService._baseUrl
    ├─ getAllUsers()
    ├─ createUser()
    ├─ updateUser()
    ├─ deleteUser()
    └─ ... (operações admin)

AppConfig.endpoint()
    ↓
Usado para construir URLs manualmente
    └─ AppConfig.endpoint('login') = 'http://localhost:3000/api/login'

AppConfig.endpointWithPath()
    ↓
Usado para APIs com caminhos customizados
    └─ AppConfig.endpointWithPath('v2', 'login') = 'http://localhost:3000/v2/login'
```

---

## 🧪 Testando o Fluxo

### 1. Verificar Configuração Atual

```dart
void main() {
  AppConfig.printConfig();  // Imprime config no console
  runApp(MyApp());
}
```

Saída:
```
┌─────────────────────────────────────┐
│        CONFIGURAÇÃO DA API          │
├─────────────────────────────────────┤
│ Host:          localhost             │
│ Porta:         3000                  │
│ Scheme:        http                  │
│ API Base URL:  http://localhost:3000/api
│ Server URL:    http://localhost:3000│
└─────────────────────────────────────┘
```

### 2. Testar Conexão Manual

```dart
import 'package:http/http.dart' as http;

void testConnection() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/health'),
      headers: {'Authorization': 'Bearer $token'},
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
```

### 3. Verificar Logs de Requisição

```dart
// Adicionar interceptor para logar requisições
http.Client client = http.Client();
// ... usar client para fazer requisições
```

---

## ⚠️ Erros Comuns

### Erro 1: "Connection refused"

**Causa**: Servidor não está rodando ou host/porta incorretos.

**Solução**:
```bash
# Verificar se servidor está rodando
curl http://localhost:3000/api/health

# Se usando host diferente
AppConfig.printConfig()  # Ver qual URL está sendo usada

# Se está em rede local, verificar IP
ping 192.168.1.10  # Ou qual for o host
```

### Erro 2: "Timeout"

**Causa**: Host inacessível ou firewall bloqueando.

**Solução**:
```bash
# Verificar conectividade
ping api.foeng.pt

# Verificar firewall
# Windows: Check Windows Defender Firewall
# Linux: sudo ufw status
# Mac: sudo /usr/libexec/ApplicationFirewall/socketfilterfw -getstatus
```

### Erro 3: "SSL Certificate Error"

**Causa**: HTTPS com certificado inválido.

**Solução**:
- ✅ Em dev: Usar HTTP (porta não 443)
- ✅ Em produção: Certificado válido obrigatório
- ⚠️ Nunca ignorar validação em produção

---

**Documentação de Fluxo Completa!** ✅

Data: 22 de Abril de 2026
