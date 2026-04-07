// Text style constants used across the app.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle h1 = GoogleFonts.cormorantGaramond(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle body = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle label = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.07 * 11,
    color: AppColors.textMuted,
  );

  static TextStyle small = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static TextStyle displayBody = GoogleFonts.cormorantGaramond(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.75,
    color: AppColors.textSecondary,
  );

  static TextStyle arabic = GoogleFonts.amiri(
    fontSize: 42,
    color: AppColors.textPrimary,
  );

  static TextStyle arabicSmall = GoogleFonts.amiri(
    fontSize: 32,
    color: AppColors.textPrimary,
  );
}
