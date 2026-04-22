const BaseRepository = require('./baseRepository');
const logger = require('../utils/logger');

/**
 * Repository para entidade Projetos
 * Responsável apenas por acesso à base de dados
 */
class ProjetosRepository extends BaseRepository {
  /**
   * Criar novo projeto
   */
  async create(nome, descricao, criadoPor) {
    const result = await this.execute(
      'INSERT INTO projetos (nome, descricao, criado_por) VALUES (?, ?, ?)',
      [nome, descricao, criadoPor]
    );
    
    logger.success(`Projeto criado: ${nome} (ID: ${result.insertId})`);
    
    return { success: true, id: result.insertId };
  }

  /**
   * Obter projeto por ID
   */
  async getById(projetoId) {
    return await this.queryOne(
      'SELECT * FROM projetos WHERE id = ?',
      [projetoId]
    );
  }

  /**
   * Obter projetos de um utilizador (criador)
   */
  async getByUserId(userId) {
    return await this.query(
      'SELECT * FROM projetos WHERE criado_por = ? ORDER BY criado_em DESC',
      [userId]
    );
  }

  /**
   * Obter projetos de um trabalhador (via relacionamento)
   */
  async getByTrabalhadorId(userId) {
    return await this.query(
      `SELECT p.* FROM projetos p
       INNER JOIN utilizador_projeto up ON p.id = up.projeto_id
       WHERE up.utilizador_id = ?
       ORDER BY p.criado_em DESC`,
      [userId]
    );
  }

  /**
   * Atualizar projeto
   */
  async update(projetoId, nome, descricao) {
    await this.execute(
      'UPDATE projetos SET nome = ?, descricao = ? WHERE id = ?',
      [nome, descricao, projetoId]
    );
    
    logger.success(`Projeto ${projetoId} atualizado`);
    
    return { success: true };
  }

  /**
   * Deletar projeto (com CASCADE DELETE)
   */
  async delete(projetoId) {
    // Com CASCADE DELETE configurado no MySQL, este DELETE
    // elimina automaticamente: nos → registos, campos_dinamicos, utilizador_no
    // E também: utilizador_projeto do projeto
    await this.execute('DELETE FROM projetos WHERE id = ?', [projetoId]);
    
    logger.success(`Projeto ${projetoId} eliminado (cascade)`);
    
    return { success: true };
  }

  /**
   * Copiar projeto (criar novo com dados do original)
   */
  async copy(projetoId, novoNome, criadoPor) {
    const result = await this.execute(
      'INSERT INTO projetos (nome, descricao, criado_por) SELECT ?, descricao, ? FROM projetos WHERE id = ?',
      [novoNome, criadoPor, projetoId]
    );
    
    logger.success(`Projeto ${projetoId} copiado para ID ${result.insertId}`);
    
    return result;
  }

  /**
   * Contar nós de um projeto
   */
  async countNodes(projetoId) {
    return await this.count('nos', 'projeto_id = ?', [projetoId]);
  }

  /**
   * Contar registos de um projeto
   */
  async countRecords(projetoId) {
    const result = await this.queryOne(
      `SELECT COUNT(*) as total FROM registos r
       JOIN nos n ON r.no_id = n.id 
       WHERE n.projeto_id = ?`,
      [projetoId]
    );
    
    return result?.total || 0;
  }

  /**
   * Obter estatísticas do projeto
   */
  async getStats(projetoId) {
    const totalNos = await this.countNodes(projetoId);
    const totalRegistos = await this.countRecords(projetoId);
    
    return {
      success: true,
      total_nos: totalNos,
      total_registos: totalRegistos
    };
  }
}

module.exports = ProjetosRepository;
