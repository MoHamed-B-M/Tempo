import 'package:flutter/material.dart';
import '../packages/animated_bubble_nav/animated_bubble_nav.dart';

BubbleDecoration bubbleDecoration(ColorScheme cs) {
  return BubbleDecoration(
    backgroundColor: cs.surfaceContainer.withValues(alpha: 0.92),
    selectedBubbleBackgroundColor: cs.primary,
    unSelectedBubbleBackgroundColor: Colors.transparent,
    selectedBubbleIconColor: cs.onPrimary,
    unSelectedBubbleIconColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
    iconSize: 24,
    shapes: BubbleShape.circular,
    bubbleItemSize: 14,
    innerIconLabelSpacing: 6,
    padding: const EdgeInsets.all(10),
    margin: EdgeInsets.zero,
    alignment: Alignment.bottomCenter,
    bubbleDuration: const Duration(milliseconds: 350),
    selectedBubbleLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: cs.onPrimary,
    ),
    unSelectedBubbleLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
    ),
  );
}
