import 'package:flutter/foundation.dart';

/// Configuração centralizada da API do aplicativo.
/// 
/// As variáveis de ambiente podem ser passadas via --dart-define durante build:
/// 
/// Exemplo - Desenvolvimento Local:
///   flutter run --dart-define=API_HOST=localhost --dart-define=API_PORT=3000
/// 
/// Exemplo - Rede Local (Android Emulator):
///   flutter run --dart-define=API_HOST=10.0.2.2 --dart-define=API_PORT=3000
/// 
/// Exemplo - Produção:
///   flutter build apk --dart-define=API_HOST=api.foeng.pt --dart-define=API_PORT=443
/// 
/// Valores padrão (sem --dart-define):
///   - Host: localhost
///   - Port: 3000
///   - Scheme: detectado automaticamente (http ou https baseado na porta)
/// 
class AppConfig {
  // ─── VARIÁVEIS DE AMBIENTE ─────────────────────────────────────────
  
  /// Host da API. Padrão: localhost
  /// Use 10.0.2.2 para Android Emulator acessar host machine
  /// Use 192.168.x.x para acesso via rede local
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'localhost',
  );

  /// Porta da API. Padrão: 3000
  static const int port = int.fromEnvironment(
    'API_PORT',
    defaultValue: 3000,
  );

  /// Caminho base da API. Padrão: /api
  static const String apiPath = String.fromEnvironment(
    'API_PATH',
    defaultValue: '/api',
  );

  /// Ativar logs de configuração. Padrão: true
  static const bool enableAppLogs = !kReleaseMode; // Desativar em release

  // ─── PROPRIEDADES CALCULADAS ──────────────────────────────────────
  
  /// Detectar scheme automaticamente (https se porta 443, senão http)
  static String get _scheme {
    if (port == 443) return 'https';
    if (port == 8443) return 'https';
    return 'http';
  }

  /// URL base completa da API (com caminho)
  /// Exemplo: http://localhost:3000/api
  static String get apiBaseUrl => '$_scheme://$host:$port$apiPath';

  /// URL base do servidor (sem caminho)
  /// Exemplo: http://localhost:3000
  static String get serverBaseUrl => '$_scheme://$host:$port';

  /// URL base para admin (igual ao serverBaseUrl)
  static String get adminBaseUrl => serverBaseUrl;

  /// URL base da API para admin (igual ao apiBaseUrl)
  static String get adminApiBaseUrl => apiBaseUrl;

  // ─── MÉTODOS AUXILIARES ───────────────────────────────────────────
  
  /// Construir URL de um endpoint específico
  /// Exemplo: endpoint('login') → http://localhost:3000/api/login
  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }

  /// Construir URL com caminho customizado
  /// Exemplo: endpointWithPath('v2', 'login') → http://localhost:3000/v2/login
  static String endpointWithPath(String customPath, String endpoint) {
    final normalizedPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$_scheme://$host:$port/$customPath$normalizedPath';
  }

  // ─── DEBUG ─────────────────────────────────────────────────────────
  
  /// Imprimir configuração atual no console
  /// Útil para verificar se as variáveis de ambiente foram passadas corretamente
  static void printConfig() {
    if (!enableAppLogs) return;

    debugPrint('┌─────────────────────────────────────┐');
    debugPrint('│        CONFIGURAÇÃO DA API          │');
    debugPrint('├─────────────────────────────────────┤');
    debugPrint('│ Host:          $host');
    debugPrint('│ Porta:         $port');
    debugPrint('│ Scheme:        $_scheme');
    debugPrint('│ API Base URL:  $apiBaseUrl');
    debugPrint('│ Server URL:    $serverBaseUrl');
    debugPrint('└─────────────────────────────────────┘');
  }
}
