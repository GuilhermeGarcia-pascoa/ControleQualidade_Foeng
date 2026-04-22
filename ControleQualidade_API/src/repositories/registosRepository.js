const BaseRepository = require('./baseRepository');
const logger = require('../utils/logger');

/**
 * Repository para entidade Registos
 * Responsável apenas por acesso à base de dados
 */
class RegistosRepository extends BaseRepository {
  /**
   * Obter registos de um nó com filtros e paginação
   */
async getByNoId(noId, limit, page, search = '', filtroColuna = null) {
  const safeNoId = Number(noId);
  const safeLimit = Number(limit);
  const safePage = Number(page);
  const offset = (safePage - 1) * safeLimit;

  let whereClause = 'r.no_id = ?';
  let countWhereClause = 'no_id = ?';
  let params = [safeNoId];
  let countParams = [safeNoId];

  if (search) {
    if (filtroColuna === '_autor') {
      whereClause += ' AND u.nome LIKE ?';
      countWhereClause += ' AND utilizador_id IN (SELECT id FROM utilizadores WHERE nome LIKE ?)';
      params.push(`%${search}%`);
      countParams.push(`%${search}%`);
    } else if (filtroColuna) {
      whereClause += ' AND JSON_EXTRACT(r.dados, ?) LIKE ?';
      countWhereClause += ' AND JSON_EXTRACT(dados, ?) LIKE ?';
      params.push(`$."${filtroColuna}"`, `%${search}%`);
      countParams.push(`$."${filtroColuna}"`, `%${search}%`);
    } else {
      whereClause += ' AND (u.nome LIKE ? OR JSON_SEARCH(r.dados, \'one\', ?) IS NOT NULL)';
      countWhereClause += ' AND (utilizador_id IN (SELECT id FROM utilizadores WHERE nome LIKE ?) OR JSON_SEARCH(dados, \'one\', ?) IS NOT NULL)';
      params.push(`%${search}%`, `%${search}%`);
      countParams.push(`%${search}%`, `%${search}%`);
    }
  }

  const registos = await this.query(
    `SELECT r.*, u.nome as nome_utilizador 
     FROM registos r 
     JOIN utilizadores u ON r.utilizador_id = u.id
     WHERE ${whereClause}
     ORDER BY r.criado_em DESC
     LIMIT ? OFFSET ?`,
    [...params, safeLimit, offset]  // ← safeLimit e offset garantidos como Number
  );

  const total = await this.count('registos', countWhereClause, countParams);

  logger.success(`${registos.length} registos obtidos para nó ${safeNoId}`);

  return this.formatPaginatedResponse(registos, total, safePage, safeLimit);
}

  /**
   * Criar novo registo
   */
  async create(noId, utilizadorId, dados) {
    const result = await this.execute(
      'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
      [noId, utilizadorId || 1, JSON.stringify(dados)]
    );
    
    logger.success(`Registo criado (ID: ${result.insertId}) para nó ${noId}`);
    
    return {
      success: true,
      id: result.insertId,
      files: (dados._files || []).length
    };
  }

  /**
   * Obter registo por ID
   */
  async getById(registoId) {
    const registo = await this.queryOne(
      `SELECT r.*, u.nome as nome_utilizador 
       FROM registos r 
       JOIN utilizadores u ON r.utilizador_id = u.id
       WHERE r.id = ?`,
      [registoId]
    );
    
    if (registo && typeof registo.dados === 'string') {
      try {
        registo.dados = JSON.parse(registo.dados);
      } catch (e) {
        // Manter como string se não for JSON válido
      }
    }
    
    return registo;
  }

  /**
   * Atualizar registo
   */
  async update(registoId, dados) {
    await this.execute(
      'UPDATE registos SET dados = ? WHERE id = ?',
      [JSON.stringify(dados), registoId]
    );
    
    logger.success(`Registo ${registoId} atualizado`);
    
    return { success: true };
  }

  /**
   * Deletar registo
   */
  async delete(registoId) {
    await this.execute('DELETE FROM registos WHERE id = ?', [registoId]);
    
    logger.success(`Registo ${registoId} deletado`);
    
    return { success: true };
  }

  /**
   * Contar registos de um nó
   */
  async countByNoId(noId) {
    return await this.count('registos', 'no_id = ?', [noId]);
  }

  /**
   * Deletar registos de um nó (quando deletar nó)
   */
  async deleteByNoId(noId) {
    await this.execute('DELETE FROM registos WHERE no_id = ?', [noId]);
    logger.success(`Registos do nó ${noId} deletados`);
    return { success: true };
  }
}

module.exports = RegistosRepository;
