import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFFF59E0B);

  // Light Theme Colors
  static const Color lightPrimaryBackground = Color(0xFFFFFFFF);
  static const Color lightSecondaryBackground = Color(0xFFF8FAFC);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF141414); // 更新为 #141414
  static const Color lightSecondaryText = Color(0xFF64748B);
  static const Color lightHintText = Color(0xFF94A3B8);

  // Dark Theme Colors
  static const Color darkPrimaryBackground = Color(0xFF0F172A);
  static const Color darkSecondaryBackground = Color(0xFF1E293B);
  static const Color darkCardBackground = Color(0xFF334155);
  static const Color darkPrimaryText = Color(0xFFF1F5F9);
  static const Color darkSecondaryText = Color(0xFFCBD5E1);
  static const Color darkHintText = Color(0xFF94A3B8);

  // 通用字体颜色定义 - 根据当前主题动态返回
  static Color get primaryTextColor =>
      _isDarkMode ? darkPrimaryText : lightPrimaryText;
  static Color get secondaryTextColor =>
      _isDarkMode ? darkSecondaryText : lightSecondaryText;
  static Color get hintTextColor => _isDarkMode ? darkHintText : lightHintText;
  static Color get primaryBackgroundColor =>
      _isDarkMode ? darkPrimaryBackground : lightPrimaryBackground;
  static Color get secondaryBackgroundColor =>
      _isDarkMode ? darkSecondaryBackground : lightSecondaryBackground;
  static Color get cardBackgroundColor =>
      _isDarkMode ? darkCardBackground : lightCardBackground;

  // 当前主题模式状态（需要在实际使用时设置）
  static bool _isDarkMode = false;

  // 设置主题模式的方法
  static void setThemeMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  // Typography - 使用 Google Fonts 并指定字重
  static String get primaryFontFamily =>
      GoogleFonts.splineSans(fontWeight: FontWeight.w400).fontFamily!;

  static String get primaryFontFamilyBold =>
      GoogleFonts.splineSans(fontWeight: FontWeight.w700).fontFamily!;

  static String get primaryFontFamilySemiBold =>
      GoogleFonts.splineSans(fontWeight: FontWeight.w600).fontFamily!;

  static String get fallbackFontFamily => GoogleFonts.splineSans().fontFamily!;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: primaryFontFamily,

      // 关键：通过 ColorScheme 设置全局文本颜色
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: lightCardBackground,
        background: lightPrimaryBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightPrimaryText, // 这是全局文本颜色
        onBackground: lightPrimaryText, // 背景上的文本颜色
        onSurfaceVariant: lightSecondaryText, // 次要文本颜色
      ),

      // 简化文本主题，让 ColorScheme 控制颜色
      textTheme: GoogleFonts.splineSansTextTheme(),

      scaffoldBackgroundColor: lightPrimaryBackground,
      cardTheme: CardThemeData(
        color: lightCardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightPrimaryBackground,
        foregroundColor: lightPrimaryText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightPrimaryText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          minimumSize: const Size(100, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: lightPrimaryText,
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSecondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: GoogleFonts.inter(color: lightHintText, fontSize: 16),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: primaryFontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: darkCardBackground,
        background: darkPrimaryBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkPrimaryText,
        onBackground: darkPrimaryText,
      ),
      scaffoldBackgroundColor: darkPrimaryBackground,
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkPrimaryBackground,
        foregroundColor: darkPrimaryText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkPrimaryText,
        ),
      ),
      textTheme: GoogleFonts.splineSansTextTheme().copyWith(
        // 设置所有文本样式的默认颜色为暗色主题颜色
        displayLarge: GoogleFonts.splineSans(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        displayMedium: GoogleFonts.splineSans(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        displaySmall: GoogleFonts.splineSans(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        headlineLarge: GoogleFonts.splineSans(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        headlineMedium: GoogleFonts.splineSans(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        headlineSmall: GoogleFonts.splineSans(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        titleLarge: GoogleFonts.splineSans(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        titleMedium: GoogleFonts.splineSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkPrimaryText,
        ),
        titleSmall: GoogleFonts.splineSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkPrimaryText,
        ),
        bodyLarge: GoogleFonts.splineSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        bodyMedium: GoogleFonts.splineSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkPrimaryText,
        ),
        bodySmall: GoogleFonts.splineSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkSecondaryText,
        ),
        labelLarge: GoogleFonts.splineSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkPrimaryText,
        ),
        labelMedium: GoogleFonts.splineSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkPrimaryText,
        ),
        labelSmall: GoogleFonts.splineSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkPrimaryText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          minimumSize: const Size(100, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: darkPrimaryText,
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSecondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: GoogleFonts.inter(color: darkHintText, fontSize: 16),
      ),
    );
  }
}
