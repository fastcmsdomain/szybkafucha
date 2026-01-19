import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../models/task_category.dart';

/// Card widget for displaying a task category
class CategoryCard extends StatelessWidget {
  final TaskCategoryData category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.1)
              : AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: isSelected ? category.color : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: isSelected ? 0.2 : 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(
                category.icon,
                size: 28,
                color: category.color,
              ),
            ),

            SizedBox(height: AppSpacing.gapSM),

            // Category name
            Text(
              category.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? category.color : AppColors.gray800,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2),

            // Price range
            Text(
              category.priceRange,
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontal category chip for selection lists
class CategoryChip extends StatelessWidget {
  final TaskCategoryData category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMD,
          vertical: AppSpacing.paddingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? category.color : AppColors.white,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(
            color: isSelected ? category.color : AppColors.gray300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 18,
              color: isSelected ? AppColors.white : category.color,
            ),
            SizedBox(width: AppSpacing.gapSM),
            Text(
              category.name,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
