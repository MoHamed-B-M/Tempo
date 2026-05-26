import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceCardDark = Color(0xFF0E0E0E);
  static const Color primaryTextDark = Color(0xFFFFFFFF);
  static const Color secondaryTextDark = Color(0xFF6B6B6B);
  static const Color accentDark = Color(0xFFFFFFFF);
  static const Color borderDark = Color(0xFF1A1A1A);
  static const Color dimWhiteDark = Color(0x33FFFFFF);
  static const Color mediumWhiteDark = Color(0x66FFFFFF);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceCardLight = Color(0xFFF2F2F2);
  static const Color primaryTextLight = Color(0xFF000000);
  static const Color secondaryTextLight = Color(0xFF8E8E93);
  static const Color accentLight = Color(0xFF000000);
  static const Color borderLight = Color(0xFFE5E5EA);
  static const Color dimWhiteLight = Color(0x33000000);
  static const Color mediumWhiteLight = Color(0x66000000);

  static Color background(Brightness b) =>
      b == Brightness.dark ? backgroundDark : backgroundLight;
  static Color surfaceCard(Brightness b) =>
      b == Brightness.dark ? surfaceCardDark : surfaceCardLight;
  static Color primaryText(Brightness b) =>
      b == Brightness.dark ? primaryTextDark : primaryTextLight;
  static Color secondaryText(Brightness b) =>
      b == Brightness.dark ? secondaryTextDark : secondaryTextLight;
  static Color accent(Brightness b) =>
      b == Brightness.dark ? accentDark : accentLight;
  static Color border(Brightness b) =>
      b == Brightness.dark ? borderDark : borderLight;
  static Color dimWhite(Brightness b) =>
      b == Brightness.dark ? dimWhiteDark : dimWhiteLight;
  static Color mediumWhite(Brightness b) =>
      b == Brightness.dark ? mediumWhiteDark : mediumWhiteLight;

  static Color backgroundOf(BuildContext c) =>
      background(Theme.of(c).brightness);
  static Color surfaceCardOf(BuildContext c) =>
      surfaceCard(Theme.of(c).brightness);
  static Color primaryTextOf(BuildContext c) =>
      primaryText(Theme.of(c).brightness);
  static Color secondaryTextOf(BuildContext c) =>
      secondaryText(Theme.of(c).brightness);
  static Color accentOf(BuildContext c) => accent(Theme.of(c).brightness);
  static Color borderOf(BuildContext c) => border(Theme.of(c).brightness);
  static Color dimWhiteOf(BuildContext c) =>
      dimWhite(Theme.of(c).brightness);
  static Color mediumWhiteOf(BuildContext c) =>
      mediumWhite(Theme.of(c).brightness);
}
