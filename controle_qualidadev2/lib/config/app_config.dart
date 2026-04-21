import 'package:flutter/foundation.dart';

class AppConfig {
  // ──── CONFIGURAÇÃO DA API ─────────────────────────────────────────────────
  static const String scheme = 'http';
  static const String host = '192.168.1.246';
  static const int port = 6003;
  static const String path = '/api';

  // ──── LOGS ─────────────────────────────────────────────────────────────────
  static const bool enableAppLogs = true;

  // ──── GETTERS ──────────────────────────────────────────────────────────────
  static String get apiBaseUrl => '$scheme://$host:$port$path';
  static String get serverBaseUrl => '$scheme://$host:$port';
  
  static String get adminBaseUrl => '$scheme://$host:$port';
  static String get adminApiBaseUrl => '$scheme://$host:$port$path';

  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }

  static void printConfig() {
    if (!enableAppLogs) {
      return;
    }

    debugPrint('APP CONFIG');
    debugPrint('Host: $host');
    debugPrint('Porta: $port');
    debugPrint('API Base URL: $apiBaseUrl');
  }
}


