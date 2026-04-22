const express = require('express');
const { body, param } = require('express-validator');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

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
router.post('/', requireAuth, validarCriarProjeto, async (req, res) => {
  const { nome, descricao, criado_por } = req.body;
  try {
    const [result] = await pool.execute(
      'INSERT INTO projetos (nome, descricao, criado_por) VALUES (?, ?, ?)',
      [nome, descricao, criado_por]
    );
    logger.success(`Projeto criado: ${nome} (ID: ${result.insertId})`);
    res.json({ success: true, id: result.insertId });
  } catch (error) {
    logger.error('Erro em POST /projetos', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── OBTER PROJETOS DO TRABALHADOR ─────────────────────────
router.get('/trabalhador/:userId', requireAuth, validarUserIdProjeto, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT p.* FROM projetos p
       INNER JOIN utilizador_projeto up ON p.id = up.projeto_id
       WHERE up.utilizador_id = ?
       ORDER BY p.criado_em DESC`,
      [req.params.userId]
    );
    logger.success(`${rows.length} projetos obtidos para utilizado ${req.params.userId}`);
    res.json({ success: true, projetos: rows });
  } catch (error) {
    logger.error('Erro em GET /projetos/trabalhador/:userId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── CONTAGEM DE NÓS E REGISTOS ────────────────────────────
router.get('/:id/contagem', requireAuth, validarIdProjeto, async (req, res) => {
  try {
    const [nos] = await pool.execute('SELECT COUNT(*) as total_nos FROM nos WHERE projeto_id = ?', [req.params.id]);
    const [registos] = await pool.execute(
      `SELECT COUNT(*) as total_registos FROM registos r
       JOIN nos n ON r.no_id = n.id WHERE n.projeto_id = ?`,
      [req.params.id]
    );
    res.json({ success: true, total_nos: nos[0].total_nos, total_registos: registos[0].total_registos });
  } catch (error) {
    logger.error('Erro em GET /projetos/:id/contagem', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── OBTER PROJETOS DE UM UTILIZADOR ───────────────────────
router.get('/:userId', requireAuth, validarUserIdProjeto, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT * FROM projetos WHERE criado_por = ? ORDER BY criado_em DESC',
      [req.params.userId]
    );
    logger.success(`${rows.length} projetos obtidos para utilizador ${req.params.userId}`);
    res.json({ success: true, projetos: rows });
  } catch (error) {
    logger.error('Erro em GET /projetos/:userId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── ATUALIZAR PROJETO ─────────────────────────────────────
router.put('/:id', requireAuth, validarAtualizarProjeto, async (req, res) => {
  const { nome, descricao } = req.body;
  try {
    await pool.execute('UPDATE projetos SET nome = ?, descricao = ? WHERE id = ?', [nome, descricao, req.params.id]);
    logger.success(`Projeto ${req.params.id} atualizado`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em PUT /projetos/:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── DELETAR PROJETO ───────────────────────────────────────
router.delete('/:id', requireAuth, validarIdProjeto, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const projetoId = req.params.id;
    logger.info(`Eliminando projeto ${projetoId}...`);
    
    await connection.execute('SET FOREIGN_KEY_CHECKS = 0');
    const [nos] = await connection.execute('SELECT id FROM nos WHERE projeto_id = ?', [projetoId]);
    const nosIds = nos.map(n => n.id);
    
    if (nosIds.length > 0) {
      const placeholders = nosIds.map(() => '?').join(',');
      await connection.execute(`DELETE FROM registos WHERE no_id IN (${placeholders})`, nosIds);
      await connection.execute(`DELETE FROM campos_dinamicos WHERE no_id IN (${placeholders})`, nosIds);
      await connection.execute(`DELETE FROM utilizador_no WHERE no_id IN (${placeholders})`, nosIds);
    }
    
    await connection.execute('DELETE FROM nos WHERE projeto_id = ?', [projetoId]);
    await connection.execute('DELETE FROM utilizador_projeto WHERE projeto_id = ?', [projetoId]);
    await connection.execute('DELETE FROM projetos WHERE id = ?', [projetoId]);
    await connection.execute('SET FOREIGN_KEY_CHECKS = 1');
    
    logger.success(`Projeto ${projetoId} eliminado`);
    res.json({ success: true, nosApagados: nosIds.length });
  } catch (error) {
    logger.error('Erro em DELETE /projetos/:id', error);
    try {
      await connection.execute('SET FOREIGN_KEY_CHECKS = 1');
    } catch (e) {}
    res.status(500).json({ success: false, error: error.message });
  } finally {
    if (connection) connection.release();
  }
});

// ─── COPIAR PROJETO ───────────────────────────────────────
router.post('/:id/copiar', requireAuth, validarIdProjeto, async (req, res) => {
  const { nome, criado_por } = req.body;
  try {
    logger.info(`Copiando projeto ${req.params.id} → "${nome}"`);
    const [result] = await pool.execute(
      'INSERT INTO projetos (nome, descricao, criado_por) SELECT ?, descricao, ? FROM projetos WHERE id = ?',
      [nome, criado_por, req.params.id]
    );
    const novoProjetoId = result.insertId;
    const [nosRaiz] = await pool.execute('SELECT id FROM nos WHERE projeto_id = ? AND pai_id IS NULL', [req.params.id]);
    
    for (const no of nosRaiz) {
      await copiarNoRecursivo(pool, no.id, null, novoProjetoId, false, true, true);
    }
    
    logger.success(`Projeto copiado para ${novoProjetoId}`);
    res.json({ success: true, id: novoProjetoId });
  } catch (error) {
    logger.error('Erro em POST /projetos/:id/copiar', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ────────────────────────────────────────────────────────────
// FUNÇÃO AUXILIAR
// ────────────────────────────────────────────────────────────

async function copiarNoRecursivo(conn, noId, novoPaiId, novoProjetoId, incluirRegistos, incluirSubpastas, incluirCampos, isPrimeiroNo = false) {
  const [nos] = await conn.execute('SELECT * FROM nos WHERE id = ?', [noId]);
  if (nos.length === 0) return;
  const no = nos[0];
  const nomeFinal = isPrimeiroNo ? `${no.nome} (Cópia)` : no.nome;

  const [res] = await conn.execute(
    'INSERT INTO nos (projeto_id, pai_id, nome) VALUES (?, ?, ?)',
    [novoProjetoId, novoPaiId, nomeFinal]
  );
  const novoNoId = res.insertId;

  if (incluirCampos) {
    const [campos] = await conn.execute(
      'SELECT * FROM campos_dinamicos WHERE no_id = ? ORDER BY ordem ASC',
      [noId]
    );
    for (const campo of campos) {
      await conn.execute(
        'INSERT INTO campos_dinamicos (no_id, nome_campo, tipo_campo, opcoes, obrigatorio, ordem) VALUES (?, ?, ?, ?, ?, ?)',
        [novoNoId, campo.nome_campo, campo.tipo_campo, campo.opcoes || null, campo.obrigatorio, campo.ordem]
      );
    }
  }

  if (incluirRegistos) {
    const [regs] = await conn.execute('SELECT * FROM registos WHERE no_id = ?', [noId]);
    for (const r of regs) {
      await conn.execute(
        'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
        [novoNoId, r.utilizador_id, r.dados]
      );
    }
  }

  if (incluirSubpastas) {
    const [filhos] = await conn.execute('SELECT id FROM nos WHERE pai_id = ?', [noId]);
    for (const f of filhos) {
      await copiarNoRecursivo(conn, f.id, novoNoId, novoProjetoId, incluirRegistos, incluirSubpastas, incluirCampos, false);
    }
  }
}

module.exports = router;
