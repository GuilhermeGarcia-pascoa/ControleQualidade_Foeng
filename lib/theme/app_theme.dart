import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  
  // A "chave" que vamos usar para procurar no ficheiro de configurações
  static const String _themeKey = "tema_escuro_ativo";

  // 1. Função para carregar o tema guardado (deves chamar isto no main.dart)
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Se não houver nada guardado, assume false (Modo Claro)
    final isDark = prefs.getBool(_themeKey) ?? false; 
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // 2. Função para alterar e guardar a nova escolha
  static Future<void> changeTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark); // Guarda no telemóvel
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light; // Atualiza a UI na hora
  }
}