const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const {
  hashPassword,
  isLegacyMd5Hash,
  verifyPassword,
} = require('../utils/hash');
const { generateToken } = require('../middleware/auth');

const router = express.Router();

router.post('/', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email e password sao obrigatorios',
    });
  }

  try {
    const [rows] = await pool.execute(
      'SELECT * FROM utilizadores WHERE email = ?',
      [email]
    );

    if (rows.length === 0) {
      logger.warn(`Tentativa de login falhada: ${email}`);
      return res.status(401).json({
        success: false,
        message: 'Credenciais invalidas',
      });
    }

    const user = rows[0];
    const passwordOk = await verifyPassword(password, user.password);

    if (!passwordOk) {
      logger.warn(`Tentativa de login falhada: ${email}`);
      return res.status(401).json({
        success: false,
        message: 'Credenciais invalidas',
      });
    }

    if (isLegacyMd5Hash(user.password)) {
      try {
        const upgradedHash = await hashPassword(password);
        await pool.execute(
          'UPDATE utilizadores SET password = ? WHERE id = ?',
          [upgradedHash, user.id]
        );
        logger.info(`Password migrada de MD5 para bcrypt: ${email}`);
      } catch (upgradeError) {
        logger.warn(
          `Falha ao migrar password para bcrypt (${email}): ${upgradeError.message}`
        );
      }
    }

    logger.success(`Login bem-sucedido: ${email}`);
    const { password: _, ...userSafe } = user;
    
    // Gerar token JWT
    const token = generateToken(user);
    
    res.json({
      success: true,
      user: userSafe,
      token,
      expiresIn: process.env.JWT_EXPIRES_IN || '8h'
    });
  } catch (error) {
    logger.error('Erro em POST /login', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
