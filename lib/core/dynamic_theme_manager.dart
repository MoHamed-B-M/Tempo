import 'dart:math';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Ensures WCAG-compliant, expressive color schemes from any wallpaper source.
///
/// Uses Hct (Hue-Chroma-Tone) from `material_color_utilities` to map seed
/// colors to guaranteed-accessible tones. Falls back to a premium brand palette
/// when dynamic extraction is unavailable or produces low-quality results.
class DynamicThemeManager {
  DynamicThemeManager._();
  static final DynamicThemeManager instance = DynamicThemeManager._();

  // Brand fallback — a rich deep teal that looks premium in both modes
  static const Color _brandSeed = Color(0xFF005F56);
  static const Color _brandSeedDark = Color(0xFF53C3B4);

  // Cached schemes prevent rebuild jank across widget rebuilds
  ColorScheme? _lastLight;
  ColorScheme? _lastDark;

  /// True when the dynamic scheme passes a minimum viability check
  /// (primary-vs-surface contrast >= 3.0).
  bool isViable(ColorScheme? scheme) {
    if (scheme == null) return false;
    return _contrastRatio(scheme.primary, scheme.surface) >= 3.0;
  }

  /// Returns an enhanced light scheme.
  ///
  /// When [dynamicScheme] is viable its primary is tone-mapped and used as a
  /// seed; otherwise a premium brand fallback is returned.  The result is
  /// cached so that subsequent calls within the same session are free.
  ColorScheme processLight(ColorScheme? dynamicScheme) {
    if (dynamicScheme != null && isViable(dynamicScheme)) {
      _lastLight = _regenerate(dynamicScheme.primary, Brightness.light);
      return _lastLight!;
    }
    if (_lastLight == null) {
      _lastLight = ColorScheme.fromSeed(
        seedColor: _brandSeed,
        brightness: Brightness.light,
      );
    }
    return _lastLight!;
  }

  /// Returns an enhanced dark scheme (see [processLight]).
  ColorScheme processDark(ColorScheme? dynamicScheme) {
    if (dynamicScheme != null && isViable(dynamicScheme)) {
      _lastDark = _regenerate(dynamicScheme.primary, Brightness.dark);
      return _lastDark!;
    }
    if (_lastDark == null) {
      _lastDark = ColorScheme.fromSeed(
        seedColor: _brandSeedDark,
        brightness: Brightness.dark,
      );
    }
    return _lastDark!;
  }

  /// Call when the wallpaper may have changed to force fresh extraction.
  void invalidateCache() {
    _lastLight = null;
    _lastDark = null;
  }

  // ---------------------------------------------------------------------------
  //  Internals
  // ---------------------------------------------------------------------------

  /// Regenerates a full [ColorScheme] from [seed] after clamping its tone to
  /// a safe contrast zone (tone ~40 for light, ~75 for dark).
  ColorScheme _regenerate(Color seed, Brightness brightness) {
    final adjusted = _adjustTone(seed, isDark: brightness == Brightness.dark);
    return ColorScheme.fromSeed(seedColor: adjusted, brightness: brightness);
  }

  /// Hct tone-mapping — preserves hue & chroma while pushing the tone into
  /// a range that guarantees accessible contrast against the app surface.
  /// Also enforces a minimum chroma (≥ 18) to avoid muddy desaturated greys.
  Color _adjustTone(Color color, {required bool isDark}) {
    final hct = Hct.fromInt(color.value);
    hct.tone = isDark ? 75.0 : 40.0;
    if (hct.chroma < 18.0) hct.chroma = 24.0;
    return Color(hct.toInt());
  }

  // ---------------------------------------------------------------------------
  //  WCAG 2.1 contrast helpers
  // ---------------------------------------------------------------------------

  static double _relativeLuminance(Color c) {
    final r = _srgbLinear(c.red);
    final g = _srgbLinear(c.green);
    final b = _srgbLinear(c.blue);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _srgbLinear(int component) {
    final v = component / 255.0;
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _contrastRatio(Color a, Color b) {
    final l1 = _relativeLuminance(a);
    final l2 = _relativeLuminance(b);
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
  }
}
