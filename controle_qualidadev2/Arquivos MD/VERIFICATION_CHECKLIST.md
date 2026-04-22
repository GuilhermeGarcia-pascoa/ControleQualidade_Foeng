# ✅ Checklist de Verificação Pós-Refatoração

## 🎯 Objetivo
Garantir que a refatoração foi bem-sucedida e o projeto está pronto para usar em diferentes ambientes.

---

## 📋 Verificações Técnicas

### 1. Ficheiros Modificados

- [ ] `lib/config/app_config.dart`
  - [ ] Sem IP 192.168.1.246 (verify com grep: não encontra)
  - [ ] Porta padrão é 3000 (não 6003)
  - [ ] Host padrão é 'localhost' (não IP)
  - [ ] `_scheme` getter existe
  - [ ] HTTPS automático para portas 443/8443
  - [ ] Método `endpoint()` existe
  - [ ] Método `endpointWithPath()` existe
  - [ ] Método `printConfig()` existe

- [ ] Nenhuma mudança necessária em:
  - [ ] `lib/database/database_helper.dart` (usa AppConfig.apiBaseUrl)
  - [ ] `lib/services/admin_service.dart` (usa AppConfig.adminApiBaseUrl)
  - [ ] Nenhuma classe tem URL hardcoded

### 2. Dependências

```bash
flutter pub get
```

- [ ] Nenhum erro de dependências
- [ ] pubspec.lock atualizado
- [ ] Todas as dependências instaladas

### 3. Linting & Analysis

```bash
flutter analyze
```

- [ ] Sem erros críticos
- [ ] Sem warnings não esperados
- [ ] Code style consistente

---

## 🧪 Testes Funcionais

### 1. Desenvolvimento Local

```bash
# Terminal 1: Backend
cd ControleQualidade_API
npm start
# ✅ Verifica: npm start executa sem erros
# ✅ Verifica: Backend roda em http://localhost:3000

# Terminal 2: App Flutter
cd controle_qualidadev2
flutter run
```

**Verificações**:
- [ ] App inicia sem erros
- [ ] `AppConfig.printConfig()` mostra:
  - [ ] `Host: localhost`
  - [ ] `Porta: 3000`
  - [ ] `Scheme: http`
  - [ ] `API Base URL: http://localhost:3000/api`
- [ ] Consegue fazer login
- [ ] Consegue ver projetos
- [ ] Consegue fazer upload de ficheiros

### 2. Android Emulator

```bash
flutter run --dart-define=API_HOST=10.0.2.2
```

**Verificações**:
- [ ] `AppConfig.printConfig()` mostra:
  - [ ] `Host: 10.0.2.2`
  - [ ] `Porta: 3000`
  - [ ] `API Base URL: http://10.0.2.2:3000/api`
- [ ] App consegue aceder ao backend na máquina host
- [ ] Login funciona
- [ ] Requisições vão para o servidor correto

### 3. Rede Local

```bash
# Assumindo backend em 192.168.1.10:3000
flutter run --dart-define=API_HOST=192.168.1.10
```

**Verificações**:
- [ ] `AppConfig.printConfig()` mostra host correto
- [ ] App consegue comunicar com backend em outro PC
- [ ] Login funciona
- [ ] Operações normais funcionam

### 4. HTTPS Automático

```bash
# Teste 1: Porta 443
flutter run --dart-define=API_PORT=443
# ✅ Verifica: _scheme retorna 'https'

# Teste 2: Porta 8443
flutter run --dart-define=API_PORT=8443
# ✅ Verifica: _scheme retorna 'https'

# Teste 3: Outra porta
flutter run --dart-define=API_PORT=5000
# ✅ Verifica: _scheme retorna 'http'
```

### 5. Caminho Customizado

```bash
flutter run --dart-define=API_PATH=/api/v2
```

**Verificações**:
- [ ] `AppConfig.printConfig()` mostra `/api/v2`
- [ ] URLs são construídas com caminho correto

---

## 🔍 Verificações de Código

### 1. Grep para Valores Hardcoded

```bash
# Procurar por IP 192.168.1.246
grep -r "192.168.1.246" .
# ✅ Esperado: Nenhum resultado (ou apenas comentários históricos)

# Procurar por porta 6003
grep -r "6003" .
# ✅ Esperado: Nenhum resultado (ou apenas comentários)

# Procurar por http:// direto (sem AppConfig)
grep -r "http://" lib/
# ✅ Esperado: Nenhum resultado (tudo deve usar AppConfig)
```

### 2. Verificar Uso de AppConfig

```bash
# Procurar uso de apiBaseUrl
grep -r "apiBaseUrl" lib/
# ✅ Esperado: DatabaseHelper, AdminService usam isso

# Procurar uso de adminApiBaseUrl
grep -r "adminApiBaseUrl" lib/
# ✅ Esperado: AdminService usa isso

# Procurar uso de endpoint()
grep -r "endpoint(" lib/
# ✅ Esperado: Diversos ficheiros usam isso
```

### 3. Verificar Padrão de Headers

```bash
# Verificar que requests usam headers com token
grep -r "Authorization.*Bearer" lib/
# ✅ Esperado: Múltiplos resultados

# Verificar que _headers() é usado
grep -r "_headers()" lib/
# ✅ Esperado: DatabaseHelper e AdminService
```

---

## 📚 Documentação

- [ ] `ENVIRONMENT_CONFIG.md` criado
  - [ ] Contém todos os exemplos de uso
  - [ ] Contém troubleshooting
  - [ ] Contém informações de HTTPS automático
  
- [ ] `API_INTEGRATION_EXAMPLES.md` criado
  - [ ] Contém exemplos de DatabaseHelper
  - [ ] Contém exemplos de AdminService
  - [ ] Contém exemplos de testes

- [ ] `BUILD_COMMANDS.md` criado
  - [ ] Contém quick reference
  - [ ] Contém scripts de build
  - [ ] Contém CI/CD examples

- [ ] `CHANGES_SUMMARY.md` criado
  - [ ] Comparação antes/depois
  - [ ] Status de ficheiros

- [ ] `HTTP_FLOW.md` criado
  - [ ] Diagrama de fluxo
  - [ ] Exemplos práticos

- [ ] `DOCUMENTATION_INDEX.md` criado
  - [ ] Índice de todos os docs
  - [ ] Quick start

---

## 🔐 Verificações de Segurança

### 1. JWT ainda funciona?
- [ ] Login gera token
- [ ] Token é armazenado em Session
- [ ] Token é enviado em Authorization header
- [ ] Requests sem token retornam 401

### 2. HTTPS em Produção?
- [ ] Porta 443 detecta HTTPS automaticamente
- [ ] Certificado é validado
- [ ] Sem aviso de segurança

### 3. Dados Sensíveis?
- [ ] API_HOST/PORT não são sensíveis (podem estar em logs)
- [ ] JWT_SECRET não está em código (está em .env)
- [ ] Ficheiros enviados são validados

---

## 📊 Testes de Performance

### 1. Tempo de Inicialização da App

```dart
// Adicionar ao main()
final stopwatch = Stopwatch()..start();
AppConfig.printConfig();
print('Config print took ${stopwatch.elapsedMilliseconds}ms');
```

- [ ] Tempo < 100ms

### 2. Tempo de Primeira Requisição

```dart
// Medir tempo de login
final stopwatch = Stopwatch()..start();
await DatabaseHelper().loginUser(email, password);
print('Login took ${stopwatch.elapsedMilliseconds}ms');
```

- [ ] Tempo < 2 segundos (dependendo de latência)

### 3. Múltiplas Requisições

```dart
// Fazer várias requisições seguidas
await Future.wait([
  DatabaseHelper().loginUser(email, password),
  DatabaseHelper().getProjects(userId),
  AdminService.instance.getAllUsers(),
]);
```

- [ ] Todas as requisições funcionam
- [ ] Sem timeouts
- [ ] Respostas corretas

---

## 🎯 Casos de Uso Reais

### 1. Novo Desenvolvedor

- [ ] Clonar repositório
- [ ] `flutter pub get`
- [ ] `flutter run` (sem flags)
- [ ] ✅ App conecta a localhost:3000 automaticamente

### 2. Android Emulator Test

- [ ] `flutter run --dart-define=API_HOST=10.0.2.2`
- [ ] ✅ App conecta ao backend local via emulator

### 3. CI/CD Pipeline

- [ ] `flutter build apk --dart-define=API_HOST=api.foeng.pt --dart-define=API_PORT=443`
- [ ] ✅ APK gerado com URL correta
- [ ] ✅ Sem necessidade de editar código

### 4. Produção

- [ ] APK publicado com hosts corretos
- [ ] ✅ HTTPS automático para porta 443
- [ ] ✅ Comunicação segura

---

## 🚀 Plano de Deploye

- [ ] Comunicar mudanças ao team
- [ ] Atualizar documentação interna
- [ ] Mergar para branch principal
- [ ] Tag versão (ex: v1.0.0-environment-config)
- [ ] Build de release
- [ ] Deploy para staging
- [ ] Testes em staging
- [ ] Deploy para produção

---

## 📝 Notas Importantes

### Para Toda a Equipe
- IP 192.168.1.246 já **não é usado**
- Use `--dart-define` para especificar host
- Localhost:3000 é o padrão para desenvolvimento
- HTTPS é automático para porta 443

### Para DevOps/CI-CD
- Builds devem incluir `--dart-define=API_HOST=...`
- Documentação de builds está em BUILD_COMMANDS.md
- Scripts de automação disponíveis em bash/PowerShell

### Para QA/Testers
- Usar emulator: `--dart-define=API_HOST=10.0.2.2`
- Usar dispositivo físico: `--dart-define=API_HOST=<IP_da_máquina>`
- Ver config ativa: `AppConfig.printConfig()`

---

## ✅ Conclusão

Refatoração **100% bem-sucedida** quando todos os itens estiverem marcados!

**Data**: 22 de Abril de 2026  
**Versão**: 1.0  
**Status**: ✅ Pronto para Produção
