import 'package:flutter/foundation.dart';

class AppConfig {
  static const String scheme = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: 'http',
  );
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.1.246',
  );
  static const int port = int.fromEnvironment(
    'API_PORT',
    defaultValue: 6003,
  );
  static const String path = String.fromEnvironment(
    'API_PATH',
    defaultValue: '/api',
  );

  static const bool enableAppLogs = true;

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
