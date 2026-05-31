import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium Off-white & Orange theme colors
  static const Color backgroundDark = Color(0xFF141312);      // Warm dark charcoal
  static const Color surfaceCardDark = Color(0xFF1F1E1C);     // Pure warm dark card
  static const Color primaryTextDark = Color(0xFFF5F4F2);     // Light off-white text
  static const Color secondaryTextDark = Color(0xFF9E9C99);   // Subdued grey-brown text
  static const Color accentDark = Color(0xFFF56D3B);          // Vibrant orange (accent)
  static const Color borderDark = Color(0xFF2C2B29);
  static const Color dimWhiteDark = Color(0x33F5F4F2);
  static const Color mediumWhiteDark = Color(0x66F5F4F2);

  static const Color backgroundLight = Color(0xFFEBEAE8);     // Warm soft off-white
  static const Color surfaceCardLight = Color(0xFFFFFFFF);    // Pure white card
  static const Color primaryTextLight = Color(0xFF0F0E0E);    // Dark charcoal text
  static const Color secondaryTextLight = Color(0xFF868583);  // Warm grey text
  static const Color accentLight = Color(0xFFF35C27);         // Vibrant orange (accent)
  static const Color borderLight = Color(0xFFE3E2DF);         // Inactive toggles / subtle borders
  static const Color dimWhiteLight = Color(0x22000000);
  static const Color mediumWhiteLight = Color(0x55000000);

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
