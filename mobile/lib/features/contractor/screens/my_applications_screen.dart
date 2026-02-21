/// My Applications Screen
/// Shows contractor's application history with statuses

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/task_provider.dart';
import '../../../core/theme/theme.dart';
import '../../client/models/task_application.dart';
import '../../client/models/task_category.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myApplicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje zgłoszenia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(myApplicationsProvider.notifier).loadApplications(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, MyApplicationsState state) {
    if (state.isLoading && state.applications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: AppSpacing.paddingSM),
            Text('Błąd: ${state.error}'),
            SizedBox(height: AppSpacing.paddingSM),
            ElevatedButton(
              onPressed: () => ref
                  .read(myApplicationsProvider.notifier)
                  .loadApplications(),
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (state.applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: AppColors.gray300),
            SizedBox(height: AppSpacing.paddingSM),
            Text(
              'Brak zgłoszeń',
              style:
                  AppTypography.bodyLarge.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: AppSpacing.paddingXS),
            Text(
              'Zgłoś się do zleceń, aby je tutaj zobaczyć',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(myApplicationsProvider.notifier).loadApplications(),
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        itemCount: state.applications.length,
        separatorBuilder: (_, __) => SizedBox(height: AppSpacing.paddingSM),
        itemBuilder: (context, index) {
          final app = state.applications[index];
          return _ApplicationListItem(
            application: app,
            onWithdraw: app.status.isPending
                ? () => _withdrawApplication(context, ref, app)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _withdrawApplication(
    BuildContext context,
    WidgetRef ref,
    MyApplication app,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wycofaj zgłoszenie'),
        content: Text(
            'Czy chcesz wycofać zgłoszenie do "${app.taskTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nie'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Wycofaj'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(myApplicationsProvider.notifier)
          .withdrawApplication(app.taskId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zgłoszenie wycofane')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }
}

class _ApplicationListItem extends StatelessWidget {
  final MyApplication application;
  final VoidCallback? onWithdraw;

  const _ApplicationListItem({
    required this.application,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    // Try matching by enum name first, then by display name
    final category = TaskCategory.values
        .where((c) => c.name == application.taskCategory)
        .firstOrNull;
    final categoryData = category != null
        ? TaskCategoryData.fromCategory(category)
        : TaskCategoryData.fromName(application.taskCategory) ??
            TaskCategoryData.fromCategory(TaskCategory.paczki);

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
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
          // Task info
          Row(
            children: [
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
              SizedBox(width: AppSpacing.paddingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.taskTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      application.taskAddress,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge
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
          ),
          SizedBox(height: AppSpacing.paddingSM),

          // Price comparison
          Row(
            children: [
              Text(
                'Twoja cena: ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              Text(
                '${application.proposedPrice.toStringAsFixed(0)} zł',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.paddingSM),
              Text(
                '(budżet: ${application.taskBudgetAmount.toStringAsFixed(0)} zł)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),

          // Withdraw button for pending
          if (onWithdraw != null) ...[
            SizedBox(height: AppSpacing.paddingSM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onWithdraw,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Wycofaj zgłoszenie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (application.status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.withdrawn:
        return AppColors.gray500;
    }
  }
}
