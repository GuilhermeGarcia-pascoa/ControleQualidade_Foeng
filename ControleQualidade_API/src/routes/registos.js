const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const pool = require('../db/pool');
const logger = require('../utils/logger');

const router = express.Router();

// ─── CONFIGURAÇÃO DE UPLOADS ──────────────────────────────
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const unique = `${Date.now()}_${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|webp/;
    cb(null, allowed.test(file.mimetype));
  },
});

// ─── OBTER REGISTOS ───────────────────────────────────────
router.get('/:noId', async (req, res) => {
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
router.post('/', upload.any(), async (req, res) => {
  try {
    const { no_id, utilizador_id, dados_json } = req.body;
    const dados = JSON.parse(dados_json);
    
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        dados[file.fieldname] = `/uploads/${file.filename}`;
      }
    }
    
    const [result] = await pool.execute(
      'INSERT INTO registos (no_id, utilizador_id, dados) VALUES (?, ?, ?)',
      [no_id, utilizador_id || 1, JSON.stringify(dados)]
    );
    
    logger.success(`Registo criado (ID: ${result.insertId}) para nó ${no_id}`);
    res.json({ success: true, id: result.insertId });
  } catch (error) {
    logger.error('Erro em POST /registos', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
