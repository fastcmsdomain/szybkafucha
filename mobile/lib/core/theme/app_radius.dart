import 'package:flutter/material.dart';

/// Szybka Fucha border radius scale
/// Based on szybkafucha.app design system
abstract class AppRadius {
  // Border radius values
  static const double sm = 6;      // 0.375rem
  static const double md = 8;      // 0.5rem
  static const double lg = 12;     // 0.75rem
  static const double xl = 16;     // 1rem
  static const double xxl = 24;    // 1.5rem
  static const double full = 9999; // Full round (pills)

  // BorderRadius objects for convenience
  static BorderRadius get radiusSM => BorderRadius.circular(sm);
  static BorderRadius get radiusMD => BorderRadius.circular(md);
  static BorderRadius get radiusLG => BorderRadius.circular(lg);
  static BorderRadius get radiusXL => BorderRadius.circular(xl);
  static BorderRadius get radiusXXL => BorderRadius.circular(xxl);
  static BorderRadius get radiusFull => BorderRadius.circular(full);

  // Common component radii
  static BorderRadius get button => radiusLG;
  static BorderRadius get card => radiusXL;
  static BorderRadius get input => radiusLG;
  static BorderRadius get chip => radiusFull;
  static BorderRadius get avatar => radiusFull;
  static BorderRadius get bottomSheet => BorderRadius.only(
        topLeft: Radius.circular(xxl),
        topRight: Radius.circular(xxl),
      );
}
