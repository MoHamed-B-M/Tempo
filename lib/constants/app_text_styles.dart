import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
  );

  static TextStyle wheelItem = GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );
}
