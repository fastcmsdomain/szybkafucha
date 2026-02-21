import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Szybka Fucha typography system
/// Body: Plus Jakarta Sans
/// Headings: Nunito (weight 800)
abstract class AppTypography {
  // Font families
  static String get bodyFontFamily => GoogleFonts.plusJakartaSans().fontFamily!;
  static String get headingFontFamily => GoogleFonts.nunito().fontFamily!;

  // Text Styles - Headings (Nunito 800)
  static TextStyle get h1 => GoogleFonts.nunito(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h2 => GoogleFonts.nunito(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h3 => GoogleFonts.nunito(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h4 => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h5 => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h6 => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  // Backward-compatible alias used by newer UI components
  static TextStyle get headingSmall => h5;

  // Text Styles - Body (Plus Jakarta Sans)
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray800,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray800,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray600,
      );

  // Text Styles - Labels
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.gray700,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.gray700,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.gray500,
      );

  // Button text
  static TextStyle get buttonLarge => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.white,
      );

  static TextStyle get buttonMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.white,
      );

  static TextStyle get buttonSmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.white,
      );

  // Caption
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray500,
      );
}
