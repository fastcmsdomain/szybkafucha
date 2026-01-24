import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/contractor_availability_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../client/models/task_category.dart';
import '../models/models.dart';
import '../widgets/availability_toggle.dart';
import '../widgets/earnings_card.dart';
import '../widgets/nearby_task_card.dart';

/// Contractor home screen / dashboard
class ContractorHomeScreen extends ConsumerStatefulWidget {
  const ContractorHomeScreen({super.key});

  @override
  ConsumerState<ContractorHomeScreen> createState() =>
      _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends ConsumerState<ContractorHomeScreen> {
  final _earnings = EarningsSummary.mock();

  @override
  void initState() {
    super.initState();
    // Load available tasks on screen open
    Future.microtask(() {
      ref.read(availableTasksProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                title: Text(
                  'Szybka Fucha',
                  style: AppTypography.h4,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // TODO: Show notifications
                    },
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.all(AppSpacing.paddingMD),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Availability toggle
                    Consumer(
                      builder: (context, ref, _) {
                        final availabilityState =
                            ref.watch(contractorAvailabilityProvider);
                        return AvailabilityToggle(
                          isOnline: availabilityState.isOnline,
                          isLoading: availabilityState.isLoading,
                          onToggle: _toggleAvailability,
                        );
                      },
                    ),

                    SizedBox(height: AppSpacing.space6),

                    // Earnings card
                    EarningsCard(
                      earnings: _earnings,
                      onTap: () => context.push(Routes.contractorEarnings),
                    ),

                    SizedBox(height: AppSpacing.space6),

                    // Active task (if any)
                    if (_hasActiveTask) ...[
                      _buildActiveTaskSection(),
                      SizedBox(height: AppSpacing.space6),
                    ],

                    // Nearby tasks section
                    _buildNearbyTasksSection(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasActiveTask {
    final activeTaskState = ref.watch(activeTaskProvider);
    return activeTaskState.task != null;
  }

  Widget _buildActiveTaskSection() {
    final activeTaskState = ref.watch(activeTaskProvider);
    final activeTask = activeTaskState.task;
    if (activeTask == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktywne zlecenie',
              style: AppTypography.h4,
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingSM,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusSM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapXS),
                  Text(
                    activeTask.status.displayName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        _buildActiveTaskCard(activeTask),
      ],
    );
  }

  Widget _buildActiveTaskCard(ContractorTask task) {
    final categoryData = TaskCategoryData.fromCategory(task.category);

    return GestureDetector(
      onTap: () => context.push(Routes.contractorTask(task.id)),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.paddingSM),
                  decoration: BoxDecoration(
                    color: categoryData.color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Icon(categoryData.icon, color: categoryData.color),
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryData.name,
                        style: AppTypography.labelLarge,
                      ),
                      Text(
                        task.address,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  task.formattedEarnings,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.gapMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(Routes.contractorTask(task.id)),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Nawiguj'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Open chat
                    },
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Czat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray700,
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

  Widget _buildNearbyTasksSection() {
    final tasksState = ref.watch(availableTasksProvider);
    final nearbyTasks = tasksState.tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zlecenia w pobliżu',
              style: AppTypography.h4,
            ),
            TextButton(
              onPressed: () => context.push(Routes.contractorTaskList),
              child: Text(
                'Zobacz wszystkie',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        if (!ref.watch(contractorAvailabilityProvider).isOnline)
          _buildOfflineMessage()
        else if (tasksState.isLoading)
          _buildLoadingState()
        else if (tasksState.error != null)
          _buildErrorState(tasksState.error!)
        else if (nearbyTasks.isEmpty)
          _buildNoTasksMessage()
        else
          ...nearbyTasks.take(3).map((task) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.gapMD),
                child: NearbyTaskCard(
                  task: task,
                  onTap: () => _showTaskDetails(task),
                  onDetails: () => _showTaskDetails(task),
                  onAccept: () => _acceptTask(task),
                ),
              )),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.radiusLG,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            'Wystąpił błąd',
            style: AppTypography.labelLarge.copyWith(
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
          SizedBox(height: AppSpacing.gapMD),
          ElevatedButton.icon(
            onPressed: () => ref.read(availableTasksProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Spróbuj ponownie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineMessage() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off,
            size: 48,
            color: AppColors.gray400,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            'Jesteś offline',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Włącz dostępność, aby zobaczyć zlecenia w pobliżu i otrzymywać powiadomienia.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoTasksMessage() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.gray400,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            'Brak zleceń w pobliżu',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Poczekaj na nowe zlecenia lub rozszerz promień działania w ustawieniach.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await ref.read(availableTasksProvider.notifier).refresh();
  }

  Future<void> _toggleAvailability(bool value) async {
    try {
      await ref
          .read(contractorAvailabilityProvider.notifier)
          .toggleAvailability(value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Jesteś teraz dostępny dla klientów'
                  : 'Nie będziesz otrzymywać nowych zleceń',
            ),
            backgroundColor: value ? AppColors.success : AppColors.gray600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // Get error from provider state
      final errorMessage =
          ref.read(contractorAvailabilityProvider).error ??
              'Nie udało się zmienić statusu dostępności';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showTaskDetails(ContractorTask task) {
    context.push(
      Routes.contractorTaskAlertRoute(task.id),
      extra: task,
    );
  }

  Future<void> _acceptTask(ContractorTask task) async {
    try {
      final acceptedTask = await ref.read(availableTasksProvider.notifier).acceptTask(task.id);

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
          ),
        );
      }
    }
  }
}
