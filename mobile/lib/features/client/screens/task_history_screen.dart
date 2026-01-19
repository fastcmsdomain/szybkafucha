import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../models/task.dart';
import '../models/task_category.dart';

/// Task history screen showing past tasks
class TaskHistoryScreen extends ConsumerStatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  ConsumerState<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends ConsumerState<TaskHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _activeTasks = [];
  List<Task> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _activeTasks = _getMockActiveTasks();
        _completedTasks = _getMockCompletedTasks();
        _isLoading = false;
      });
    }
  }

  List<Task> _getMockActiveTasks() {
    return [
      Task(
        id: 'active_1',
        category: TaskCategory.paczki,
        description: 'Odbiór paczki z paczkomatu i dostawa pod drzwi',
        address: 'ul. Marszałkowska 1, Warszawa',
        budget: 45,
        isImmediate: true,
        status: TaskStatus.inProgress,
        clientId: 'user_1',
        contractorId: 'contractor_1',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        acceptedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ];
  }

  List<Task> _getMockCompletedTasks() {
    return [
      Task(
        id: 'completed_1',
        category: TaskCategory.zakupy,
        description: 'Zakupy spożywcze z Biedronki',
        address: 'ul. Złota 44, Warszawa',
        budget: 60,
        isImmediate: true,
        status: TaskStatus.completed,
        clientId: 'user_1',
        contractorId: 'contractor_2',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'completed_2',
        category: TaskCategory.montaz,
        description: 'Montaż półek IKEA',
        address: 'ul. Puławska 12, Warszawa',
        budget: 150,
        isImmediate: false,
        scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
        status: TaskStatus.completed,
        clientId: 'user_1',
        contractorId: 'contractor_3',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 5)),
        completedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Task(
        id: 'completed_3',
        category: TaskCategory.paczki,
        description: 'Nadanie paczki Poczta Polska',
        address: 'ul. Nowy Świat 21, Warszawa',
        budget: 35,
        isImmediate: true,
        status: TaskStatus.completed,
        clientId: 'user_1',
        contractorId: 'contractor_1',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 10)),
        completedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Task(
        id: 'cancelled_1',
        category: TaskCategory.sprzatanie,
        description: 'Sprzątanie mieszkania 50m2',
        address: 'ul. Wołoska 3, Warszawa',
        budget: 200,
        isImmediate: false,
        scheduledAt: DateTime.now().subtract(const Duration(days: 15)),
        status: TaskStatus.cancelled,
        clientId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 16)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historia zleceń',
          style: AppTypography.h4,
        ),
        centerTitle: true,
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
                  if (_activeTasks.isNotEmpty) ...[
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
                        '${_activeTasks.length}',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(_activeTasks, isActive: true),
                _buildTaskList(_completedTasks, isActive: false),
              ],
            ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, {required bool isActive}) {
    if (tasks.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
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
        if (isActive && task.status == TaskStatus.inProgress) {
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

            // Action button for active tasks
            if (isActive && task.status == TaskStatus.inProgress) ...[
              SizedBox(height: AppSpacing.gapMD),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(Routes.clientTaskTrack(task.id)),
                  child: Text('Śledź zlecenie'),
                ),
              ),
            ],
          ],
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
      case TaskStatus.inProgress:
        color = AppColors.primary;
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

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppStrings.close),
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
