import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../models/task_category.dart';
import '../widgets/category_card.dart';

/// Category selection screen - first step in task creation
/// Shows all available categories in a scrollable 2-column grid layout
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
        title: SFRainbowText(AppStrings.selectCategory),
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

              // Category pills (2-column wrap to mirror design)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double spacing = AppSpacing.gapMD;
                    final double itemWidth =
                        (constraints.maxWidth - spacing) / 2;

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: TaskCategoryData.all.map((category) {
                          return SizedBox(
                            width: itemWidth,
                            child: CategoryCard(
                              category: category,
                              isSelected: _selectedCategory ==
                                  category.category,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category.category;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
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
