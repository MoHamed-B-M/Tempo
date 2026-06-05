import 'package:flutter/animation.dart';

class MotionTokens {
  MotionTokens._();

  // M3 expressive motion curves
  static const emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);
  static const standardAccelerate = Cubic(0.2, 0.0, 1.0, 0.1);

  // Duration tokens
  static const emphasizedDuration = Duration(milliseconds: 500);
  static const standardDuration = Duration(milliseconds: 300);
  static const expressiveDuration = Duration(milliseconds: 600);
}
