import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignTokens {
  DesignTokens._();

  static const _seedLight = Color(0xFF616161);
  static const _seedDark = Color(0xFF1A1A1A);

  static ColorScheme lightColorScheme({ColorScheme? dynamicColor}) {
    return dynamicColor ??
        ColorScheme.fromSeed(
          seedColor: _seedLight,
          brightness: Brightness.light,
        );
  }

  static ColorScheme darkColorScheme({ColorScheme? dynamicColor}) {
    return dynamicColor ??
        ColorScheme.fromSeed(
          seedColor: _seedDark,
          brightness: Brightness.dark,
        );
  }

  static TextTheme textTheme() {
    final family = GoogleFonts.nunito().fontFamily;
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: family,
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontFamily: family,
        fontSize: 45,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontFamily: family,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontFamily: family,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  static TextTheme emphasizedTextTheme() {
    final base = textTheme();
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w800),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w800),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
