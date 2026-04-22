const { validationResult } = require('express-validator');

/**
 * Middleware para processar erros de validação
 * Retorna 400 com erros formatados se houver validações inválidas
 */
function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false, 
      errors: errors.array().map(e => ({
        campo: e.path,
        mensagem: e.msg,
        valor: e.value
      }))
    });
  }
  next();
}

module.exports = validate;
