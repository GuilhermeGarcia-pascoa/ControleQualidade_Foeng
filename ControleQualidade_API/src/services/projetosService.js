const BaseService = require('./baseService');
const ProjetosRepository = require('../repositories/projetosRepository');
const NosRepository = require('../repositories/nosRepository');

/**
 * Service para Projetos
 * Responsável por lógica de negócio e orquestração
 */
class ProjetosService extends BaseService {
  constructor(pool) {
    const projetosRepository = new ProjetosRepository(pool);
    super(projetosRepository);
    this.pool = pool;
    this.nosRepository = new NosRepository(pool);
  }

  /**
   * Criar novo projeto com validação
   */
  async createProjeto(nome, descricao, criadoPor) {
    return this.execute(async () => {
      // Validações
      nome = this.validateRequired(nome, 'Nome do projeto');
      nome = this.validateStringLength(nome, 255, 'Nome');
      
      if (descricao) {
        descricao = this.validateStringLength(descricao, 1000, 'Descrição');
      }
      
      criadoPor = this.validatePositiveInt(criadoPor, 'ID do criador');

      return await this.repository.create(nome, descricao || null, criadoPor);
    }, 'createProjeto');
  }

  /**
   * Obter projeto por ID
   */
  async getProjeto(projetoId) {
    return this.execute(async () => {
      projetoId = this.validatePositiveInt(projetoId, 'Projeto ID');
      
      const projeto = await this.repository.getById(projetoId);
      if (!projeto) {
        this.error('Projeto não encontrado', 'NOT_FOUND');
      }

      return {
        success: true,
        projeto
      };
    }, 'getProjeto');
  }

  /**
   * Obter projetos de um utilizador (criador)
   */
  async getByUserId(userId) {
    return this.execute(async () => {
      userId = this.validatePositiveInt(userId, 'User ID');
      
      const projetos = await this.repository.getByUserId(userId);
      
      return {
        success: true,
        projetos,
        total: projetos.length
      };
    }, 'getByUserId');
  }

  /**
   * Obter projetos de um trabalhador
   */
  async getByTrabalhadorId(userId) {
    return this.execute(async () => {
      userId = this.validatePositiveInt(userId, 'User ID');
      
      const projetos = await this.repository.getByTrabalhadorId(userId);
      
      return {
        success: true,
        projetos,
        total: projetos.length
      };
    }, 'getByTrabalhadorId');
  }

  /**
   * Atualizar projeto
   */
  async updateProjeto(projetoId, nome, descricao) {
    return this.execute(async () => {
      projetoId = this.validatePositiveInt(projetoId, 'Projeto ID');
      
      // Verificar se existe
      const projeto = await this.repository.getById(projetoId);
      if (!projeto) {
        this.error('Projeto não encontrado', 'NOT_FOUND');
      }

      // Validações (opcionais, só valida se fornecido)
      if (nome !== undefined) {
        nome = this.validateRequired(nome, 'Nome do projeto');
        nome = this.validateStringLength(nome, 255, 'Nome');
      }

      if (descricao !== undefined) {
        descricao = this.validateStringLength(descricao, 1000, 'Descrição');
      }

      return await this.repository.update(
        projetoId,
        nome || projeto.nome,
        descricao !== undefined ? descricao : projeto.descricao
      );
    }, 'updateProjeto');
  }

  /**
   * Deletar projeto
   */
  async deleteProjeto(projetoId) {
    return this.execute(async () => {
      projetoId = this.validatePositiveInt(projetoId, 'Projeto ID');
      
      // Verificar se existe
      const projeto = await this.repository.getById(projetoId);
      if (!projeto) {
        this.error('Projeto não encontrado', 'NOT_FOUND');
      }

      return await this.repository.delete(projetoId);
    }, 'deleteProjeto');
  }

  /**
   * Copiar projeto (criar novo com nós)
   */
  async copyProjeto(projetoId, novoNome, criadoPor, incluirNos = true) {
    return this.execute(async () => {
      projetoId = this.validatePositiveInt(projetoId, 'Projeto ID');
      novoNome = this.validateRequired(novoNome, 'Novo nome');
      criadoPor = this.validatePositiveInt(criadoPor, 'ID do criador');

      // Verificar se projeto original existe
      const projetoOriginal = await this.repository.getById(projetoId);
      if (!projetoOriginal) {
        this.error('Projeto original não encontrado', 'NOT_FOUND');
      }

      // Copiar projeto
      const copiaResult = await this.repository.copy(projetoId, novoNome, criadoPor);
      const novoProjetoId = copiaResult.insertId;

      // Copiar nós se solicitado
      if (incluirNos) {
        const nosRaiz = await this.nosRepository.query(
          'SELECT id FROM nos WHERE projeto_id = ? AND pai_id IS NULL',
          [projetoId]
        );

        for (const no of nosRaiz) {
          await this._copiarNoRecursivo(no.id, null, novoProjetoId);
        }
      }

      this.logger.success(`Projeto copiado para ID ${novoProjetoId}`);

      return {
        success: true,
        id: novoProjetoId
      };
    }, 'copyProjeto');
  }

  /**
   * Obter estatísticas do projeto
   */
  async getStats(projetoId) {
    return this.execute(async () => {
      projetoId = this.validatePositiveInt(projetoId, 'Projeto ID');
      
      // Verificar se existe
      const projeto = await this.repository.getById(projetoId);
      if (!projeto) {
        this.error('Projeto não encontrado', 'NOT_FOUND');
      }

      return await this.repository.getStats(projetoId);
    }, 'getStats');
  }

  /**
   * Copiar nó recursivamente (helper privado)
   */
  async _copiarNoRecursivo(noId, novoPaiId, novoProjetoId, isPrimeiroNo = false) {
    const nos = await this.nosRepository.getById(noId);
    if (!nos) return;

    // Nome com "(Cópia)" se for primeiro nó
    const nomeFinal = isPrimeiroNo ? `${nos.nome} (Cópia)` : nos.nome;

    // Copiar nó
    const result = await this.nosRepository.execute(
      'INSERT INTO nos (projeto_id, pai_id, nome) VALUES (?, ?, ?)',
      [novoProjetoId, novoPaiId, nomeFinal]
    );
    const novoNoId = result.insertId;

    // Copiar campos dinâmicos se existem
    const campos = await this.nosRepository.query(
      'SELECT * FROM campos_dinamicos WHERE no_id = ? ORDER BY ordem ASC',
      [noId]
    );

    for (const campo of campos) {
      await this.nosRepository.execute(
        'INSERT INTO campos_dinamicos (no_id, nome, tipo, ordem) VALUES (?, ?, ?, ?)',
        [novoNoId, campo.nome, campo.tipo, campo.ordem]
      );
    }

    // Copiar subpastas
    const subpastas = await this.nosRepository.query(
      'SELECT id FROM nos WHERE pai_id = ? ORDER BY id',
      [noId]
    );

    for (const subpasta of subpastas) {
      await this._copiarNoRecursivo(subpasta.id, novoNoId, novoProjetoId);
    }
  }
}

module.exports = ProjetosService;
