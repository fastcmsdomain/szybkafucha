import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/websocket_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_chat_badge.dart';
import '../../client/models/task_category.dart';
import '../models/models.dart';

/// Contractor home screen / dashboard
class ContractorHomeScreen extends ConsumerStatefulWidget {
  const ContractorHomeScreen({super.key});

  @override
  ConsumerState<ContractorHomeScreen> createState() =>
      _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends ConsumerState<ContractorHomeScreen> {
  bool _isProfileComplete = true; // Assume complete until checked
  bool _isCheckingProfile = true;

  @override
  void initState() {
    super.initState();
    // Load available tasks on screen open
    Future.microtask(() {
      ref.read(availableTasksProvider.notifier).loadTasks();
      ref.read(activeTaskProvider.notifier).refreshActiveTask();
      ref.read(contractorActiveTasksProvider.notifier).loadTasks();
      _checkProfileCompletion();
    });
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>(
        '/contractor/profile/complete',
      );

      if (mounted) {
        setState(() {
          _isProfileComplete = response['complete'] as bool? ?? false;
          _isCheckingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      if (mounted) {
        setState(() {
          _isCheckingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for new tasks via WebSocket
    ref.listen<AsyncValue<NewTaskEvent>>(newTaskAvailableProvider, (previous, next) {
      next.whenData((newTask) {
        // Refresh task list
        ref.read(availableTasksProvider.notifier).refresh();

        // Show alert dialog for new task
        _showNewTaskAlert(newTask);
      });
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // Content
              SliverPadding(
                padding: EdgeInsets.all(AppSpacing.paddingMD),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Top header: greeting left, actions right
                    _buildTopHeader(),

                    SizedBox(height: AppSpacing.space6),

                    // Profile completion banner (if incomplete)
                    if (!_isCheckingProfile && !_isProfileComplete)
                      ...[
                        _buildCompletionBanner(),
                        SizedBox(height: AppSpacing.space6),
                      ],

                    // Active task section (shows task or placeholder)
                    _buildActiveTaskSection(),

                    SizedBox(height: AppSpacing.space6),

                    // See all tasks button
                    _buildSeeAllButton(),

                    SizedBox(height: AppSpacing.space6),

                    // How it works section
                    _buildHowItWorksSection(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Wykonawco';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.gray600,
          ),
        ),
        SizedBox(height: AppSpacing.gapXS),
        Text(
          userName,
          style: AppTypography.h2.copyWith(fontSize: 24),
        ),
        ],
    );
  }

  Widget _buildTopHeader() {
    final tasksState = ref.watch(availableTasksProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildGreeting()),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              onPressed: tasksState.isLoading ? null : _refreshData,
              tooltip: 'Odśwież',
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Show notifications
              },
            ),
          ],
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dzień dobry';
    if (hour < 18) return 'Cześć';
    return 'Dobry wieczór';
  }

  Widget _buildCompletionBanner() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 28),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Text(
              'Dokończ rejestrację, aby zacząć zarabiać',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push(Routes.contractorProfileEdit),
            child: Text(
              'Uzupełnij',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTaskSection() {
    final activeTasksState = ref.watch(contractorActiveTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SFRainbowText('Aktywne zlecenia', style: AppTypography.h5),
            TextButton(
              onPressed: () =>
                  ref.read(contractorActiveTasksProvider.notifier).refresh(),
              child: Text(
                'Odśwież',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        if (activeTasksState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.paddingXL),
              child: CircularProgressIndicator(),
            ),
          )
        else if (activeTasksState.tasks.isEmpty)
          _buildNoActiveTaskPlaceholder()
        else
          ...activeTasksState.tasks.map(
            (task) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.gapMD),
              child: _buildActiveTaskCard(task),
            ),
          ),
      ],
    );
  }

  Widget _buildNoActiveTaskPlaceholder() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 48,
            color: AppColors.gray400,
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            'Brak aktywnych zleceń',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Przejrzyj dostępne zlecenia i zaakceptuj jedno, aby rozpocząć pracę.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeeAllButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push(Routes.contractorTaskList),
        icon: const Icon(Icons.list_alt),
        label: const Text('Zobacz wszystkie zlecenia'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusLG,
          ),
        ),
      ),
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
          border: Border.all(color: AppColors.gray200),
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
                _buildContractorStatusBadge(task.status),
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

            // Footer — address + earnings
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
                    onPressed: () => context.push(Routes.contractorTask(task.id)),
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
                            'taskTitle': task.description,
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

  Widget _buildContractorStatusBadge(ContractorTaskStatus status) {
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

  Future<void> _refreshData() async {
    await Future.wait([
      ref.read(availableTasksProvider.notifier).refresh(),
      ref.read(activeTaskProvider.notifier).refreshActiveTask(),
      ref.read(contractorActiveTasksProvider.notifier).refresh(),
    ]);
  }

  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SFRainbowText('Jak zacząć zarabiać?', style: AppTypography.h5),
        SizedBox(height: AppSpacing.gapMD),
        _buildStepItem(
          number: '1',
          title: 'Przeglądaj zlecenia',
          description:
              'Nowe zadania pojawiają się w Twojej okolicy — wybierz to, co Ci odpowiada',
          icon: Icons.search,
          color: AppColors.primary,
        ),
        _buildStepItem(
          number: '2',
          title: 'Zaakceptuj zlecenie',
          description:
              'Kliknij „Akceptuj" i umów się z szefem na szczegóły',
          icon: Icons.handshake_outlined,
          color: AppColors.warning,
        ),
        _buildStepItem(
          number: '3',
          title: 'Wykonaj zadanie',
          description:
              'Zrealizuj zlecenie i potwierdź zakończenie pracy',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        ),
        _buildStepItem(
          number: '4',
          title: 'Odbierz wypłatę',
          description:
              'Pieniądze trafiają na Twoje konto — szybko i bezpiecznie',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.info,
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
    required Color color,
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
                  color: color,
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
              padding:
                  EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.paddingMD),
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
                    color: color,
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

  void _showNewTaskAlert(NewTaskEvent task) {
    // Haptic feedback for attention
    HapticFeedback.heavyImpact();

    // Get category data - use paczki as fallback if category not found
    final category = TaskCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == task.category.toLowerCase(),
      orElse: () => TaskCategory.paczki,
    );
    final categoryData = TaskCategoryData.fromCategory(category);

    // Show bottom sheet alert
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusXL,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: AppSpacing.paddingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with pulsing indicator
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Text(
                    'Nowe zlecenie!',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  if (task.distance != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.paddingSM,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: AppRadius.radiusSM,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 14,
                            color: AppColors.info,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${task.distance!.toStringAsFixed(1)} km',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Task details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.paddingMD),
                        decoration: BoxDecoration(
                          color: categoryData.color.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusLG,
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
                            SizedBox(height: 4),
                            Text(
                              task.address,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.gray500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.gapLG),

                  // Earnings
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.paddingMD),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: AppRadius.radiusLG,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Do zarobienia: ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '${task.budgetAmount.toStringAsFixed(0)} zł',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray700,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusLG,
                        ),
                        side: BorderSide(color: AppColors.gray300),
                      ),
                      child: const Text('Pomiń'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.gapMD),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to task alert screen with more details
                        context.push(Routes.contractorTaskAlertRoute(task.id));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusLG,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: AppSpacing.gapSM),
                          const Text('Zobacz szczegóły'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
