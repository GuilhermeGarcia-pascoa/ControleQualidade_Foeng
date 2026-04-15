import 'package:shared_preferences/shared_preferences.dart';

/// Gestão de sessão com cache em memória para evitar leituras desnecessárias
/// ao disco e garantir consistência mesmo após o app voltar do background.
class Session {
  // ─── Cache em memória ──────────────────────────────────────────
  static int? _cachedId;
  static String? _cachedPerfil;

  // ─── GUARDAR ──────────────────────────────────────────────────
  static Future<void> saveUser(int id, String perfil) async {
    _cachedId = id;
    _cachedPerfil = perfil;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id);
    await prefs.setString('perfil', perfil);
  }

  // ─── LER (usa cache se disponível) ────────────────────────────
  static Future<Map<String, dynamic>?> getUser() async {
    // Se o cache está preenchido, usa-o diretamente
    if (_cachedId != null && _cachedPerfil != null) {
      return {'id': _cachedId!, 'perfil': _cachedPerfil!};
    }

    // Caso contrário, lê do disco e preenche o cache
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    final perfil = prefs.getString('perfil');

    if (id != null && perfil != null) {
      _cachedId = id;
      _cachedPerfil = perfil;
      return {'id': id, 'perfil': perfil};
    }

    return null;
  }

  // ─── OBTER ID ─────────────────────────────────────────────────
  static Future<int> getUserId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId') ?? 0;
    _cachedId = id;
    return id;
  }

  // ─── OBTER PERFIL ─────────────────────────────────────────────
  static Future<String?> getPerfil() async {
    if (_cachedPerfil != null) return _cachedPerfil;

    final prefs = await SharedPreferences.getInstance();
    final perfil = prefs.getString('perfil');
    _cachedPerfil = perfil;
    return perfil;
  }

  // ─── VERIFICAR SE ESTÁ AUTENTICADO ────────────────────────────
  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null && (user['id'] as int) > 0;
  }

  // ─── LOGOUT (limpa cache E disco) ─────────────────────────────
  static Future<void> logout() async {
    // Limpa cache em memória primeiro
    _cachedId = null;
    _cachedPerfil = null;

    // Limpa dados persistidos
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}