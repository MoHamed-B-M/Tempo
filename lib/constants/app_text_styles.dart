import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayTime(BuildContext c) => GoogleFonts.inter(
        fontSize: 64,
        fontWeight: FontWeight.w300,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 4,
        height: 1.0,
      );

  static TextStyle heading(BuildContext c) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 1.5,
      );

  static TextStyle subheading(BuildContext c) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryTextOf(c),
        letterSpacing: 2,
      );

  static TextStyle body(BuildContext c) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 0.5,
      );

  static TextStyle wheelItem(BuildContext c) => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w200,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 4,
      );

  static TextStyle wheelItemDim(BuildContext c) => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w200,
        color: AppColors.dimWhiteOf(c),
        letterSpacing: 4,
      );

  static TextStyle alarmTime(BuildContext c) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 2,
      );

  static TextStyle alarmLabel(BuildContext c) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: AppColors.secondaryTextOf(c),
        letterSpacing: 1,
      );

  static TextStyle buttonLabel(BuildContext c) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryTextOf(c),
        letterSpacing: 2,
      );
}
