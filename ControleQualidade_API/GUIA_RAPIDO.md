# 🚀 Guia Rápido - Validação com Express-Validator

## ⚡ Início Rápido (5 minutos)

### 1️⃣ Verificar Instalação

```bash
npm list express-validator
```

Deve mostrar: `express-validator@7.x.x` (ou superior)

---

### 2️⃣ Verificar Ficheiros

Confirme que existem:

```
✅ src/middleware/validate.js (novo)
✅ src/routes/auth.js (modificado)
✅ src/routes/projetos.js (modificado)
✅ src/routes/nos.js (modificado)
✅ src/routes/registos.js (modificado)
✅ src/routes/utilizadores.js (modificado)
✅ src/routes/campos.js (modificado)
```

---

### 3️⃣ Iniciar o API

```bash
npm start
# ou
node src/index.js
```

---

### 4️⃣ Testar Validação

#### Windows (PowerShell)
```powershell
.\test-validation.ps1 -Token "seu_jwt_token"
```

#### Linux/Mac (Bash)
```bash
chmod +x test-validation.sh
./test-validation.sh
```

#### cURL (Manual)
```bash
curl -X POST http://localhost:3000/api/auth \
  -H "Content-Type: application/json" \
  -d '{"email":"invalido","password":"123"}'
```

---

## 📋 Resposta de Erro Esperada

Todos os erros de validação retornam:

```json
{
  "success": false,
  "errors": [
    {
      "campo": "nome_do_campo",
      "mensagem": "descrição do erro em português",
      "valor": "valor_submetido"
    }
  ]
}
```

**HTTP Status**: `400 Bad Request`

---

## 📊 Validações por Endpoint

### 🔐 Auth

| Endpoint | Campos | Validação |
|----------|--------|-----------|
| `POST /api/auth` | email | isEmail() |
| | password | notEmpty(), min 4 |

### 📊 Projetos

| Endpoint | Campos | Validação |
|----------|--------|-----------|
| `POST /api/projetos` | nome | notEmpty(), max 255 |
| | descricao | optional, max 1000 |
| `PUT /api/projetos/:id` | nome | optional, max 255 |
| | descricao | optional, max 1000 |
| `GET /api/projetos/:id/...` | id | isInt() > 0 |

### 🗂️ Nós

| Endpoint | Campos | Validação |
|----------|--------|-----------|
| `POST /api/nos` | projeto_id | isInt() > 0 |
| | nome | notEmpty(), max 255 |
| | pai_id | optional, isInt() > 0 |
| `PUT /api/nos/:id` | nome | notEmpty(), max 255 |

### 📋 Registos

| Endpoint | Campos | Validação |
|----------|--------|-----------|
| `POST /api/registos` | no_id | isInt() > 0 |
| | dados_json | notEmpty(), JSON válido |
| `GET /api/registos/:noId` | limit | 1-100 |
| | page | isInt() > 0 |
| | search | max 500 |

### 👥 Utilizadores

| Endpoint | Campos | Validação |
|----------|--------|-----------|
| `POST /api/utilizadores` | nome | notEmpty(), max 255 |
| | email | isEmail() |
| | password | min 4 |
| | perfil | isIn(['admin','trabalhador','utilizador']) |
| `PUT /api/utilizadores/:id/senha` | password | min 4 |

### 🔧 Campos Dinâmicos

| Endpoint | Campos | Validação |
|----------|--------|-----------|
| `POST /api/campos` | no_id | isInt() > 0 |
| | nome_campo | notEmpty(), max 255 |
| | tipo_campo | isIn(['text','email','number','date','checkbox','select','textarea','file']) |
| | opcoes | optional, max 1000 |
| `PUT /api/campos/:id/ordem` | ordem | isInt() >= 0 |

---

## 🎯 Casos de Uso Comuns

### ✅ Sucesso
```bash
curl -X POST http://localhost:3000/api/auth \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "senhavalida123"
  }'
```

### ❌ Falha - Email Inválido
```bash
curl -X POST http://localhost:3000/api/auth \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nao_email_valido",
    "password": "senha123"
  }'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "email",
      "mensagem": "email inválido",
      "valor": "nao_email_valido"
    }
  ]
}
```

### ❌ Falha - Múltiplos Erros
```bash
curl -X POST http://localhost:3000/api/utilizadores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "nome": "",
    "email": "email_invalido",
    "password": "123",
    "perfil": "superuser"
  }'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "nome",
      "mensagem": "nome é obrigatório",
      "valor": ""
    },
    {
      "campo": "email",
      "mensagem": "email inválido",
      "valor": "email_invalido"
    },
    {
      "campo": "password",
      "mensagem": "password demasiado curta (mín. 4 caracteres)",
      "valor": "123"
    },
    {
      "campo": "perfil",
      "mensagem": "perfil inválido",
      "valor": "superuser"
    }
  ]
}
```

---

## 🔍 Debug

### Verificar se validação está ativa

1. Submeta dados claramente inválidos
2. Confirme que recebe HTTP 400
3. Verifique que response tem estrutura de erro

### Se não funcionar

1. **Confirme a instalação**
   ```bash
   npm list express-validator
   npm list
   ```

2. **Verifique o middleware**
   ```bash
   cat src/middleware/validate.js
   ```

3. **Teste um endpoint simples**
   ```bash
   curl -X POST http://localhost:3000/api/auth \
     -H "Content-Type: application/json" \
     -d '{"email":"x","password":"y"}'
   ```

4. **Veja os logs do API**
   - Deve aparecer em src/utils/logger.js

---

## 📚 Recursos

| Ficheiro | Descrição |
|----------|-----------|
| `IMPLEMENTACAO_VALIDACAO.md` | Detalhes técnicos completos |
| `VALIDACAO_EXEMPLOS.md` | 50+ exemplos de testes |
| `test-validation.ps1` | Script PowerShell (Windows) |
| `test-validation.sh` | Script Bash (Linux/Mac) |

---

## ✨ Funcionalidades Implementadas

✅ Validação de entrada estruturada  
✅ Middleware reutilizável  
✅ Mensagens de erro em português  
✅ Normalização de dados (emails trimados)  
✅ Type-safety (IDs > 0, tipos corretos)  
✅ JSON validation (dados_json)  
✅ Enums whitelist (perfil, tipo_campo)  
✅ Limites de comprimento (nome max 255)  
✅ Limites de paginação (max 100 registos)  
✅ HTTP 400 consistente  

---

## 🎓 Boas Práticas

1. ✅ Sempre valide IDs (devem ser > 0)
2. ✅ Sempre trimpe strings
3. ✅ Sempre normalizei emails
4. ✅ Use listas brancas para enums
5. ✅ Defina limites de comprimento
6. ✅ Retorne mensagens claras
7. ✅ Inclua campo e valor na resposta

---

## 🆘 Suporte

**Erro comum: "Express-validator not found"**
```bash
npm install express-validator
npm start
```

**Erro comum: "Middleware não está aplicado"**
- Confirme `const validate = require('../middleware/validate')`
- Confirme que está adicionado aos routes: `router.post('/', validarSchema, validate, handler)`

**Erro comum: "400 mas sem erros"**
- Confirme que middleware `validate` está sendo chamado
- Verifique logs: `logger.warn()` em `src/middleware/validate.js`

---

## 🚀 Próximos Passos

- [ ] Adicionar testes automatizados (Jest/Mocha)
- [ ] Implementar rate limiting
- [ ] Adicionar sanitização adicional
- [ ] Implementar CORS validation
- [ ] Adicionar logging de validações falhadas
- [ ] Criar dashboard de erros comuns

---

**Última atualização**: 2024  
**Status**: ✅ Completo e testado
