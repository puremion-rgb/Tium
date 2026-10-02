import 'package:flutter/material.dart';

/// design_tokens.json 기준 색상.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF2E7D32);
  static const primaryDark = Color(0xFF1F5A25);
  static const accent = Color(0xFFA5D67A);
  static const accentLight = Color(0xFFE6F2DA);
  static const background = Color(0xFFFCF8EE);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF333333);
  static const textSecondary = Color(0xFF687270);
  static const textHint = Color(0xFFA2A79C);
  static const line = Color(0xFFECE6D6);
  static const track = Color(0xFFE9EEE0);
  static const pointYellow = Color(0xFFFFD54F);
  static const pointPeach = Color(0xFFFFB8A8);
  static const streak = Color(0xFFE8833A);
  static const error = Color(0xFFE95350);
}

class AppRadius {
  AppRadius._();
  static const card = 20.0;
  static const button = 26.0;
  static const chip = 16.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// 로고·축하 문구처럼 크게 쓰는 곳에만 쓰는 둥근 글꼴.
const displayFont = 'Jua';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
        bodyMedium: const TextStyle(fontSize: 14, color: AppColors.text),
        bodySmall: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Color(0xFFD6DCC8), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF26321F),
      ),
    );
  }
}
