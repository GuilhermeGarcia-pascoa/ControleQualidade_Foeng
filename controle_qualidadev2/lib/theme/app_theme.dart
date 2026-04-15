import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../utils/session.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static Future<void> loadTheme() async {
    try {
      final userId = await Session.getUserId();
      if (userId == 0) {
        return;
      }

      final isDark = await DatabaseHelper.instance.obterTemaPorUsuario(userId);
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('loadTheme erro: $e');
      themeMode.value = ThemeMode.light;
    }
  }

  static Future<void> changeTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;

    try {
      final userId = await Session.getUserId();
      if (userId == 0) {
        return;
      }

      await DatabaseHelper.instance.atualizarTemaUsuario(userId, isDark);
    } catch (e) {
      debugPrint('changeTheme erro: $e');
    }
  }
}
