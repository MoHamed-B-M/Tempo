import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFFF56D3B);

  static ThemeData light({ColorScheme? dynamicColor}) =>
      _build(dynamicColor ?? ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ));

  static ThemeData dark({ColorScheme? dynamicColor}) =>
      _build(dynamicColor ?? ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ));

  static ThemeData _build(ColorScheme cs) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor: cs.surface,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        contentTextStyle: GoogleFonts.inter(color: cs.onSurface),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 0.5,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.onPrimaryContainer;
          }
          return cs.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primaryContainer;
          }
          return cs.surfaceContainerHighest;
        }),
      ),
    );
  }
}

class _FadeSlidePageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        )),
        child: child,
      ),
    );
  }
}
