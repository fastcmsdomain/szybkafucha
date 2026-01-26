import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../models/earnings.dart';

/// Earnings summary card for contractor dashboard
class EarningsCard extends StatelessWidget {
  final EarningsSummary earnings;
  final VoidCallback? onTap;

  const EarningsCard({
    super.key,
    required this.earnings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: AppRadius.radiusLG,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zarobki',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.gapMD),

            // This week earnings
            Text(
              '${earnings.weekEarnings.toStringAsFixed(2)} PLN',
              style: AppTypography.h1.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Ten tydzień',
              style: AppTypography.caption.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),

            SizedBox(height: AppSpacing.space4),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  'Dzisiaj',
                  '${earnings.todayEarnings.toStringAsFixed(0)} PLN',
                  '${earnings.tasksToday} zleceń',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.white.withValues(alpha: 0.2),
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.gapMD),
                ),
                _buildStatItem(
                  'Do wypłaty',
                  '${earnings.pendingPayout.toStringAsFixed(0)} PLN',
                  'Dostępne',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subValue) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.white,
            ),
          ),
          Text(
            subValue,
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
