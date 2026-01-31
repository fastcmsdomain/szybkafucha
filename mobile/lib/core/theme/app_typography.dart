import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Szybka Fucha typography system
///
/// Uses system fonts (Roboto on Android, San Francisco on iOS) for reliable
/// rendering in emulator environments without network access.
///
/// For production with Google Fonts (Plus Jakarta Sans, Nunito), fonts should
/// be bundled in assets or network access ensured.
abstract class AppTypography {
  // System font family
  static const String _fontFamily = 'Roboto';

  // Text Styles - Headings
  static TextStyle get h1 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h5 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  static TextStyle get h6 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: AppColors.gray900,
      );

  // Text Styles - Body
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray800,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray800,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray600,
      );

  // Text Styles - Labels
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.gray700,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.gray700,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.gray500,
      );

  // Button text
  static TextStyle get buttonLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.white,
      );

  static TextStyle get buttonMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.white,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.white,
      );

  // Caption
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.gray500,
      );
}
