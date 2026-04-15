/// Configuração da aplicação
/// Modifique apenas as variáveis abaixo conforme necessário
class AppConfig {
  // ─── AMBIENTE ──────────────────────────────────────────
  /// Se true: usa localhost | Se false: usa IP do PC na rede
  static const bool isLocalhost = false;

  // ─── API CONFIGURATION ─────────────────────────────────
  /// IP do PC na rede local (ex: 192.168.1.65)
  static const String localIp = '192.168.1.66';

  /// Porta do servidor Node.js
  static const int apiPort = 3000;

  // ─── URLS ──────────────────────────────────────────────
  /// URL base da API (muda conforme isLocalhost)
  static String get apiBaseUrl {
    if (isLocalhost) {
      return 'http://localhost:$apiPort/api';
    } else {
      return 'http://$localIp:$apiPort/api';
    }
  }

  // ─── ENDPOINTS ─────────────────────────────────────────
  static String get loginUrl => '$apiBaseUrl/login';
  static String get projetosUrl => '$apiBaseUrl/projetos';
  static String get nosUrl => '$apiBaseUrl/nos';
  static String get camposUrl => '$apiBaseUrl/campos';
  static String get registosUrl => '$apiBaseUrl/registos';
  static String get utilizadoresUrl => '$apiBaseUrl/utilizadores';

  // ─── DEBUG ─────────────────────────────────────────────
  static void printConfig() {
    print('═══════════════════════════════════════');
    print('🔧 APP CONFIG');
    print('├─ Ambiente: ${isLocalhost ? 'Localhost' : 'Rede Local'}');
    print('├─ IP: $localIp');
    print('├─ Porta: $apiPort');
    print('└─ API Base URL: $apiBaseUrl');
    print('═══════════════════════════════════════');
  }
}
