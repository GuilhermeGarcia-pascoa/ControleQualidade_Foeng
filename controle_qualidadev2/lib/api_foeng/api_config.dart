import 'dart:convert';
import 'package:flutter/services.dart';

class ApiConfig {
  static late Map<String, dynamic> _config;
  static bool _initialized = false;

  /// Carrega as configurações do ficheiro assets/config.json
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      _config = jsonDecode(jsonString);
      _initialized = true;
      print('✅ ApiConfig carregado com sucesso');
    } catch (e) {
      print('❌ ERRO ao carregar ApiConfig: $e');
      // Configuração padrão em caso de erro
      _config = {
        'isLocalhost': true,
        'meuIpDoPC': '192.168.1.87',
        'port': 3000,
        'baseUrl': {
          'web': 'http://localhost:3000/api',
          'localhost': 'http://192.168.1.87:3000/api',
          'production': 'https://o-teu-dominio-real.com/api'
        }
      };
      _initialized = true;
    }
  }

  /// Obtém a configuração completa
  static Map<String, dynamic> get config => _config;

  /// Obtém se está em localhost
  static bool get isLocalhost => _config['isLocalhost'] ?? true;

  /// Obtém o IP do PC
  static String get meuIpDoPC => _config['meuIpDoPC'] ?? '192.168.1.87';

  /// Obtém a porta
  static int get port => _config['port'] ?? 3000;

  /// Obtém a base URL conforme ambiente
  static String get baseUrl {
    final baseUrls = _config['baseUrl'] as Map<String, dynamic>?;
    if (baseUrls == null) return 'http://192.168.1.87:3000/api';

    if (isLocalhost) {
      return baseUrls['localhost'] ?? 'http://192.168.1.87:3000/api';
    }
    return baseUrls['production'] ?? 'http://192.168.1.87:3000/api';
  }

  /// Obtém a configuração da base de dados
  static Map<String, dynamic> get dbConfig => _config['dbConfig'] ?? {};
}
