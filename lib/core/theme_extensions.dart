import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class ExpressiveSpacing extends ThemeExtension<ExpressiveSpacing> {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  const ExpressiveSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  @override
  ExpressiveSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return ExpressiveSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  ExpressiveSpacing lerp(ThemeExtension<ExpressiveSpacing>? other, double t) {
    if (other is! ExpressiveSpacing) return this;
    return ExpressiveSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }
}

class ExpressiveRadius extends ThemeExtension<ExpressiveRadius> {
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;

  const ExpressiveRadius({
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.full = 28,
  });

  @override
  ExpressiveRadius copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? full,
  }) {
    return ExpressiveRadius(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      full: full ?? this.full,
    );
  }

  @override
  ExpressiveRadius lerp(ThemeExtension<ExpressiveRadius>? other, double t) {
    if (other is! ExpressiveRadius) return this;
    return ExpressiveRadius(
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      full: lerpDouble(full, other.full, t)!,
    );
  }
}

class ExpressiveMotion extends ThemeExtension<ExpressiveMotion> {
  final Curve emphasizedDecelerate;
  final Curve emphasizedAccelerate;
  final Curve standardDecelerate;
  final Curve standardAccelerate;
  final Duration emphasizedDuration;
  final Duration standardDuration;
  final Duration expressiveDuration;

  const ExpressiveMotion({
    this.emphasizedDecelerate = const Cubic(0.05, 0.7, 0.1, 1.0),
    this.emphasizedAccelerate = const Cubic(0.3, 0.0, 0.8, 0.15),
    this.standardDecelerate = const Cubic(0.0, 0.0, 0.0, 1.0),
    this.standardAccelerate = const Cubic(0.2, 0.0, 1.0, 0.1),
    this.emphasizedDuration = const Duration(milliseconds: 500),
    this.standardDuration = const Duration(milliseconds: 300),
    this.expressiveDuration = const Duration(milliseconds: 600),
  });

  @override
  ExpressiveMotion copyWith({
    Curve? emphasizedDecelerate,
    Curve? emphasizedAccelerate,
    Curve? standardDecelerate,
    Curve? standardAccelerate,
    Duration? emphasizedDuration,
    Duration? standardDuration,
    Duration? expressiveDuration,
  }) {
    return ExpressiveMotion(
      emphasizedDecelerate: emphasizedDecelerate ?? this.emphasizedDecelerate,
      emphasizedAccelerate: emphasizedAccelerate ?? this.emphasizedAccelerate,
      standardDecelerate: standardDecelerate ?? this.standardDecelerate,
      standardAccelerate: standardAccelerate ?? this.standardAccelerate,
      emphasizedDuration: emphasizedDuration ?? this.emphasizedDuration,
      standardDuration: standardDuration ?? this.standardDuration,
      expressiveDuration: expressiveDuration ?? this.expressiveDuration,
    );
  }

  @override
  ExpressiveMotion lerp(ThemeExtension<ExpressiveMotion>? other, double t) {
    if (other is! ExpressiveMotion) return this;
    return ExpressiveMotion(
      emphasizedDecelerate: t < 0.5 ? emphasizedDecelerate : other.emphasizedDecelerate,
      emphasizedAccelerate: t < 0.5 ? emphasizedAccelerate : other.emphasizedAccelerate,
      standardDecelerate: t < 0.5 ? standardDecelerate : other.standardDecelerate,
      standardAccelerate: t < 0.5 ? standardAccelerate : other.standardAccelerate,
      emphasizedDuration: t < 0.5 ? emphasizedDuration : other.emphasizedDuration,
      standardDuration: t < 0.5 ? standardDuration : other.standardDuration,
      expressiveDuration: t < 0.5 ? expressiveDuration : other.expressiveDuration,
    );
  }
}
