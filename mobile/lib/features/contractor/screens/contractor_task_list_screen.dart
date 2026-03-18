import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_chat_badge.dart';
import '../../client/models/task_category.dart';
import '../models/models.dart';

/// Contractor Zlecenia tab — shows contractor's current/active tasks
class ContractorTaskListScreen extends ConsumerStatefulWidget {
  const ContractorTaskListScreen({super.key});

  @override
  ConsumerState<ContractorTaskListScreen> createState() =>
      _ContractorTaskListScreenState();
}

class _ContractorTaskListScreenState
    extends ConsumerState<ContractorTaskListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(contractorActiveTasksProvider.notifier).loadTasks();
      ref.read(activeTaskProvider.notifier).refreshActiveTask();
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([
      ref.read(contractorActiveTasksProvider.notifier).refresh(),
      ref.read(activeTaskProvider.notifier).refreshActiveTask(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final activeTasksState = ref.watch(contractorActiveTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText('Moje zlecenia'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: activeTasksState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: activeTasksState.isLoading ? null : _refreshData,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: activeTasksState.isLoading && activeTasksState.tasks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : activeTasksState.tasks.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.paddingMD),
                    itemCount: activeTasksState.tasks.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppSpacing.gapMD),
                    itemBuilder: (context, index) =>
                        _buildActiveTaskCard(activeTasksState.tasks[index]),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(Icons.work_outline, size: 64, color: AppColors.gray400),
              SizedBox(height: AppSpacing.gapMD),
              Text(
                'Brak aktywnych zleceń',
                style: AppTypography.h5.copyWith(color: AppColors.gray600),
              ),
              SizedBox(height: AppSpacing.gapSM),
              Text(
                'Przejdź do Główna, aby przeglądać\ndostępne zlecenia.',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _taskDetailRoute(ContractorTask task) {
    if (task.status == ContractorTaskStatus.offered) {
      return Routes.contractorTaskRoomRoute(task.id);
    }
    return Routes.contractorTask(task.id);
  }

  Widget _buildActiveTaskCard(ContractorTask task) {
    final categoryData = TaskCategoryData.fromCategory(task.category);
    final bool isActive = task.status == ContractorTaskStatus.accepted ||
        task.status == ContractorTaskStatus.confirmed ||
        task.status == ContractorTaskStatus.inProgress ||
        task.status == ContractorTaskStatus.pendingComplete;

    return GestureDetector(
      onTap: () => context.push(_taskDetailRoute(task)),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: isActive ? AppColors.success : AppColors.gray200,
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — icon + category + date | status badge
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.paddingSM),
                  decoration: BoxDecoration(
                    color: categoryData.color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Icon(categoryData.icon,
                      color: categoryData.color, size: 24),
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryData.name,
                        style: AppTypography.labelMedium
                            .copyWith(color: categoryData.color),
                      ),
                      Text(
                        _formatDate(task.createdAt),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(task.status),
              ],
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Title + description
            Text(
              task.title,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description.trim().isNotEmpty) ...[
              SizedBox(height: AppSpacing.gapXS),
              Text(
                task.description,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            SizedBox(height: AppSpacing.gapMD),

            // Footer — address + earnings
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.gray500),
                SizedBox(width: AppSpacing.gapXS),
                Expanded(
                  child: Text(
                    task.address,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.gray500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: AppSpacing.gapSM),
                Text(
                  task.formattedEarnings,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Action row — Więcej + Czat
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(_taskDetailRoute(task)),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Więcej'),
                  ),
                ),
                SizedBox(width: AppSpacing.gapSM),
                Expanded(
                  child: SFChatBadge(
                    taskId: task.id,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final currentUser = ref.read(currentUserProvider);
                        context.push(
                          Routes.contractorTaskChatRoute(task.id),
                          extra: {
                            'otherUserId': task.clientId,
                            'taskTitle': task.title.trim().isNotEmpty
                                ? task.title
                                : (task.description.trim().isNotEmpty
                                    ? task.description
                                    : 'Czat'),
                            'otherUserName': task.clientName,
                            'otherUserAvatarUrl': task.clientAvatarUrl,
                            'currentUserId': currentUser?.id ?? '',
                            'currentUserName': currentUser?.name ?? 'Ty',
                          },
                        );
                      },
                      icon: const Icon(Icons.chat_outlined, size: 16),
                      label: const Text('Czat'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Dzisiaj, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Wczoraj';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dni temu';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  Widget _buildStatusBadge(ContractorTaskStatus status) {
    Color color;
    switch (status) {
      case ContractorTaskStatus.confirmed:
        color = AppColors.success;
      case ContractorTaskStatus.inProgress:
        color = AppColors.primary;
      case ContractorTaskStatus.pendingComplete:
        color = AppColors.info;
      case ContractorTaskStatus.accepted:
        color = AppColors.warning;
      default:
        color = AppColors.gray500;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingSM,
        vertical: AppSpacing.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSM,
      ),
      child: Text(
        status.displayName,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
