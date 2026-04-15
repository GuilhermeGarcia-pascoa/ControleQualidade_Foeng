# Controlo de Qualidade FOENG

Aplicação móvel (Android/iOS) desenvolvida em **Flutter** para gestão de controlo de qualidade da FOENG. Permite criar projetos, organizar nós hierárquicos, definir campos dinâmicos de formulário e registar dados de qualidade — tudo com controlo de acessos por perfil de utilizador.

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Frontend | Flutter (Dart) |
| Backend / API | Node.js + Express |
| Base de dados | MySQL (`foeng_db`) |
| Comunicação | REST HTTP/JSON |

---

## Funcionalidades

- **Autenticação** com sessão persistente via `shared_preferences`
- **Dois perfis de acesso**: `admin` e `trabalhador`
- **Gestão de projetos**: criação e listagem (admins veem todos; trabalhadores apenas os seus)
- **Nós hierárquicos**: estrutura em árvore dentro de cada projeto (pai/filho)
- **Campos dinâmicos**: cada nó pode ter campos de formulário configuráveis (texto, número, data, seleção, etc.) com suporte a campos obrigatórios e ordenação
- **Registos de qualidade**: preenchimento de formulários por nó
- **Gestão de membros**: associação/remoção de trabalhadores a projetos

---

## Estrutura do Projeto

```
ControleQualidade_Foeng/
├── lib/
│   ├── main.dart                        # Ponto de entrada da app
│   ├── models/
│   │   └── models.dart                  # Modelos: Utilizador, Projeto, No, CampoDinamico
│   ├── screens/
│   │   ├── login_screen.dart            # Ecrã de login
│   │   ├── dashboard_screen.dart        # Lista de projetos
│   │   ├── nos_screen.dart              # Árvore de nós do projeto
│   │   ├── preencher_tabela_screen.dart # Preenchimento de formulário
│   │   └── gerir_membros_screen.dart    # Gestão de membros do projeto
│   ├── widgets/
│   │   └── campo_widget.dart            # Widget reutilizável para campos dinâmicos
│   ├── database/
│   │   └── database_helper.dart         # Cliente HTTP para a API REST
│   └── utils/
│       └── session.dart                 # Gestão de sessão com SharedPreferences
├── api_foeng/
│   └── server.js                        # API REST em Express + MySQL
├── android/                             # Configuração Android
├── ios/                                 # Configuração iOS
└── pubspec.yaml
```

---

## API REST

O servidor corre na porta `3000`. Todos os endpoints têm o prefixo `/api`.

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/api/login` | Autenticação de utilizador |
| `GET` | `/api/projetos/:userId` | Listar projetos de um admin |
| `POST` | `/api/projetos` | Criar novo projeto |
| `GET` | `/api/projetos/trabalhador/:userId` | Listar projetos de um trabalhador |
| `GET` | `/api/nos/:projetoId` | Listar nós (com filtro por `pai_id`) |
| `POST` | `/api/nos` | Criar nó |
| `DELETE` | `/api/nos/:id` | Apagar nó |
| `GET` | `/api/campos/:noId` | Listar campos dinâmicos de um nó |
| `POST` | `/api/campos` | Criar campo dinâmico |
| `GET` | `/api/registos/:noId` | Listar registos de um nó |
| `POST` | `/api/registos` | Guardar registo |
| `GET` | `/api/utilizadores/email/:email` | Procurar utilizador por email |
| `GET` | `/api/utilizador_projeto/:projetoId` | Listar membros de um projeto |
| `POST` | `/api/utilizador_projeto` | Adicionar membro a projeto |
| `DELETE` | `/api/utilizador_projeto/:projetoId/:utilizadorId` | Remover membro de projeto |

---

## Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.0.0`
- [Node.js](https://nodejs.org/) `>=18`
- MySQL com uma base de dados `foeng_db`

---

## Instalação e Execução

### 1. Base de dados

Cria a base de dados MySQL e as tabelas necessárias (`utilizadores`, `projetos`, `nos`, `campos_dinamicos`, `registos`, `utilizador_projeto`).

### 2. API (Backend)

```bash
cd api_foeng
npm install
```

Edita o ficheiro `server.js` e substitui a password da base de dados:

```js
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: 'A_TUA_PASSWORD',   // <-- alterar aqui
  database: 'foeng_db'
};
```

Inicia o servidor:

```bash
node server.js
# Servidor a correr em http://localhost:3000
```

### 3. App Flutter

```bash
flutter pub get
flutter run
```

> **Nota:** Em emulador Android, o endereço da API é automaticamente redirecionado para `http://10.0.2.2:3000/api`. Em iOS/Web usa `http://localhost:3000/api`.

---

## Credenciais de Teste

| Campo | Valor |
|---|---|
| Email | `admin@foeng.pt` |
| Password | `admin` |

---

## Dependências Flutter

| Pacote | Versão | Uso |
|---|---|---|
| `sqflite` | ^2.3.0 | (reservado para uso local futuro) |
| `http` | ^1.6.0 | Chamadas à API REST |
| `shared_preferences` | ^2.2.2 | Persistência de sessão |
| `image_picker` | ^1.0.7 | Captura de imagens nos registos |
| `intl` | ^0.19.0 | Formatação de datas |
| `path_provider` | ^2.1.2 | Acesso ao sistema de ficheiros |
| `crypto` | ^3.0.3 | Hash de passwords |
| `path` | ^1.8.3 | Manipulação de caminhos |
