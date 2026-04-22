const logger = require('../utils/logger');

/**
 * Middleware de tratamento de erros centralizado
 * Padroniza respostas de erro em toda a API
 */
const errorHandler = (err, req, res, next) => {
  // Log do erro
  logger.error(`[${req.method}] ${req.path} - ${err.message}`, err);

  // Status code padrão
  let statusCode = 500;
  let message = err.message || 'Erro interno do servidor';
  let code = err.code || 'INTERNAL_ERROR';

  // Mapear erros específicos
  if (err.code === 'NOT_FOUND') {
    statusCode = 404;
  } else if (err.code === 'INVALID_JSON' || err.code === 'VALIDATION_ERROR') {
    statusCode = 400;
  } else if (err.code === 'MISSING_DADOS' || err.code === 'INVALID_ACCESS') {
    statusCode = 400;
  } else if (err.code === 'CIRCULAR_REFERENCE') {
    statusCode = 400;
  } else if (err.code === 'INVALID_PARENT') {
    statusCode = 400;
  } else if (err.code === 'ALREADY_EXISTS') {
    statusCode = 409;
  } else if (err.code === 'UNAUTHORIZED') {
    statusCode = 401;
  } else if (err.code === 'FORBIDDEN') {
    statusCode = 403;
  } else if (err.message?.includes('FOREIGN KEY constraint fails')) {
    statusCode = 409;
    message = 'Não é possível executar esta operação (referência em uso)';
    code = 'CONSTRAINT_ERROR';
  } else if (err.message?.includes('Duplicate entry')) {
    statusCode = 409;
    message = 'Registro duplicado (valor já existe)';
    code = 'DUPLICATE_ERROR';
  }

  // Resposta padronizada
  res.status(statusCode).json({
    success: false,
    error: message,
    code: code,
    timestamp: new Date().toISOString(),
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

/**
 * Wrapper para async routes
 * Evita try/catch em cada rota
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

/**
 * Validar autenticação e retornar erro padronizado
 */
const authErrorHandler = (err, req, res, next) => {
  if (err.message === 'Acesso negado' || err.message === 'Token inválido ou expirado') {
    return res.status(401).json({
      success: false,
      error: 'Token inválido ou expirado',
      code: 'UNAUTHORIZED',
      timestamp: new Date().toISOString()
    });
  }
  next(err);
};

module.exports = {
  errorHandler,
  asyncHandler,
  authErrorHandler
};
