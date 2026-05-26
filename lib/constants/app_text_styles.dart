import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle displayTime = GoogleFonts.inter(
    fontSize: 64,
    fontWeight: FontWeight.w300,
    color: AppColors.primaryText,
    letterSpacing: 4,
    height: 1.0,
  );

  static TextStyle heading = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: 1.5,
  );

  static TextStyle subheading = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    letterSpacing: 2,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
    letterSpacing: 0.5,
  );

  static TextStyle wheelItem = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w200,
    color: AppColors.primaryText,
    letterSpacing: 4,
  );

  static TextStyle wheelItemDim = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w200,
    color: AppColors.dimWhite,
    letterSpacing: 4,
  );

  static TextStyle alarmTime = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
    letterSpacing: 2,
  );

  static TextStyle alarmLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w300,
    color: AppColors.secondaryText,
    letterSpacing: 1,
  );

  static TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
    letterSpacing: 2,
  );
}

