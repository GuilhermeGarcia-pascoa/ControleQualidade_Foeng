# 📚 Documentação Completa - Índice

Esta pasta contém toda a documentação sobre o projeto **Controlo de Qualidade**.

## 📋 Ficheiros de Documentação

### 1. **[ENVIRONMENT_CONFIG.md](ENVIRONMENT_CONFIG.md)** 📖
Guia completo sobre configuração de ambiente.
- ✅ Como usar variáveis de ambiente
- ✅ Exemplos para cada cenário (dev, staging, prod)
- ✅ Detecção automática de HTTPS
- ✅ Troubleshooting comum

**Leia quando**: Precisa entender como configurar a API para diferentes ambientes.

---

### 2. **[API_INTEGRATION_EXAMPLES.md](API_INTEGRATION_EXAMPLES.md)** 💻
Exemplos práticos de código.
- ✅ Como DatabaseHelper usa AppConfig
- ✅ Como AdminService usa AppConfig
- ✅ Testes com AppConfig
- ✅ Endpoints customizados

**Leia quando**: Precisa integrar AppConfig no seu código.

---

### 3. **[BUILD_COMMANDS.md](BUILD_COMMANDS.md)** 🔨
Referência rápida de comandos de build.
- ✅ Quick reference de todos os comandos
- ✅ Scripts de automação (bash/PowerShell)
- ✅ Integração CI/CD (GitHub/GitLab)
- ✅ Debugging e troubleshooting

**Leia quando**: Precisa de um comando específico ou quer automatizar builds.

---

### 4. **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** 📊
Resumo visual das mudanças antes/depois.
- ✅ Comparação visual
- ✅ Ficheiros afetados
- ✅ Testes realizados
- ✅ Casos de uso

**Leia quando**: Quer entender o que mudou e por quê.

---

### 5. **[README.md](README.md)** 📄
Informações gerais do projeto.
- ✅ Descrição geral
- ✅ Setup e instalação
- ✅ Como correr o app
- ✅ Estrutura do projeto

**Leia quando**: Está começando no projeto.

---

## 🎯 Quick Start

### 1. Desenvolvimento Local
```bash
# No terminal do backend
cd ControleQualidade_API
npm start
# API roda em: http://localhost:3000

# No outro terminal, do app
cd controle_qualidadev2
flutter run
# App automaticamente conecta a: http://localhost:3000/api ✓
```

### 2. Android Emulator
```bash
flutter run --dart-define=API_HOST=10.0.2.2
# App conecta a: http://10.0.2.2:3000/api ✓
```

### 3. Rede Local
```bash
flutter run --dart-define=API_HOST=192.168.1.10
# App conecta a: http://192.168.1.10:3000/api ✓
```

### 4. Produção
```bash
flutter build apk \
  --dart-define=API_HOST=api.foeng.pt \
  --dart-define=API_PORT=443 \
  --release
# App conecta a: https://api.foeng.pt/api ✓
```

---

## 🏗️ Estrutura do Projeto

```
controle_qualidadev2/
├── lib/
│   ├── main.dart                    # App principal
│   ├── config/
│   │   └── app_config.dart         # ✅ REFATORADO - Configuração dinâmica
│   ├── database/
│   │   └── database_helper.dart    # ✅ Usa AppConfig.apiBaseUrl
│   ├── services/
│   │   └── admin_service.dart      # ✅ Usa AppConfig.adminApiBaseUrl
│   ├── screens/                     # Telas do app
│   └── widgets/                     # Componentes reutilizáveis
│
├── 📚 DOCUMENTAÇÃO (NOVO)
│   ├── ENVIRONMENT_CONFIG.md        # Guia de variáveis de ambiente
│   ├── API_INTEGRATION_EXAMPLES.md  # Exemplos de código
│   ├── BUILD_COMMANDS.md            # Referência de comandos
│   ├── CHANGES_SUMMARY.md           # Resumo de mudanças
│   └── DOCUMENTATION_INDEX.md       # Este ficheiro
│
├── pubspec.yaml                     # Dependências
├── analysis_options.yaml            # Lint rules
└── ...
```

---

## 🔑 Variáveis de Ambiente

| Variável | Tipo | Padrão | Exemplo |
|----------|------|--------|---------|
| `API_HOST` | String | `localhost` | `flutter run --dart-define=API_HOST=api.foeng.pt` |
| `API_PORT` | int | `3000` | `flutter run --dart-define=API_PORT=443` |
| `API_PATH` | String | `/api` | `flutter run --dart-define=API_PATH=/api/v2` |

---

## 🔐 Detecção HTTPS Automática

Quando a porta é **443** ou **8443**, o app automaticamente usa HTTPS.

```bash
# HTTP explícito
flutter run --dart-define=API_PORT=3000
# URL: http://localhost:3000/api

# HTTPS automático
flutter run --dart-define=API_PORT=443
# URL: https://localhost/api
```

---

## 📞 Dúvidas Frequentes

### P: O IP 192.168.1.246 ainda está em uso?
**R**: Não! Removido completamente. Use `--dart-define=API_HOST=192.168.1.246` se precisar.

### P: Como voltar ao IP antigo?
**R**: `flutter run --dart-define=API_HOST=192.168.1.246 --dart-define=API_PORT=6003`

### P: Qual é o novo padrão?
**R**: `localhost:3000` - perfeito para desenvolvimento local.

### P: Preciso mudar código para cada ambiente?
**R**: Não! Use `--dart-define` durante build.

### P: Como testar em Android Emulator?
**R**: `flutter run --dart-define=API_HOST=10.0.2.2`

### P: HTTPS funciona automaticamente?
**R**: Sim! Porta 443 = HTTPS automático.

---

## 🚀 Próximas Fases Planejadas

- [ ] **JWT Authentication** - ✅ Já implementado
  - Middleware de autenticação
  - Proteção de rotas
  - Token generation

- [ ] **Secure File Upload** - ✅ Já implementado
  - Multer 2.0.0
  - Validação 4-camadas
  - Limite de tamanho

- [ ] **Environment Configuration** - ✅ Implementado (esta fase)
  - Remover IPs hardcoded
  - Suporte a múltiplos ambientes
  - HTTPS automático

- [ ] **Testing** (Próximo)
  - Unit tests
  - Integration tests
  - E2E tests

- [ ] **Deployment** (Futuro)
  - Docker containers
  - CI/CD pipelines
  - Monitoring

---

## 📊 Status do Projeto

| Componente | Status | Documentação |
|-----------|--------|-------------|
| JWT Auth | ✅ Completo | Documentado |
| File Upload | ✅ Completo | Documentado |
| Environment Config | ✅ Completo | Documentado |
| API Integration | ✅ Funcionando | Exemplos fornecidos |
| Build System | ✅ Configurado | Comandos documentados |

---

## 📞 Suporte

Para problemas ou dúvidas:

1. **Verificar documentação**: Veja a documentação relevante acima
2. **Testar localmente**: `flutter run` + `AppConfig.printConfig()`
3. **Verificar logs**: Console do Flutter mostra detalhes da requisição
4. **Debugging**: Adicione breakpoints no DatabaseHelper

---

## 🎓 Para Iniciantes

Se é a primeira vez trabalhando neste projeto:

1. **Leia primeiro**: [README.md](README.md)
2. **Depois**: [ENVIRONMENT_CONFIG.md](ENVIRONMENT_CONFIG.md)
3. **Exemplos**: [API_INTEGRATION_EXAMPLES.md](API_INTEGRATION_EXAMPLES.md)
4. **Referência**: [BUILD_COMMANDS.md](BUILD_COMMANDS.md)

---

## 🔗 Ficheiros Principais

### Código
- [lib/config/app_config.dart](lib/config/app_config.dart) - Configuração (REFATORADO)
- [lib/database/database_helper.dart](lib/database/database_helper.dart) - BD
- [lib/services/admin_service.dart](lib/services/admin_service.dart) - Admin

### Configuração
- [pubspec.yaml](pubspec.yaml) - Dependências
- [analysis_options.yaml](analysis_options.yaml) - Lint rules

### Documentação
- [ENVIRONMENT_CONFIG.md](ENVIRONMENT_CONFIG.md) - Variáveis de ambiente
- [API_INTEGRATION_EXAMPLES.md](API_INTEGRATION_EXAMPLES.md) - Exemplos de código
- [BUILD_COMMANDS.md](BUILD_COMMANDS.md) - Comandos de build
- [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) - Resumo de mudanças

---

## ✅ Checklist de Setup

- [ ] `flutter pub get` - Instalar dependências
- [ ] `AppConfig.printConfig()` - Verificar config
- [ ] `flutter run` - Testar desenvolvimento
- [ ] Backend em http://localhost:3000
- [ ] App conecta automaticamente

---

**Última atualização**: 22 de Abril de 2026  
**Documentação versão**: 1.0  
**Status**: ✅ Completo e Testado
