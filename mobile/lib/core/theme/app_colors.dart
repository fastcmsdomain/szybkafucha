import 'package:flutter/material.dart';

/// Szybka Fucha color palette
/// Based on szybkafucha.app landing page design system
abstract class AppColors {
  // Primary - Coral Red
  static const Color primary = Color(0xFFE94560);
  static const Color primaryDark = Color(0xFFD13A54);
  static const Color primaryLight = Color(0xFFFF6B7A);

  // Secondary - Navy
  static const Color secondary = Color(0xFF1A1A2E);
  static const Color secondaryLight = Color(0xFF16213E);

  // Accent - Deep Blue
  static const Color accent = Color(0xFF0F3460);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral Colors (Tailwind gray scale)
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Rainbow gradient colors (for animated borders)
  static const List<Color> rainbowGradient = [
    Color(0xFFE94560), // primary
    Color(0xFFF59E0B), // warning/amber
    Color(0xFF10B981), // success/green
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
    Color(0xFFE94560), // primary (loop)
  ];

  // Star rating color
  static const Color starRating = Color(0xFFFCD34D);
}
