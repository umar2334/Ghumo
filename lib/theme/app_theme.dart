import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette — Khaki Orange + Dark Slate Green
  static const Color primary = Color(0xFFF2B759); // Khaki Orange
  static const Color primaryDark = Color(0xFFD4973A);
  static const Color accent = Color(0xFFFFD080);
  static const Color darkSlate = Color(0xFF0A4A3C); // Dark Slate Gray

  // Backgrounds — deep dark teal-black
  static const Color background = Color(0xFF060F0C);
  static const Color surface = Color(0xFF0A1A14);
  static const Color card = Color(0xFF0E2119);
  static const Color cardElevated = Color(0xFF122820);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF7DBFA8);
  static const Color textMuted = Color(0xFF3D6050);

  // UI
  static const Color divider = Color(0xFF142A20);
  static const Color danger = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFF8800);
  static const Color success = Color(0xFF4CAF50);
  static const Color overlayDark = Color(0xCC000000);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      background: AppColors.background,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
          color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28),
      headlineMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 22),
      titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18),
      titleMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16),
      bodyLarge:
          GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      bodyMedium:
          GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
      labelSmall: GoogleFonts.inter(
          color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        letterSpacing: 1.2,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle:
          GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),
  );
}
