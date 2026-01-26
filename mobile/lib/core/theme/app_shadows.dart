import 'package:flutter/material.dart';

/// Szybka Fucha shadow/elevation scale
/// Based on szybkafucha.app design system
abstract class AppShadows {
  // Shadow definitions
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 10),
          blurRadius: 15,
          spreadRadius: -3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 20),
          blurRadius: 25,
          spreadRadius: -5,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 8),
          blurRadius: 10,
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> get xxl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(0, 25),
          blurRadius: 50,
          spreadRadius: -12,
        ),
      ];

  // Elevation mapping for Material widgets
  static double get elevationSM => 1;
  static double get elevationMD => 3;
  static double get elevationLG => 6;
  static double get elevationXL => 12;
  static double get elevationXXL => 24;
}
