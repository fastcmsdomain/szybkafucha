import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A text widget with a rainbow gradient effect.
/// Uses the app's rainbow colors (coral → pink → purple → blue).
class SFRainbowText extends StatelessWidget {
  const SFRainbowText(
    this.text, {
    super.key,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFE94560),
          Color(0xFFEC4899),
          Color(0xFF8B5CF6),
          Color(0xFF3B82F6),
        ],
      ).createShader(bounds),
      child: Text(
        text,
        style: (style ?? AppTypography.h4).copyWith(color: AppColors.white),
      ),
    );
  }
}
