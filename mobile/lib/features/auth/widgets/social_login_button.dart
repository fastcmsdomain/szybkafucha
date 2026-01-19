import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Types of social login
enum SocialLoginType {
  google,
  apple,
  phone,
}

/// Social login button widget
/// Supports Google, Apple, and Phone login styles
class SocialLoginButton extends StatelessWidget {
  final SocialLoginType type;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.type,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _getBorderColor(),
            width: 1.5,
          ),
          backgroundColor: _getBackgroundColor(),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMD,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getTextColor(),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  SizedBox(width: AppSpacing.gapMD),
                  Text(
                    _getLabel(),
                    style: AppTypography.buttonMedium.copyWith(
                      color: _getTextColor(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (type) {
      case SocialLoginType.google:
        return _GoogleIcon();
      case SocialLoginType.apple:
        return Icon(
          Icons.apple,
          size: 24,
          color: AppColors.white,
        );
      case SocialLoginType.phone:
        return Icon(
          Icons.phone_android_rounded,
          size: 24,
          color: AppColors.gray700,
        );
    }
  }

  String _getLabel() {
    switch (type) {
      case SocialLoginType.google:
        return 'Kontynuuj z Google';
      case SocialLoginType.apple:
        return 'Kontynuuj z Apple';
      case SocialLoginType.phone:
        return 'Kontynuuj z numerem telefonu';
    }
  }

  Color _getBackgroundColor() {
    switch (type) {
      case SocialLoginType.google:
        return AppColors.white;
      case SocialLoginType.apple:
        return AppColors.secondary;
      case SocialLoginType.phone:
        return AppColors.white;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case SocialLoginType.google:
        return AppColors.gray300;
      case SocialLoginType.apple:
        return AppColors.secondary;
      case SocialLoginType.phone:
        return AppColors.gray300;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case SocialLoginType.google:
        return AppColors.gray700;
      case SocialLoginType.apple:
        return AppColors.white;
      case SocialLoginType.phone:
        return AppColors.gray700;
    }
  }
}

/// Google's multicolor icon
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Using a simple G icon since we don't have the actual Google logo
    // In production, use google_fonts or an actual SVG/PNG
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4), // Blue
                  Color(0xFFEA4335), // Red
                  Color(0xFFFBBC05), // Yellow
                  Color(0xFF34A853), // Green
                ],
              ).createShader(
                const Rect.fromLTWH(0, 0, 24, 24),
              ),
          ),
        ),
      ),
    );
  }
}
