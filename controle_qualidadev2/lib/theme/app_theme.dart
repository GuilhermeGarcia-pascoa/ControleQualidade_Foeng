import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/session.dart';

/// FOENG Quality Control — Design System
/// Tema premium inspirado em produtos enterprise como Linear, Vercel, Notion Pro
/// Paleta: Deep Slate + Indigo Accent + Warm Neutrals
class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  // ─── PALETA PRINCIPAL ─────────────────────────────────────────
  // Indigo profundo — identidade visual FOENG
  static const Color brand900 = Color(0xFF1E1B4B);
  static const Color brand800 = Color(0xFF312E81);
  static const Color brand700 = Color(0xFF3730A3);
  static const Color brand600 = Color(0xFF4338CA);
  static const Color brand500 = Color(0xFF4F46E5);
  static const Color brand400 = Color(0xFF6366F1);
  static const Color brand300 = Color(0xFF818CF8);
  static const Color brand200 = Color(0xFFC7D2FE);
  static const Color brand100 = Color(0xFFE0E7FF);
  static const Color brand50  = Color(0xFFEEF2FF);

  // Legado — mantém compatibilidade com ecrãs existentes
  static const Color primaryNavy       = Color(0xFF0F172A);
  static const Color primaryNavyLight  = Color(0xFF1E293B);
  static const Color primaryNavyMid    = Color(0xFF334155);
  static const Color accentBlue        = Color(0xFF4F46E5);   // brand500
  static const Color accentBlueLight   = Color(0xFF6366F1);   // brand400
  static const Color accentBluePale    = Color(0xFFEEF2FF);   // brand50
  static const Color accentTeal        = Color(0xFF0891B2);
  static const Color accentTealPale    = Color(0xFFECFEFF);

  // ─── NEUTRALS QUENTES (Slate) ─────────────────────────────────
  static const Color neutral50  = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral150 = Color(0xFFE9EFF7);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral950 = Color(0xFF020617);

  // ─── SEMÂNTICAS ───────────────────────────────────────────────
  static const Color success      = Color(0xFF059669);
  static const Color successPale  = Color(0xFFECFDF5);
  static const Color successLight = Color(0xFF34D399);
  static const Color error        = Color(0xFFDC2626);
  static const Color errorPale    = Color(0xFFFEF2F2);
  static const Color errorLight   = Color(0xFFF87171);
  static const Color warning      = Color(0xFFD97706);
  static const Color warningPale  = Color(0xFFFFFBEB);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color info         = Color(0xFF0284C7);
  static const Color infoPale     = Color(0xFFF0F9FF);

  // ─── DARK MODE ────────────────────────────────────────────────
  static const Color darkBg           = Color(0xFF080B14);
  static const Color darkSurface      = Color(0xFF0D1117);
  static const Color darkSurfaceRaised = Color(0xFF161B27);
  static const Color darkSurfaceHigh  = Color(0xFF1C2333);
  static const Color darkSurfaceFloat = Color(0xFF212840);
  static const Color darkBorder       = Color(0xFF1E2D47);
  static const Color darkBorderLight  = Color(0xFF2D3F5C);

  // ─── TIPOGRAFIA ───────────────────────────────────────────────
  // Usar 'Geist' ou 'DM Sans' se disponível; fallback para sistema
  static const String _fontFamily = 'DM Sans';

  // ─── LIGHT THEME ──────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brand500,
          brightness: Brightness.light,
          primary: brand500,
          secondary: accentTeal,
          tertiary: brand300,
          surface: Colors.white,
          surfaceContainerLowest: neutral50,
          surfaceContainerLow: neutral100,
          surfaceContainer: neutral150,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: neutral900,
          onSurfaceVariant: neutral500,
          outline: neutral200,
          outlineVariant: neutral150,
          error: error,
        ),
        scaffoldBackgroundColor: neutral50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: Color(0x0A000000),
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: neutral700, size: 20),
          actionsIconTheme: IconThemeData(color: neutral600, size: 20),
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            color: neutral900,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: neutral200, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand500,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: -0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: neutral700,
            side: const BorderSide(color: neutral200, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: brand500,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brand500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: neutral50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: neutral200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: neutral200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: brand500, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          labelStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: neutral500,
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: neutral400,
            fontSize: 14,
          ),
          errorStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: error,
            fontSize: 12,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: brand500,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          extendedTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: neutral100,
          thickness: 1,
          space: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: neutral100,
          selectedColor: brand100,
          labelStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            color: neutral700,
            fontWeight: FontWeight.w500,
          ),
          selectedShadowColor: Colors.transparent,
          shadowColor: Colors.transparent,
          side: const BorderSide(color: neutral200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          elevation: 0,
          pressElevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: neutral900,
          contentTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
          elevation: 4,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: const Color(0x1A000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: neutral900,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: neutral600,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: const Color(0x18000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: neutral150),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: neutral700,
            fontSize: 14,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brand500;
            return neutral300;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brand100;
            return neutral150;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brand500;
            return Colors.transparent;
          }),
          side: const BorderSide(color: neutral300, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: brand500,
          linearTrackColor: neutral150,
        ),
        textTheme: _buildTextTheme(isDark: false),
      );

  // ─── DARK THEME ───────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brand400,
          brightness: Brightness.dark,
          primary: brand400,
          secondary: accentTeal,
          tertiary: brand300,
          surface: darkSurfaceRaised,
          surfaceContainerLowest: darkSurface,
          surfaceContainerLow: darkSurfaceRaised,
          surfaceContainer: darkSurfaceHigh,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFFE2E8F0),
          onSurfaceVariant: const Color(0xFF94A3B8),
          outline: darkBorder,
          outlineVariant: darkSurfaceFloat,
          error: errorLight,
        ),
        scaffoldBackgroundColor: darkSurface,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurfaceRaised,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: Color(0x14000000),
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFFCBD5E1), size: 20),
          actionsIconTheme: IconThemeData(color: Color(0xFF94A3B8), size: 20),
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            color: Color(0xFFE2E8F0),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkSurfaceRaised,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: darkBorder, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand500,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFCBD5E1),
            side: const BorderSide(color: darkBorder),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: brand300,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brand500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurfaceHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: brand400, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: errorLight),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: errorLight, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          labelStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: brand500,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          extendedTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: darkBorder,
          thickness: 1,
          space: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: darkSurfaceHigh,
          selectedColor: const Color(0xFF1E2D47),
          labelStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w500,
          ),
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          elevation: 0,
          pressElevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkSurfaceFloat,
          contentTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: darkBorderLight),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: darkSurfaceRaised,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: const Color(0x33000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: darkBorder),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: Color(0xFFE2E8F0),
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: Color(0xFF94A3B8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: darkSurfaceRaised,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: const Color(0x33000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: darkBorder),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: Color(0xFFCBD5E1),
            fontSize: 14,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: darkSurfaceRaised,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brand400;
            return neutral500;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF1E2D47);
            return darkSurfaceFloat;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brand400;
            return Colors.transparent;
          }),
          side: const BorderSide(color: neutral500, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: brand400,
          linearTrackColor: darkSurfaceHigh,
        ),
        textTheme: _buildTextTheme(isDark: true),
      );

  // ─── TEXT THEME ───────────────────────────────────────────────
  static TextTheme _buildTextTheme({required bool isDark}) {
    final base = isDark ? const Color(0xFFE2E8F0) : neutral900;
    final muted = isDark ? const Color(0xFF94A3B8) : neutral500;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: base,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: base,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: base,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: base,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: base,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: base,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: base,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: base,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: base,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: base,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: base,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: base,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: muted,
      ),
    );
  }

  // ─── PERSISTÊNCIA DO TEMA ─────────────────────────────────────
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