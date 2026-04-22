# 🔧 Configuração de Ambiente - API Flutter

## 📋 Visão Geral

O aplicativo Flutter agora suporta configuração dinâmica da API através de variáveis de ambiente. Não há mais IPs hardcoded!

**Antes**: API fixada em `192.168.1.246:6003` 😞  
**Agora**: Configurável via `--dart-define` durante build 🎉

---

## 🚀 Como Usar

### 1. Desenvolvimento Local (localhost)

Padrão (sem flags):
```bash
flutter run
```

**Resultado**: Conecta a http://localhost:3000/api

---

### 2. Desenvolvimento Local com Porta Customizada

```bash
flutter run --dart-define=API_PORT=8000
```

**Resultado**: Conecta a http://localhost:8000/api

---

### 3. Rede Local (máquina específica)

```bash
flutter run --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=3000
```

**Resultado**: Conecta a http://192.168.1.10:3000/api

---

### 4. Android Emulator (aceder ao host machine)

```bash
flutter run --dart-define=API_HOST=10.0.2.2 --dart-define=API_PORT=3000
```

**Resultado**: Conecta a http://10.0.2.2:3000/api

⚠️ **Nota**: 10.0.2.2 é o alias especial do Android Emulator para aceder ao localhost da máquina host.

---

### 5. iOS Simulator (aceder ao host machine)

```bash
flutter run --dart-define=API_HOST=127.0.0.1 --dart-define=API_PORT=3000
```

**Resultado**: Conecta a http://127.0.0.1:3000/api

---

### 6. Produção (HTTPS)

```bash
flutter build apk --dart-define=API_HOST=api.foeng.pt --dart-define=API_PORT=443
```

**Resultado**: Conecta a https://api.foeng.pt/api (porta 443 ativa HTTPS automaticamente)

---

### 7. Build de Release com API Staging

```bash
flutter build apk --dart-define=API_HOST=staging-api.foeng.pt --dart-define=API_PORT=3000
```

**Resultado**: Conecta a http://staging-api.foeng.pt:3000/api

---

## 📊 Variáveis Disponíveis

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `API_HOST` | String | `localhost` | Host/IP do servidor |
| `API_PORT` | int | `3000` | Porta do servidor |
| `API_PATH` | String | `/api` | Caminho base da API |

---

## 🔐 Detecção Automática de Scheme

O scheme (http/https) é **detectado automaticamente**:

- **Porta 443** → `https://`
- **Porta 8443** → `https://`
- **Outras portas** → `http://`

**Exemplos**:

```bash
# Produção (HTTPS automático)
flutter run --dart-define=API_HOST=api.example.com --dart-define=API_PORT=443
# Resultado: https://api.example.com/api

# Staging (HTTP explícito)
flutter run --dart-define=API_HOST=staging-api.example.com --dart-define=API_PORT=3000
# Resultado: http://staging-api.example.com:3000/api
```

---

## 💾 Ficheiros Afetados

### Modificado: `lib/config/app_config.dart`

**Antes**:
```dart
static const String host = String.fromEnvironment(
  'API_HOST',
  defaultValue: '192.168.1.246',  // ❌ IP hardcoded
);
```

**Depois**:
```dart
static const String host = String.fromEnvironment(
  'API_HOST',
  defaultValue: 'localhost',  // ✅ Genérico
);

// ✅ Suporte automático de HTTPS
static String get _scheme {
  if (port == 443) return 'https';
  if (port == 8443) return 'https';
  return 'http';
}
```

### Usando em Todo o Projeto:

- **DatabaseHelper**: `String get _baseUrl => AppConfig.apiBaseUrl;`
- **AdminService**: `String get _baseUrl => AppConfig.adminApiBaseUrl;`
- Todas as rotas usam `AppConfig.endpoint()` ou `AppConfig.apiBaseUrl`

---

## 🧪 Testando a Configuração

### Verificar Configuração Ativa

Adicione isto no `main()` do seu app:

```dart
void main() {
  AppConfig.printConfig();  // Imprime config no console
  runApp(const MyApp());
}
```

**Saída (exemplo)**:
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

---

## 📱 Cenários Comuns

### Cenário 1: Desenvolvedor Local

```bash
# Terminal 1: Iniciar backend
cd ControleQualidade_API
npm start  # Roda em localhost:3000

# Terminal 2: Executar app
flutter run
# Automaticamente conecta a http://localhost:3000/api ✓
```

### Cenário 2: Testar com Dispositivo Físico

Máquina tem IP 192.168.1.10:
```bash
flutter run --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=3000
```

Dispositivo conecta a http://192.168.1.10:3000/api ✓

### Cenário 3: Android Emulator

```bash
flutter run --dart-define=API_HOST=10.0.2.2 --dart-define=API_PORT=3000
```

Emulator conecta a http://10.0.2.2:3000/api ✓

### Cenário 4: Build para Produção

```bash
flutter build apk \
  --dart-define=API_HOST=api.foeng.pt \
  --dart-define=API_PORT=443 \
  --release
```

App conecta a https://api.foeng.pt/api ✓

### Cenário 5: Build para Staging

```bash
flutter build apk \
  --dart-define=API_HOST=staging-api.foeng.pt \
  --dart-define=API_PORT=3000 \
  --release
```

App conecta a http://staging-api.foeng.pt:3000/api ✓

---

## 🔗 Referências no Código

### Em DatabaseHelper

```dart
class DatabaseHelper {
  String get _baseUrl => AppConfig.apiBaseUrl;
  
  Future<Response> loginUser(String email, String password) {
    return http.post(
      Uri.parse('$_baseUrl/login'),  // ✓ Usa AppConfig automaticamente
      body: jsonEncode({'email': email, 'password': password}),
    );
  }
}
```

### Em AdminService

```dart
class AdminService {
  String get _baseUrl => AppConfig.adminApiBaseUrl;
  
  Future<List<Utilizador>> getAllUsers() {
    return http.get(
      Uri.parse('$_baseUrl/utilizadores'),  // ✓ Usa AppConfig automaticamente
      headers: await _headers(),
    );
  }
}
```

---

## ⚠️ Notas Importantes

### ✅ Fazer

- ✅ Usar `--dart-define` para cada build
- ✅ Documentar variáveis no ficheiro de configuração
- ✅ Testar com diferentes hosts antes de deploy
- ✅ Usar HTTPS em produção (porta 443)

### ❌ Não Fazer

- ❌ Editar app_config.dart com IPs hardcoded
- ❌ Esquecer de passar `--dart-define` para builds
- ❌ Usar HTTP em produção (inseguro)
- ❌ Publicar builds sem configurar o host correto

---

## 🛠️ Troubleshooting

### Problema: "Connection refused"

**Causa**: Host/porta incorretos ou servidor offline

**Solução**:
1. Verificar se servidor está rodando
2. Confirmar host e porta: `AppConfig.printConfig()`
3. Testar conexão: `curl http://HOST:PORTA/api/health`

### Problema: "Timeout"

**Causa**: Host inacessível ou firewall bloqueando

**Solução**:
1. Verificar ping ao host: `ping HOST`
2. Verificar firewall/rede
3. Se Android Emulator, usar `10.0.2.2` em vez de `localhost`

### Problema: "SSL Certificate Error"

**Causa**: HTTPS sem certificado válido

**Solução**:
1. Usar HTTP (porta não 443) para dev
2. Usar certificado válido em produção
3. Ou adicionar exceção de segurança (dev only)

---

## 📚 Exemplos Práticos

### Script de Build Automatizado

```bash
#!/bin/bash

# build.sh - Script de build com variáveis de ambiente

case "$1" in
  dev)
    echo "🔨 Building para desenvolvimento..."
    flutter build apk \
      --dart-define=API_HOST=localhost \
      --dart-define=API_PORT=3000 \
      --release
    ;;
  staging)
    echo "🔨 Building para staging..."
    flutter build apk \
      --dart-define=API_HOST=staging-api.foeng.pt \
      --dart-define=API_PORT=3000 \
      --release
    ;;
  prod)
    echo "🔨 Building para produção..."
    flutter build apk \
      --dart-define=API_HOST=api.foeng.pt \
      --dart-define=API_PORT=443 \
      --release
    ;;
  *)
    echo "Uso: ./build.sh [dev|staging|prod]"
    exit 1
    ;;
esac
```

**Uso**:
```bash
chmod +x build.sh
./build.sh dev      # Build local
./build.sh staging  # Build staging
./build.sh prod     # Build produção
```

---

**Configuração de Ambiente Implementada com Sucesso!** ✅

Data: 22 de Abril de 2026  
Versão: 1.0
