import 'package:flutter/foundation.dart';

class AppConfig {
  // ──── CONFIGURAÇÃO DA API PRINCIPAL ────────────────────────────────────────
  static const String apiScheme = 'http';
  static const String apiHost = '192.168.1.246';
  static const int apiPort = 6003;
  static const String apiPath = '/api';

  // ──── CONFIGURAÇÃO DO ADMIN SERVICE ────────────────────────────────────────
  // Nota: Em Android Emulator usa 10.0.2.2; em dispositivo físico usa o IP da máquina.
  static const String adminScheme = 'http';
  static const String adminHost = '192.168.1.63';
  static const int adminPort = 3000;
  static const String adminPath = '/api';

  // ──── LOGS ─────────────────────────────────────────────────────────────────
  static const bool enableAppLogs = true;

  // ──── GETTERS ──────────────────────────────────────────────────────────────
  static String get apiBaseUrl => '$apiScheme://$apiHost:$apiPort$apiPath';
  static String get serverBaseUrl => '$apiScheme://$apiHost:$apiPort';
  
  static String get adminBaseUrl => '$adminScheme://$adminHost:$adminPort';
  static String get adminApiBaseUrl => '$adminScheme://$adminHost:$adminPort$adminPath';

  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }

  static void printConfig() {
    if (!enableAppLogs) {
      return;
    }

    debugPrint('APP CONFIG');
    debugPrint('Host: $apiHost');
    debugPrint('Porta: $apiPort');
    debugPrint('API Base URL: $apiBaseUrl');
  }
}
