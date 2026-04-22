const BaseRepository = require('./baseRepository');
const logger = require('../utils/logger');

/**
 * Repository para entidade Nós
 * Responsável apenas por acesso à base de dados
 */
class NosRepository extends BaseRepository {
  /**
   * Criar novo nó
   */
  async create(projetoId, nome, paiId = null) {
    const result = await this.execute(
      'INSERT INTO nos (projeto_id, pai_id, nome) VALUES (?, ?, ?)',
      [projetoId, paiId || null, nome]
    );
    
    logger.success(`Nó criado: ${nome} (ID: ${result.insertId}, Projeto: ${projetoId})`);
    
    return { success: true, id: result.insertId };
  }

  /**
   * Obter nó por ID
   */
  async getById(noId) {
    return await this.queryOne(
      'SELECT * FROM nos WHERE id = ?',
      [noId]
    );
  }

  /**
   * Obter nós de um projeto
   */
  async getByProjetoId(projetoId, paiId = null) {
    let sql = 'SELECT * FROM nos WHERE projeto_id = ?';
    let params = [projetoId];

    if (paiId !== null && paiId !== undefined) {
      sql += ' AND pai_id = ?';
      params.push(paiId);
    }

    sql += ' ORDER BY nome ASC';

    return await this.query(sql, params);
  }

  /**
   * Obter ancestrais de um nó
   */
  async getAncestors(noId) {
    // Recursivamente buscar todos os pais até a raiz
    const ancestrais = [];
    let currentId = noId;

    while (currentId) {
      const no = await this.getById(currentId);
      if (!no) break;

      ancestrais.unshift(no); // Inserir no início
      currentId = no.pai_id;
    }

    return ancestrais;
  }

  /**
   * Obter descendentes de um nó (árvore)
   */
  async getDescendants(noId) {
    const descendentes = [];

    const buscarDescendentes = async (id) => {
      const filhos = await this.query(
        'SELECT * FROM nos WHERE pai_id = ? ORDER BY nome ASC',
        [id]
      );

      for (const filho of filhos) {
        descendentes.push(filho);
        await buscarDescendentes(filho.id);
      }
    };

    await buscarDescendentes(noId);
    return descendentes;
  }

  /**
   * Atualizar nó
   */
  async update(noId, nome, paiId = undefined) {
    let sql = 'UPDATE nos SET nome = ?';
    let params = [nome];

    if (paiId !== undefined) {
      sql += ', pai_id = ?';
      params.push(paiId || null);
    }

    sql += ' WHERE id = ?';
    params.push(noId);

    await this.execute(sql, params);
    
    logger.success(`Nó ${noId} atualizado`);
    
    return { success: true };
  }

  /**
   * Deletar nó (CASCADE DELETE em registos)
   */
  async delete(noId) {
    // Com CASCADE DELETE no schema, registos são automaticamente deletados
    await this.execute('DELETE FROM nos WHERE id = ?', [noId]);
    
    logger.success(`Nó ${noId} deletado`);
    
    return { success: true };
  }

  /**
   * Mover nó para novo pai
   */
  async move(noId, novoPaiId = null) {
    await this.execute(
      'UPDATE nos SET pai_id = ? WHERE id = ?',
      [novoPaiId || null, noId]
    );
    
    logger.success(`Nó ${noId} movido para pai ${novoPaiId || 'nenhum (raiz)'}`);
    
    return { success: true };
  }

  /**
   * Copiar nó
   */
  async copy(noId, novoNome, novoProjetoId, novoPaiId = null) {
    const no = await this.getById(noId);
    if (!no) {
      throw new Error('Nó original não encontrado');
    }

    const result = await this.execute(
      'INSERT INTO nos (projeto_id, pai_id, nome) VALUES (?, ?, ?)',
      [novoProjetoId, novoPaiId || null, novoNome]
    );
    
    logger.success(`Nó ${noId} copiado para ${result.insertId}`);
    
    return result;
  }

  /**
   * Obter informações de um nó (com ancestrais)
   */
  async getInfo(noId) {
    const no = await this.getById(noId);
    if (!no) return null;

    const ancestrais = await this.getAncestors(noId);
    const registos = await this.query(
      'SELECT COUNT(*) as total FROM registos WHERE no_id = ?',
      [noId]
    );

    return {
      ...no,
      ancestrais,
      totalRegistos: registos[0]?.total || 0
    };
  }

  /**
   * Obter nós partilhados com um utilizador
   */
  async getSharedWithUser(userId) {
    return await this.query(
      `SELECT DISTINCT n.* FROM nos n
       INNER JOIN utilizador_no un ON n.id = un.no_id
       WHERE un.utilizador_id = ?
       ORDER BY n.nome ASC`,
      [userId]
    );
  }

  /**
   * Obter acesso de um utilizador a um nó
   */
  async getUserAccess(noId, userId) {
    return await this.queryOne(
      'SELECT * FROM utilizador_no WHERE no_id = ? AND utilizador_id = ?',
      [noId, userId]
    );
  }

  /**
   * Adicionar acesso de utilizador a nó
   */
  async addUserAccess(noId, userId, acesso = 'leitura') {
    const result = await this.execute(
      'INSERT INTO utilizador_no (no_id, utilizador_id, acesso) VALUES (?, ?, ?)',
      [noId, userId, acesso]
    );
    
    logger.success(`Acesso adicionado: utilizador ${userId} → nó ${noId} (${acesso})`);
    
    return { success: true, id: result.insertId };
  }

  /**
   * Remover acesso de utilizador a nó
   */
  async removeUserAccess(noId, userId) {
    await this.execute(
      'DELETE FROM utilizador_no WHERE no_id = ? AND utilizador_id = ?',
      [noId, userId]
    );
    
    logger.success(`Acesso removido: utilizador ${userId} → nó ${noId}`);
    
    return { success: true };
  }

  /**
   * Contar nós de um projeto
   */
  async countByProjetoId(projetoId) {
    return await this.count('nos', 'projeto_id = ?', [projetoId]);
  }
}

module.exports = NosRepository;
