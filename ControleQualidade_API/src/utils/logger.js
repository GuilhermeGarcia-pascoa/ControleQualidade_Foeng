const fs = require('fs');
const path = require('path');

// Cores para o terminal
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  blue: '\x1b[34m',
};

const logger = {
  info: (message) => {
    const timestamp = new Date().toISOString();
    const log = `[${timestamp}] ℹ️  ${message}`;
    console.log(`${colors.cyan}${log}${colors.reset}`);
  },

  success: (message) => {
    const timestamp = new Date().toISOString();
    const log = `[${timestamp}] ✅ ${message}`;
    console.log(`${colors.green}${log}${colors.reset}`);
  },

  warn: (message) => {
    const timestamp = new Date().toISOString();
    const log = `[${timestamp}] ⚠️  ${message}`;
    console.log(`${colors.yellow}${log}${colors.reset}`);
  },

  error: (message, error = null) => {
    const timestamp = new Date().toISOString();
    const log = `[${timestamp}] ❌ ${message}`;
    console.error(`${colors.red}${log}${colors.reset}`);
    if (error) {
      console.error(`${colors.red}${error.stack || error}${colors.reset}`);
    }
  },

  request: (method, path, statusCode) => {
    const timestamp = new Date().toISOString();
    const color = statusCode >= 400 ? colors.red : colors.green;
    const log = `[${timestamp}] 📡 ${method} ${path} → ${statusCode}`;
    console.log(`${color}${log}${colors.reset}`);
  },
};

module.exports = logger;
