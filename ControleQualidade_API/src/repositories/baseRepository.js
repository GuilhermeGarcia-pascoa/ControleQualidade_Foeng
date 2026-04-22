const logger = require('../utils/logger');

/**
 * Classe base para todos os repositories
 * Fornece acesso ao pool de BD e métodos comuns de query
 */
class BaseRepository {
  constructor(pool) {
    this.pool = pool;
    this.logger = logger;
  }

  /**
   * Executa uma query SELECT
   */
  async query(sql, params = []) {
    try {
      const [rows] = await this.pool.execute(sql, params);
      return rows;
    } catch (error) {
      this.logger.error(`Erro em query: ${sql}`, error);
      throw error;
    }
  }

  /**
   * Executa uma query e retorna primeira linha
   */
  async queryOne(sql, params = []) {
    const rows = await this.query(sql, params);
    return rows.length > 0 ? rows[0] : null;
  }

  /**
   * Executa INSERT/UPDATE/DELETE
   */
  async execute(sql, params = []) {
    try {
      const [result] = await this.pool.execute(sql, params);
      return result;
    } catch (error) {
      this.logger.error(`Erro em execute: ${sql}`, error);
      throw error;
    }
  }

  /**
   * Obtém conexão para transações
   */
  async getConnection() {
    return await this.pool.getConnection();
  }

  /**
   * Conta registos com filtros
   */
  async count(table, whereClause = '', params = []) {
    const sql = `SELECT COUNT(*) as total FROM ${table}${whereClause ? ` WHERE ${whereClause}` : ''}`;
    const result = await this.queryOne(sql, params);
    return result?.total || 0;
  }

  /**
   * Retorna resposta com paginação
   */
  formatPaginatedResponse(rows, total, page, limit) {
    return {
      success: true,
      data: rows,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit)
    };
  }
}

module.exports = BaseRepository;
