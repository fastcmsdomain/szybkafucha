import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../models/contractor_task.dart';
import '../../client/models/task_category.dart';

/// Contractor task history screen showing active and past tasks in tabs
class ContractorTaskHistoryScreen extends ConsumerStatefulWidget {
  const ContractorTaskHistoryScreen({super.key});

  @override
  ConsumerState<ContractorTaskHistoryScreen> createState() =>
      _ContractorTaskHistoryScreenState();
}

class _ContractorTaskHistoryScreenState
    extends ConsumerState<ContractorTaskHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(contractorActiveTasksProvider.notifier).refresh();
      ref.read(contractorHistoryProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(contractorActiveTasksProvider.notifier).refresh(),
      ref.read(contractorHistoryProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(contractorActiveTasksProvider);
    final historyState = ref.watch(contractorHistoryProvider);
    final isLoading = activeState.isLoading || historyState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: SFRainbowText('Moje zlecenia'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refresh,
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
                  const Text('Aktywne'),
                  if (activeState.tasks.isNotEmpty) ...[
                    SizedBox(width: AppSpacing.gapSM),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.paddingXS,
                        vertical: AppSpacing.gapXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.radiusFull,
                      ),
                      child: Text(
                        '${activeState.tasks.length}',
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
            const Tab(text: 'Historia'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(activeState.tasks, isActive: true),
                _buildTaskList(historyState.tasks, isActive: false),
              ],
            ),
    );
  }

  Widget _buildTaskList(List<ContractorTask> tasks, {required bool isActive}) {
    if (tasks.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        itemCount: tasks.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: AppSpacing.gapMD),
        itemBuilder: (context, index) =>
            _buildTaskCard(tasks[index], isActive: isActive),
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
                  ? 'Przeglądaj dostępne zlecenia, aby zacząć zarabiać'
                  : 'Tutaj pojawią się Twoje zakończone zlecenia',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              SizedBox(height: AppSpacing.space6),
              ElevatedButton.icon(
                onPressed: () => context.go(Routes.contractorTaskList),
                icon: const Icon(Icons.search),
                label: const Text('Szukaj zleceń'),
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

  Widget _buildTaskCard(ContractorTask task, {required bool isActive}) {
    final categoryData = TaskCategoryData.fromCategory(task.category);

    return Semantics(
      label: 'Zlecenie ${categoryData.name}, ${task.status.displayName}',
      button: true,
      child: GestureDetector(
        onTap: isActive
            ? () => context.push(Routes.contractorTask(task.id))
            : () => _showTaskDetails(task),
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
                      color: categoryData.color.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMD,
                    ),
                    child: Icon(
                      categoryData.icon,
                      color: categoryData.color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryData.name,
                          style: AppTypography.labelMedium.copyWith(
                            color: categoryData.color,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.gray500,
                  ),
                  SizedBox(width: AppSpacing.gapXS),
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
                  SizedBox(width: AppSpacing.gapSM),
                  Text(
                    '${task.price} PLN',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Action button for active tasks
              if (isActive) ...[
                SizedBox(height: AppSpacing.gapMD),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            context.push(Routes.contractorTask(task.id)),
                        child: const Text('Szczegóły'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.gapSM),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                            Routes.contractorTaskChatRoute(task.id)),
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text('Czat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ContractorTaskStatus status) {
    final color = switch (status) {
      ContractorTaskStatus.available => AppColors.gray400,
      ContractorTaskStatus.offered => AppColors.warning,
      ContractorTaskStatus.accepted => AppColors.info,
      ContractorTaskStatus.confirmed => AppColors.success,
      ContractorTaskStatus.inProgress => AppColors.primary,
      ContractorTaskStatus.pendingComplete => AppColors.info,
      ContractorTaskStatus.completed => AppColors.success,
      ContractorTaskStatus.cancelled => AppColors.gray500,
    };

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

  void _showTaskDetails(ContractorTask task) {
    final categoryData = TaskCategoryData.fromCategory(task.category);

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
                          color: categoryData.color.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusMD,
                        ),
                        child: Icon(
                          categoryData.icon,
                          color: categoryData.color,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: AppSpacing.gapMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryData.name,
                              style: AppTypography.h4,
                            ),
                            _buildStatusBadge(task.status),
                          ],
                        ),
                      ),
                      Text(
                        '${task.price} PLN',
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
                          task.address,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.space4),

                  // Dates
                  _buildDetailRow('Zlecono', _formatDate(task.createdAt)),
                  if (task.acceptedAt != null)
                    _buildDetailRow(
                        'Przyjęto', _formatDate(task.acceptedAt!)),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Zamknij'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
