const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const { md5 } = require('../utils/hash');

const router = express.Router();

// ─── LOGIN ───────────────────────────────────────────────
router.post('/', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email e password são obrigatórios' });
  }

  try {
    const hashedPassword = md5(password);

    const [rows] = await pool.execute(
      'SELECT * FROM utilizadores WHERE email = ? AND password = ?',
      [email, hashedPassword]
    );

    if (rows.length > 0) {
      logger.success(`Login bem-sucedido: ${email}`);
      const { password: _, ...userSafe } = rows[0];
      res.json({ success: true, user: userSafe });
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