import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headline Styles
  static TextStyle get headlineLarge => GoogleFonts.spaceGrotesk(
    fontSize: 32.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get headlineMedium => GoogleFonts.spaceGrotesk(
    fontSize: 28.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.accentYellowGreen,
  );

  static TextStyle get headlineSmall => GoogleFonts.spaceGrotesk(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Body Styles
  static TextStyle get bodyLarge => GoogleFonts.spaceGrotesk(
    fontSize: 16.sp,
    fontWeight: FontWeight.w300,
    color: Colors.white,
  );

  static TextStyle get bodyMedium => GoogleFonts.spaceGrotesk(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
    fontSize: 12.sp,
    fontWeight: FontWeight.w300,
    color: Colors.white70,
  );

  // Label Styles - Different Sizes
  static TextStyle get label14 => GoogleFonts.spaceGrotesk(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.accentYellowGreen,
  );

  static TextStyle get label16 => GoogleFonts.spaceGrotesk(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.accentYellowGreen,
  );

  static TextStyle get label18 => GoogleFonts.spaceGrotesk(
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.accentYellowGreen,
  );

  static TextStyle get label20 => GoogleFonts.spaceGrotesk(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.accentYellowGreen,
  );

  // Label with White Color
  static TextStyle get label14White => GoogleFonts.spaceGrotesk(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle get label16White => GoogleFonts.spaceGrotesk(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle get label18White => GoogleFonts.spaceGrotesk(
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Title Styles
  static TextStyle get titleLarge => GoogleFonts.spaceGrotesk(
    fontSize: 22.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get titleMedium => GoogleFonts.spaceGrotesk(
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle get titleSmall => GoogleFonts.spaceGrotesk(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}