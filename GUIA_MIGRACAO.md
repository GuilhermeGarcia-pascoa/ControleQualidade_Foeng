# 🚀 Guia de Separação — Backend + Flutter

## Situação Atual
O teu projeto Flutter (`controle_qualidadev2`) tem um backend Node.js integrado dentro dele, o que não é boa prática. Cada parte deveria estar em repositórios separados.

---

## ✅ O QUE FOI CRIADO

### 1. **Backend Node.js** (repositório novo)
📁 `ControleQualidade_API/` 
- Estrutura profissional e escalável
- Separação de rotas, utilidades e middleware
- Logging automático
- Tratamento de erros centralizado
- Suporte para uploads de ficheiros

### 2. **Flutter mais limpo**
📱 `controle_qualidadev2/`
- Novo `database_helper.dart` que **apenas faz chamadas HTTP**
- Sem lógica de servidor integrada
- Preparado para usar a API externa

---

## 📋 PASSO 1 — Configurar o Backend

### 1.1 Abrir PowerShell na pasta `ControleQualidade_API`

### 1.2 Criar ficheiro `.env`

```bash
cp .env.example .env
```

### 1.3 Editar `.env` com as credenciais reais

Abrir `.env` e atualizar:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=Admin@123+
DB_NAME=foeng_db
DB_PORT=3306
PORT=3000
```

### 1.4 Instalar dependências

```bash
npm install
```

### 1.5 Testar se funciona

```bash
npm start
```

Abrir browser e aceder a:
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

✅ Se funcionar, deixa o servidor rodando. Vamos precisar dele depois.

---

## 🧹 PASSO 2 — Limpar o Repositório Flutter

No repositório `controle_qualidadev2/`, **APAGAR**:

```
❌ api_foeng/          ← Toda a pasta (serverless agora!)
❌ node_modules/       ← Não é precisado no Flutter
❌ package.json        ← Flutter usa pubspec.yaml
❌ package-lock.json   ← Não é precisado no Flutter
```

### Confirmar que estas pastas/ficheiros foram apagados:

```bash
cd c:\ProjetosFlutter\projetoControloQualidade\controle_qualidadev2
rm -r api_foeng/     # Linux/Mac
rmdir /s api_foeng   # Windows PowerShell (com confirmação)

rm -r node_modules/
rmdir /s node_modules

rm package.json
del package.json

rm package-lock.json
del package-lock.json
```

---

## 📱 PASSO 3 — Atualizar Flutter para usar o API Externo

### 3.1 Descobrir o IP do Servidor

No PC onde vai correr o Node.js, abrir **CMD** ou **PowerShell** e digitar:

```
ipconfig
```

Procurar o **"Endereço IPv4"** da rede (normalmente começa com `192.168.1.XX` ou `10.0.0.XX`)

Exemplo: `192.168.1.42`

### 3.2 Atualizar o `database_helper.dart`

1. Abrir o ficheiro novo que foi criado:
   ```
   c:\ProjetosFlutter\projetoControloQualidade\controle_qualidadev2\lib\database\database_helper_novo.dart
   ```

2. **COPIAR** todo o conteúdo do ficheiro novo

3. Abrir o ficheiro atual:
   ```
   c:\ProjetosFlutter\projetoControloQualidade\controle_qualidadev2\lib\database\database_helper.dart
   ```

4. **COLAR** por cima (substituir tudo)

5. **SALVAR**

### 3.3 Atualizar o IP do Servidor

No `database_helper.dart`, encontrar a linha:

```dart
static const String _baseUrl = 'http://192.168.1.XX:3000/api';
```

**MUDA O IP PARA O REAL DO TEU SERVIDOR.** Exemplo:

```dart
static const String _baseUrl = 'http://192.168.1.42:3000/api';
```

✅ **SALVA O FICHEIRO**

### 3.4 Remover o ficheiro antigo

Apagar:
```
c:\ProjetosFlutter\projetoControloQualidade\controle_qualidadev2\lib\database\database_helper_novo.dart
```

---

## 🔥 PASSO 4 — Firewall do Windows

O Windows pode bloquear ligações à porta 3000. Para abrir:

1. Ir a **Painel de Controlo → Firewall do Windows**
2. Clicar em **Regras de Entrada → Nova Regra**
3. Selecionar **Porta** → **Seguinte**
4. Selecionar **TCP** → Digitar porta **3000** → **Seguinte**
5. Selecionar **Permitir a ligação** → **Seguinte**
6. Aplicar para **Domínio**, **Privada** e **Pública** → **Seguinte**
7. Nome: "Node.js API 3000" → **Concluir**

---

## ✅ PASSO 5 — Testar Tudo

### No Telemóvel (na mesma Wi-Fi):

Abrir o browser e aceder a:
```
http://192.168.1.42:3000/api/health
```

Se aparecer JSON com `"success": true`, está tudo bem!

### No Flutter:

1. Abrir o VS Code no projeto Flutter
2. Executar: `flutter pub get` (para sync com pubspec.yaml)
3. Executar: `flutter run`

Tentar fazer **login**. Se funcionar, significa que a API está comunicando com o frontend! 🎉

---

## 📚 Estrutura Final

### Backend (repositório novo)

```
ControleQualidade_API/
├── src/
│   ├── index.js                    ← Servidor principal
│   ├── db/
│   │   └── pool.js                 ← Conexão MySQL
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
│   └── utils/
│       ├── logger.js
│       └── errorHandler.js
├── uploads/                        ← Ficheiros de upload
├── package.json
├── .env                           ← NÃO submeter ao Git!
├── .env.example                   ← Template
├── .gitignore
└── README.md
```

### Flutter (repositório limpo)

```
controle_qualidadev2/
├── lib/
│   ├── main.dart
│   ├── database/
│   │   └── database_helper.dart    ← SÓ faz HTTP calls
│   ├── models/
│   ├── screens/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── android/
├── ios/
├── assets/
├── pubspec.yaml                   ← SEM package.json
└── .gitignore
```

---

## 🐛 Troubleshooting

### Erro: "Cannot connect to API"

**Causa:** IP errado ou servidor não está a rodar

**Solução:**
1. Verificar se Node.js está a rodar: `npm start`
2. Verificar IP correto: `ipconfig`
3. Verificar firewall Windows

### Erro: "ECONNREFUSED"

**Causa:** Servidor não está a rodar ou porta bloqueada

**Solução:**
1. Iniciar servidor: `npm start` na pasta do backend
2. Verificar se está a correr em http://localhost:3000/api/health

### Erro: "Database connection failed"

**Causa:** Credenciais MySQL incorretas em `.env`

**Solução:**
1. Verificar que MySQL está a rodar
2. Verificar credenciais em `.env`
3. Verificar que a BD `foeng_db` existe

### Telemóvel não consegue aceder ao PC

**Causa:** IP privado do PC errado ou firewall

**Solução:**
1. No PC, abrir CMD: `ipconfig`
2. Copiar IPv4 corretamente (ex: `192.168.1.42`)
3. No Flutter, atualizar `_baseUrl`
4. Verificar firewall Windows permite porta 3000
5. Telemóvel deve estar na **mesma rede Wi-Fi**

---

## 📌 Próximos Passos

Quando tudo estiver funcionando:

1. ✅ Criar repositório GitHub para o backend: `ControleQualidade_API`
2. ✅ Fazer Git commit e push do backend
3. ✅ Fazer Git commit e push do Flutter (sem `api_foeng/`, sem `node_modules/`, etc)
4. ✅ Documentar no README do backend como fazer setup

---

## 📞 Endpoints da API

Todos os endpoints começam com: `http://192.168.1.42:3000/api`

### Autenticação
- `POST /login`

### Utilizadores
- `GET /utilizadores/pesquisar/:texto`
- `GET /utilizadores/email/:email`
- `GET /utilizadores/:id/tema`
- `PUT /utilizadores/:id/tema`

### Projetos
- `POST /projetos`
- `GET /projetos/:userId`
- `GET /projetos/trabalhador/:userId`
- `GET /projetos/:id/contagem`
- `PUT /projetos/:id`
- `DELETE /projetos/:id`
- `POST /projetos/:id/copiar`

### Nós
- `GET /nos/:projetoId`
- `GET /nos/:noId/ancestrais`
- `GET /nos/:noId/descendentes`
- `POST /nos`
- `PUT /nos/:id`
- `PUT /nos/:id/mover`
- `DELETE /nos/:id`
- `GET /nos/partilhados/:userId`

### Campos
- `GET /campos/:noId`
- `POST /campos`
- `PUT /campos/:id`
- `PUT /campos/:id/ordem`
- `DELETE /campos/:id`

### Registos
- `GET /registos/:noId`
- `POST /registos` (com upload)

### Controlo de Acesso
- `POST /utilizador_projeto` - Adicionar ao projeto
- `POST /utilizador_no` - Dar acesso a nó

### Database
- `GET /database/audit/campos-por-no`
- `GET /database/cleanup/orphaned-campos`
- `POST /database/cleanup/orphaned-campos`

---

## ✨ Benefícios dessa Separação

✅ **Escalabilidade**: API pode estar noutro servidor
✅ **Reusabilidade**: API pode ser usada por outras apps (web, etc)
✅ **Segurança**: Credenciais BB não ficam no frontend
✅ **Manutenção**: Mais fácil fazer updates no backend sem quebrar app
✅ **Performance**: Backend isolado, sem competir recursos com Flutter

---

**🎉 Pronto! A migração está completa!**
