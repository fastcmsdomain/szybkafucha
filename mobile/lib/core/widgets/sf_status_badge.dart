import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Task status enum matching backend
enum TaskStatus {
  created,
  accepted,
  inProgress,
  pendingComplete,
  completed,
  confirmed,
  cancelled,
  disputed,
}

/// Task status badge widget
class SFStatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool showIcon;

  const SFStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingSM,
        vertical: AppSpacing.paddingXS,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppRadius.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _icon,
              size: 14,
              color: _textColor,
            ),
            SizedBox(width: AppSpacing.gapXS),
          ],
          Text(
            _label,
            style: AppTypography.labelSmall.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String get _label => switch (status) {
        TaskStatus.created => 'Nowe',
        TaskStatus.accepted => 'Zaakceptowane',
        TaskStatus.inProgress => 'W trakcie',
        TaskStatus.pendingComplete => 'Oczekuje na potwierdzenie wykonawcy',
        TaskStatus.completed => 'Ukończone',
        TaskStatus.confirmed => 'Potwierdzone',
        TaskStatus.cancelled => 'Anulowane',
        TaskStatus.disputed => 'Sporne',
      };

  IconData get _icon => switch (status) {
        TaskStatus.created => Icons.fiber_new_rounded,
        TaskStatus.accepted => Icons.thumb_up_rounded,
        TaskStatus.inProgress => Icons.hourglass_top_rounded,
        TaskStatus.pendingComplete => Icons.pending_actions,
        TaskStatus.completed => Icons.check_circle_outline_rounded,
        TaskStatus.confirmed => Icons.verified_rounded,
        TaskStatus.cancelled => Icons.cancel_outlined,
        TaskStatus.disputed => Icons.warning_rounded,
      };

  Color get _backgroundColor => switch (status) {
        TaskStatus.created => AppColors.primary.withValues(alpha: 0.1),
        TaskStatus.accepted => AppColors.accent.withValues(alpha: 0.1),
        TaskStatus.inProgress => AppColors.warning.withValues(alpha: 0.1),
        TaskStatus.pendingComplete => AppColors.info.withValues(alpha: 0.1),
        TaskStatus.completed => AppColors.success.withValues(alpha: 0.1),
        TaskStatus.confirmed => AppColors.success.withValues(alpha: 0.1),
        TaskStatus.cancelled => AppColors.gray200,
        TaskStatus.disputed => AppColors.error.withValues(alpha: 0.1),
      };

  Color get _textColor => switch (status) {
        TaskStatus.created => AppColors.primary,
        TaskStatus.accepted => AppColors.accent,
        TaskStatus.inProgress => AppColors.warning,
        TaskStatus.pendingComplete => AppColors.info,
        TaskStatus.completed => AppColors.success,
        TaskStatus.confirmed => AppColors.success,
        TaskStatus.cancelled => AppColors.gray600,
        TaskStatus.disputed => AppColors.error,
      };
}

/// KYC status badge
enum KycStatus {
  pending,
  inProgress,
  verified,
  rejected,
}

class SFKycBadge extends StatelessWidget {
  final KycStatus status;

  const SFKycBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingSM,
        vertical: AppSpacing.paddingXS,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppRadius.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 14,
            color: _textColor,
          ),
          SizedBox(width: AppSpacing.gapXS),
          Text(
            _label,
            style: AppTypography.labelSmall.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String get _label => switch (status) {
        KycStatus.pending => 'Oczekuje',
        KycStatus.inProgress => 'Weryfikacja',
        KycStatus.verified => 'Zweryfikowany',
        KycStatus.rejected => 'Odrzucony',
      };

  IconData get _icon => switch (status) {
        KycStatus.pending => Icons.schedule_rounded,
        KycStatus.inProgress => Icons.hourglass_top_rounded,
        KycStatus.verified => Icons.verified_user_rounded,
        KycStatus.rejected => Icons.gpp_bad_rounded,
      };

  Color get _backgroundColor => switch (status) {
        KycStatus.pending => AppColors.gray200,
        KycStatus.inProgress => AppColors.warning.withValues(alpha: 0.1),
        KycStatus.verified => AppColors.success.withValues(alpha: 0.1),
        KycStatus.rejected => AppColors.error.withValues(alpha: 0.1),
      };

  Color get _textColor => switch (status) {
        KycStatus.pending => AppColors.gray600,
        KycStatus.inProgress => AppColors.warning,
        KycStatus.verified => AppColors.success,
        KycStatus.rejected => AppColors.error,
      };
}
