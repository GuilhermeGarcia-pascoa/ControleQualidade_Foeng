const express = require('express');
const { body, param } = require('express-validator');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// Validações para parâmetros de ID
const validarNoId = [
  param('noId').isInt({ min: 1 }).withMessage('ID do nó inválido'),
  validate
];

const validarProjetoIdNos = [
  param('projetoId').isInt({ min: 1 }).withMessage('ID do projeto inválido'),
  validate
];

const validarNoIdPath = [
  param('id').isInt({ min: 1 }).withMessage('ID do nó inválido'),
  validate
];

const validarUserIdNos = [
  param('userId').isInt({ min: 1 }).withMessage('ID do utilizador inválido'),
  validate
];

// Validações para criar nó
const validarCriarNo = [
  body('projeto_id')
    .isInt({ min: 1 })
    .withMessage('projeto_id deve ser um inteiro positivo'),
  body('nome')
    .trim()
    .notEmpty()
    .withMessage('nome é obrigatório')
    .isLength({ max: 255 })
    .withMessage('nome demasiado longo (máx. 255 caracteres)'),
  body('pai_id').optional({ nullable: true }).isInt({ min: 1 }).withMessage('pai_id inválido'),
  validate
];

// Validações para atualizar nó
const validarAtualizarNo = [
  param('id').isInt({ min: 1 }).withMessage('ID do nó inválido'),
  body('nome')
    .trim()
    .notEmpty()
    .withMessage('nome é obrigatório')
    .isLength({ max: 255 })
    .withMessage('nome demasiado longo (máx. 255 caracteres)'),
  validate
];

// Validações para mover nó
const validarMoverNo = [
  param('id').isInt({ min: 1 }).withMessage('ID do nó inválido'),
  body('pai_id')
    .optional({ nullable: true })  // ← adicionar nullable: true
    .isInt({ min: 1 })
    .withMessage('pai_id inválido'),
  validate
];

// Validações para copiar nó
const validarCopiarNo = [
  param('id').isInt({ min: 1 }).withMessage('ID do nó inválido'),
  body('novo_projeto_id')
    .optional()
    .isInt({ min: 1 })
    .withMessage('novo_projeto_id inválido'),
  body('novo_pai_id')
    .optional()
    .isInt({ min: 1 })
    .withMessage('novo_pai_id inválido'),
  body('incluir_registos')
    .optional()
    .isBoolean()
    .withMessage('incluir_registos deve ser um booleano'),
  body('incluir_subpastas')
    .optional()
    .isBoolean()
    .withMessage('incluir_subpastas deve ser um booleano'),
  body('incluir_campos')
    .optional()
    .isBoolean()
    .withMessage('incluir_campos deve ser um booleano'),
  validate
];

// ─── OBTER ANCESTRAIS ─────────────────────────────────────
// IMPORTANTE: Rotas específicas SEMPRE antes das genéricas (/:projetoId)
router.get('/:noId/ancestrais', requireAuth, validarNoId, async (req, res) => {
  const { noId } = req.params;
  try {
    logger.info(`[ancestrais] Obtendo para noId=${noId}`);
    const ancestrais = [];
    let idAtual = parseInt(noId);

    while (true) {
      const [rows] = await pool.query('SELECT * FROM nos WHERE id = ?', [idAtual]);
      if (rows.length === 0) break;
      const no = rows[0];
      if (no.id !== parseInt(noId)) ancestrais.push(no);
      if (no.pai_id === null) break;
      idAtual = no.pai_id;
    }

    logger.success(`[ancestrais] ${ancestrais.length} ancestrais para noId=${noId}`);
    res.json({ ancestrais });
  } catch (err) {
    logger.error('Erro em GET /:noId/ancestrais', err);
    res.status(500).json({ error: 'Erro interno ao obter ancestrais.' });
  }
});

// ─── OBTER DESCENDENTES ───────────────────────────────────
router.get('/:noId/descendentes', requireAuth, validarNoId, async (req, res) => {
  const { noId } = req.params;
  try {
    const descendentes = [];
    async function recolherDescendentes(paiId) {
      const [filhos] = await pool.query('SELECT * FROM nos WHERE pai_id = ?', [paiId]);
      for (const filho of filhos) {
        descendentes.push(filho);
        await recolherDescendentes(filho.id);
      }
    }
    await recolherDescendentes(parseInt(noId));
    res.json({ descendentes });
  } catch (err) {
    logger.error('Erro em GET /:noId/descendentes', err);
    res.status(500).json({ error: 'Erro interno ao obter descendentes.' });
  }
});

// ─── OBTER INFORMAÇÃO DO NÓ ───────────────────────────────
router.get('/info/:noId', requireAuth, validarNoId, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, projeto_id, pai_id, nome FROM nos WHERE id = ?',
      [req.params.noId]
    );
    if (rows.length > 0) {
      res.json({ success: true, ...rows[0] });
    } else {
      res.status(404).json({ success: false });
    }
  } catch (error) {
    logger.error('Erro em GET /info/:noId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── PARTILHADOS ──────────────────────────────────────────
// CRÍTICO: Esta rota DEVE estar antes de /:projetoId
// Devolve nós partilhados diretamente (via utilizador_no) E
// nós de projetos onde o utilizador é membro (via utilizador_projeto)
router.get('/partilhados/:userId', requireAuth, validarUserIdNos, async (req, res) => {
  try {
    const { userId } = req.params;
    logger.info(`[partilhados] Obtendo para userId=${userId}`);

    // 1. Nós partilhados diretamente via utilizador_no
    const [nosDirectos] = await pool.execute(
      `SELECT n.id, n.projeto_id, n.pai_id, n.nome, p.nome AS projeto_nome
       FROM utilizador_no un
       JOIN nos n ON n.id = un.no_id
       JOIN projetos p ON p.id = n.projeto_id
       WHERE un.utilizador_id = ?
       ORDER BY p.nome ASC, n.nome ASC`,
      [userId]
    );

    // 2. Nós raiz de projetos onde o utilizador é membro via utilizador_projeto
    // (caso o admin tenha adicionado via "Gerir Membros" do projeto)
    const [nosViaProjeto] = await pool.execute(
      `SELECT n.id, n.projeto_id, n.pai_id, n.nome, p.nome AS projeto_nome
       FROM utilizador_projeto up
       JOIN projetos p ON p.id = up.projeto_id
       JOIN nos n ON n.projeto_id = p.id AND n.pai_id IS NULL
       WHERE up.utilizador_id = ?
       ORDER BY p.nome ASC, n.nome ASC`,
      [userId]
    );

    // 3. Merge sem duplicados (preferir os diretos)
    const idsDiretos = new Set(nosDirectos.map(n => n.id));
    const nosViaProjFiltrados = nosViaProjeto.filter(n => !idsDiretos.has(n.id));
    const todosNos = [...nosDirectos, ...nosViaProjFiltrados];

    // 4. Calcular breadcrumb para cada nó
    async function getBreadcrumb(paiId) {
      const breadcrumb = [];
      let atual = paiId;
      while (atual !== null && atual !== undefined) {
        const [rows] = await pool.execute(
          'SELECT id, nome, pai_id FROM nos WHERE id = ?',
          [atual]
        );
        if (rows.length === 0) break;
        breadcrumb.unshift(rows[0].nome);
        atual = rows[0].pai_id;
      }
      return breadcrumb;
    }

    const resultado = [];
    for (const no of todosNos) {
      const breadcrumb = await getBreadcrumb(no.pai_id);
      resultado.push({
        id: no.id,
        nome: no.nome,
        projeto_id: no.projeto_id,
        projeto_nome: no.projeto_nome,
        pai_id: no.pai_id,
        breadcrumb,
      });
    }

    logger.success(`[partilhados] ${resultado.length} pastas para userId=${userId} (${nosDirectos.length} diretas + ${nosViaProjFiltrados.length} via projeto)`);
    res.json({ success: true, nos: resultado });
  } catch (error) {
    logger.error('Erro em GET /partilhados/:userId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── OBTER TODOS OS NÓS DE UM PROJETO ──────────────────────
router.get('/:projetoId/todos', requireAuth, validarProjetoIdNos, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT * FROM nos WHERE projeto_id = ? ORDER BY nome ASC',
      [req.params.projetoId]
    );
    res.json({ success: true, nos: rows });
  } catch (error) {
    logger.error('Erro em GET /:projetoId/todos', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── NÓS COM ACESSO ───────────────────────────────────────
router.get('/:projetoId/acesso/:userId', requireAuth, async (req, res) => {
  const { projetoId, userId } = req.params;
  // Validação manual para esta rota que tem múltiplos parâmetros
  if (!Number.isInteger(parseInt(projetoId)) || parseInt(projetoId) < 1 ||
      !Number.isInteger(parseInt(userId)) || parseInt(userId) < 1) {
    return res.status(400).json({
      success: false,
      errors: [
        { campo: 'projetoId', mensagem: 'ID do projeto inválido' },
        { campo: 'userId', mensagem: 'ID do utilizador inválido' }
      ]
    });
  }
  try {
    const [diretos] = await pool.query(
      `SELECT n.id FROM utilizador_no un
       JOIN nos n ON n.id = un.no_id
       WHERE un.utilizador_id = ? AND n.projeto_id = ?`,
      [userId, projetoId]
    );
    const idsComAcesso = new Set(diretos.map(r => r.id));

    // Incluir também todos os nós do projeto se o utilizador for membro via utilizador_projeto
    const [membroProjeto] = await pool.query(
      'SELECT id FROM utilizador_projeto WHERE utilizador_id = ? AND projeto_id = ?',
      [userId, projetoId]
    );
    if (membroProjeto.length > 0) {
      const [todosNos] = await pool.query(
        'SELECT id FROM nos WHERE projeto_id = ?',
        [projetoId]
      );
      todosNos.forEach(n => idsComAcesso.add(n.id));
    }

    async function adicionarDescendentes(paiId) {
      const [filhos] = await pool.query('SELECT id FROM nos WHERE pai_id = ?', [paiId]);
      for (const filho of filhos) {
        idsComAcesso.add(filho.id);
        await adicionarDescendentes(filho.id);
      }
    }
    for (const { id } of diretos) await adicionarDescendentes(id);

    async function adicionarAncestral(noId) {
      const [rows] = await pool.query('SELECT id, pai_id FROM nos WHERE id = ?', [noId]);
      if (rows.length > 0 && rows[0].pai_id !== null) {
        idsComAcesso.add(rows[0].pai_id);
        await adicionarAncestral(rows[0].pai_id);
      }
    }
    for (const { id } of diretos) await adicionarAncestral(id);

    res.json({ success: true, nos_com_acesso: [...idsComAcesso] });
  } catch (err) {
    logger.error('Erro em GET /:projetoId/acesso/:userId', err);
    res.status(500).json({ error: 'Erro interno ao obter acessos.' });
  }
});

// ─── CRIAR NÓ ──────────────────────────────────────────────
router.post('/', requireAuth, validarCriarNo, async (req, res) => {
  const { projeto_id, pai_id, nome } = req.body;
  try {
    const [result] = await pool.execute(
      'INSERT INTO nos (projeto_id, pai_id, nome) VALUES (?, ?, ?)',
      [projeto_id, pai_id || null, nome]
    );
    logger.success(`Nó criado: ${nome} (ID: ${result.insertId})`);
    res.json({ success: true, id: result.insertId });
  } catch (error) {
    logger.error('Erro em POST /nos', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── ATUALIZAR NÓ ─────────────────────────────────────────
router.put('/:id', requireAuth, validarAtualizarNo, async (req, res) => {
  const { nome } = req.body;
  try {
    await pool.execute('UPDATE nos SET nome = ? WHERE id = ?', [nome, req.params.id]);
    logger.success(`Nó ${req.params.id} atualizado`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em PUT /nos/:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── MOVER NÓ ─────────────────────────────────────────────
router.put('/:id/mover', requireAuth, validarMoverNo, async (req, res) => {
  const { pai_id } = req.body;
  try {
    await pool.execute('UPDATE nos SET pai_id = ? WHERE id = ?', [pai_id || null, req.params.id]);
    logger.success(`Nó ${req.params.id} movido`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em PUT /nos/:id/mover', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── DELETAR NÓ ───────────────────────────────────────────
router.delete('/:id', requireAuth, validarNoIdPath, async (req, res) => {
  try {
    await pool.execute('DELETE FROM nos WHERE id = ?', [req.params.id]);
    logger.success(`Nó ${req.params.id} eliminado`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em DELETE /nos/:id', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── DUPLICAR  NÓ ─────────────────────────────────────────────
router.post('/:id/duplicar', requireAuth, validarCopiarNo, async (req, res) => {
  const { novo_pai_id, novo_projeto_id, incluir_registos, incluir_subpastas, incluir_campos } = req.body;
  try {
    const [nos] = await pool.execute('SELECT projeto_id FROM nos WHERE id = ?', [req.params.id]);
    if (nos.length === 0) return res.status(404).json({ success: false, error: 'Nó não encontrado' });

    const projetoId = novo_projeto_id || nos[0].projeto_id;
    const copiarSubpastas = incluir_subpastas !== false;
    const copiarCampos = incluir_campos !== false;
    const copiarRegistos = incluir_registos === true;

    await copiarNoRecursivo(pool, req.params.id, novo_pai_id || null, projetoId, copiarRegistos, copiarSubpastas, copiarCampos, true);
    logger.success(`Nó ${req.params.id} copiado`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em POST /nos/:id/copiar', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── NÓS POR PROJETO (genérica) — DEVE SER A ÚLTIMA ────────
router.get('/:projetoId', requireAuth, validarProjetoIdNos, async (req, res) => {
  const { projetoId } = req.params;
  const { pai_id } = req.query;
  try {
    let rows;
    if (pai_id === undefined || pai_id === 'null' || pai_id === '') {
      [rows] = await pool.execute(
        'SELECT * FROM nos WHERE projeto_id = ? AND pai_id IS NULL ORDER BY nome ASC',
        [projetoId]
      );
    } else {
      [rows] = await pool.execute(
        'SELECT * FROM nos WHERE projeto_id = ? AND pai_id = ? ORDER BY nome ASC',
        [projetoId, pai_id]
      );
    }
    res.json({ success: true, nos: rows });
  } catch (error) {
    logger.error('Erro em GET /:projetoId', error);
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