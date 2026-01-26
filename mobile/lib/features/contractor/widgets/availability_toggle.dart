import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Availability toggle widget for contractors
class AvailabilityToggle extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

  const AvailabilityToggle({
    super.key,
    required this.isOnline,
    this.isLoading = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        gradient: isOnline
            ? LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.1),
                  AppColors.success.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isOnline ? null : AppColors.gray100,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(
          color: isOnline
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.gray400,
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: AppColors.white,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.gapMD),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Jesteś online' : 'Jesteś offline',
                  style: AppTypography.labelLarge.copyWith(
                    color: isOnline ? AppColors.success : AppColors.gray600,
                  ),
                ),
                Text(
                  isOnline
                      ? 'Otrzymujesz powiadomienia o nowych zleceniach'
                      : 'Nie otrzymujesz nowych zleceń',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),

          // Toggle switch
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  isOnline ? AppColors.success : AppColors.gray400,
                ),
              ),
            )
          else
            Switch(
              value: isOnline,
              onChanged: onToggle,
              activeThumbColor: AppColors.success,
              activeTrackColor: AppColors.success.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}
