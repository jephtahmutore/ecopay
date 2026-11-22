import 'package:flutter/material.dart';

/// EcoPay brand colours. Change them here and the whole app follows.
class AppColors {
  AppColors._();

  static const midnight = Color(0xFF0B1220);
  static const midnightLight = Color(0xFF16213D);
  static const primary = Color(0xFF00B386);
  static const primaryDark = Color(0xFF008566);
  static const mint = Color(0xFF34E3B0);
  static const cyan = Color(0xFF00A3C4);
  static const ink = Color(0xFF0B1220);
  static const muted = Color(0xFF6B7489);
  static const surface = Color(0xFFF4F6FB);
  static const border = Color(0xFFE6EAF2);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFF43F5E);
  static const blue = Color(0xFF3B6BFD);
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFFB7A3C);
  static const pink = Color(0xFFEC4899);
  static const teal = Color(0xFF14B8A6);
}

class AppGradients {
  AppGradients._();

  /// The signature EcoPay gradient: emerald to cyan to electric blue.
  static const brand = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A3C4), Color(0xFF3B5BFD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const hero = LinearGradient(
    colors: [AppColors.midnight, AppColors.midnightLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// A rich two tone gradient from any colour.
  static LinearGradient of(Color color) => LinearGradient(
        colors: [Color.lerp(color, Colors.white, 0.15)!, Color.lerp(color, Colors.black, 0.2)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppShadows {
  AppShadows._();

  static const soft = [
    BoxShadow(color: Color(0x12101828), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10)),
      ];
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.cyan,
      tertiary: AppColors.mint,
      surface: AppColors.surface,
    );

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    bool selected(Set<WidgetState> s) => s.contains(WidgetState.selected);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary, 1.8),
        errorBorder: border(AppColors.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: AppColors.border, width: 1.4),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        labelStyle: WidgetStateTextStyle.resolveWith((s) => TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w700,
              color: selected(s) ? Colors.white : AppColors.ink,
            )),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              fontWeight: selected(s) ? FontWeight.w800 : FontWeight.w600,
              color: selected(s) ? AppColors.primaryDark : AppColors.muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: selected(s) ? AppColors.primaryDark : AppColors.muted),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) => selected(s) ? AppColors.primary : null),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.midnight,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
