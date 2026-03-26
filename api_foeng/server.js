const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ─── PASTA DE UPLOADS ─────────────────────────────────────
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

app.use('/uploads', express.static(uploadDir));

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const unique = `${Date.now()}_${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|webp/;
    cb(null, allowed.test(file.mimetype));
  },
});

const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: 'Admin@123+',
  database: 'foeng_db',
};

// ─── LOGIN ───────────────────────────────────────────────
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      'SELECT * FROM utilizadores WHERE email = ? AND password = ?',
      [email, password]
    );
    await connection.end();
    if (rows.length > 0) {
      res.json({ success: true, user: rows[0] });
    } else {
      res.status(401).json({ success: false, message: 'Credenciais inválidas' });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── UTILIZADORES — rotas específicas PRIMEIRO ───────────
app.get('/api/utilizadores/pesquisar/:texto', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const texto = `%${req.params.texto}%`;
    const [rows] = await connection.execute(
      'SELECT id, nome, email, perfil FROM utilizadores WHERE nome LIKE ? OR email LIKE ? LIMIT 5',
      [texto, texto]
    );
    await connection.end();
    res.json({ success: true, utilizadores: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/utilizadores/email/:email', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      'SELECT id, nome, email, perfil FROM utilizadores WHERE email = ?',
      [req.params.email]
    );
    await connection.end();
    if (rows.length > 0) {
      res.json({ success: true, utilizador: rows[0] });
    } else {
      res.status(404).json({ success: false, message: 'Utilizador não encontrado' });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── PROJETOS — rotas específicas PRIMEIRO ───────────────
app.get('/api/projetos/trabalhador/:userId', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      `SELECT p.* FROM projetos p
       INNER JOIN utilizador_projeto up ON p.id = up.projeto_id
       WHERE up.utilizador_id = ?
       ORDER BY p.criado_em DESC`,
      [req.params.userId]
    );
    await connection.end();
    res.json({ success: true, projetos: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/projetos/:id/contagem', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [nos] = await connection.execute(
      'SELECT COUNT(*) as total_nos FROM nos WHERE projeto_id = ?', [req.params.id]
    );
    const [registos] = await connection.execute(
      `SELECT COUNT(*) as total_registos FROM registos r
       JOIN nos n ON r.no_id = n.id WHERE n.projeto_id = ?`,
      [req.params.id]
    );
    await connection.end();
    res.json({ success: true, total_nos: nos[0].total_nos, total_registos: registos[0].total_registos });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/projetos/:id/copiar', async (req, res) => {
  const { nome, criado_por } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [result] = await connection.execute(
      'INSERT INTO projetos (nome, descricao, criado_por) SELECT ?, descricao, ? FROM projetos WHERE id = ?',
      [nome, criado_por, req.params.id]
    );
    const novoProjetoId = result.insertId;
    const [nosRaiz] = await connection.execute(
      'SELECT id FROM nos WHERE projeto_id = ? AND pai_id IS NULL', [req.params.id]
    );
    for (const no of nosRaiz) {
      await copiarNoRecursivo(connection, no.id, null, novoProjetoId, false);
    }
    await connection.end();
    res.json({ success: true, id: novoProjetoId });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── PROJETOS — rotas genéricas DEPOIS ───────────────────
app.get('/api/projetos/:userId', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      'SELECT * FROM projetos WHERE criado_por = ? ORDER BY criado_em DESC',
      [req.params.userId]
    );
    await connection.end();
    res.json({ success: true, projetos: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/projetos', async (req, res) => {
  const { nome, descricao, criado_por } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [result] = await connection.execute(
      'INSERT INTO projetos (nome, descricao, criado_por) VALUES (?, ?, ?)',
      [nome, descricao, criado_por]
    );
    await connection.end();
    res.json({ success: true, id: result.insertId });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.put('/api/projetos/:id', async (req, res) => {
  const { nome, descricao } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.execute(
      'UPDATE projetos SET nome = ?, descricao = ? WHERE id = ?',
      [nome, descricao, req.params.id]
    );
    await connection.end();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/projetos/:id', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [nosCount] = await connection.execute(
      'SELECT COUNT(*) as total FROM nos WHERE projeto_id = ?', [req.params.id]
    );
    await connection.execute('DELETE FROM projetos WHERE id = ?', [req.params.id]);
    await connection.end();
    res.json({ success: true, nosApagados: nosCount[0].total });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── NÓS — rotas específicas PRIMEIRO ────────────────────
app.get('/api/nos/:projetoId/todos', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      'SELECT * FROM nos WHERE projeto_id = ? ORDER BY nome ASC',
      [req.params.projetoId]
    );
    await connection.end();
    res.json({ success: true, nos: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/nos/:id/copiar', async (req, res) => {
  const { novo_pai_id, novo_projeto_id, incluir_registos } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [nos] = await connection.execute('SELECT projeto_id FROM nos WHERE id = ?', [req.params.id]);
    const projetoId = novo_projeto_id || nos[0].projeto_id;
    await copiarNoRecursivo(connection, req.params.id, novo_pai_id || null, projetoId, incluir_registos);
    await connection.end();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.put('/api/nos/:id/mover', async (req, res) => {
  const { pai_id } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.execute(
      'UPDATE nos SET pai_id = ? WHERE id = ?',
      [pai_id || null, req.params.id]
    );
    await connection.end();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── NÓS — rotas genéricas DEPOIS ────────────────────────
app.get('/api/nos/:projetoId', async (req, res) => {
  const { projetoId } = req.params;
  const { pai_id } = req.query;
  try {
    const connection = await mysql.createConnection(dbConfig);
    let rows;
    if (pai_id === undefined || pai_id === 'null' || pai_id === '') {
      [rows] = await connection.execute(
        'SELECT * FROM nos WHERE projeto_id = ? AND pai_id IS NULL ORDER BY nome ASC',
        [projetoId]
      );
    } else {
      [rows] = await connection.execute(
        'SELECT * FROM nos WHERE projeto_id = ? AND pai_id = ? ORDER BY nome ASC',
        [projetoId, pai_id]
      );
    }
    await connection.end();
    res.json({ success: true, nos: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/nos', async (req, res) => {
  const { projeto_id, pai_id, nome } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [result] = await connection.execute(
      'INSERT INTO nos (projeto_id, pai_id, nome) VALUES (?, ?, ?)',
      [projeto_id, pai_id || null, nome]
    );
    await connection.end();
    res.json({ success: true, id: result.insertId });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.put('/api/nos/:id', async (req, res) => {
  const { nome } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.execute('UPDATE nos SET nome = ? WHERE id = ?', [nome, req.params.id]);
    await connection.end();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/nos/:id', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.execute('DELETE FROM nos WHERE id = ?', [req.params.id]);
    await connection.end();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── CAMPOS DINÂMICOS ─────────────────────────────────────
app.get('/api/campos/:noId', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      'SELECT * FROM campos_dinamicos WHERE no_id = ? ORDER BY ordem ASC',
      [req.params.noId]
    );
    await connection.end();
    res.json({ success: true, campos: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/campos', async (req, res) => {
  const { no_id, nome_campo, tipo_campo, opcoes, obrigatorio, ordem } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [result] = await connection.execute(
      'INSERT INTO campos_dinamicos (no_id, nome_campo, tipo_campo, opcoes, obrigatorio, ordem) VALUES (?, ?, ?, ?, ?, ?)',
      [no_id, nome_campo, tipo_campo, opcoes || null, obrigatorio ? 1 : 0, ordem]
    );
    await connection.end();
    res.json({ success: true, id: result.insertId });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── REGISTOS ─────────────────────────────────────────────
app.get('/api/registos/:noId', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      `SELECT r.*, u.nome as nome_utilizador 
       FROM registos r 
       JOIN utilizadores u ON r.utilizador_id = u.id
       WHERE r.no_id = ? 
       ORDER BY r.criado_em DESC`,
      [req.params.noId]
    );
    await connection.end();
    res.json({ success: true, registos: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/registos', upload.any(), async (req, res) => {
  try {
    const { no_id, utilizador_id, dados_json } = req.body;
    const dados = JSON.parse(dados_json);

    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const url = `/uploads/${file.filename}`;
        dados[file.fieldname] = url;
      }
    }

    const connection = await mysql.createConnection(dbConfig);
    const [result] = await connection.execute(
      'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
      [no_id, utilizador_id || 1, JSON.stringify(dados)]
    );
    await connection.end();

    res.json({ success: true, id: result.insertId });
  } catch (error) {
    console.error('Erro ao guardar registo:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── UTILIZADOR_PROJETO ───────────────────────────────────
app.get('/api/utilizador_projeto/:projetoId', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(
      `SELECT u.id, u.nome, u.email, u.perfil 
       FROM utilizadores u
       INNER JOIN utilizador_projeto up ON u.id = up.utilizador_id
       WHERE up.projeto_id = ?`,
      [req.params.projetoId]
    );
    await connection.end();
    res.json({ success: true, membros: rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/utilizador_projeto', async (req, res) => {
  const { utilizador_id, projeto_id } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.execute(
      'INSERT IGNORE INTO utilizador_projeto (utilizador_id, projeto_id) VALUES (?, ?)',
      [utilizador_id, projeto_id]
    );
    await connection.end();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/utilizador_projeto/:projetoId/:utilizadorId', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.execute(
      'DELETE FROM utilizador_projeto WHERE projeto_id = ? AND utilizador_id = ?',
      [req.params.projetoId, req.params.utilizadorId]
    );
    await connection.end();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── COPIAR NÓ (recursivo) ────────────────────────────────
async function copiarNoRecursivo(connection, noId, novoPaiId, novoProjetoId, incluirRegistos) {
  const [nos] = await connection.execute('SELECT * FROM nos WHERE id = ?', [noId]);
  if (nos.length === 0) return;
  const no = nos[0];

  const [result] = await connection.execute(
    'INSERT INTO nos (projeto_id, pai_id, nome) VALUES (?, ?, ?)',
    [novoProjetoId, novoPaiId, no.nome]
  );
  const novoNoId = result.insertId;

  const [campos] = await connection.execute(
    'SELECT * FROM campos_dinamicos WHERE no_id = ?', [noId]
  );
  for (const campo of campos) {
    await connection.execute(
      'INSERT INTO campos_dinamicos (no_id, nome_campo, tipo_campo, opcoes, obrigatorio, ordem) VALUES (?, ?, ?, ?, ?, ?)',
      [novoNoId, campo.nome_campo, campo.tipo_campo, campo.opcoes, campo.obrigatorio, campo.ordem]
    );
  }

  if (incluirRegistos) {
    const [registos] = await connection.execute(
      'SELECT * FROM registos WHERE no_id = ?', [noId]
    );
    for (const registo of registos) {
      await connection.execute(
        'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
        [novoNoId, registo.utilizador_id, registo.dados]
      );
    }
  }

  const [filhos] = await connection.execute(
    'SELECT id FROM nos WHERE pai_id = ?', [noId]
  );
  for (const filho of filhos) {
    await copiarNoRecursivo(connection, filho.id, novoNoId, novoProjetoId, incluirRegistos);
  }
}

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 API a correr em http://localhost:${PORT}`);
});