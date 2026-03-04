/// Application Card Widget
/// Displays a contractor's application/bid for a task

import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_chat_badge.dart';
import '../models/task_application.dart';

class ApplicationCard extends StatelessWidget {
  final TaskApplication application;
  final int? taskBudget;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onKick;
  final VoidCallback? onChat;
  final VoidCallback? onViewProfile;
  final VoidCallback? onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    this.taskBudget,
    this.onAccept,
    this.onReject,
    this.onKick,
    this.onChat,
    this.onViewProfile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = application.status.isPending;
    final priceDifference = taskBudget != null
        ? application.proposedPrice - taskBudget!
        : null;
    final isCheaper = priceDifference != null && priceDifference < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: application.status == ApplicationStatus.accepted
                ? AppColors.success
                : AppColors.gray200,
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
            // Contractor info row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.gray200,
                  backgroundImage: application.contractorAvatarUrl != null
                      ? NetworkImage(application.contractorAvatarUrl!)
                      : null,
                  child: application.contractorAvatarUrl == null
                      ? Icon(Icons.person, color: AppColors.gray500, size: 24)
                      : null,
                ),
                SizedBox(width: AppSpacing.paddingSM),

                // Name + rating + stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.contractorName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.warning),
                          SizedBox(width: 2),
                          Text(
                            application.formattedRating,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' (${application.contractorReviewCount})',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                          SizedBox(width: AppSpacing.paddingSM),
                          Icon(Icons.check_circle, size: 14, color: AppColors.success),
                          SizedBox(width: 2),
                          Text(
                            '${application.contractorCompletedTasks} zleceń',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Proposed price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      application.formattedPrice,
                      style: AppTypography.headingSmall.copyWith(
                        color: isCheaper ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (priceDifference != null)
                      Text(
                        priceDifference == 0
                            ? 'Twój budżet'
                            : '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)} zł',
                        style: AppTypography.bodySmall.copyWith(
                          color: isCheaper ? AppColors.success : AppColors.gray500,
                        ),
                      ),
                  ],
                ),
              ],
            ),


            // Message
            if (application.message != null &&
                application.message!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.paddingSM),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: AppRadius.radiusMD,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote,
                        size: 16, color: AppColors.gray400),
                    SizedBox(width: AppSpacing.paddingXS),
                    Expanded(
                      child: Text(
                        application.message!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray700,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (only for pending applications)
            if (isPending && (onAccept != null || onReject != null || onKick != null || onChat != null)) ...[
              SizedBox(height: AppSpacing.paddingSM),
              // Row 1: Profil | Czat
              if (onViewProfile != null || onChat != null)
                Row(
                  children: [
                    if (onViewProfile != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onViewProfile,
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text('Profil'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                            padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.paddingSM),
                          ),
                        ),
                      ),
                    if (onViewProfile != null && onChat != null)
                      SizedBox(width: AppSpacing.paddingSM),
                    if (onChat != null)
                      Expanded(
                        child: SFChatBadge(
                          taskId: application.taskId,
                          otherUserId: application.contractorId,
                          child: OutlinedButton.icon(
                            onPressed: onChat,
                            icon: Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Czat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
                              padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.paddingSM),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              // Row 2: Zwolnij | Akceptuj
              if (onKick != null || onAccept != null)
                SizedBox(height: AppSpacing.paddingXS),
              if (onKick != null || onAccept != null)
                Row(
                  children: [
                    if (onKick != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onKick,
                          icon: Icon(Icons.person_remove, size: 16),
                          label: const Text('Zwolnij'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.paddingSM),
                          ),
                        ),
                      ),
                    if (onKick != null && onAccept != null)
                      SizedBox(width: AppSpacing.paddingSM),
                    if (onAccept != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAccept,
                          icon: Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Akceptuj'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.paddingSM),
                          ),
                        ),
                      ),
                  ],
                ),
            ],

            // Status badge (for non-pending)
            if (!isPending) ...[
              SizedBox(height: AppSpacing.paddingSM),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingSM,
                  vertical: AppSpacing.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusSM,
                ),
                child: Text(
                  application.status.displayName,
                  style: AppTypography.bodySmall.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (application.status) {
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.withdrawn:
        return AppColors.gray500;
      case ApplicationStatus.kicked:
        return AppColors.gray500;
      case ApplicationStatus.pending:
        return AppColors.warning;
    }
  }
}
