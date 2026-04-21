import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/session.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  // ─── DESIGN TOKENS ────────────────────────────────────────────
  // Primary: Deep Navy
  static const Color primaryNavy = Color(0xFF0A1628);
  static const Color primaryNavyLight = Color(0xFF1A2E4A);
  static const Color primaryNavyMid = Color(0xFF243B5E);

  // Accent: Electric Blue
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueLight = Color(0xFF3B82F6);
  static const Color accentBluePale = Color(0xFFEFF6FF);

  // Accent: Teal (secondary CTA)
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentTealPale = Color(0xFFF0FDFA);

  // Neutrals
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successPale = Color(0xFFECFDF5);
  static const Color error = Color(0xFFDC2626);
  static const Color errorPale = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningPale = Color(0xFFFFFBEB);

  // Dark mode surfaces
  static const Color darkSurface = Color(0xFF0F1923);
  static const Color darkSurfaceRaised = Color(0xFF162032);
  static const Color darkSurfaceHigh = Color(0xFF1E2D42);
  static const Color darkBorder = Color(0xFF1E3A5F);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentBlue,
          brightness: Brightness.light,
          primary: accentBlue,
          secondary: accentTeal,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: neutral900,
          error: error,
        ),
        scaffoldBackgroundColor: neutral50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: neutral800),
          titleTextStyle: TextStyle(
            color: neutral900,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: neutral200, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: neutral50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: neutral200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: neutral200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: neutral500, fontSize: 14),
          hintStyle: const TextStyle(color: neutral400, fontSize: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: StadiumBorder(),
        ),
        dividerTheme: const DividerThemeData(
          color: neutral100,
          thickness: 1,
          space: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: neutral100,
          selectedColor: accentBluePale,
          labelStyle: const TextStyle(fontSize: 13, color: neutral700),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentBlue,
          brightness: Brightness.dark,
          primary: accentBlueLight,
          secondary: accentTeal,
          surface: darkSurfaceRaised,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFFE2E8F0),
          error: const Color(0xFFF87171),
        ),
        scaffoldBackgroundColor: darkSurface,
        appBarTheme: AppBarTheme(
          backgroundColor: darkSurfaceRaised,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFFCBD5E1)),
          titleTextStyle: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkSurfaceRaised,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: darkBorder, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurfaceHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentBlueLight, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: StadiumBorder(),
        ),
        dividerTheme: const DividerThemeData(
          color: darkBorder,
          thickness: 1,
          space: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: darkSurfaceHigh,
          selectedColor: const Color(0xFF1E3A5F),
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
      );

  static Future<void> loadTheme() async {
    try {
      final userId = await Session.getUserId();
      if (userId == 0) return;
      final isDark = await DatabaseHelper.instance.obterTemaPorUsuario(userId);
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      themeMode.value = ThemeMode.light;
    }
  }

  static Future<void> changeTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final userId = await Session.getUserId();
      if (userId == 0) return;
      await DatabaseHelper.instance.atualizarTemaUsuario(userId, isDark);
    } catch (_) {}
  }
}