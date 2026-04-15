const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');

const router = express.Router();

// ─── AUDITORIA DE CAMPOS ───────────────────────────────────
router.get('/audit/campos-por-no', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.execute(`
      SELECT cd.no_id, COUNT(*) as total_campos, n.nome as nome_no, n.projeto_id
      FROM campos_dinamicos cd
      LEFT JOIN nos n ON cd.no_id = n.id
      GROUP BY cd.no_id ORDER BY total_campos DESC LIMIT 20
    `);
    logger.success(`Auditoria de campos concluída: ${result.length} nós analisados`);
    res.json({ success: true, auditoria: result });
  } catch (error) {
    logger.error('Erro em GET /database/audit/campos-por-no', error);
    res.status(500).json({ success: false, error: error.message });
  } finally {
    connection.release();
  }
});

// ─── VERIFICAR CAMPOS ÓRFÃOS ───────────────────────────────
router.get('/cleanup/orphaned-campos', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.execute(
      'SELECT COUNT(*) as count FROM campos_dinamicos WHERE no_id NOT IN (SELECT id FROM nos)'
    );
    logger.info(`Campos órfãos encontrados: ${result[0].count}`);
    res.json({ success: true, orphanedCount: result[0].count });
  } catch (error) {
    logger.error('Erro em GET /database/cleanup/orphaned-campos', error);
    res.status(500).json({ success: false, error: error.message });
  } finally {
    connection.release();
  }
});

// ─── LIMPAR CAMPOS ÓRFÃOS ──────────────────────────────────
router.post('/cleanup/orphaned-campos', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const [result] = await connection.execute(
      'DELETE FROM campos_dinamicos WHERE no_id NOT IN (SELECT id FROM nos)'
    );
    const [afterCount] = await connection.execute('SELECT COUNT(*) as count FROM campos_dinamicos');
    logger.success(`Limpeza concluída: ${result.affectedRows} registos deletados, ${afterCount[0].count} restantes`);
    res.json({ success: true, deletedCount: result.affectedRows, remainingCount: afterCount[0].count });
  } catch (error) {
    logger.error('Erro em POST /database/cleanup/orphaned-campos', error);
    res.status(500).json({ success: false, error: error.message });
  } finally {
    connection.release();
  }
});

module.exports = router;
