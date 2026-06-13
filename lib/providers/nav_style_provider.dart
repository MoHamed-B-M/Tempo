import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/hive_helper.dart';
import '../packages/animated_bubble_nav/animated_bubble_nav.dart';

enum NavBarPreset {
  bubble,
  pill,
  minimal,
  compact;

  String get label {
    switch (this) {
      case NavBarPreset.bubble:
        return 'Bubble';
      case NavBarPreset.pill:
        return 'Pill';
      case NavBarPreset.minimal:
        return 'Minimal';
      case NavBarPreset.compact:
        return 'Compact';
    }
  }

  IconData get icon {
    switch (this) {
      case NavBarPreset.bubble:
        return Icons.circle;
      case NavBarPreset.pill:
        return Icons.rounded_corner;
      case NavBarPreset.minimal:
        return Icons.horizontal_rule;
      case NavBarPreset.compact:
        return Icons.space_dashboard;
    }
  }

  BubbleDecoration decoration(ColorScheme cs) {
    switch (this) {
      case NavBarPreset.bubble:
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
      case NavBarPreset.pill:
        return BubbleDecoration(
          backgroundColor: cs.surfaceContainer.withValues(alpha: 0.92),
          selectedBubbleBackgroundColor: cs.primary,
          unSelectedBubbleBackgroundColor: Colors.transparent,
          selectedBubbleIconColor: cs.onPrimary,
          unSelectedBubbleIconColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
          iconSize: 24,
          shapes: BubbleShape.square,
          squareBordersRadius: 32,
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
      case NavBarPreset.minimal:
        return BubbleDecoration(
          backgroundColor: Colors.transparent,
          selectedBubbleBackgroundColor: cs.primary.withValues(alpha: 0.15),
          unSelectedBubbleBackgroundColor: Colors.transparent,
          selectedBubbleIconColor: cs.primary,
          unSelectedBubbleIconColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
          iconSize: 24,
          shapes: BubbleShape.square,
          squareBordersRadius: 12,
          bubbleItemSize: 10,
          innerIconLabelSpacing: 6,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          margin: EdgeInsets.zero,
          alignment: Alignment.bottomCenter,
          bubbleDuration: const Duration(milliseconds: 300),
          selectedBubbleLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
          unSelectedBubbleLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        );
      case NavBarPreset.compact:
        return BubbleDecoration(
          backgroundColor: cs.surfaceContainer.withValues(alpha: 0.92),
          selectedBubbleBackgroundColor: cs.primary,
          unSelectedBubbleBackgroundColor: Colors.transparent,
          selectedBubbleIconColor: cs.onPrimary,
          unSelectedBubbleIconColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
          iconSize: 22,
          shapes: BubbleShape.square,
          squareBordersRadius: 20,
          bubbleItemSize: 8,
          innerIconLabelSpacing: 4,
          padding: const EdgeInsets.all(6),
          margin: EdgeInsets.zero,
          alignment: Alignment.bottomCenter,
          bubbleDuration: const Duration(milliseconds: 300),
          selectedBubbleLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onPrimary,
          ),
          unSelectedBubbleLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
    }
  }
}

final navStyleProvider = NotifierProvider<NavStyleNotifier, NavStyleState>(
  NavStyleNotifier.new,
);

class NavStyleState {
  final bool useBubbleNav;
  final NavBarPreset selectedPreset;

  const NavStyleState({
    this.useBubbleNav = false,
    this.selectedPreset = NavBarPreset.pill,
  });

  NavStyleState copyWith({bool? useBubbleNav, NavBarPreset? selectedPreset}) {
    return NavStyleState(
      useBubbleNav: useBubbleNav ?? this.useBubbleNav,
      selectedPreset: selectedPreset ?? this.selectedPreset,
    );
  }
}

class NavStyleNotifier extends Notifier<NavStyleState> {
  @override
  NavStyleState build() {
    final useBubble = HiveHelper.settings.get('use_bubble_nav') as bool? ?? false;
    final presetIndex = HiveHelper.settings.get('nav_bar_preset') as int? ?? 1;
    final preset = NavBarPreset.values[presetIndex.clamp(0, NavBarPreset.values.length - 1)];
    return NavStyleState(useBubbleNav: useBubble, selectedPreset: preset);
  }

  Future<void> toggle() async {
    final next = !state.useBubbleNav;
    state = state.copyWith(useBubbleNav: next);
    await HiveHelper.settings.put('use_bubble_nav', next);
  }

  Future<void> setPreset(NavBarPreset preset) async {
    state = state.copyWith(selectedPreset: preset);
    await HiveHelper.settings.put('nav_bar_preset', preset.index);
  }
}
