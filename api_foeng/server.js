const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: 'A_TUA_PASSWORD',
    database: 'foeng_db'
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

// ─── PROJETOS ─────────────────────────────────────────────
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

// ─── NÓS (hierarquia) ─────────────────────────────────────

// Buscar filhos diretos de um nó (ou raiz do projeto se pai_id = null)
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

app.post('/api/registos', async (req, res) => {
    const { no_id, utilizador_id, dados } = req.body;
    try {
        const connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute(
            'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
            [no_id, utilizador_id, JSON.stringify(dados)]
        );
        await connection.end();
        res.json({ success: true, id: result.insertId });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ─── UTILIZADOR_PROJETO ───────────────────────────────────

// Buscar projetos de um trabalhador (só os que foi adicionado)
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

// Pesquisar utilizador por email
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

// Adicionar utilizador a projeto
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

// Remover utilizador de projeto
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

// Listar membros de um projeto
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

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`🚀 API a correr em http://localhost:${PORT}`);
});