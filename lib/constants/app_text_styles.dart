import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayTime(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 72,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTextOf(c),
        letterSpacing: -1,
        height: 1.0,
      );

  static TextStyle heading(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryTextOf(c),
        letterSpacing: -0.5,
      );

  static TextStyle subheading(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextOf(c),
        letterSpacing: 0,
      );

  static TextStyle body(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 0,
      );

  static TextStyle wheelItem(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 1,
      );

  static TextStyle wheelItemDim(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.dimWhiteOf(c),
        letterSpacing: 1,
      );

  static TextStyle alarmTime(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTextOf(c),
        letterSpacing: -0.5,
      );

  static TextStyle alarmLabel(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextOf(c),
        letterSpacing: 0,
      );

  static TextStyle buttonLabel(BuildContext c) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 0.5,
      );
}
