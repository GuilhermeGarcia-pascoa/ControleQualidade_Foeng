const BaseService = require('./baseService');
const RegistosRepository = require('../repositories/registosRepository');

/**
 * Service para Registos
 * Responsável por lógica de negócio e orquestração
 */
class RegistosService extends BaseService {
  constructor(pool) {
    const registosRepository = new RegistosRepository(pool);
    super(registosRepository);
    this.pool = pool;
  }

  /**
   * Obter registos de um nó com validação
   */
  async getRegistos(noId, limit = 30, page = 1, search = '', filtroColuna = null) {
    return this.execute(async () => {
      // Validações
      noId = this.validatePositiveInt(noId, 'No ID');
      const { limit: validLimit, page: validPage } = this.validatePagination(limit, page);

      // Chamar repository
      return await this.repository.getByNoId(
        noId,
        validLimit,
        validPage,
        search.trim(),
        filtroColuna
      );
    }, 'getRegistos');
  }

  /**
   * Criar novo registo com validação
   */
  async createRegisto(noId, utilizadorId, dadosJson, files = []) {
    return this.execute(async () => {
      // Validações
      noId = this.validatePositiveInt(noId, 'No ID');
      
      if (!dadosJson) {
        this.error('dados_json é obrigatório', 'MISSING_DADOS');
      }

      // Parse JSON
      let dados;
      try {
        dados = typeof dadosJson === 'string' ? JSON.parse(dadosJson) : dadosJson;
      } catch (e) {
        this.error('JSON inválido em dados_json', 'INVALID_JSON');
      }

      // Adicionar caminhos dos ficheiros
      if (files && files.length > 0) {
        dados._files = files.map(f => ({
          filename: f.filename,
          originalName: f.originalname,
          mimetype: f.mimetype,
          size: f.size,
          path: `/uploads/${f.filename}`
        }));
        
        this.logger.info(`${files.length} ficheiro(s) adicionado(s) ao registo`);
      }

      // Chamar repository
      return await this.repository.create(noId, utilizadorId, dados);
    }, 'createRegisto');
  }

  /**
   * Obter registo por ID
   */
  async getRegisto(registoId) {
    return this.execute(async () => {
      registoId = this.validatePositiveInt(registoId, 'Registo ID');
      
      const registo = await this.repository.getById(registoId);
      if (!registo) {
        this.error('Registo não encontrado', 'NOT_FOUND');
      }

      return {
        success: true,
        registo
      };
    }, 'getRegisto');
  }

  /**
   * Atualizar registo
   */
  async updateRegisto(registoId, dadosJson) {
    return this.execute(async () => {
      registoId = this.validatePositiveInt(registoId, 'Registo ID');
      
      // Verificar se existe
      const registo = await this.repository.getById(registoId);
      if (!registo) {
        this.error('Registo não encontrado', 'NOT_FOUND');
      }

      // Parse JSON
      let dados;
      try {
        dados = typeof dadosJson === 'string' ? JSON.parse(dadosJson) : dadosJson;
      } catch (e) {
        this.error('JSON inválido em dados_json', 'INVALID_JSON');
      }

      // Chamar repository
      return await this.repository.update(registoId, dados);
    }, 'updateRegisto');
  }

  /**
   * Deletar registo
   */
  async deleteRegisto(registoId) {
    return this.execute(async () => {
      registoId = this.validatePositiveInt(registoId, 'Registo ID');
      
      // Verificar se existe
      const registo = await this.repository.getById(registoId);
      if (!registo) {
        this.error('Registo não encontrado', 'NOT_FOUND');
      }

      return await this.repository.delete(registoId);
    }, 'deleteRegisto');
  }

  /**
   * Contar registos de um nó
   */
  async countByNoId(noId) {
    return this.execute(async () => {
      noId = this.validatePositiveInt(noId, 'No ID');
      const total = await this.repository.countByNoId(noId);
      return { success: true, total };
    }, 'countByNoId');
  }
}

module.exports = RegistosService;
