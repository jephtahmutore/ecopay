import 'package:flutter/material.dart';

/// Brand colours for the glass look. A deep night sky background lets the
/// frosted glass panels and the bright accents stand out.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF060B1A);
  static const navy = Color(0xFF0B1636);
  static const blue = Color(0xFF2563EB);
  static const cyan = Color(0xFF22D3EE);
  static const mint = Color(0xFF34D399);
  static const violet = Color(0xFF8B5CF6);
  static const amber = Color(0xFFFBBF24);
  static const rose = Color(0xFFFB7185);

  /// White text at reduced strength for secondary labels.
  static const muted = Color(0xB3FFFFFF);
  static const faint = Color(0x80FFFFFF);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.cyan,
      onPrimary: AppColors.ink,
      secondary: AppColors.mint,
      onSecondary: AppColors.ink,
      tertiary: AppColors.violet,
      surface: AppColors.navy,
      onSurface: Colors.white,
      onSurfaceVariant: AppColors.muted,
      error: AppColors.rose,
    );

    final radius = BorderRadius.circular(16);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ink,
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        labelStyle: const TextStyle(color: AppColors.muted),
        floatingLabelStyle: const TextStyle(color: AppColors.cyan),
        hintStyle: const TextStyle(color: AppColors.faint),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(Colors.white.withValues(alpha: 0.18)),
        enabledBorder: border(Colors.white.withValues(alpha: 0.18)),
        focusedBorder: border(AppColors.cyan, 1.6),
        errorBorder: border(AppColors.rose),
        focusedErrorBorder: border(AppColors.rose, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.35),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.ink,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.12)),
    );
  }
}
