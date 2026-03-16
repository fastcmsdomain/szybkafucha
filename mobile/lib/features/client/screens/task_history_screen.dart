import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_task_location_map.dart';
import '../models/task.dart';

/// Task history screen showing past (completed/cancelled) tasks only
/// Uses real API data via clientTasksProvider
class TaskHistoryScreen extends ConsumerStatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  ConsumerState<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends ConsumerState<TaskHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(clientTasksProvider.notifier).loadTasks();
    });
  }

  Future<void> _refreshTasks() async {
    await ref.read(clientTasksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(clientTasksProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final clientTasks = currentUserId == null
        ? tasksState.tasks
        : tasksState.tasks
            .where((task) => task.clientId == currentUserId)
            .toList();
    final completedTasks =
        clientTasks.where((task) => !task.status.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText('Historia zleceń'),
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
      body: tasksState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasksState.error != null
              ? _buildErrorState(tasksState.error!)
              : _buildTaskList(completedTasks),
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

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        itemCount: tasks.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: AppSpacing.gapMD),
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index]);
        },
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
              Icons.history,
              size: 64,
              color: AppColors.gray300,
            ),
            SizedBox(height: AppSpacing.space4),
            Text(
              'Brak historii zleceń',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Tutaj pojawią się Twoje zakończone zlecenia',
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

  Widget _buildTaskCard(Task task) {
    final category = task.categoryData;

    return Semantics(
      label: 'Otwórz szczegóły zlecenia ${category.name}',
      button: true,
      child: GestureDetector(
        onTap: () => _showTaskDetails(task),
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
            ],
          ),
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
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.paddingLG),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: AppSpacing.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
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

                // Title
                Text(
                  'Tytuł',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                SizedBox(height: AppSpacing.gapXS),
                Text(
                  task.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                  task.description.trim().isEmpty
                      ? 'Brak opisu'
                      : task.description,
                  style: AppTypography.bodyMedium,
                ),

                SizedBox(height: AppSpacing.space4),

                // Location
                if (task.address != null || _hasLocation(task)) ...[
                  Text(
                    'Lokalizacja',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  if (task.address != null) ...[
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
                  ] else ...[
                    SizedBox(height: AppSpacing.gapXS),
                    Text(
                      'Dokładna pozycja zadania',
                      style: AppTypography.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.space4),
                  ],
                  if (_hasLocation(task)) ...[
                    SFTaskLocationMap(
                      taskLocation: LatLng(task.latitude!, task.longitude!),
                    ),
                    SizedBox(height: AppSpacing.space4),
                  ],
                ],

                // Dates
                _buildDetailRow('Utworzono', _formatDate(task.createdAt)),
                if (task.acceptedAt != null)
                  _buildDetailRow('Przyjęto', _formatDate(task.acceptedAt!)),
                if (task.completedAt != null)
                  _buildDetailRow(
                      'Zakończono', _formatDate(task.completedAt!)),

                SizedBox(height: AppSpacing.space6),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(AppStrings.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasLocation(Task task) {
    return task.latitude != null &&
        task.longitude != null &&
        task.latitude != 0 &&
        task.longitude != 0;
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
