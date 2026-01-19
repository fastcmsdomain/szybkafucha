import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../client/models/task_category.dart';
import '../models/contractor_task.dart';

/// Nearby task card for contractor dashboard
class NearbyTaskCard extends StatelessWidget {
  final ContractorTask task;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;

  const NearbyTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final categoryData = TaskCategoryData.fromCategory(task.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: task.isUrgent ? AppColors.warning : AppColors.gray200,
            width: task.isUrgent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Category icon
                Container(
                  padding: EdgeInsets.all(AppSpacing.paddingSM),
                  decoration: BoxDecoration(
                    color: categoryData.color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Icon(
                    categoryData.icon,
                    color: categoryData.color,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppSpacing.gapMD),

                // Category and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            categoryData.name,
                            style: AppTypography.labelMedium,
                          ),
                          if (task.isUrgent) ...[
                            SizedBox(width: AppSpacing.gapSM),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: AppRadius.radiusSM,
                              ),
                              child: Text(
                                'PILNE',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _getTimeAgo(task.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      task.formattedEarnings,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'do zarobienia',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Description
            Text(
              task.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Location and distance
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.gray500,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.address,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingSM,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: AppRadius.radiusSM,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 12,
                        color: AppColors.gray600,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${task.formattedDistance} • ${task.formattedEta}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Client info and accept button
            Row(
              children: [
                // Client info
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.gray200,
                  child: Text(
                    task.clientName[0],
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.gapSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.clientName,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 2),
                          Text(
                            task.clientRating.toStringAsFixed(1),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Accept button
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingMD,
                      vertical: AppSpacing.paddingSM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                  child: const Text('Przyjmij'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Przed chwilą';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min temu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} godz. temu';
    } else {
      return '${difference.inDays} dni temu';
    }
  }
}
