const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');

const router = express.Router();

// ─── UTILIZADORES ─────────────────────────────────────────
router.get('/pesquisar/:texto', async (req, res) => {
  try {
    const texto = `%${req.params.texto}%`;
    const [rows] = await pool.execute(
      'SELECT id, nome, email, perfil FROM utilizadores WHERE nome LIKE ? OR email LIKE ? LIMIT 5',
      [texto, texto]
    );
    logger.success(`Pesquisa de utilizadores: ${rows.length} resultados`);
    res.json({ success: true, utilizadores: rows });
  } catch (error) {
    logger.error('Erro em GET /pesquisar/:texto', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

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

module.exports = router;
