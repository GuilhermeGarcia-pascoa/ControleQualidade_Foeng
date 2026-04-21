const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');

const router = express.Router();

// ─── DAR ACESSO A NÓ ───────────────────────────────────────
router.post('/', async (req, res) => {
  const { utilizador_id, no_id } = req.body;
  logger.info(`Dando acesso a nó ${no_id} para utilizador ${utilizador_id}`);
  try {
    await pool.execute(
      'INSERT IGNORE INTO utilizador_no (utilizador_id, no_id) VALUES (?, ?)',
      [utilizador_id, no_id]
    );
    logger.success(`Acesso ao nó ${no_id} concedido ao utilizador ${utilizador_id}`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em POST /utilizador_no', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── OBTER MEMBROS DO NÓ ───────────────────────────────────
router.get('/:noId', async (req, res) => {
  try {
    const { noId } = req.params;
    logger.info(`Obtendo membros do nó ${noId}`);
    const [rows] = await pool.execute(
      `SELECT u.id, u.nome, u.email, u.perfil
       FROM utilizadores u
       INNER JOIN utilizador_no un ON u.id = un.utilizador_id
       WHERE un.no_id = ?`,
      [noId]
    );
    logger.success(`${rows.length} membros obtidos para nó ${noId}`);
    res.json({ success: true, membros: rows });
  } catch (error) {
    logger.error('Erro em GET /utilizador_no/:noId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── VERIFICAR ACESSO A NÓ ─────────────────────────────────
router.get('/:noId/acesso/:userId', async (req, res) => {
  try {
    const { noId, userId } = req.params;
    let noAtual = parseInt(noId);
    let temAcesso = false;
    
    while (noAtual !== null) {
      const [acesso] = await pool.execute(
        'SELECT id FROM utilizador_no WHERE no_id = ? AND utilizador_id = ?',
        [noAtual, userId]
      );
      if (acesso.length > 0) {
        temAcesso = true;
        break;
      }
      const [pai] = await pool.execute('SELECT pai_id FROM nos WHERE id = ?', [noAtual]);
      if (pai.length === 0 || pai[0].pai_id === null) break;
      noAtual = pai[0].pai_id;
    }
    
    res.json({ success: true, temAcesso });
  } catch (error) {
    logger.error('Erro em GET /utilizador_no/:noId/acesso/:userId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── REMOVER ACESSO A NÓ ───────────────────────────────────
router.delete('/:noId/:utilizadorId', async (req, res) => {
  try {
    await pool.execute(
      'DELETE FROM utilizador_no WHERE no_id = ? AND utilizador_id = ?',
      [req.params.noId, req.params.utilizadorId]
    );
    logger.success(`Acesso ao nó ${req.params.noId} removido do utilizador ${req.params.utilizadorId}`);
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em DELETE /utilizador_no/:noId/:utilizadorId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
