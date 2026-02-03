import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Rainbow progress dots widget for task flow visualization
/// Displays colorful dots with checkmarks for completed steps
class SFRainbowProgress extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final bool isSmall;

  const SFRainbowProgress({
    super.key,
    required this.steps,
    required this.currentStep,
    this.isSmall = false,
  });

  // Rainbow colors for each step
  static const List<Color> _stepColors = [
    Color(0xFFE94560), // Red/Primary
    Color(0xFFF59E0B), // Orange/Amber
    Color(0xFF10B981), // Green/Success
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple/Violet
  ];

  @override
  Widget build(BuildContext context) {
    final dotSize = isSmall ? 20.0 : 28.0;
    final iconSize = isSmall ? 12.0 : 16.0;
    final fontSize = isSmall ? 9.0 : 11.0;
    final lineHeight = isSmall ? 2.0 : 3.0;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line between steps
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final nextColor = _getStepColor(stepIndex + 1);
          final prevColor = _getStepColor(stepIndex);

          return Expanded(
            child: Container(
              height: lineHeight,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? LinearGradient(
                        colors: [prevColor, nextColor],
                      )
                    : null,
                color: isCompleted ? null : AppColors.gray200,
              ),
            ),
          );
        } else {
          // Step dot
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          final stepColor = _getStepColor(stepIndex);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent ? stepColor : AppColors.gray200,
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: stepColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: iconSize,
                          color: AppColors.white,
                        )
                      : isCurrent
                          ? Container(
                              width: dotSize * 0.35,
                              height: dotSize * 0.35,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              SizedBox(height: isSmall ? 3 : 5),
              SizedBox(
                width: isSmall ? 50 : 60,
                child: Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: fontSize,
                    color: isCompleted || isCurrent
                        ? AppColors.gray700
                        : AppColors.gray400,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Color _getStepColor(int index) {
    if (index < 0 || index >= _stepColors.length) {
      return _stepColors[index % _stepColors.length];
    }
    return _stepColors[index];
  }
}
