# 🔐 Autenticação JWT - Implementação Completa

## 📋 Resumo Executivo

Implementação de autenticação segura com JWT (JSON Web Tokens) no backend Node.js do projeto Controle de Qualidade FOENG.

**Data**: 21 de Abril de 2026  
**Status**: ✅ Concluído  

---

## 🎯 Objetivos Alcançados

- ✅ Sistema de autenticação JWT funcional
- ✅ Proteção de rotas críticas
- ✅ Roles de autorização (admin/utilizador)
- ✅ Validação de tokens
- ✅ Boas práticas de segurança

---

## 📦 Dependências Instaladas

```bash
npm install jsonwebtoken
```

**Versão instalada**: 9.x (compatível)

---

## 🔑 Configuração

### 1. Variáveis de Ambiente (.env)

```env
# JWT Configuration
JWT_SECRET=foeng_jwt_secret_2026_super_seguro_mudar_em_producao
JWT_EXPIRES_IN=8h
```

⚠️ **IMPORTANTE**: Em produção, alterar o `JWT_SECRET` para um valor seguro e aleatório!

---

## 📁 Arquivos Criados/Modificados

### Novo Arquivo: `src/middleware/auth.js`

Middleware centralizado para autenticação e autorização com as funções:

#### 1. `requireAuth(req, res, next)`
- Valida token JWT obrigatoriamente
- Extrai dados do utilizador para `req.user`
- Retorna 401 se token ausente/inválido

**Uso**:
```javascript
router.get('/dados', requireAuth, (req, res) => {
  console.log(req.user.id, req.user.email);
});
```

#### 2. `optionalAuth(req, res, next)`
- Valida token se existir, mas não rejeita sem token
- Útil para endpoints públicos com dados adicionais se autenticado

#### 3. `requireAdmin(req, res, next)`
- **DEVE ser usado após `requireAuth`**
- Verifica se perfil do utilizador é 'admin'
- Retorna 403 (Forbidden) se não for admin

**Uso**:
```javascript
router.delete('/utilizadores/:id', requireAuth, requireAdmin, (req, res) => {
  // Apenas admins podem deletar utilizadores
});
```

#### 4. `generateToken(user)`
- Gera token JWT assinado
- Incluí: `id`, `email`, `perfil`
- Expiração configurável via `.env`

**Retorno**:
```javascript
{
  token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  expiresIn: "8h"
}
```

---

## 🔄 Fluxo de Autenticação

### 1. Login (POST /api/login)

**Request**:
```json
{
  "email": "user@example.com",
  "password": "senha123"
}
```

**Response (Sucesso)**:
```json
{
  "success": true,
  "user": {
    "id": 1,
    "nome": "João Silva",
    "email": "user@example.com",
    "perfil": "admin"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "8h"
}
```

**Response (Falha)**:
```json
{
  "success": false,
  "message": "Credenciais inválidas"
}
```

### 2. Usar Token em Requests Protegidas

**Header obrigatório**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Exemplo com curl**:
```bash
curl -X GET http://localhost:3000/api/utilizadores \
  -H "Authorization: Bearer TOKEN_AQUI"
```

**Exemplo com JavaScript/Flutter**:
```javascript
const token = localStorage.getItem('token');
const response = await fetch('/api/utilizadores', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

### 3. Erros Comuns

| Código | Erro | Solução |
|--------|------|--------|
| 401 | Token ausente | Incluir header `Authorization` |
| 401 | Token inválido | Fazer login novamente |
| 401 | Token expirado | Fazer login para obter novo token |
| 403 | Permissão negada | Usar conta admin para operações administrativas |

---

## 🛡️ Rotas Protegidas

### Utilizadores
- `GET /api/utilizadores` → **`requireAuth, requireAdmin`**
- `POST /api/utilizadores` → **`requireAuth, requireAdmin`**
- `PUT /api/utilizadores/:id` → **`requireAuth, requireAdmin`**
- `DELETE /api/utilizadores/:id` → **`requireAuth, requireAdmin`**
- `PUT /api/utilizadores/:id/senha` → **`requireAuth`**
- `PUT /api/utilizadores/:id/tema` → **`requireAuth`**
- `GET /api/utilizadores/:id/tema` → **`requireAuth`**
- `POST /api/utilizadores/registar` → **Pública** (sem autenticação)
- `GET /api/utilizadores/email/:email` → **Pública** (verificação de disponibilidade)

### Projetos
- `GET /api/projetos/:userId` → **`requireAuth`**
- `POST /api/projetos/` → **`requireAuth`**
- `PUT /api/projetos/:id` → **`requireAuth`**
- `DELETE /api/projetos/:id` → **`requireAuth`**
- `GET /api/projetos/trabalhador/:userId` → **`requireAuth`**
- `POST /api/projetos/:id/copiar` → **`requireAuth`**

### Nós
- `GET /api/nos/:projetoId` → **`requireAuth`**
- `GET /api/nos/:noId/ancestrais` → **`requireAuth`**
- `GET /api/nos/:noId/descendentes` → **`requireAuth`**
- `POST /api/nos/` → **`requireAuth`**
- `PUT /api/nos/:id` → **`requireAuth`**
- `DELETE /api/nos/:id` → **`requireAuth`**
- `POST /api/nos/:id/copiar` → **`requireAuth`**

### Registos
- `GET /api/registos/:noId` → **`requireAuth`**
- `POST /api/registos/` → **`requireAuth`**

---

## 🔐 Segurança - Boas Práticas Implementadas

✅ **Tokens JWT assinados** com secret seguro  
✅ **Expiração de tokens** (8 horas por padrão)  
✅ **Extração segura de dados** do token  
✅ **Validação em tempo real** de tokens  
✅ **Diferenciação de roles** (admin vs utilizador)  
✅ **Senhas hashadas** com bcryptjs  
✅ **Mensagens de erro genéricas** (sem revelar detalhes)  

---

## 🚀 Próximos Passos Recomendados

### 1. Frontend (Flutter/Web)
```dart
// Exemplo de implementação no Flutter
final response = await http.post(
  Uri.parse('http://localhost:3000/api/login'),
  body: {'email': email, 'password': password},
);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  final token = data['token'];
  
  // Guardar token localmente
  await storage.write(key: 'jwt_token', value: token);
  
  // Usar em próximos requests
  final headers = {'Authorization': 'Bearer $token'};
}
```

### 2. Refresh Tokens (EXTRA)
Implementar sistema de refresh tokens para melhor segurança:
```javascript
router.post('/refresh', (req, res) => {
  // Validar refresh token
  // Gerar novo access token
  // Retornar novo token
});
```

### 3. Rate Limiting
Adicionar proteção contra brute force:
```bash
npm install express-rate-limit
```

### 4. Auditoria de Logins
Registar tentativas de login para fins de segurança.

---

## 📊 Estrutura do Token JWT

```
Header: {
  "alg": "HS256",
  "typ": "JWT"
}

Payload: {
  "id": 1,
  "email": "user@example.com",
  "perfil": "admin",
  "iat": 1713687600,
  "exp": 1713717600
}

Signature: HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

---

## 🧪 Testes Recomendados

### 1. Login Bem-Sucedido
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"senha123"}'
```

### 2. Acesso Protegido com Token
```bash
curl -X GET http://localhost:3000/api/utilizadores \
  -H "Authorization: Bearer TOKEN_AQUI"
```

### 3. Acesso Protegido SEM Token (deve falhar)
```bash
curl -X GET http://localhost:3000/api/utilizadores
# Deve retornar 401: Não autenticado
```

### 4. Token Expirado (deve falhar)
Aguardar expiração do token e tentar acesso novamente.

---

## 📝 Ficheiro de Configuração Atualizado

### `.env`
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=Admin@123+
DB_NAME=foeng_db
DB_PORT=3306

PORT=3000

# JWT Configuration
JWT_SECRET=foeng_jwt_secret_2026_super_seguro_mudar_em_producao
JWT_EXPIRES_IN=8h
NODE_ENV=development
```

---

## ⚠️ Avisos Importantes

1. **Alterar JWT_SECRET em Produção**
   - Usar gerador de secrets seguro
   - Minimo 32 caracteres aleatórios
   
2. **HTTPS em Produção**
   - Sempre usar HTTPS, nunca HTTP em produção
   - Protege token durante transmissão

3. **Armazenamento Seguro do Token (Frontend)**
   - Não guardar em localStorage (vulnerável a XSS)
   - Usar httpOnly cookies ou secure storage
   
4. **Expiração de Sessão**
   - Implementar timeout de sessão
   - Avisar utilizador antes de expiração

---

## 📞 Suporte e Dúvidas

Para questões sobre a implementação JWT:
1. Verificar logs do servidor
2. Validar format do token (header Authorization)
3. Confirmar que JWT_SECRET está configurado
4. Verificar expiração do token

---

**Implementação Concluída com Sucesso** ✅  
**Data**: 21 de Abril de 2026  
**Versão**: 1.0
