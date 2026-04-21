const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');

const router = express.Router();

router.post('/', async (req, res) => {
  const { utilizador_id, projeto_id } = req.body;
  logger.info(`Adicionando utilizador ${utilizador_id} ao projeto ${projeto_id}`);

  try {
    const [utilizadores] = await pool.execute(
      'SELECT perfil FROM utilizadores WHERE id = ?',
      [utilizador_id]
    );

    if (utilizadores.length === 0) {
      return res
        .status(404)
        .json({ success: false, error: 'Utilizador nao encontrado.' });
    }

    if (
      utilizadores[0].perfil === 'admin' ||
      utilizadores[0].perfil === 'gestor'
    ) {
      return res.status(400).json({
        success: false,
        error: 'Administradores e gestores ja tem acesso a todos os projetos.',
      });
    }

    await pool.execute(
      'INSERT IGNORE INTO utilizador_projeto (utilizador_id, projeto_id) VALUES (?, ?)',
      [utilizador_id, projeto_id]
    );

    logger.success(
      `Utilizador ${utilizador_id} adicionado ao projeto ${projeto_id}`
    );
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro em POST /utilizador_projeto', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/:projetoId', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT u.id, u.nome, u.email, u.perfil
       FROM utilizadores u
       INNER JOIN utilizador_projeto up ON u.id = up.utilizador_id
       WHERE up.projeto_id = ?`,
      [req.params.projetoId]
    );

    logger.success(
      `${rows.length} membros obtidos para projeto ${req.params.projetoId}`
    );
    res.json({ success: true, membros: rows });
  } catch (error) {
    logger.error('Erro em GET /utilizador_projeto/:projetoId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.delete('/:projetoId/:utilizadorId', async (req, res) => {
  try {
    await pool.execute(
      'DELETE FROM utilizador_projeto WHERE projeto_id = ? AND utilizador_id = ?',
      [req.params.projetoId, req.params.utilizadorId]
    );

    logger.success(
      `Utilizador ${req.params.utilizadorId} removido do projeto ${req.params.projetoId}`
    );
    res.json({ success: true });
  } catch (error) {
    logger.error(
      'Erro em DELETE /utilizador_projeto/:projetoId/:utilizadorId',
      error
    );
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
