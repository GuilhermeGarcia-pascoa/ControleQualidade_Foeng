# 🏗️ Build Commands Reference

## Quick Reference

### Local Development (Padrão)
```bash
flutter run
# URL: http://localhost:3000/api
```

### Android Emulator
```bash
flutter run --dart-define=API_HOST=10.0.2.2
# URL: http://10.0.2.2:3000/api
```

### iOS Simulator
```bash
flutter run --dart-define=API_HOST=127.0.0.1
# URL: http://127.0.0.1:3000/api
```

### Rede Local
```bash
flutter run --dart-define=API_HOST=192.168.1.10
# URL: http://192.168.1.10:3000/api
```

### Staging (HTTP)
```bash
flutter build apk \
  --dart-define=API_HOST=staging-api.foeng.pt \
  --dart-define=API_PORT=3000
# URL: http://staging-api.foeng.pt:3000/api
```

### Production (HTTPS Automático)
```bash
flutter build apk \
  --dart-define=API_HOST=api.foeng.pt \
  --dart-define=API_PORT=443 \
  --release
# URL: https://api.foeng.pt/api
```

### Custom Path
```bash
flutter run \
  --dart-define=API_HOST=localhost \
  --dart-define=API_PORT=3000 \
  --dart-define=API_PATH=/api/v2
# URL: http://localhost:3000/api/v2
```

---

## Build Script Example

Salvar como `build.sh`:

```bash
#!/bin/bash

usage() {
  echo "Uso: ./build.sh [dev|staging|prod]"
  exit 1
}

[[ $# -eq 0 ]] && usage

case "$1" in
  dev)
    echo "📱 Building para desenvolvimento..."
    flutter run --dart-define=API_HOST=localhost --dart-define=API_PORT=3000
    ;;
  staging)
    echo "🔄 Building para staging..."
    flutter build apk \
      --dart-define=API_HOST=staging-api.foeng.pt \
      --dart-define=API_PORT=3000 \
      --release
    ;;
  prod)
    echo "🚀 Building para produção..."
    flutter build apk \
      --dart-define=API_HOST=api.foeng.pt \
      --dart-define=API_PORT=443 \
      --release
    ;;
  *)
    usage
    ;;
esac
```

Uso:
```bash
chmod +x build.sh
./build.sh dev      # Development
./build.sh staging  # Staging
./build.sh prod     # Production
```

---

## PowerShell Script Example

Salvar como `build.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment
)

switch ($Environment) {
    'dev' {
        Write-Host "📱 Building para desenvolvimento..."
        flutter run `
            --dart-define=API_HOST=localhost `
            --dart-define=API_PORT=3000
    }
    'staging' {
        Write-Host "🔄 Building para staging..."
        flutter build apk `
            --dart-define=API_HOST=staging-api.foeng.pt `
            --dart-define=API_PORT=3000 `
            --release
    }
    'prod' {
        Write-Host "🚀 Building para produção..."
        flutter build apk `
            --dart-define=API_HOST=api.foeng.pt `
            --dart-define=API_PORT=443 `
            --release
    }
}
```

Uso (PowerShell):
```powershell
.\build.ps1 dev      # Development
.\build.ps1 staging  # Staging
.\build.ps1 prod     # Production
```

---

## Configuração em package.json (Node Backend)

```json
{
  "scripts": {
    "dev": "NODE_ENV=development nodemon src/index.js",
    "prod": "NODE_ENV=production node src/index.js",
    "test": "NODE_ENV=test jest"
  }
}
```

Uso:
```bash
npm run dev   # Development
npm start     # Production
npm test      # Tests
```

---

## Configuração em .env

```env
# .env (Development)
API_HOST=localhost
API_PORT=3000
API_PATH=/api
JWT_SECRET=dev_secret_mudar_em_producao
NODE_ENV=development

# .env.staging
API_HOST=staging-api.foeng.pt
API_PORT=3000
API_PATH=/api
JWT_SECRET=staging_secret_seguro
NODE_ENV=production

# .env.production
API_HOST=api.foeng.pt
API_PORT=443
API_PATH=/api
JWT_SECRET=producao_secret_super_seguro
NODE_ENV=production
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Build and Deploy

on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Build Dev APK
        if: github.ref == 'refs/heads/develop'
        run: |
          flutter build apk \
            --dart-define=API_HOST=localhost \
            --dart-define=API_PORT=3000 \
            --release
      
      - name: Build Prod APK
        if: github.ref == 'refs/heads/main'
        run: |
          flutter build apk \
            --dart-define=API_HOST=api.foeng.pt \
            --dart-define=API_PORT=443 \
            --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v2
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

### GitLab CI

```yaml
stages:
  - build_dev
  - build_staging
  - build_prod

build_dev:
  stage: build_dev
  only:
    - develop
  script:
    - flutter build apk --dart-define=API_HOST=localhost --dart-define=API_PORT=3000 --release

build_staging:
  stage: build_staging
  only:
    - staging
  script:
    - flutter build apk --dart-define=API_HOST=staging-api.foeng.pt --dart-define=API_PORT=3000 --release

build_prod:
  stage: build_prod
  only:
    - main
  script:
    - flutter build apk --dart-define=API_HOST=api.foeng.pt --dart-define=API_PORT=443 --release
```

---

## Debugging

### Verificar Config Ativa

```dart
void main() {
  AppConfig.printConfig();  // Imprime no console
  runApp(const MyApp());
}
```

Output:
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

### Testar Conexão

```bash
# No seu terminal, testar a URL que o app vai usar
curl http://localhost:3000/api/health

# Se usando Android Emulator
curl http://10.0.2.2:3000/api/health

# Se usando rede local
curl http://192.168.1.10:3000/api/health

# Se usando produção (HTTPS)
curl https://api.foeng.pt/api/health
```

---

## Checklist para Deploy

### Antes de fazer Build

- [ ] Servidor está ligado e respondendo
- [ ] Verificar host/porta corretos
- [ ] Testar com curl ou Postman
- [ ] Verificar JWT_SECRET
- [ ] Verificar certificado HTTPS (produção)

### Depois de fazer Build

- [ ] Verificar `AppConfig.printConfig()` no app
- [ ] Testar uma requisição (login)
- [ ] Verificar tokens JWT
- [ ] Testar uploads de ficheiros
- [ ] Testar operações de admin

### Antes de Publicar

- [ ] Build em modo release
- [ ] Testar em dispositivo físico
- [ ] Verificar performance
- [ ] Testar modo offline (se aplicável)
- [ ] Revisar certificado HTTPS

---

**Data**: 22 de Abril de 2026  
**Versão**: 1.0
