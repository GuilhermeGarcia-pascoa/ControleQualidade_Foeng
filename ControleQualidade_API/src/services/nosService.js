const BaseService = require('./baseService');
const NosRepository = require('../repositories/nosRepository');
const RegistosRepository = require('../repositories/registosRepository');

/**
 * Service para Nós
 * Responsável por lógica de negócio e orquestração
 */
class NosService extends BaseService {
  constructor(pool) {
    const nosRepository = new NosRepository(pool);
    super(nosRepository);
    this.pool = pool;
    this.registosRepository = new RegistosRepository(pool);
  }

  /**
   * Criar novo nó com validação
   */
  async createNo(projetoId, nome, paiId = null) {
    return this.execute(async () => {
      // Validações
      projetoId = this.validatePositiveInt(projetoId, 'Projeto ID');
      nome = this.validateRequired(nome, 'Nome do nó');
      nome = this.validateStringLength(nome, 255, 'Nome');

      if (paiId) {
        paiId = this.validatePositiveInt(paiId, 'Pai ID');
        // Verificar se pai existe e pertence ao mesmo projeto
        const pai = await this.repository.getById(paiId);
        if (!pai || pai.projeto_id !== projetoId) {
          this.error('Nó pai não encontrado ou pertence a outro projeto', 'INVALID_PARENT');
        }
      }

      return await this.repository.create(projetoId, nome, paiId || null);
    }, 'createNo');
  }

  /**
   * Obter nó por ID
   */
  async getNo(noId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');

      const no = await this.repository.getById(noId);
      if (!no) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      return { success: true, no };
    }, 'getNo');
  }

  /**
   * Obter nós de um projeto
   */
  async getByProjetoId(projetoId, paiId = null) {
    return this.execute(async () => {
      projetoId = this.validatePositiveInt(projetoId, 'Projeto ID');
      
      if (paiId) {
        paiId = this.validatePositiveInt(paiId, 'Pai ID');
      }

      const nos = await this.repository.getByProjetoId(projetoId, paiId);

      return {
        success: true,
        nos,
        total: nos.length
      };
    }, 'getByProjetoId');
  }

  /**
   * Obter ancestrais de um nó
   */
  async getAncestors(noId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');

      const no = await this.repository.getById(noId);
      if (!no) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      const ancestrais = await this.repository.getAncestors(noId);

      return {
        success: true,
        ancestrais,
        total: ancestrais.length
      };
    }, 'getAncestors');
  }

  /**
   * Obter descendentes de um nó
   */
  async getDescendants(noId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');

      const no = await this.repository.getById(noId);
      if (!no) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      const descendentes = await this.repository.getDescendants(noId);

      return {
        success: true,
        descendentes,
        total: descendentes.length
      };
    }, 'getDescendants');
  }

  /**
   * Obter informações completas de um nó
   */
  async getInfo(noId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');

      const info = await this.repository.getInfo(noId);
      if (!info) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      return { success: true, no: info };
    }, 'getInfo');
  }

  /**
   * Atualizar nó
   */
  async updateNo(noId, nome, paiId = undefined) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');
      nome = this.validateRequired(nome, 'Nome do nó');
      nome = this.validateStringLength(nome, 255, 'Nome');

      const no = await this.repository.getById(noId);
      if (!no) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      // Validar novo pai se fornecido
      if (paiId !== undefined && paiId !== null) {
        paiId = this.validatePositiveInt(paiId, 'Pai ID');
        const pai = await this.repository.getById(paiId);
        if (!pai || pai.projeto_id !== no.projeto_id) {
          this.error('Nó pai inválido', 'INVALID_PARENT');
        }
      }

      return await this.repository.update(noId, nome, paiId);
    }, 'updateNo');
  }

  /**
   * Deletar nó (deleta também registos via CASCADE)
   */
  async deleteNo(noId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');

      const no = await this.repository.getById(noId);
      if (!no) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      return await this.repository.delete(noId);
    }, 'deleteNo');
  }

  /**
   * Mover nó para novo pai
   */
  async moveNo(noId, novoPaiId = null) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');

      const no = await this.repository.getById(noId);
      if (!no) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      // Validar novo pai
      if (novoPaiId) {
        novoPaiId = this.validatePositiveInt(novoPaiId, 'Novo Pai ID');
        const pai = await this.repository.getById(novoPaiId);
        if (!pai || pai.projeto_id !== no.projeto_id) {
          this.error('Nó pai inválido', 'INVALID_PARENT');
        }

        // Impedir circular reference
        const descendentes = await this.repository.getDescendants(noId);
        if (descendentes.some(d => d.id === novoPaiId)) {
          this.error('Não é possível mover para descendente (referência circular)', 'CIRCULAR_REFERENCE');
        }
      }

      return await this.repository.move(noId, novoPaiId || null);
    }, 'moveNo');
  }

  /**
   * Copiar nó (com subpastas e campos)
   */
  async copyNo(noId, novoProjetoId, novoPaiId = null, incluirRegistos = false) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');
      novoProjetoId = this.validatePositiveInt(novoProjetoId, 'Novo Projeto ID');

      const no = await this.repository.getById(noId);
      if (!no) {
        this.error('Nó não encontrado', 'NOT_FOUND');
      }

      if (novoPaiId) {
        novoPaiId = this.validatePositiveInt(novoPaiId, 'Novo Pai ID');
      }

      // Copiar nó com "(Cópia)"
      const novoNome = `${no.nome} (Cópia)`;
      const result = await this.repository.copy(noId, novoNome, novoProjetoId, novoPaiId);
      const novoNoId = result.insertId;

      // Copiar campos dinâmicos
      const campos = await this.repository.query(
        'SELECT * FROM campos_dinamicos WHERE no_id = ? ORDER BY ordem ASC',
        [noId]
      );

      for (const campo of campos) {
        await this.repository.execute(
          'INSERT INTO campos_dinamicos (no_id, nome, tipo, ordem) VALUES (?, ?, ?, ?)',
          [novoNoId, campo.nome, campo.tipo, campo.ordem]
        );
      }

      // Copiar subpastas recursivamente
      const subpastas = await this.repository.query(
        'SELECT id FROM nos WHERE pai_id = ? ORDER BY id',
        [noId]
      );

      for (const subpasta of subpastas) {
        await this._copiarNoRecursivo(subpasta.id, novoNoId, novoProjetoId, incluirRegistos);
      }

      // Copiar registos se solicitado
      if (incluirRegistos) {
        const registos = await this.registosRepository.query(
          'SELECT * FROM registos WHERE no_id = ?',
          [noId]
        );

        for (const registo of registos) {
          await this.registosRepository.execute(
            'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
            [novoNoId, registo.utilizador_id, registo.dados]
          );
        }
      }

      this.logger.success(`Nó ${noId} copiado para ${novoNoId}`);

      return { success: true, id: novoNoId };
    }, 'copyNo');
  }

  /**
   * Obter nós partilhados com utilizador
   */
  async getSharedWithUser(userId) {
    return this.execute(async () => {
      userId = this.validatePositiveInt(userId, 'User ID');

      const nos = await this.repository.getSharedWithUser(userId);

      return {
        success: true,
        nos,
        total: nos.length
      };
    }, 'getSharedWithUser');
  }

  /**
   * Obter acesso de utilizador a nó
   */
  async getUserAccess(noId, userId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');
      userId = this.validatePositiveInt(userId, 'User ID');

      const acesso = await this.repository.getUserAccess(noId, userId);

      return {
        success: true,
        acesso,
        temAcesso: !!acesso
      };
    }, 'getUserAccess');
  }

  /**
   * Adicionar acesso de utilizador
   */
  async addUserAccess(noId, userId, acesso = 'leitura') {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');
      userId = this.validatePositiveInt(userId, 'User ID');

      if (!['leitura', 'escrita'].includes(acesso)) {
        this.error('Acesso deve ser "leitura" ou "escrita"', 'INVALID_ACCESS');
      }

      // Verificar se já existe
      const existente = await this.repository.getUserAccess(noId, userId);
      if (existente) {
        this.error('Utilizador já tem acesso a este nó', 'ALREADY_EXISTS');
      }

      return await this.repository.addUserAccess(noId, userId, acesso);
    }, 'addUserAccess');
  }

  /**
   * Remover acesso de utilizador
   */
  async removeUserAccess(noId, userId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');
      userId = this.validatePositiveInt(userId, 'User ID');

      const acesso = await this.repository.getUserAccess(noId, userId);
      if (!acesso) {
        this.error('Utilizador não tem acesso a este nó', 'NOT_FOUND');
      }

      return await this.repository.removeUserAccess(noId, userId);
    }, 'removeUserAccess');
  }

  /**
   * Copiar nó recursivamente (helper privado)
   */
  async _copiarNoRecursivo(noId, novoPaiId, novoProjetoId, incluirRegistos) {
    const no = await this.repository.getById(noId);
    if (!no) return;

    // Copiar nó
    const result = await this.repository.copy(noId, no.nome, novoProjetoId, novoPaiId);
    const novoNoId = result.insertId;

    // Copiar campos
    const campos = await this.repository.query(
      'SELECT * FROM campos_dinamicos WHERE no_id = ? ORDER BY ordem ASC',
      [noId]
    );

    for (const campo of campos) {
      await this.repository.execute(
        'INSERT INTO campos_dinamicos (no_id, nome, tipo, ordem) VALUES (?, ?, ?, ?)',
        [novoNoId, campo.nome, campo.tipo, campo.ordem]
      );
    }

    // Copiar registos se solicitado
    if (incluirRegistos) {
      const registos = await this.registosRepository.query(
        'SELECT * FROM registos WHERE no_id = ?',
        [noId]
      );

      for (const registo of registos) {
        await this.registosRepository.execute(
          'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
          [novoNoId, registo.utilizador_id, registo.dados]
        );
      }
    }

    // Copiar subpastas recursivamente
    const subpastas = await this.repository.query(
      'SELECT id FROM nos WHERE pai_id = ? ORDER BY id',
      [noId]
    );

    for (const subpasta of subpastas) {
      await this._copiarNoRecursivo(subpasta.id, novoNoId, novoProjetoId, incluirRegistos);
    }
  }
}

module.exports = NosService;
