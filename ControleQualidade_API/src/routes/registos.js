const express = require('express');
const pool = require('../db/pool');
const logger = require('../utils/logger');
const { requireAuth } = require('../middleware/auth');
const { upload, handleUploadError } = require('../config/upload');

const router = express.Router();

// ─── OBTER REGISTOS ───────────────────────────────────────
router.get('/:noId', requireAuth, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT r.*, u.nome as nome_utilizador 
       FROM registos r 
       JOIN utilizadores u ON r.utilizador_id = u.id
       WHERE r.no_id = ? 
       ORDER BY r.criado_em DESC`,
      [req.params.noId]
    );
    logger.success(`${rows.length} registos obtidos para nó ${req.params.noId}`);
    res.json({ success: true, registos: rows });
  } catch (error) {
    logger.error('Erro em GET /registos/:noId', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ─── CRIAR REGISTO (com upload de ficheiros) ───────────────
router.post('/', requireAuth, (req, res) => {
  // Usar upload.array() com limite de 5 ficheiros
  upload.array('files', 5)(req, res, async function (err) {
    // Tratar erros de upload
    if (err) {
      logger.warn(`Erro no upload: ${err.message}`);
      return res.status(400).json({
        success: false,
        error: err.message,
        code: err.code || 'UPLOAD_ERROR'
      });
    }

    try {
      const { no_id, utilizador_id, dados_json } = req.body;
      
      // Validar campos obrigatórios
      if (!no_id || !dados_json) {
        return res.status(400).json({
          success: false,
          error: 'Campos obrigatórios: no_id, dados_json'
        });
      }

      let dados;
      try {
        dados = JSON.parse(dados_json);
      } catch (parseErr) {
        return res.status(400).json({
          success: false,
          error: 'JSON inválido em dados_json'
        });
      }
      
      // Adicionar caminhos dos ficheiros ao objeto dados
      if (req.files && req.files.length > 0) {
        logger.info(`${req.files.length} ficheiro(s) enviado(s) para nó ${no_id}`);
        
        for (const file of req.files) {
          // Usar fieldname como chave ou 'arquivo' como padrão
          const fieldName = file.fieldname || 'arquivo';
          
          // Se multiple, criar array
          if (!dados[fieldName]) {
            dados[fieldName] = [];
          }
          
          if (Array.isArray(dados[fieldName])) {
            dados[fieldName].push(`/uploads/${file.filename}`);
          } else {
            dados[fieldName] = `/uploads/${file.filename}`;
          }
        }
      }
      
      // Inserir registo na base de dados
      const [result] = await pool.execute(
        'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
        [no_id, utilizador_id || 1, JSON.stringify(dados)]
      );
      
      logger.success(`Registo criado (ID: ${result.insertId}) para nó ${no_id} com ${req.files?.length || 0} ficheiro(s)`);
      res.json({
        success: true,
        id: result.insertId,
        files: req.files?.length || 0
      });
    } catch (error) {
      logger.error('Erro em POST /registos', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });
});

module.exports = router;
