import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Card widget with optional rainbow border animation
class SFCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool hasRainbowBorder;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const SFCard({
    super.key,
    required this.child,
    this.padding,
    this.hasRainbowBorder = false,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (hasRainbowBorder) {
      return _RainbowBorderCard(
        onTap: onTap,
        padding: padding ?? EdgeInsets.all(AppSpacing.paddingMD),
        backgroundColor: backgroundColor ?? AppColors.white,
        child: child,
      );
    }

    return Material(
      color: backgroundColor ?? AppColors.white,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: padding ?? EdgeInsets.all(AppSpacing.paddingMD),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.gray100),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Card with animated rainbow border
class _RainbowBorderCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const _RainbowBorderCard({
    required this.child,
    required this.padding,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  State<_RainbowBorderCard> createState() => _RainbowBorderCardState();
}

class _RainbowBorderCardState extends State<_RainbowBorderCard>
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
            borderRadius: AppRadius.card,
            gradient: LinearGradient(
              begin: Alignment(-1 + (_controller.value * 2), 0),
              end: Alignment(1 + (_controller.value * 2), 0),
              colors: AppColors.rainbowGradient,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Material(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.xl - 2),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl - 2),
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
