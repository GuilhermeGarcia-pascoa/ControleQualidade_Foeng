import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static Future<void> saveUser(int id, String perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id);
    await prefs.setString('perfil', perfil);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    final perfil = prefs.getString('perfil');
    if (id != null && perfil != null) {
      return {'id': id, 'perfil': perfil};
    }
    return null;
  }

  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId') ?? 0;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}