# 🔐 Validação de Inputs com Express-Validator

## Resumo da Implementação

✅ Middleware reutilizável criado em `src/middleware/validate.js`
✅ Validações adicionadas a todos os endpoints críticos
✅ Formato consistente de erros HTTP 400

---

## 📋 Ficheiros Modificados

| Ficheiro | Validações Adicionadas |
|----------|----------------------|
| `src/routes/auth.js` | POST / (login) |
| `src/routes/projetos.js` | POST, PUT, GET |
| `src/routes/nos.js` | POST, PUT, DELETE, GET |
| `src/routes/registos.js` | POST, GET |
| `src/routes/utilizadores.js` | POST, PUT, GET, /registar |
| `src/routes/campos.js` | POST, PUT, DELETE, GET |
| `src/middleware/validate.js` | **NOVO** - Middleware reutilizável |

---

## 🧪 Exemplos de Testes com CURL

### 1️⃣ **LOGIN (Auth)**

#### ❌ Erro - Email inválido
```bash
curl -X POST http://localhost:3000/api/auth \
  -H "Content-Type: application/json" \
  -d '{"email":"invalido","password":"pass1234"}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "email",
      "mensagem": "email inválido",
      "valor": "invalido"
    }
  ]
}
```

#### ❌ Erro - Password muito curta
```bash
curl -X POST http://localhost:3000/api/auth \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"123"}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "password",
      "mensagem": "password demasiado curta",
      "valor": "123"
    }
  ]
}
```

#### ✅ Sucesso
```bash
curl -X POST http://localhost:3000/api/auth \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'
```

---

### 2️⃣ **CRIAR PROJETO**

#### ❌ Erro - Nome vazio
```bash
curl -X POST http://localhost:3000/api/projetos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"nome":"","descricao":"Projeto de teste","criado_por":1}'
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
    }
  ]
}
```

#### ❌ Erro - Descrição muito longa
```bash
curl -X POST http://localhost:3000/api/projetos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"nome":"Projeto","descricao":"'$(printf 'A%.0s' {1..1001})'","criado_por":1}'
```

#### ✅ Sucesso
```bash
curl -X POST http://localhost:3000/api/projetos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"nome":"Novo Projeto","descricao":"Descrição do projeto","criado_por":1}'
```

**Resposta:**
```json
{
  "success": true,
  "id": 15
}
```

---

### 3️⃣ **CRIAR NÓ**

#### ❌ Erro - Projeto ID inválido
```bash
curl -X POST http://localhost:3000/api/nos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"projeto_id":"abc","nome":"Pasta Teste","pai_id":null}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "projeto_id",
      "mensagem": "projeto_id deve ser um inteiro positivo",
      "valor": "abc"
    }
  ]
}
```

#### ❌ Erro - Nome demasiado longo
```bash
curl -X POST http://localhost:3000/api/nos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"projeto_id":1,"nome":"'$(printf 'A%.0s' {1..256})'","pai_id":null}'
```

#### ✅ Sucesso
```bash
curl -X POST http://localhost:3000/api/nos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"projeto_id":1,"nome":"Pasta Principal","pai_id":null}'
```

---

### 4️⃣ **CRIAR REGISTO**

#### ❌ Erro - no_id inválido
```bash
curl -X POST http://localhost:3000/api/registos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"no_id":"invalido","dados_json":"{\"campo\":\"valor\"}"}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "no_id",
      "mensagem": "no_id deve ser um inteiro positivo",
      "valor": "invalido"
    }
  ]
}
```

#### ❌ Erro - JSON inválido
```bash
curl -X POST http://localhost:3000/api/registos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"no_id":5,"dados_json":"{campo:valor}"}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "dados_json",
      "mensagem": "JSON inválido em dados_json",
      "valor": "{campo:valor}"
    }
  ]
}
```

#### ✅ Sucesso
```bash
curl -X POST http://localhost:3000/api/registos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"no_id":5,"utilizador_id":1,"dados_json":"{\"nome\":\"Teste\",\"status\":\"Ativo\"}"}'
```

---

### 5️⃣ **CRIAR UTILIZADOR**

#### ❌ Erro - Email inválido
```bash
curl -X POST http://localhost:3000/api/utilizadores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"nome":"João Silva","email":"email_invalido","password":"pass1234","perfil":"trabalhador"}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "email",
      "mensagem": "email inválido",
      "valor": "email_invalido"
    }
  ]
}
```

#### ❌ Erro - Password muito curta
```bash
curl -X POST http://localhost:3000/api/utilizadores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"nome":"João Silva","email":"joao@example.com","password":"123","perfil":"trabalhador"}'
```

#### ❌ Erro - Perfil inválido
```bash
curl -X POST http://localhost:3000/api/utilizadores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"nome":"João Silva","email":"joao@example.com","password":"pass1234","perfil":"superuser"}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "perfil",
      "mensagem": "perfil inválido",
      "valor": "superuser"
    }
  ]
}
```

#### ✅ Sucesso
```bash
curl -X POST http://localhost:3000/api/utilizadores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{"nome":"João Silva","email":"joao@example.com","password":"pass1234","perfil":"trabalhador"}'
```

---

### 6️⃣ **CRIAR CAMPO DINÂMICO**

#### ❌ Erro - Tipo de campo inválido
```bash
curl -X POST http://localhost:3000/api/campos \
  -H "Content-Type: application/json" \
  -d '{"no_id":5,"nome_campo":"Status","tipo_campo":"custom","opcoes":null,"obrigatorio":true,"ordem":1}'
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "tipo_campo",
      "mensagem": "tipo_campo inválido",
      "valor": "custom"
    }
  ]
}
```

#### ✅ Sucesso - Tipos válidos
```bash
# select
curl -X POST http://localhost:3000/api/campos \
  -H "Content-Type: application/json" \
  -d '{"no_id":5,"nome_campo":"Status","tipo_campo":"select","opcoes":"Ativo,Inativo,Pendente","obrigatorio":true,"ordem":1}'

# email
curl -X POST http://localhost:3000/api/campos \
  -H "Content-Type: application/json" \
  -d '{"no_id":5,"nome_campo":"Email de Contacto","tipo_campo":"email","opcoes":null,"obrigatorio":false,"ordem":2}'

# date
curl -X POST http://localhost:3000/api/campos \
  -H "Content-Type: application/json" \
  -d '{"no_id":5,"nome_campo":"Data de Criação","tipo_campo":"date","opcoes":null,"obrigatorio":true,"ordem":3}'
```

---

### 7️⃣ **OBTER REGISTOS COM PAGINAÇÃO**

#### ❌ Erro - Limit fora do intervalo
```bash
curl -X GET "http://localhost:3000/api/registos/5?limit=200&page=1" \
  -H "Authorization: Bearer TOKEN_JWT"
```

**Resposta:**
```json
{
  "success": false,
  "errors": [
    {
      "campo": "limit",
      "mensagem": "limit deve ser entre 1 e 100",
      "valor": "200"
    }
  ]
}
```

#### ✅ Sucesso - Paginação válida
```bash
curl -X GET "http://localhost:3000/api/registos/5?limit=50&page=2&search=teste" \
  -H "Authorization: Bearer TOKEN_JWT"
```

---

## 📊 Tipos de Campos Dinâmicos Válidos

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `text` | Campo de texto simples | Nome, Descrição |
| `email` | Campo de email | Email de contacto |
| `number` | Campo numérico | Quantidade, Preço |
| `date` | Campo de data | Data de criação |
| `checkbox` | Booleano | Ativo/Inativo |
| `select` | Lista de opções | Status (Ativo\|Inativo\|Pendente) |
| `textarea` | Texto longo | Notas, Comentários |
| `file` | Upload de ficheiro | Documentação |

---

## 🔍 Exemplo de Resposta de Validação Completa

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
      "valor": "not-an-email"
    },
    {
      "campo": "password",
      "mensagem": "password demasiado curta (mín. 4 caracteres)",
      "valor": "12"
    }
  ]
}
```

---

## 🎯 Padrão de Resposta Consistente

Todos os erros de validação retornam:

```
HTTP 400 Bad Request
Content-Type: application/json

{
  "success": false,
  "errors": [
    {
      "campo": "nome_do_campo",
      "mensagem": "descrição do erro",
      "valor": "valor_submetido"
    }
  ]
}
```

---

## ✨ Benefícios da Implementação

✅ **Validação estruturada** - Sem duplicação de código  
✅ **Mensagens claras** - Erros descritivos em português  
✅ **Segurança** - Rejeita dados inválidos antes de chegar à BD  
✅ **Consistência** - Mesmo formato em todos os endpoints  
✅ **Normalizações** - Email normalizado, strings trimadas  
✅ **Type-safe** - IDs sempre positivos, tipos corretos  

---

## 🔧 Como Testar em Postman

1. **Import Collection**
   - Crie uma nova collection em Postman
   - Nome: "Validação API"

2. **Adicione variáveis globais**
   - `base_url`: http://localhost:3000/api
   - `token`: (copie o JWT recebido no login)

3. **Crie requests de teste**
   ```
   POST {{base_url}}/auth
   Body: {"email":"admin@example.com","password":"password123"}
   
   POST {{base_url}}/projetos
   Headers: Authorization: Bearer {{token}}
   Body: {"nome":"Teste","descricao":"Projeto de teste"}
   ```

---

## 📝 Boas Práticas

- ✅ Use sempre `Content-Type: application/json`
- ✅ Inclua o token JWT em headers quando necessário
- ✅ Teste com dados inválidos para validar erros
- ✅ Verifique as restrições de comprimento
- ✅ Confirme que valores positivos são obrigatórios para IDs
- ✅ Valide enums (ex: perfil, tipo_campo)

---

## 🚀 Próximos Passos (Opcional)

- [ ] Adicionar rate limiting
- [ ] Implementar custom validators
- [ ] Adicionar SQL injection prevention
- [ ] Implementar CORS validation
- [ ] Adicionar logging de validações falhadas
