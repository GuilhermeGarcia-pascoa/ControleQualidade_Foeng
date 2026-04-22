const express = require('express');
const { body, param } = require('express-validator');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const validate = require('../middleware/validate');

const router = express.Router();

// Validações para parâmetros
const validarNoId = [
  param('noId').isInt({ min: 1 }).withMessage('ID do nó inválido'),
  validate
];

const validarIdCampo = [
  param('id').isInt({ min: 1 }).withMessage('ID do campo inválido'),
  validate
];

// Validações para criar campo
const validarCriarCampo = [
  body('no_id')
    .isInt({ min: 1 })
    .withMessage('no_id deve ser um inteiro positivo'),
  body('nome_campo')
    .trim()
    .notEmpty()
    .withMessage('nome_campo é obrigatório')
    .isLength({ max: 255 })
    .withMessage('nome_campo demasiado longo (máx. 255 caracteres)'),
  body('tipo_campo')
  .trim()
  .notEmpty()
  .withMessage('tipo_campo é obrigatório')
  .isIn(['text', 'email', 'number', 'date', 'checkbox', 'select', 'textarea', 'file', 'texto', 'numero', 'data', 'selecao', 'imagem'])
  .withMessage('tipo_campo inválido'),
body('opcoes')
  .optional({ nullable: true }) 
  .isString()
  .isLength({ max: 1000 })
  .withMessage('opcoes demasiado longo'),
    .withMessage('opcoes demasiado longo'),
  body('obrigatorio')
    .optional()
    .isBoolean()
    .withMessage('obrigatorio deve ser um booleano'),
  body('ordem')
    .optional()
    .isInt({ min: 0 })
    .withMessage('ordem deve ser um inteiro não-negativo'),
  validate
];

// Validações para atualizar campo
const validarAtualizarCampo = [
  param('id').isInt({ min: 1 }).withMessage('ID do campo inválido'),
  body('nome_campo')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('nome_campo não pode estar vazio')
    .isLength({ max: 255 })
    .withMessage('nome_campo demasiado longo (máx. 255 caracteres)'),
  body('tipo_campo')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('tipo_campo não pode estar vazio')
    .isIn(['text', 'email', 'number', 'date', 'checkbox', 'select', 'textarea', 'file'])
    .withMessage('tipo_campo inválido'),
  body('opcoes')
    .optional()
    .isString()
    .isLength({ max: 1000 })
    .withMessage('opcoes demasiado longo'),
  body('obrigatorio')
    .optional()
    .isBoolean()
    .withMessage('obrigatorio deve ser um booleano'),
  validate
];

// Validações para atualizar ordem
const validarAtualizarOrdem = [
  param('id').isInt({ min: 1 }).withMessage('ID do campo inválido'),
  body('ordem')
    .isInt({ min: 0 })
    .withMessage('ordem deve ser um inteiro não-negativo'),
  validate
];

// ─── OBTER CAMPOS ─────────────────────────────────────────
router.get('/:noId', validarNoId, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT * FROM campos_dinamicos WHERE no_id = ? ORDER BY ordem ASC',
      [req.params.noId]
    );
    logger.success(`${rows.length} campos obtidos para nó ${req.params.noId}`);
    res.json({ success: true, campos: rows });
  } catch (error) {
    logger.error('Erro em GET /campos/:noId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── CRIAR CAMPO ───────────────────────────────────────────
router.post('/', validarCriarCampo, async (req, res) => {
  const { no_id, nome_campo, tipo_campo, opcoes, obrigatorio, ordem } = req.body;
  try {
    const [result] = await pool.execute(
      'INSERT INTO campos_dinamicos (no_id, nome_campo, tipo_campo, opcoes, obrigatorio, ordem) VALUES (?, ?, ?, ?, ?, ?)',
      [no_id, nome_campo, tipo_campo, opcoes || null, obrigatorio ? 1 : 0, ordem]
    );
    logger.success(`Campo criado: ${nome_campo} (ID: ${result.insertId})`);
    res.json({ success: true, id: result.insertId });
  } catch (error) {
    logger.error('Erro em POST /campos', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── ATUALIZAR CAMPO ───────────────────────────────────────
router.put('/:id', validarAtualizarCampo, async (req, res) => {
  const { id } = req.params;
  const { nome_campo, tipo_campo, opcoes, obrigatorio } = req.body;
  try {
    await pool.execute(
      'UPDATE campos_dinamicos SET nome_campo = ?, tipo_campo = ?, opcoes = ?, obrigatorio = ? WHERE id = ?',
      [nome_campo, tipo_campo, opcoes || null, obrigatorio, id]
    );
    logger.success(`Campo ${id} atualizado`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em PUT /campos/:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── ATUALIZAR ORDEM DO CAMPO ──────────────────────────────
router.put('/:id/ordem', validarAtualizarOrdem, async (req, res) => {
  const { id } = req.params;
  const { ordem } = req.body;
  try {
    await pool.execute('UPDATE campos_dinamicos SET ordem = ? WHERE id = ?', [ordem, id]);
    logger.success(`Ordem do campo ${id} atualizada para ${ordem}`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em PUT /campos/:id/ordem', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── DELETAR CAMPO ─────────────────────────────────────────
router.delete('/:id', validarIdCampo, async (req, res) => {
  const { id } = req.params;
  try {
    const [result] = await pool.execute('DELETE FROM campos_dinamicos WHERE id = ?', [id]);
    if (result.affectedRows > 0) {
      logger.success(`Campo ${id} eliminado`);
      res.json({ success: true, message: 'Campo eliminado com sucesso' });
    } else {
      res.status(404).json({ success: false, error: 'Campo não encontrado' });
    }
  } catch (error) {
    logger.error('Erro em DELETE /campos/:id', error);
    
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      res.status(400).json({
        success: false,
        error: 'Não é possível apagar: existem registos que utilizam este campo.',
      });
    } else {
      res.status(500).json({ success: false, error: error.message });
    }
  }
});

module.exports = router;
