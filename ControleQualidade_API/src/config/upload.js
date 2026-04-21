const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ─── CRIAR PASTA DE UPLOADS SE NÃO EXISTIR ────────────────
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// ─── CONFIGURAÇÃO DE ARMAZENAMENTO ────────────────────────
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Armazenar na pasta uploads/
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Gerar nome único: timestamp-random-originalname
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});

// ─── TIPOS MIME PERMITIDOS (IMAGENS APENAS) ──────────────
const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/jpg'
];

// ─── EXTENSÕES PERMITIDAS (VALIDAÇÃO DUPLA) ──────────────
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];

// ─── LIMITES DE FICHEIRO ──────────────────────────────────
const LIMITS = {
  fileSize: 5 * 1024 * 1024, // 5MB máximo
  files: 10 // máximo 10 ficheiros por requisição
};

// ─── FILTRO DE FICHEIROS ──────────────────────────────────
/**
 * Validação rigorosa de ficheiros:
 * 1. Verificar MIME type real (não apenas extensão)
 * 2. Verificar extensão do ficheiro
 * 3. Rejeitar ficheiros suspeitos
 */
const fileFilter = (req, file, cb) => {
  // Validação 1: MIME type
  if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    const error = new Error(
      `Tipo de ficheiro não permitido: ${file.mimetype}. Permitidos: ${ALLOWED_MIME_TYPES.join(', ')}`
    );
    error.code = 'INVALID_MIME_TYPE';
    return cb(error, false);
  }

  // Validação 2: Extensão do ficheiro
  const ext = path.extname(file.originalname).toLowerCase();
  if (!ALLOWED_EXTENSIONS.includes(ext)) {
    const error = new Error(
      `Extensão não permitida: ${ext}. Permitidas: ${ALLOWED_EXTENSIONS.join(', ')}`
    );
    error.code = 'INVALID_EXTENSION';
    return cb(error, false);
  }

  // Validação 3: Nome do ficheiro seguro
  // Remover caracteres perigosos do nome original
  const safeName = file.originalname
    .replace(/[^\w\s.-]/g, '') // Remove caracteres especiais
    .replace(/\s+/g, '_'); // Espaços para underscore
  
  if (!safeName || safeName.length === 0) {
    const error = new Error('Nome de ficheiro inválido');
    error.code = 'INVALID_FILENAME';
    return cb(error, false);
  }

  // Tudo OK - ficheiro permitido
  cb(null, true);
};

// ─── CONFIGURAÇÃO DO MULTER ───────────────────────────────
const upload = multer({
  storage,
  fileFilter,
  limits: LIMITS
});

// ─── MIDDLEWARE DE ERRO DE UPLOAD ─────────────────────────
/**
 * Middleware para capturar e tratar erros de upload
 * Deve ser usado após o upload middleware
 */
const handleUploadError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    // Erros do Multer
    let message = '';
    let statusCode = 400;

    switch (err.code) {
      case 'LIMIT_FILE_SIZE':
        message = `Ficheiro muito grande. Máximo: ${LIMITS.fileSize / (1024 * 1024)}MB`;
        break;
      case 'LIMIT_FILE_COUNT':
        message = `Demasiados ficheiros. Máximo: ${LIMITS.files}`;
        break;
      case 'LIMIT_PART_COUNT':
        message = 'Demasiados campos de formulário';
        break;
      case 'LIMIT_FIELD_KEY':
        message = 'Nome de campo muito longo';
        break;
      case 'LIMIT_FIELD_VALUE':
        message = 'Valor de campo muito longo';
        break;
      default:
        message = err.message || 'Erro ao fazer upload do ficheiro';
    }

    return res.status(statusCode).json({
      success: false,
      error: message,
      code: err.code
    });
  } else if (err && err.code) {
    // Erros customizados do fileFilter
    const statusCode = 400;
    return res.status(statusCode).json({
      success: false,
      error: err.message,
      code: err.code
    });
  }

  // Passar para próximo middleware se não for erro de upload
  next(err);
};

// ─── EXPORTAÇÕES ───────────────────────────────────────────
module.exports = {
  upload,
  handleUploadError,
  uploadDir,
  ALLOWED_MIME_TYPES,
  ALLOWED_EXTENSIONS,
  LIMITS
};
