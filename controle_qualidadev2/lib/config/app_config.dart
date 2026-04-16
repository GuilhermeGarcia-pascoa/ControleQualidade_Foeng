import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiScheme = 'http';
  static const String apiHost = '192.168.1.63';
  static const int apiPort = 3000;
  static const String apiPath = '/api';
  static const bool enableAppLogs = true;

  static String get apiBaseUrl => '$apiScheme://$apiHost:$apiPort$apiPath';
  static String get serverBaseUrl => '$apiScheme://$apiHost:$apiPort';

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
