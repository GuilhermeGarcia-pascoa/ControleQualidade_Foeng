# Guia de Setup — Backend Node.js

## 1. Instalação Inicial

1. Abrir PowerShell na pasta `ControleQualidade_API`
2. Criar o ficheiro `.env` baseado em `.env.example`:

```bash
cp .env.example .env
```

3. Editar o ficheiro `.env` com as credenciais reais da tua base de dados:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=Admin@123+
DB_NAME=foeng_db
DB_PORT=3306
PORT=3000
```

4. Instalar dependências:

```bash
npm install
```

## 2. Iniciar o Servidor

**Produção:**
```bash
npm start
```

**Desenvolvimento (com hot-reload):**
```bash
npm run dev
```

O servidor iniciará em `http://localhost:3000`

## 3. Verificar se está funcional

Abrir o browser e aceder a:
```
http://localhost:3000/api/health
```

Deverá aparecer:
```json
{
  "success": true,
  "message": "API is running",
  "timestamp": "2024-04-13T..."
}
```

## 4. Endpoints Disponíveis

### Autenticação
- `POST /api/login` - Login de utilizador

### Utilizadores
- `GET /api/utilizadores/pesquisar/:texto` - Pesquisar utilizadores
- `GET /api/utilizadores/email/:email` - Procurar por email
- `GET /api/utilizadores/:id/tema` - Obter tema do utilizador
- `PUT /api/utilizadores/:id/tema` - Atualizar tema

### Projetos
- `POST /api/projetos` - Criar projeto
- `GET /api/projetos/trabalhador/:userId` - Projetos do trabalhador
- `GET /api/projetos/:id/contagem` - Contagem de nós e registos
- `GET /api/projetos/:userId` - Meus projetos
- `PUT /api/projetos/:id` - Atualizar projeto
- `DELETE /api/projetos/:id` - Eliminar projeto
- `POST /api/projetos/:id/copiar` - Copiar projeto

### Nós (Pastas)
- `GET /api/nos/:noId/ancestrais` - Obter ancestrais
- `GET /api/nos/:noId/descendentes` - Obter descendentes
- `GET /api/nos/info/:noId` - Informação do nó
- `POST /api/nos` - Criar nó
- `PUT /api/nos/:id` - Atualizar nó
- `PUT /api/nos/:id/mover` - Mover nó
- `DELETE /api/nos/:id` - Eliminar nó
- `POST /api/nos/:id/copiar` - Copiar nó
- `GET /api/nos/partilhados/:userId` - Nós partilhados
- `GET /api/nos/:projetoId/acesso/:userId` - Nós com acesso

### Campos Dinâmicos
- `GET /api/campos/:noId` - Obter campos
- `POST /api/campos` - Criar campo
- `PUT /api/campos/:id` - Atualizar campo
- `PUT /api/campos/:id/ordem` - Atualizar ordem
- `DELETE /api/campos/:id` - Eliminar campo

### Registos
- `GET /api/registos/:noId` - Obter registos
- `POST /api/registos` - Criar registo (com upload)

### Utilizador-Projeto
- `POST /api/utilizador_projeto` - Adicionar ao projeto
- `GET /api/utilizador_projeto/:projetoId` - Membros do projeto
- `DELETE /api/utilizador_projeto/:projetoId/:utilizadorId` - Remover do projeto

### Utilizador-Nó
- `POST /api/utilizador_no` - Dar acesso a nó
- `GET /api/utilizador_no/:noId` - Membros do nó
- `GET /api/utilizador_no/:noId/acesso/:userId` - Verificar acesso
- `DELETE /api/utilizador_no/:noId/:utilizadorId` - Remover acesso

### Base de Dados
- `GET /api/database/audit/campos-por-no` - Auditoria de campos
- `GET /api/database/cleanup/orphaned-campos` - Verificar órfãos
- `POST /api/database/cleanup/orphaned-campos` - Limpar órfãos

## 5. Estrutura de Pastas

```
ControleQualidade_API/
├── src/
│   ├── index.js              ← Entrada principal
│   ├── db/
│   │   └── pool.js           ← Conexão à BD
│   ├── routes/
│   │   ├── auth.js
│   │   ├── utilizadores.js
│   │   ├── projetos.js
│   │   ├── nos.js
│   │   ├── campos.js
│   │   ├── registos.js
│   │   ├── utilizador_projeto.js
│   │   ├── utilizador_no.js
│   │   └── database.js
│   ├── middleware/
│   │   └── (reservado para autenticação futura)
│   └── utils/
│       ├── logger.js         ← Sistema de logs
│       └── errorHandler.js   ← Tratamento de erros
├── uploads/                  ← Ficheiros uploads
├── package.json
├── .env                      ← Variáveis de ambiente (NÃO submeter ao Git)
├── .env.example              ← Template do .env
└── .gitignore
```

## 6. Troubleshooting

### Erro: "Cannot find module 'mysql2'"
```bash
npm install
```

### Erro: "ECONNREFUSED 127.0.0.1:3306"
- Verificar se MySQL está rodando
- Verificar credenciais em `.env`

### Erro: "Unknown database 'foeng_db'"
- A base de dados não existe
- Criar a BD no MySQL (ou restaurar de um dump)

### Porta 3000 já está em uso
Alterar `PORT` no `.env` ou matar o processo:
```bash
netstat -ano | findstr :3000  # Listar
taskkill /PID <PID> /F        # Matar
```
