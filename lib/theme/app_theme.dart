// lib/theme/app_theme.dart
// ============================================================
//  FOENG Quality Control — Sistema de Tema Centralizado
//  Equivalente ao "CSS externo" em Flutter
//  Importa este ficheiro em todas as screens:
//    import 'package:controlo_qualidade_foeng/theme/app_theme.dart';
// ============================================================
 
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
 
// ─────────────────────────────────────────────
//  PALETA DE CORES
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();
 
  // Primárias
  static const Color primary        = Color(0xFF0A2540);
  static const Color primaryLight   = Color(0xFF1A3A5C);
  static const Color accent         = Color(0xFF00C2A8);
  static const Color accentDark     = Color(0xFF009E87);
 
  // Superfícies
  static const Color background     = Color(0xFFF4F6F9);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceAlt     = Color(0xFFEDF0F5);
  static const Color cardShadow     = Color(0x1A0A2540);
 
  // Texto
  static const Color textPrimary    = Color(0xFF0A2540);
  static const Color textSecondary  = Color(0xFF6B7A99);
  static const Color textOnDark     = Color(0xFFFFFFFF);
  static const Color textMuted      = Color(0xFFADB5C7);
 
  // Estado
  static const Color success        = Color(0xFF2ECC71);
  static const Color warning        = Color(0xFFF39C12);
  static const Color error          = Color(0xFFE74C3C);
  static const Color info           = Color(0xFF3498DB);
 
  // Bordas
  static const Color border         = Color(0xFFDDE2EC);
  static const Color borderFocus    = Color(0xFF00C2A8);
 
  // Admin vs Trabalhador (badges)
  static const Color badgeAdmin     = Color(0xFF0A2540);
  static const Color badgeWorker    = Color(0xFF00C2A8);
}
 
// ─────────────────────────────────────────────
//  TIPOGRAFIA (Atualizado para Google Fonts)
// ─────────────────────────────────────────────
class AppText {
  AppText._();
 
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
 
  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );
 
  static TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );
 
  static TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
 
  static TextStyle headingSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );
 
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
 
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
 
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
 
  static TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
 
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );
 
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
 
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    letterSpacing: 0.3,
  );
 
  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
 
  static TextStyle displayLargeOnDark  = displayLarge.copyWith(color: AppColors.textOnDark);
  static TextStyle headingLargeOnDark  = headingLarge.copyWith(color: AppColors.textOnDark);
  static TextStyle bodyMediumOnDark    = bodyMedium.copyWith(color: AppColors.textOnDark.withOpacity(0.85));
  static TextStyle labelOnDark         = label.copyWith(color: AppColors.textOnDark.withOpacity(0.65));
}
 
// ─────────────────────────────────────────────
//  ESPAÇAMENTOS
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
 
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
 
  static const EdgeInsets screenPadding    = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets screenPaddingH   = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets cardPadding      = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20);
  static const EdgeInsets inputPadding     = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const EdgeInsets buttonPadding    = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
  static const EdgeInsets chipPadding      = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
}
 
// ─────────────────────────────────────────────
//  RAIOS DE BORDA
// ─────────────────────────────────────────────
class AppRadius {
  AppRadius._();
 
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double full = 999.0;
 
  static const BorderRadius borderXs   = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));
}
 
// ─────────────────────────────────────────────
//  SOMBRAS
// ─────────────────────────────────────────────
class AppShadows {
  AppShadows._();
 
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
 
  static const List<BoxShadow> md = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
 
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
 
  static const List<BoxShadow> accent = [
    BoxShadow(
      color: Color(0x3300C2A8),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];
}
 
// ─────────────────────────────────────────────
//  DECORAÇÕES REUTILIZÁVEIS
// ─────────────────────────────────────────────
class AppDecorations {
  AppDecorations._();
 
  static BoxDecoration card = const BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderLg,
    boxShadow: AppShadows.sm,
  );
 
  static BoxDecoration cardOutlined = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderLg,
    border: Border.all(color: AppColors.border, width: 1),
  );
 
  static BoxDecoration cardAccent = const BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderLg,
    boxShadow: AppShadows.sm,
    border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
  );
 
  static BoxDecoration headerGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryLight],
    ),
  );
 
  static BoxDecoration screenBackground = const BoxDecoration(
    color: AppColors.background,
  );
 
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
          : null,
      suffix: suffix,
      labelStyle: AppText.label,
      hintStyle: AppText.caption,
      filled: true,
      fillColor: AppColors.surfaceAlt,
      contentPadding: AppSpacing.inputPadding,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.borderFocus, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.error),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────
//  ESTILOS DE BOTÃO REUTILIZÁVEIS
// ─────────────────────────────────────────────
class AppButtonStyles {
  AppButtonStyles._();
 
  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.textOnDark,
    padding: AppSpacing.buttonPadding,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    elevation: 0,
    textStyle: AppText.buttonMedium,
  );
 
  static ButtonStyle primaryDark = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnDark,
    padding: AppSpacing.buttonPadding,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    elevation: 0,
    textStyle: AppText.buttonMedium,
  );
 
  static ButtonStyle outlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary, width: 1.5),
    padding: AppSpacing.buttonPadding,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    textStyle: AppText.buttonMedium,
  );
 
  static ButtonStyle ghost = TextButton.styleFrom(
    foregroundColor: AppColors.accent,
    padding: AppSpacing.buttonPadding,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    textStyle: AppText.buttonMedium,
  );
 
  static ButtonStyle danger = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.textOnDark,
    padding: AppSpacing.buttonPadding,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    elevation: 0,
    textStyle: AppText.buttonMedium,
  );
}
 
// ─────────────────────────────────────────────
//  TEMA GLOBAL (MaterialApp theme)
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();
 
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    
    // FONTE GLOBAL APLICADA AQUI
    textTheme: GoogleFonts.interTextTheme(),
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
 
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.headingLargeOnDark,
      iconTheme: const IconThemeData(color: AppColors.textOnDark),
    ),
 
    // Cards 
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      margin: EdgeInsets.zero,
    ),
 
    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      labelStyle: AppText.label,
      hintStyle: AppText.caption,
      contentPadding: AppSpacing.inputPadding,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.borderFocus, width: 2),
      ),
    ),
 
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppButtonStyles.primary,
    ),
 
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppButtonStyles.outlined,
    ),
 
    textButtonTheme: TextButtonThemeData(
      style: AppButtonStyles.ghost,
    ),
 
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceAlt,
      selectedColor: AppColors.accent,
      labelStyle: AppText.bodySmall,
      padding: AppSpacing.chipPadding,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
    ),
 
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
 
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: AppText.bodyMediumOnDark,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      behavior: SnackBarBehavior.floating,
    ),
 
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.textOnDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    ),
  );
}
 
// ─────────────────────────────────────────────
//  WIDGETS REUTILIZÁVEIS
// ─────────────────────────────────────────────
 
class ProfileBadge extends StatelessWidget {
  final String role;
  const ProfileBadge({super.key, required this.role});
 
  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(
        color: (isAdmin ? AppColors.badgeAdmin : AppColors.badgeWorker).withOpacity(0.12),
        borderRadius: AppRadius.borderFull,
        border: Border.all(
          color: isAdmin ? AppColors.badgeAdmin : AppColors.badgeWorker,
          width: 1,
        ),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Trabalhador',
        style: AppText.labelSmall.copyWith(
          color: isAdmin ? AppColors.badgeAdmin : AppColors.badgeWorker,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
 
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
 
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.headingMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppText.caption),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
 
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool outlined;
  final bool accentLeft;
 
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.outlined = false,
    this.accentLeft = false,
  });
 
  @override
  Widget build(BuildContext context) {
    final decoration = accentLeft
        ? AppDecorations.cardAccent
        : outlined
            ? AppDecorations.cardOutlined
            : AppDecorations.card;
 
    final content = Container(
      padding: padding ?? AppSpacing.cardPadding,
      decoration: decoration,
      child: child,
    );
 
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
 
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
 
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppText.headingSmall, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!, style: AppText.caption, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
 
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  const AppLoadingIndicator({super.key, this.message});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2.5,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: AppText.caption),
          ],
        ],
      ),
    ); 
  }
}