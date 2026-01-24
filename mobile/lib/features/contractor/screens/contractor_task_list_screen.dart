import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/task_provider.dart';
import '../../../core/providers/contractor_availability_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../models/contractor_task.dart';
import '../widgets/nearby_task_card.dart';

/// Full list of available tasks for contractors
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
    // Load tasks on screen open
    Future.microtask(() {
      ref.read(availableTasksProvider.notifier).loadTasks();
    });
  }

  Future<void> _refreshTasks() async {
    await ref.read(availableTasksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(availableTasksProvider);
    final availabilityState = ref.watch(contractorAvailabilityProvider);
    final tasks = tasksState.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dostępne zlecenia',
          style: AppTypography.h4,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: _buildBody(tasksState, availabilityState, tasks),
      ),
    );
  }

  Widget _buildBody(
    AvailableTasksState tasksState,
    dynamic availabilityState,
    List<ContractorTask> tasks,
  ) {
    // Check if contractor is offline
    if (!availabilityState.isOnline) {
      return _buildOfflineMessage();
    }

    // Loading state
    if (tasksState.isLoading && tasks.isEmpty) {
      return _buildLoadingState();
    }

    // Error state
    if (tasksState.error != null) {
      return _buildErrorState(tasksState.error!);
    }

    // Empty state
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }

    // List of tasks
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.gapMD),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return NearbyTaskCard(
          task: task,
          onTap: () => _showTaskDetails(task),
          onDetails: () => _showTaskDetails(task),
          onAccept: () => _acceptTask(task),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Ładowanie zleceń...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
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
              Icons.search_off,
              size: 64,
              color: AppColors.gray400,
            ),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Brak dostępnych zleceń',
              style: AppTypography.h5.copyWith(
                color: AppColors.gray600,
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Obecnie nie ma żadnych dostępnych zleceń w Twojej okolicy. '
              'Sprawdź ponownie później.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Odśwież'),
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

  Widget _buildOfflineMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: AppColors.gray400,
            ),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Jesteś offline',
              style: AppTypography.h5.copyWith(
                color: AppColors.gray600,
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Włącz dostępność, aby zobaczyć dostępne zlecenia i otrzymywać powiadomienia.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to home where they can toggle availability
                context.go(Routes.contractorHome);
              },
              icon: const Icon(Icons.home),
              label: const Text('Wróć do ekranu głównego'),
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

  void _showTaskDetails(ContractorTask task) {
    context.push(
      Routes.contractorTaskAlertRoute(task.id),
      extra: task,
    );
  }

  Future<void> _acceptTask(ContractorTask task) async {
    try {
      final acceptedTask =
          await ref.read(availableTasksProvider.notifier).acceptTask(task.id);

      // Set as active task in provider
      ref.read(activeTaskProvider.notifier).setTask(acceptedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zaakceptowano zlecenie: ${task.category.name}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate to active task screen
        context.push(Routes.contractorTask(task.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
