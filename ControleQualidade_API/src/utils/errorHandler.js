const logger = require('./logger');

const errorHandler = (err, req, res) => {
  logger.error(`Erro em ${req.method} ${req.path}`, err);

  // Erro de validação
  if (err.statusCode === 400) {
    return res.status(400).json({
      success: false,
      error: err.message || 'Dados inválidos',
    });
  }

  // Erro de autenticação
  if (err.statusCode === 401) {
    return res.status(401).json({
      success: false,
      error: 'Não autenticado',
    });
  }

  // Erro de autorização
  if (err.statusCode === 403) {
    return res.status(403).json({
      success: false,
      error: 'Sem permissão',
    });
  }

  // Erro de não encontrado
  if (err.statusCode === 404) {
    return res.status(404).json({
      success: false,
      error: 'Recurso não encontrado',
    });
  }

  // Erro de banco de dados
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(400).json({
      success: false,
      error: 'Registo já existe',
    });
  }

  if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    return res.status(400).json({
      success: false,
      error: 'Não é possível apagar: existem registos que dependem deste.',
    });
  }

  // Erro genérico
  res.status(500).json({
    success: false,
    error: 'Erro interno do servidor',
  });
};

module.exports = errorHandler;
