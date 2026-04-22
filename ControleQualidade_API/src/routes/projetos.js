const express = require('express');
const { body, param } = require('express-validator');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const { asyncHandler } = require('../middleware/errorHandler');
const ProjetosService = require('../services/projetosService');

const router = express.Router();
const projetosService = new ProjetosService(pool);

// Validações para criar projeto
const validarCriarProjeto = [
  body('nome')
    .trim()
    .notEmpty()
    .withMessage('nome é obrigatório')
    .isLength({ max: 255 })
    .withMessage('nome demasiado longo (máx. 255 caracteres)'),
  body('descricao')
    .optional()
    .isString()
    .isLength({ max: 1000 })
    .withMessage('descrição demasiado longa (máx. 1000 caracteres)'),
  validate
];

// Validações para atualizar projeto
const validarAtualizarProjeto = [
  param('id').isInt({ min: 1 }).withMessage('ID do projeto inválido'),
  body('nome')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('nome não pode estar vazio')
    .isLength({ max: 255 })
    .withMessage('nome demasiado longo (máx. 255 caracteres)'),
  body('descricao')
    .optional()
    .isString()
    .isLength({ max: 1000 })
    .withMessage('descrição demasiado longa (máx. 1000 caracteres)'),
  validate
];

// Validações para parâmetros de ID
const validarIdProjeto = [
  param('id').isInt({ min: 1 }).withMessage('ID do projeto inválido'),
  validate
];

const validarUserIdProjeto = [
  param('userId').isInt({ min: 1 }).withMessage('ID do utilizador inválido'),
  validate
];

// ─── CRIAR PROJETO ─────────────────────────────────────────
router.post('/', requireAuth, validarCriarProjeto, asyncHandler(async (req, res) => {
  const { nome, descricao, criado_por } = req.body;

  const result = await projetosService.createProjeto(nome, descricao, criado_por);
  res.json(result);
}));

// ─── OBTER PROJETOS DO TRABALHADOR ─────────────────────────
router.get('/trabalhador/:userId', requireAuth, validarUserIdProjeto, asyncHandler(async (req, res) => {
  const { userId } = req.params;

  const result = await projetosService.getByTrabalhadorId(userId);
  res.json(result);
}));

// ─── CONTAGEM DE NÓS E REGISTOS ────────────────────────────
router.get('/:id/contagem', requireAuth, validarIdProjeto, asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await projetosService.getStats(id);
  res.json(result);
}));

// ─── OBTER PROJETOS DE UM UTILIZADOR ───────────────────────
router.get('/:userId', requireAuth, validarUserIdProjeto, asyncHandler(async (req, res) => {
  const { userId } = req.params;

  const result = await projetosService.getByUserId(userId);
  res.json(result);
}));

// ─── ATUALIZAR PROJETO ─────────────────────────────────────
router.put('/:id', requireAuth, validarAtualizarProjeto, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { nome, descricao } = req.body;

  const result = await projetosService.updateProjeto(id, nome, descricao);
  res.json(result);
}));

// ─── DELETAR PROJETO (seguro com CASCADE DELETE no schema) ──
router.delete('/:id', requireAuth, validarIdProjeto, asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await projetosService.deleteProjeto(id);
  res.json(result);
}));

// ─── COPIAR PROJETO ───────────────────────────────────────
router.post('/:id/copiar', requireAuth, validarIdProjeto, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { nome, criado_por } = req.body;

  const result = await projetosService.copyProjeto(id, nome, criado_por, true);
  res.json(result);
}));

module.exports = router;