import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Types of social login
enum SocialLoginType {
  google,
  apple,
  phone,
  email,
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
                      height: 1.2,
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
      case SocialLoginType.email:
        return Icon(
          Icons.email_outlined,
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
      case SocialLoginType.email:
        return 'Kontynuuj z e-mailem';
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
      case SocialLoginType.email:
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
      case SocialLoginType.email:
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
      case SocialLoginType.email:
        return AppColors.gray700;
    }
  }
}

/// Google's multicolor icon
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width * 0.36);
    final stroke = size.width * 0.16;

    Paint segment(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red (top-left)
    canvas.drawArc(
      rect,
      _degToRad(200),
      _degToRad(95),
      false,
      segment(const Color(0xFFEA4335)),
    );

    // White (bottom-left)
    canvas.drawArc(
      rect,
      _degToRad(295),
      _degToRad(70),
      false,
      segment(Colors.white),
    );

    // Green (bottom-right)
    canvas.drawArc(
      rect,
      _degToRad(5),
      _degToRad(88),
      false,
      segment(const Color(0xFF34A853)),
    );

    // Blue (top-right)
    canvas.drawArc(
      rect,
      _degToRad(95),
      _degToRad(105),
      false,
      segment(const Color(0xFF4285F4)),
    );

    // Horizontal blue bar to form the "G" opening.
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final y = center.dy;
    canvas.drawLine(
      Offset(size.width * 0.52, y),
      Offset(size.width * 0.86, y),
      barPaint,
    );
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
