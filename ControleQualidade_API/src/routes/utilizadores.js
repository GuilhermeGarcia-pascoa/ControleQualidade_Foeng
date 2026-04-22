const express = require('express');
const { body, param, query } = require('express-validator');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const validate = require('../middleware/validate');
const { hashPassword } = require('../utils/hash');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Validações para criar utilizador
const validarCriarUtilizador = [
  body('nome')
    .trim()
    .notEmpty()
    .withMessage('nome é obrigatório')
    .isLength({ max: 255 })
    .withMessage('nome demasiado longo (máx. 255 caracteres)'),
  body('email')
    .isEmail()
    .withMessage('email inválido')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('password é obrigatória')
    .isLength({ min: 4 })
    .withMessage('password demasiado curta (mín. 4 caracteres)'),
  body('perfil')
    .optional()
    .isIn(['admin', 'trabalhador', 'utilizador'])
    .withMessage('perfil inválido'),
  validate
];

// Validações para registar utilizador
const validarRegistarUtilizador = [
  body('nome')
    .trim()
    .notEmpty()
    .withMessage('nome é obrigatório')
    .isLength({ max: 255 })
    .withMessage('nome demasiado longo'),
  body('email')
    .isEmail()
    .withMessage('email inválido')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('password é obrigatória')
    .isLength({ min: 4 })
    .withMessage('password demasiado curta (mín. 4 caracteres)'),
  body('perfil')
    .optional()
    .isIn(['admin', 'trabalhador', 'utilizador'])
    .withMessage('perfil inválido'),
  validate
];

// Validações para alterar senha
const validarAlterarSenha = [
  param('id').isInt({ min: 1 }).withMessage('ID do utilizador inválido'),
  body('password')
    .notEmpty()
    .withMessage('password é obrigatória')
    .isLength({ min: 4 })
    .withMessage('password demasiado curta (mín. 4 caracteres)'),
  validate
];

// Validações para editar utilizador
const validarEditarUtilizador = [
  param('id').isInt({ min: 1 }).withMessage('ID do utilizador inválido'),
  body('nome')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('nome não pode estar vazio')
    .isLength({ max: 255 })
    .withMessage('nome demasiado longo (máx. 255 caracteres)'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('email inválido')
    .normalizeEmail(),
  body('perfil')
    .optional()
    .isIn(['admin', 'trabalhador', 'utilizador'])
    .withMessage('perfil inválido'),
  validate
];

// Validações para parâmetros
const validarIdUtilizador = [
  param('id').isInt({ min: 1 }).withMessage('ID do utilizador inválido'),
  validate
];

const validarEmailParam = [
  param('email').isEmail().withMessage('email inválido').normalizeEmail(),
  validate
];

const validarTextoSearch = [
  param('texto')
    .trim()
    .notEmpty()
    .withMessage('texto de busca é obrigatório')
    .isLength({ max: 100 })
    .withMessage('texto demasiado longo'),
  validate
];

// ─── LISTAR TODOS ───────────────────────────────────────────────────
router.get('/', requireAuth, requireAdmin, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, nome, email, perfil FROM utilizadores'
    );
    logger.success(`Listagem de utilizadores: ${rows.length} resultados`);
    res.json({ success: true, utilizadores: rows });
  } catch (error) {
    logger.error('Erro em GET /', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── CRIAR UTILIZADOR ─────────────────────────────────────────────
router.post('/', requireAuth, requireAdmin, validarCriarUtilizador, async (req, res) => {
  const { nome, email, password, perfil } = req.body;

  try {
    const [existe] = await pool.execute(
      'SELECT id FROM utilizadores WHERE email = ?',
      [email]
    );

    if (existe.length > 0) {
      return res.status(409).json({ success: false, message: 'Email já registado' });
    }

    const hashedPassword = await hashPassword(password);

    const [result] = await pool.execute(
      'INSERT INTO utilizadores (nome, email, password, perfil) VALUES (?, ?, ?, ?)',
      [nome, email, hashedPassword, perfil || 'utilizador']
    );

    logger.success(`Novo utilizador criado: ${email}`);
    res.status(201).json({
      success: true,
      utilizador: { id: result.insertId, nome, email, perfil: perfil || 'utilizador' },
    });
  } catch (error) {
    logger.error('Erro em POST /', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── REGISTO ──────────────────────────────────────────────────────
router.post('/registar', validarRegistarUtilizador, async (req, res) => {
  const { nome, email, password, perfil } = req.body;

  try {
    const [existe] = await pool.execute(
      'SELECT id FROM utilizadores WHERE email = ?',
      [email]
    );

    if (existe.length > 0) {
      return res.status(409).json({ success: false, message: 'Email já registado' });
    }

    const hashedPassword = await hashPassword(password);

    const [result] = await pool.execute(
      'INSERT INTO utilizadores (nome, email, password, perfil) VALUES (?, ?, ?, ?)',
      [nome, email, hashedPassword, perfil || 'utilizador']
    );

    logger.success(`Novo utilizador registado: ${email}`);
    res.status(201).json({
      success: true,
      utilizador: { id: result.insertId, nome, email, perfil: perfil || 'utilizador' },
    });
  } catch (error) {
    logger.error('Erro em POST /utilizadores/registar', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── BUSCAR POR EMAIL ─────────────────────────────────────
router.get('/email/:email', validarEmailParam, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, nome, email, perfil FROM utilizadores WHERE email = ?',
      [req.params.email]
    );
    if (rows.length > 0) {
      res.json({ success: true, utilizador: rows[0] });
    } else {
      res.status(404).json({ success: false, message: 'Utilizador não encontrado' });
    }
  } catch (error) {
    logger.error('Erro em GET /email/:email', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── ALTERAR SENHA ────────────────────────────────────────────────────
router.put('/:id/senha', requireAuth, validarAlterarSenha, async (req, res) => {
  const { password } = req.body;

  try {
    const hashedPassword = await hashPassword(password);
    await pool.execute(
      'UPDATE utilizadores SET password = ? WHERE id = ?',
      [hashedPassword, req.params.id]
    );
    logger.success(`Senha atualizada para utilizador ${req.params.id}`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em PUT /:id/senha', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── TEMA ─────────────────────────────────────────────────
router.get('/:id/tema', requireAuth, validarIdUtilizador, async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT tema_escuro FROM utilizadores WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ success: false });
    res.json({ success: true, tema_escuro: rows[0].tema_escuro === 1 });
  } catch (e) {
    logger.error('Erro em GET /:id/tema', e);
    res.status(500).json({ success: false, error: e.message });
  }
});

router.put('/:id/tema', requireAuth, validarIdUtilizador, async (req, res) => {
  try {
    const { tema_escuro } = req.body;
    await pool.execute('UPDATE utilizadores SET tema_escuro = ? WHERE id = ?', [tema_escuro ? 1 : 0, req.params.id]);
    logger.success(`Tema atualizado para utilizador ${req.params.id}`);
    res.json({ success: true });
  } catch (e) {
    logger.error('Erro em PUT /:id/tema', e);
    res.status(500).json({ success: false, error: e.message });
  }
});

// ─── EDITAR UTILIZADOR ────────────────────────────────────────────────
router.put('/:id', requireAuth, requireAdmin, validarEditarUtilizador, async (req, res) => {
  const { nome, email, perfil } = req.body;

  try {
    // Verificar se o email já existe (excepto para o utilizador atual)
    const [existe] = await pool.execute(
      'SELECT id FROM utilizadores WHERE email = ? AND id != ?',
      [email, req.params.id]
    );

    if (existe.length > 0) {
      return res.status(409).json({ success: false, message: 'Email já registado' });
    }

    await pool.execute(
      'UPDATE utilizadores SET nome = ?, email = ?, perfil = ? WHERE id = ?',
      [nome, email, perfil || 'utilizador', req.params.id]
    );

    logger.success(`Utilizador ${req.params.id} atualizado`);
    res.json({ success: true, utilizador: { id: parseInt(req.params.id), nome, email, perfil: perfil || 'utilizador' } });
  } catch (error) {
    logger.error('Erro em PUT /:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── APAGAR UTILIZADOR ───────────────────────────────────────────────
router.delete('/:id', requireAuth, requireAdmin, validarIdUtilizador, async (req, res) => {
  try {
    await pool.execute('DELETE FROM utilizadores WHERE id = ?', [req.params.id]);
    logger.success(`Utilizador eliminado: ${req.params.id}`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em DELETE /:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── PESQUISAR POR TEXTO (nome ou email) ───────────────────────────────────
router.get('/pesquisar/:texto', validarTextoSearch, async (req, res) => {
  try {
    const texto = `%${req.params.texto}%`;
    const [rows] = await pool.execute(
      `SELECT id, nome, email, perfil
       FROM utilizadores
       WHERE nome LIKE ? OR email LIKE ?
       ORDER BY nome ASC
       LIMIT 10`,
      [texto, texto]
    );
    logger.success(`Pesquisa "${req.params.texto}": ${rows.length} resultados`);
    res.json({ success: true, utilizadores: rows });
  } catch (error) {
    logger.error('Erro em GET /utilizadores/pesquisar/:texto', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
