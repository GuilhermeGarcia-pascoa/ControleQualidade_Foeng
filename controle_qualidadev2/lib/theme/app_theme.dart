import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/session.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  static Future<void> loadTheme(String baseUrl) async {
    try {
      final userId = await Session.getUserId();
      if (userId == 0) return; // 0 = sem sessão

      final response = await http.get(
        Uri.parse('$baseUrl/utilizadores/$userId/tema'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isDark = data['tema_escuro'] == true;
        themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      debugPrint('❌ loadTheme erro: $e');
      themeMode.value = ThemeMode.light;
    }
  }

  static Future<void> changeTheme(bool isDark, String baseUrl) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;

    try {
      final userId = await Session.getUserId();
      if (userId == 0) return; // 0 = sem sessão

      await http.put(
        Uri.parse('$baseUrl/utilizadores/$userId/tema'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tema_escuro': isDark}),
      );
    } catch (e) {
      debugPrint('❌ changeTheme erro: $e');
    }
  }
}