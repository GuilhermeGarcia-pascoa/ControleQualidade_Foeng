const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const BCRYPT_ROUNDS = 12;
const MD5_REGEX = /^[a-f0-9]{32}$/i;

function md5(text) {
  return crypto.createHash('md5').update(text).digest('hex');
}

function isLegacyMd5Hash(hash) {
  return typeof hash === 'string' && MD5_REGEX.test(hash);
}

async function hashPassword(password) {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

async function verifyPassword(password, hash) {
  if (!hash) {
    return false;
  }

  if (isLegacyMd5Hash(hash)) {
    return md5(password) === hash;
  }

  return bcrypt.compare(password, hash);
}

module.exports = {
  hashPassword,
  isLegacyMd5Hash,
  md5,
  verifyPassword,
};
