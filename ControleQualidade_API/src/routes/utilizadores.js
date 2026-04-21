const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const { md5 } = require('../utils/hash');

const router = express.Router();

// ─── LISTAR TODOS ───────────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, nome, email, perfil FROM utilizadores'
    );
    logger.success(`Listagem de utilizadores: ${rows.length} resultados`);
    res.json({ success: true, utilizadores: rows });
  } catch (error) {
    logger.error('Erro em GET /', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── CRIAR UTILIZADOR ─────────────────────────────────────────────
router.post('/', async (req, res) => {
  const { nome, email, password, perfil } = req.body;

  if (!nome || !email || !password) {
    return res.status(400).json({ success: false, message: 'Nome, email e password são obrigatórios' });
  }

  try {
    const [existe] = await pool.execute(
      'SELECT id FROM utilizadores WHERE email = ?',
      [email]
    );

    if (existe.length > 0) {
      return res.status(409).json({ success: false, message: 'Email já registado' });
    }

    const hashedPassword = md5(password);

    const [result] = await pool.execute(
      'INSERT INTO utilizadores (nome, email, password, perfil) VALUES (?, ?, ?, ?)',
      [nome, email, hashedPassword, perfil || 'utilizador']
    );

    logger.success(`Novo utilizador criado: ${email}`);
    res.status(201).json({
      success: true,
      utilizador: { id: result.insertId, nome, email, perfil: perfil || 'utilizador' },
    });
  } catch (error) {
    logger.error('Erro em POST /', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── REGISTO ──────────────────────────────────────────────────────
router.post('/registar', async (req, res) => {
  const { nome, email, password, perfil } = req.body;

  if (!nome || !email || !password) {
    return res.status(400).json({ success: false, message: 'Nome, email e password são obrigatórios' });
  }

  try {
    const [existe] = await pool.execute(
      'SELECT id FROM utilizadores WHERE email = ?',
      [email]
    );

    if (existe.length > 0) {
      return res.status(409).json({ success: false, message: 'Email já registado' });
    }

    const hashedPassword = md5(password);

    const [result] = await pool.execute(
      'INSERT INTO utilizadores (nome, email, password, perfil) VALUES (?, ?, ?, ?)',
      [nome, email, hashedPassword, perfil || 'utilizador']
    );

    logger.success(`Novo utilizador registado: ${email}`);
    res.status(201).json({
      success: true,
      utilizador: { id: result.insertId, nome, email, perfil: perfil || 'utilizador' },
    });
  } catch (error) {
    logger.error('Erro em POST /utilizadores/registar', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── BUSCAR POR EMAIL ─────────────────────────────────────
router.get('/email/:email', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, nome, email, perfil FROM utilizadores WHERE email = ?',
      [req.params.email]
    );
    if (rows.length > 0) {
      res.json({ success: true, utilizador: rows[0] });
    } else {
      res.status(404).json({ success: false, message: 'Utilizador não encontrado' });
    }
  } catch (error) {
    logger.error('Erro em GET /email/:email', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── ALTERAR SENHA ────────────────────────────────────────────────────
router.put('/:id/senha', async (req, res) => {
  const { password } = req.body;
  if (!password) {
    return res.status(400).json({ success: false, message: 'Password obrigatória' });
  }

  try {
    const hashedPassword = md5(password);
    await pool.execute(
      'UPDATE utilizadores SET password = ? WHERE id = ?',
      [hashedPassword, req.params.id]
    );
    logger.success(`Senha atualizada para utilizador ${req.params.id}`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em PUT /:id/senha', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── TEMA ─────────────────────────────────────────────────
router.get('/:id/tema', async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT tema_escuro FROM utilizadores WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ success: false });
    res.json({ success: true, tema_escuro: rows[0].tema_escuro === 1 });
  } catch (e) {
    logger.error('Erro em GET /:id/tema', e);
    res.status(500).json({ success: false, error: e.message });
  }
});

router.put('/:id/tema', async (req, res) => {
  try {
    const { tema_escuro } = req.body;
    await pool.execute('UPDATE utilizadores SET tema_escuro = ? WHERE id = ?', [tema_escuro ? 1 : 0, req.params.id]);
    logger.success(`Tema atualizado para utilizador ${req.params.id}`);
    res.json({ success: true });
  } catch (e) {
    logger.error('Erro em PUT /:id/tema', e);
    res.status(500).json({ success: false, error: e.message });
  }
});

// ─── EDITAR UTILIZADOR ────────────────────────────────────────────────
router.put('/:id', async (req, res) => {
  const { nome, email, perfil } = req.body;

  if (!nome || !email) {
    return res.status(400).json({ success: false, message: 'Nome e email são obrigatórios' });
  }

  try {
    // Verificar se o email já existe (excepto para o utilizador atual)
    const [existe] = await pool.execute(
      'SELECT id FROM utilizadores WHERE email = ? AND id != ?',
      [email, req.params.id]
    );

    if (existe.length > 0) {
      return res.status(409).json({ success: false, message: 'Email já registado' });
    }

    await pool.execute(
      'UPDATE utilizadores SET nome = ?, email = ?, perfil = ? WHERE id = ?',
      [nome, email, perfil || 'utilizador', req.params.id]
    );

    logger.success(`Utilizador ${req.params.id} atualizado`);
    res.json({ success: true, utilizador: { id: parseInt(req.params.id), nome, email, perfil: perfil || 'utilizador' } });
  } catch (error) {
    logger.error('Erro em PUT /:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── APAGAR UTILIZADOR ───────────────────────────────────────────────
router.delete('/:id', async (req, res) => {
  try {
    await pool.execute('DELETE FROM utilizadores WHERE id = ?', [req.params.id]);
    logger.success(`Utilizador eliminado: ${req.params.id}`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em DELETE /:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── PESQUISAR POR TEXTO (nome ou email) ───────────────────────────────────
router.get('/pesquisar/:texto', async (req, res) => {
  try {
    const texto = `%${req.params.texto}%`;
    const [rows] = await pool.execute(
      `SELECT id, nome, email, perfil
       FROM utilizadores
       WHERE nome LIKE ? OR email LIKE ?
       ORDER BY nome ASC
       LIMIT 10`,
      [texto, texto]
    );
    logger.success(`Pesquisa "${req.params.texto}": ${rows.length} resultados`);
    res.json({ success: true, utilizadores: rows });
  } catch (error) {
    logger.error('Erro em GET /utilizadores/pesquisar/:texto', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;