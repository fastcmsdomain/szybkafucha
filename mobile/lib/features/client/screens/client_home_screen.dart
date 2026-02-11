import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../models/task.dart';
// import '../models/task_category.dart';
// import '../widgets/category_card.dart';

/// Client home screen - main dashboard for clients
/// Shows welcome message, quick actions, and active/recent tasks
class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Tasks are auto-loaded by clientTasksProvider when created
    // Only load if not already loaded or data is stale
    Future.microtask(() {
      final state = ref.read(clientTasksProvider);
      if (state.tasks.isEmpty && !state.isLoading) {
        ref.read(clientTasksProvider.notifier).loadTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bottomNavPadding = AppSpacing.paddingLG + kBottomNavigationBarHeight;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.paddingLG,
            AppSpacing.paddingLG,
            AppSpacing.paddingLG,
            bottomNavPadding + AppSpacing.paddingMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome header
              _buildWelcomeHeader(user?.name),

              // SizedBox(height: AppSpacing.space8),

              // Quick action - Create task
              // _buildQuickActionCard(context),

              // SizedBox(height: AppSpacing.space8),

              // Popular categories
              // _buildPopularCategories(context),

              // SizedBox(height: AppSpacing.space8),

              // Active tasks section
              _buildActiveTasksSection(context),

              SizedBox(height: AppSpacing.space4),

              // How it works section
              _buildHowItWorksSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.clientCreateTask),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nowe zlecenie'),
      ),
    );
  }

  Widget _buildWelcomeHeader(String? userName) {
    final greeting = _getGreeting();
    final name = userName ?? 'Użytkowniku';
    final tasksState = ref.watch(clientTasksProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(height: AppSpacing.gapXS),
              Text(
                name,
                style: AppTypography.h2,
              ),
            ],
          ),
        ),
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
              : Icon(Icons.refresh, color: AppColors.primary),
          onPressed: tasksState.isLoading ? null : _refreshTasks,
          tooltip: 'Odśwież',
        ),
      ],
    );
  }

  Future<void> _refreshTasks() async {
    await ref.read(clientTasksProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Odświeżono'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dzień dobry';
    if (hour < 18) return 'Cześć';
    return 'Dobry wieczór';
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.clientCategories),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.radiusXL,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Potrzebujesz pomocy?',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapSM),
                  Text(
                    'Znajdź kogoś, kto pomoże Ci w codziennych zadaniach',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapMD),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingMD,
                      vertical: AppSpacing.paddingSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      'Utwórz zlecenie',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.gapMD),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(
                Icons.handshake_outlined,
                size: 48,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTasksSection(BuildContext context) {
    final tasksState = ref.watch(clientTasksProvider);
    final activeTasks = tasksState.activeTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.activeTasks,
              style: AppTypography.h5,
            ),
            TextButton(
              onPressed: () => context.go(Routes.clientHistory),
              child: Text(
                AppStrings.viewHistory,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        
        // Loading state
        if (tasksState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.paddingXL),
              child: CircularProgressIndicator(),
            ),
          )
        // Empty state
        else if (activeTasks.isEmpty)
          _buildEmptyState()
        // List of active tasks
        else
          ...activeTasks.take(3).map((task) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.gapMD),
                child: _buildTaskCard(context, task),
              )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 48,
            color: AppColors.gray400,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            AppStrings.noActiveTasks,
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
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final category = task.categoryData;

    final isLocked = task.status == TaskStatus.pendingComplete;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
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
              crossAxisAlignment: CrossAxisAlignment.center,
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

            // Action button for active tasks (skip waiting-for-contractor-confirmation)
            if (task.status.isActive && task.status != TaskStatus.pendingComplete) ...[
              SizedBox(height: AppSpacing.gapMD),
              Row(
                children: [
                  // Track button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push(Routes.clientTaskTrack(task.id)),
                      child: Text('Więcej'),
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

  void _showCancelConfirmation(BuildContext context, Task task) {
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

  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jak to działa?',
          style: AppTypography.h5,
        ),
        SizedBox(height: AppSpacing.gapMD),
        _buildStepItem(
          number: '1',
          title: 'Opisz zadanie',
          description: 'Wybierz kategorię i opisz, czego potrzebujesz',
          icon: Icons.edit_note_outlined,
        ),
        _buildStepItem(
          number: '2',
          title: 'Znajdź pomocnika',
          description: 'Przeglądaj profile i wybierz najlepszą osobę',
          icon: Icons.person_search_outlined,
        ),
        _buildStepItem(
          number: '3',
          title: 'Gotowe!',
          description: 'Śledź postęp i oceń po zakończeniu',
          icon: Icons.check_circle_outline,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.gray200,
                  ),
                ),
            ],
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.paddingMD),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    icon,
                    color: AppColors.gray400,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
