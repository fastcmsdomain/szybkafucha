import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../models/task.dart';

/// Task history screen showing past tasks
/// Uses real API data via clientTasksProvider
class TaskHistoryScreen extends ConsumerStatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  ConsumerState<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends ConsumerState<TaskHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load tasks on screen open
    Future.microtask(() {
      ref.read(clientTasksProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    await ref.read(clientTasksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(clientTasksProvider);
    final activeTasks = tasksState.activeTasks;
    final completedTasks = tasksState.completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historia zleceń',
          style: AppTypography.h4,
        ),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Aktywne'),
                  if (activeTasks.isNotEmpty) ...[
                    SizedBox(width: AppSpacing.gapSM),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.radiusFull,
                      ),
                      child: Text(
                        '${activeTasks.length}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Historia'),
          ],
        ),
      ),
      body: tasksState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasksState.error != null
              ? _buildErrorState(tasksState.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(activeTasks, isActive: true),
                    _buildTaskList(completedTasks, isActive: false),
                  ],
                ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.space4),
            Text(
              'Wystąpił błąd',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
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
              icon: Icon(Icons.refresh),
              label: Text('Spróbuj ponownie'),
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

  Widget _buildTaskList(List<Task> tasks, {required bool isActive}) {
    if (tasks.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        itemCount: tasks.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: AppSpacing.gapMD),
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index], isActive: isActive);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.pending_actions : Icons.history,
              size: 64,
              color: AppColors.gray300,
            ),
            SizedBox(height: AppSpacing.space4),
            Text(
              isActive
                  ? 'Brak aktywnych zleceń'
                  : 'Brak historii zleceń',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              isActive
                  ? 'Utwórz nowe zlecenie, aby znaleźć pomocnika'
                  : 'Tutaj pojawią się Twoje zakończone zlecenia',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              SizedBox(height: AppSpacing.space6),
              ElevatedButton.icon(
                onPressed: () => context.go(Routes.clientCreateTask),
                icon: Icon(Icons.add),
                label: Text('Nowe zlecenie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, {required bool isActive}) {
    final category = task.categoryData;

    return GestureDetector(
      onTap: () {
        if (isActive &&
            (task.status == TaskStatus.inProgress ||
                task.status == TaskStatus.pendingComplete)) {
          context.push(Routes.clientTaskTrack(task.id));
        } else {
          // Show task details in a bottom sheet
          _showTaskDetails(task);
        }
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: AppColors.gray200),
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
                _buildStatusBadge(task.status),
              ],
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Description
            Text(
              task.description,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Footer row
            Row(
              children: [
                if (task.address != null) ...[
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.gray500,
                  ),
                  SizedBox(width: 4),
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
                ],
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
            if (isActive) ...[
              SizedBox(height: AppSpacing.gapMD),
              Row(
                children: [
                  // Track button (for in progress tasks)
                  if (task.status == TaskStatus.inProgress ||
                      task.status == TaskStatus.accepted ||
                      task.status == TaskStatus.confirmed ||
                      task.status == TaskStatus.pendingComplete)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(Routes.clientTaskTrack(task.id)),
                        child: Text('Więcej'),
                      ),
                    ),
                  if (task.status == TaskStatus.inProgress ||
                      task.status == TaskStatus.accepted ||
                      task.status == TaskStatus.confirmed ||
                      task.status == TaskStatus.pendingComplete)
                    SizedBox(width: AppSpacing.gapSM),
                  // Cancel button (for all active non-completed tasks)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelConfirmation(task),
                      icon: Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                      label: Text(
                        'Anuluj',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color color = switch (status) {
      TaskStatus.posted => AppColors.warning,
      TaskStatus.accepted => AppColors.info,
      TaskStatus.confirmed => AppColors.success,
      TaskStatus.inProgress => AppColors.primary,
      TaskStatus.pendingComplete => AppColors.info,
      TaskStatus.completed => AppColors.success,
      TaskStatus.cancelled => AppColors.gray500,
      TaskStatus.disputed => AppColors.error,
    };

    String text = status.displayName;

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

  void _showTaskDetails(Task task) {
    final category = task.categoryData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.radiusXL.topLeft.x),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: AppSpacing.paddingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: AppRadius.radiusFull,
              ),
            ),

            Padding(
              padding: EdgeInsets.all(AppSpacing.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.paddingMD),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusMD,
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: AppSpacing.gapMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: AppTypography.h4,
                            ),
                            _buildStatusBadge(task.status),
                          ],
                        ),
                      ),
                      Text(
                        '${task.budget} PLN',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.space4),

                  // Description
                  Text(
                    'Opis',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapXS),
                  Text(
                    task.description,
                    style: AppTypography.bodyMedium,
                  ),

                  SizedBox(height: AppSpacing.space4),

                  // Location
                  if (task.address != null) ...[
                    Text(
                      'Lokalizacja',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    SizedBox(height: AppSpacing.gapXS),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.gray600,
                        ),
                        SizedBox(width: AppSpacing.gapSM),
                        Expanded(
                          child: Text(
                            task.address!,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.space4),
                  ],

                  // Dates
                  _buildDetailRow('Utworzono', _formatDate(task.createdAt)),
                  if (task.acceptedAt != null)
                    _buildDetailRow('Przyjęto', _formatDate(task.acceptedAt!)),
                  if (task.completedAt != null)
                    _buildDetailRow('Zakończono', _formatDate(task.completedAt!)),

                  SizedBox(height: AppSpacing.space6),

                  // Action buttons row
                  Row(
                    children: [
                      // Cancel button (for active tasks)
                      if (task.status.isActive) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCancelConfirmation(task);
                            },
                            icon: Icon(Icons.cancel_outlined, color: AppColors.error),
                            label: Text(
                              'Anuluj',
                              style: TextStyle(color: AppColors.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.gapMD),
                      ],
                      // Close button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppStrings.close),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anuluj zlecenie?'),
        content: Text(
          'Czy na pewno chcesz anulować to zlecenie? '
          '${task.status == TaskStatus.posted ? '' : 'Może to wiązać się z opłatą.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nie'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelTask(task);
            },
            child: Text(
              'Tak, anuluj',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTask(Task task) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/tasks/${task.id}/cancel');

      // Refresh tasks list
      await ref.read(clientTasksProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zlecenie zostało anulowane'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd anulowania: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.gapXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
