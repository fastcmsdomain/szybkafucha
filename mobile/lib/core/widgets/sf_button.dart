import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Button variants for Szybka Fucha app
enum SFButtonVariant { primary, ghost, gradient }

/// Button sizes
enum SFButtonSize { small, medium, large }

/// Custom button widget with multiple variants
class SFButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SFButtonVariant variant;
  final SFButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  const SFButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SFButtonVariant.primary,
    this.size = SFButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: switch (variant) {
        SFButtonVariant.primary => _buildPrimaryButton(),
        SFButtonVariant.ghost => _buildGhostButton(),
        SFButtonVariant.gradient => _buildGradientButton(),
      },
    );
  }

  EdgeInsets get _padding => switch (size) {
        SFButtonSize.small => EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingMD,
            vertical: AppSpacing.paddingXS,
          ),
        SFButtonSize.medium => EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingLG,
            vertical: AppSpacing.paddingSM,
          ),
        SFButtonSize.large => EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingXL,
            vertical: AppSpacing.paddingMD,
          ),
      };

  double get _fontSize => switch (size) {
        SFButtonSize.small => 14,
        SFButtonSize.medium => 16,
        SFButtonSize.large => 18,
      };

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(textColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: _fontSize + 4),
          SizedBox(width: AppSpacing.gapSM),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailingIcon != null) ...[
          SizedBox(width: AppSpacing.gapSM),
          Icon(trailingIcon, size: _fontSize + 4),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
      ),
      child: _buildContent(AppColors.white),
    );
  }

  Widget _buildGhostButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gray700,
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
        side: BorderSide(color: AppColors.gray200, width: 2),
      ),
      child: _buildContent(AppColors.gray700),
    );
  }

  Widget _buildGradientButton() {
    return _AnimatedGradientButton(
      onPressed: isLoading ? null : onPressed,
      padding: _padding,
      child: _buildContent(AppColors.gray700),
    );
  }
}

/// Button with animated rainbow border
class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final Widget child;

  const _AnimatedGradientButton({
    required this.onPressed,
    required this.padding,
    required this.child,
  });

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.button,
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: _controller.value * 2 * 3.14159,
              colors: AppColors.rainbowGradient,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Material(
            color: AppColors.white,
            borderRadius: AppRadius.button,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: AppRadius.button,
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
