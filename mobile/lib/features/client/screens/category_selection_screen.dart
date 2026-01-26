import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../models/task_category.dart';
import '../widgets/category_card.dart';

/// Category selection screen - first step in task creation
/// Shows 6 categories in a grid layout
class CategorySelectionScreen extends ConsumerStatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  ConsumerState<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState
    extends ConsumerState<CategorySelectionScreen> {
  TaskCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.selectCategory,
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header text
              Text(
                'Czego potrzebujesz?',
                style: AppTypography.h3,
              ),

              SizedBox(height: AppSpacing.gapSM),

              Text(
                'Wybierz kategorię, która najlepiej opisuje Twoje zadanie',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),

              SizedBox(height: AppSpacing.space8),

              // Category grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.gapMD,
                    mainAxisSpacing: AppSpacing.gapMD,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: TaskCategoryData.all.length,
                  itemBuilder: (context, index) {
                    final category = TaskCategoryData.all[index];
                    return CategoryCard(
                      category: category,
                      isSelected: _selectedCategory == category.category,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category.category;
                        });
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: AppSpacing.space4),

              // Selected category info
              if (_selectedCategory != null) _buildSelectedInfo(),

              SizedBox(height: AppSpacing.space4),

              // Continue button
              ElevatedButton(
                onPressed: _selectedCategory != null ? _continueToDetails : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.gray200,
                  disabledForegroundColor: AppColors.gray400,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                  ),
                ),
                child: Text(
                  AppStrings.continueText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedInfo() {
    final category = TaskCategoryData.fromCategory(_selectedCategory!);

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.2),
              borderRadius: AppRadius.radiusSM,
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: category.color,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  category.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                category.priceRange,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                category.estimatedTime,
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _continueToDetails() {
    if (_selectedCategory == null) return;

    // Navigate to task details screen with selected category
    context.push(
      Routes.clientCreateTask,
      extra: _selectedCategory,
    );
  }
}
