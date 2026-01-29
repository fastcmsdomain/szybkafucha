import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../models/task_category.dart';

/// Large pill-style category button (matches common-categories.png)
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
    return _CategoryPill(
      category: category,
      isSelected: isSelected,
      onTap: onTap,
      dense: false,
    );
  }
}

/// Compact pill for inline selection lists (keeps the same visual language)
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
    return _CategoryPill(
      category: category,
      isSelected: isSelected,
      onTap: onTap,
      dense: true,
    );
  }
}

/// Shared pill implementation used across screens to keep categories consistent.
class _CategoryPill extends StatelessWidget {
  final TaskCategoryData category;
  final bool isSelected;
  final bool dense;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.isSelected,
    required this.dense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double verticalPadding =
        dense ? AppSpacing.paddingSM : AppSpacing.paddingMD;
    final double horizontalPadding =
        dense ? AppSpacing.paddingMD : AppSpacing.paddingLG;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(
          minHeight: dense ? 52 : 64,
          minWidth: dense ? 150 : 180,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(
            color: isSelected
                ? category.color.withValues(alpha: 0.65)
                : AppColors.gray300,
            width: isSelected ? 1.6 : 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.gray900.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: dense ? 20 : 22,
              color: category.color,
            ),
            SizedBox(width: AppSpacing.gapMD),
            Flexible(
              child: Text(
                category.name,
                style: (dense ? AppTypography.bodyMedium : AppTypography.bodyLarge)
                    .copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
