const express = require('express');
const { body, param, query } = require('express-validator');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const { upload, handleUploadError } = require('../config/upload');
const { asyncHandler } = require('../middleware/errorHandler');
const RegistosService = require('../services/registosService');

const router = express.Router();
const registosService = new RegistosService(pool);

// Validações para GET registos
const validarObterRegistos = [
  param('noId').isInt({ min: 1 }).withMessage('ID do nó inválido'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('limit deve ser entre 1 e 100'),
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('page deve ser um inteiro positivo'),
  query('search')
    .optional()
    .isString()
    .trim()
    .isLength({ max: 500 })
    .withMessage('search demasiado longo'),
  query('filtroColuna')
    .optional()
    .isString()
    .isLength({ max: 100 })
    .withMessage('filtroColuna demasiado longo'),
  validate
];

// Validações para POST registo
const validarCriarRegisto = [
  body('no_id')
    .notEmpty().withMessage('no_id é obrigatório')
    .customSanitizer(value => parseInt(value))
    .isInt({ min: 1 }).withMessage('no_id deve ser um inteiro positivo'),
  body('dados_json')
    .notEmpty().withMessage('dados_json é obrigatório'),
  validate
];

// ─── OBTER REGISTOS ───────────────────────────────────────
router.get('/:noId', requireAuth, validarObterRegistos, asyncHandler(async (req, res) => {
  const { noId } = req.params;
  const limit = parseInt(req.query.limit) || 30;
  const page = parseInt(req.query.page) || 1;
  const search = req.query.search || '';
  const filtroColuna = req.query.filtroColuna || null;

  const result = await registosService.getRegistos(noId, limit, page, search, filtroColuna);
  res.json({
    ...result,
    registos: result.data
  });
}));

// ─── CRIAR REGISTO (com upload de ficheiros) ───────────────
router.post('/', requireAuth, (req, res, next) => {
  upload.any()(req, res, (err) => {   // ← aceita ficheiros com qualquer nome de campo
    if (err) {
      return res.status(400).json({
        success: false,
        error: err.message,
        code: err.code || 'UPLOAD_ERROR'
      });
    }
    next();
  });
}, validarCriarRegisto, asyncHandler(async (req, res) => {
  const { no_id, utilizador_id, dados_json } = req.body;

  const result = await registosService.createRegisto(
    no_id,
    utilizador_id,
    dados_json,
    req.files || []
  );

  res.json(result);
}));

module.exports = router;