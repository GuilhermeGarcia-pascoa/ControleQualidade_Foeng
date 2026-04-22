const logger = require('../utils/logger');

/**
 * Classe base para todos os services
 * Fornece métodos comuns e tratamento de erros padronizado
 */
class BaseService {
  constructor(repository) {
    this.repository = repository;
    this.logger = logger;
  }

  /**
   * Valida se um valor é numérico positivo
   */
  validatePositiveInt(value, fieldName = 'ID') {
    const num = parseInt(value);
    if (isNaN(num) || num < 1) {
      throw new Error(`${fieldName} deve ser um número inteiro positivo`);
    }
    return num;
  }

  /**
   * Valida se um valor não está vazio
   */
  validateRequired(value, fieldName = 'Campo') {
    if (!value || (typeof value === 'string' && !value.trim())) {
      throw new Error(`${fieldName} é obrigatório`);
    }
    return value;
  }

  /**
   * Valida tamanho de string
   */
  validateStringLength(value, max, fieldName = 'Campo') {
    if (typeof value === 'string' && value.length > max) {
      throw new Error(`${fieldName} não pode ter mais de ${max} caracteres`);
    }
    return value;
  }

  /**
   * Valida paginação (limit, offset/page)
   */
  validatePagination(limit, page) {
    const parsedLimit = parseInt(limit) || 30;
    const parsedPage = parseInt(page) || 1;
    
    // Máximo 100 por página
    const finalLimit = Math.min(parsedLimit, 100);
    const offset = (parsedPage - 1) * finalLimit;

    return { limit: finalLimit, page: parsedPage, offset };
  }

  /**
   * Executa uma operação com tratamento de erros
   */
  async execute(fn, context = '') {
    try {
      return await fn();
    } catch (error) {
      this.logger.error(`Erro em ${context}:`, error);
      throw error;
    }
  }

  /**
   * Retorna resposta padronizada
   */
  success(data, message = 'Operação bem-sucedida') {
    return {
      success: true,
      message,
      ...data
    };
  }

  /**
   * Retorna resposta de erro padronizada
   */
  error(message, code = 'ERROR') {
    const error = new Error(message);
    error.code = code;
    throw error;
  }
}

module.exports = BaseService;
