import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_chat_badge.dart';
import '../models/task.dart';

/// Client task list screen - shows all active tasks
/// Displayed under the "Zlecenia" tab
class ClientTaskListScreen extends ConsumerStatefulWidget {
  const ClientTaskListScreen({super.key});

  @override
  ConsumerState<ClientTaskListScreen> createState() =>
      _ClientTaskListScreenState();
}

class _ClientTaskListScreenState extends ConsumerState<ClientTaskListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(clientTasksProvider);
      if (state.tasks.isEmpty && !state.isLoading) {
        ref.read(clientTasksProvider.notifier).loadTasks();
      }
    });
  }

  Future<void> _refreshTasks() async {
    await ref.read(clientTasksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(clientTasksProvider);
    final activeTasks = tasksState.activeTasks;

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText('Zlecenia'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: tasksState.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: tasksState.isLoading ? null : _refreshTasks,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: tasksState.isLoading && activeTasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : tasksState.error != null
              ? _buildErrorState(tasksState.error!)
              : activeTasks.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshTasks,
                      child: ListView.separated(
                        padding: EdgeInsets.all(AppSpacing.paddingMD),
                        itemCount: activeTasks.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: AppSpacing.gapMD),
                        itemBuilder: (context, index) {
                          return _buildTaskCard(context, activeTasks[index]);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.clientCreateTask),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nowe zlecenie'),
        tooltip: 'Utwórz nowe zlecenie',
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Wystąpił błąd',
              style: AppTypography.h5.copyWith(
                color: AppColors.gray600,
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 48,
              color: AppColors.gray400,
            ),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Brak aktywnych zleceń',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Utwórz swoje pierwsze zlecenie, aby znaleźć pomocnika',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final category = task.categoryData;

    return Semantics(
      label: 'Otwórz szczegóły zlecenia ${category.name}',
      button: true,
      child: GestureDetector(
        onTap: () {
          if (task.status.isActive) {
            context.push(Routes.clientTaskTrack(task.id));
          } else {
            context.go(Routes.clientHistory);
          }
        },
        child: Container(
          padding: EdgeInsets.all(AppSpacing.paddingMD),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.radiusLG,
            border: Border.all(
              color: task.status == TaskStatus.confirmed ||
                      task.status == TaskStatus.inProgress ||
                      task.status == TaskStatus.pendingComplete
                  ? AppColors.success
                  : AppColors.gray200,
              width: task.status == TaskStatus.confirmed ||
                      task.status == TaskStatus.inProgress ||
                      task.status == TaskStatus.pendingComplete
                  ? 2.0
                  : 1.0,
            ),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.paddingSM),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMD,
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
                          style: AppTypography.labelMedium.copyWith(
                            color: category.color,
                          ),
                        ),
                        Text(
                          _formatDate(task.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(task.status),
                      SizedBox(height: AppSpacing.gapXS),
                      _buildApplicationsBadge(task),
                    ],
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.gapMD),

              // Title + description preview
              Text(
                task.title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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

              // Footer row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (task.address != null) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    SizedBox(width: AppSpacing.gapXS),
                    Expanded(
                      child: Text(
                        task.address!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppSpacing.gapSM),
                  ] else
                    const Spacer(),
                  Text(
                    '${task.budget} PLN',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Action buttons for active tasks
              if (task.status.isActive) ...[
                SizedBox(height: AppSpacing.gapMD),
                Row(
                  children: [
                    // Track button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.push(Routes.clientTaskTrack(task.id)),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Więcej'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                    // Chat button — visible when contractor is assigned
                    if (task.status == TaskStatus.confirmed ||
                        task.status == TaskStatus.inProgress ||
                        task.status == TaskStatus.pendingComplete) ...[
                      SizedBox(width: AppSpacing.gapSM),
                      Expanded(
                        child: SFChatBadge(
                          taskId: task.id,
                          otherUserId:
                              task.contractor?.id ?? task.contractorId,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final currentUser =
                                  ref.read(currentUserProvider);
                              context.push(
                                Routes.clientTaskChatRoute(task.id),
                                extra: {
                                  'otherUserId': task.contractor?.id ??
                                      task.contractorId ??
                                      '',
                                  'taskTitle': task.title.trim().isNotEmpty
                                      ? task.title
                                      : (task.description.trim().isNotEmpty
                                          ? task.description
                                          : 'Czat'),
                                  'otherUserName':
                                      task.contractor?.name ?? 'Wykonawca',
                                  'otherUserAvatarUrl':
                                      task.contractor?.avatarUrl,
                                  'currentUserId': currentUser?.id ?? '',
                                  'currentUserName':
                                      currentUser?.name ?? 'Ty',
                                },
                              );
                            },
                            icon:
                                const Icon(Icons.chat_outlined, size: 16),
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
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color color;
    String text = status.displayName;

    switch (status) {
      case TaskStatus.posted:
        color = AppColors.warning;
      case TaskStatus.accepted:
        color = AppColors.info;
      case TaskStatus.confirmed:
        color = AppColors.success;
      case TaskStatus.inProgress:
        color = AppColors.primary;
      case TaskStatus.pendingComplete:
        color = AppColors.info;
      case TaskStatus.completed:
        color = AppColors.success;
      case TaskStatus.cancelled:
        color = AppColors.gray500;
      case TaskStatus.disputed:
        color = AppColors.error;
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
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildApplicationsBadge(Task task) {
    final isFull = task.applicationCount >= task.maxApplications;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingSM,
        vertical: AppSpacing.paddingXS,
      ),
      decoration: BoxDecoration(
        color: isFull
            ? AppColors.gray200
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 12,
            color: isFull ? AppColors.gray500 : AppColors.primary,
          ),
          SizedBox(width: AppSpacing.gapXS),
          Text(
            '${task.applicationCount}/${task.maxApplications}',
            style: AppTypography.caption.copyWith(
              color: isFull ? AppColors.gray500 : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
}
