const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

// Configuração segura do JWT_SECRET
const SECRET = process.env.JWT_SECRET || 'dev_secret_key_change_in_production';

/**
 * Middleware de autenticação obrigatória
 * Verifica se o token JWT é válido e adiciona dados do utilizador ao request
 */
function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  // Verificar se o header Authorization está presente
  if (!authHeader) {
    logger.warn('Tentativa de acesso sem token');
    return res.status(401).json({
      success: false,
      error: 'Não autenticado. Token ausente.',
      code: 'NO_TOKEN'
    });
  }

  // Extrair o token do header "Bearer <token>"
  const token = authHeader.split(' ')[1];

  if (!token) {
    logger.warn('Token ausente no header Authorization');
    return res.status(401).json({
      success: false,
      error: 'Não autenticado. Formato inválido.',
      code: 'INVALID_FORMAT'
    });
  }

  try {
    // Verificar e decodificar o token
    const decoded = jwt.verify(token, SECRET);
    req.user = decoded; // Adicionar dados do utilizador ao request
    logger.info(`Autenticação bem-sucedida para utilizador ${decoded.id}`);
    next();
  } catch (err) {
    logger.warn(`Token inválido: ${err.message}`);

    // Mensagens específicas para diferentes tipos de erro
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Token expirado',
        code: 'TOKEN_EXPIRED'
      });
    }

    return res.status(401).json({
      success: false,
      error: 'Token inválido',
      code: 'INVALID_TOKEN'
    });
  }
}

/**
 * Middleware de autenticação opcional
 * Tenta extrair dados do utilizador, mas não rejeita se não existir token
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, SECRET);
      req.user = decoded;
    } catch (err) {
      logger.info('Token opcional inválido, continuando sem autenticação');
    }
  }

  next();
}

/**
 * Middleware para exigir permissão de admin
 * Deve ser utilizado APÓS requireAuth
 */
function requireAdmin(req, res, next) {
  if (!req.user) {
    logger.warn('Tentativa de acesso admin sem autenticação');
    return res.status(401).json({
      success: false,
      error: 'Não autenticado',
      code: 'NO_AUTH'
    });
  }

  // Verificar se o perfil é 'admin'
  if (req.user.perfil !== 'admin') {
    logger.warn(`Tentativa de acesso admin por utilizador ${req.user.id} (perfil: ${req.user.perfil})`);
    return res.status(403).json({
      success: false,
      error: 'Acesso negado. Permissões insuficientes.',
      code: 'FORBIDDEN'
    });
  }

  next();
}

/**
 * Middleware para gerar token JWT
 * Utilizado internamente no endpoint de login
 */
function generateToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      perfil: user.perfil
    },
    SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '8h'
    }
  );
}

module.exports = {
  requireAuth,
  optionalAuth,
  requireAdmin,
  generateToken
};
