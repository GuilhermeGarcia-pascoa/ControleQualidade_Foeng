const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');

const router = express.Router();

// ─── LOGIN ───────────────────────────────────────────────
router.post('/', async (req, res) => {
  const { email, password } = req.body;
  try {
    const [rows] = await pool.execute(
      'SELECT * FROM utilizadores WHERE email = ? AND password = ?',
      [email, password]
    );
    if (rows.length > 0) {
      logger.success(`Login bem-sucedido: ${email}`);
      res.json({ success: true, user: rows[0] });
    } else {
      logger.warn(`Tentativa de login falhada: ${email}`);
      res.status(401).json({ success: false, message: 'Credenciais inválidas' });
    }
  } catch (error) {
    logger.error('Erro em POST /login', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
