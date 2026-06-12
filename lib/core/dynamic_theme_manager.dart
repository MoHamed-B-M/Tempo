import 'dart:math';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Optimised Material You theme manager with forced seed extraction and
/// green-hue chroma boost.
///
/// Instead of trusting the platform's built-in [ColorScheme] conversion
/// (which can be muted or restricted on OEM skins like ColorOS), this manager
/// extracts **only the hue** from the dynamic seed, discards the platform's
/// chroma/tone, and rebuilds a fresh scheme with guaranteed-vibrant chroma
/// and WCAG-safe tone values.
///
/// Green hues (90–150°) receive a chroma boost to prevent the desaturated
/// look that many dynamic colour engines produce for wallpaper greens.
class DynamicThemeManager {
  DynamicThemeManager._();
  static final DynamicThemeManager instance = DynamicThemeManager._();

  // ---------------------------------------------------------------------------
  //  Brand fallback — explicit green hex (used when platform returns null or a
  //  low-quality scheme).
  // ---------------------------------------------------------------------------
  static const Color _brandSeed = Color(0xFF2E7D32);   // Forest Green (light)
  static const Color _brandSeedDark = Color(0xFF66BB6A); // Soft Green  (dark)

  // ---------------------------------------------------------------------------
  //  Cached schemes — prevent rebuild jank across widget rebuilds.
  // ---------------------------------------------------------------------------
  ColorScheme? _lastLight;
  ColorScheme? _lastDark;

  // ---------------------------------------------------------------------------
  //  Green hue range in the Hct colour space.
  // ---------------------------------------------------------------------------
  static const double _greenHueMin = 90.0;
  static const double _greenHueMax = 150.0;

  /// Returns `true` when the dynamic scheme passes a minimum viability check
  /// (primary-vs-surface contrast ≥ 3.0).
  bool isViable(ColorScheme? scheme) {
    if (scheme == null) return false;
    return _contrastRatio(scheme.primary, scheme.surface) >= 3.0;
  }

  /// Extract the **hue** from [dynamicScheme] and build a fresh light scheme
  /// with guaranteed-vibrant chroma and WCAG-safe tone.
  ///
  /// If [dynamicScheme] is null or non-viable the brand fallback is returned.
  /// The result is cached to avoid unnecessary work on rebuilds.
  ColorScheme processLight(ColorScheme? dynamicScheme) {
    if (dynamicScheme != null && isViable(dynamicScheme)) {
      _lastLight = _forgeScheme(dynamicScheme.primary, Brightness.light);
      return _lastLight!;
    }
    _lastLight ??= ColorScheme.fromSeed(
      seedColor: _brandSeed,
      brightness: Brightness.light,
    );
    return _lastLight!;
  }

  /// Dark-mode counterpart of [processLight].
  ColorScheme processDark(ColorScheme? dynamicScheme) {
    if (dynamicScheme != null && isViable(dynamicScheme)) {
      _lastDark = _forgeScheme(dynamicScheme.primary, Brightness.dark);
      return _lastDark!;
    }
    _lastDark ??= ColorScheme.fromSeed(
      seedColor: _brandSeedDark,
      brightness: Brightness.dark,
    );
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

  /// Build a full [ColorScheme] by extracting **only the hue** from [seed],
  /// then applying our own chroma (boosted for greens) and WCAG-safe tone.
  ///
  /// This bypasses OEM-specific colour restrictions (ColorOS, MIUI, etc.)
  /// because the platform's chroma/tone values are discarded entirely.
  ColorScheme _forgeScheme(Color seed, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final hct = Hct.fromInt(seed.toARGB32());

    // Keep the wallpaper's hue — this is the only thing we need from the OS.
    final double hue = hct.hue;
    // Apply our own expressive chroma (double for greens).
    final double chroma = _chromaFor(hue);
    // Clamp tone for guaranteed WCAG AA contrast.
    final double tone = isDark ? 75.0 : 40.0;

    final fresh = Hct.from(hue, chroma, tone);
    return ColorScheme.fromSeed(
      seedColor: Color(fresh.toInt()),
      brightness: brightness,
    );
  }

  /// Return a chroma value that keeps the colour vibrant.
  ///
  /// Green hues get a significant boost (52) because dynamic engines almost
  /// always under-saturate wallpaper greens.  All other hues get a standard
  /// expressive value (36).
  static double _chromaFor(double hue) {
    if (hue >= _greenHueMin && hue <= _greenHueMax) return 52.0;
    return 36.0;
  }

  // ---------------------------------------------------------------------------
  //  WCAG 2.1 contrast helpers
  // ---------------------------------------------------------------------------

  static double _relativeLuminance(Color c) {
    final r = _srgbLinear(c.r);
    final g = _srgbLinear(c.g);
    final b = _srgbLinear(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _srgbLinear(double component) {
    return component <= 0.04045
        ? component / 12.92
        : pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _contrastRatio(Color a, Color b) {
    final l1 = _relativeLuminance(a);
    final l2 = _relativeLuminance(b);
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
  }
}
