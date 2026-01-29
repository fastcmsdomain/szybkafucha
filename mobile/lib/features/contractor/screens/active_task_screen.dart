import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/task_provider.dart';
import '../../../core/widgets/sf_map_view.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../client/models/task_category.dart';
import '../models/contractor_task.dart';

/// Active task screen for contractors - shows task details, navigation, and progress
class ActiveTaskScreen extends ConsumerStatefulWidget {
  final String taskId;

  const ActiveTaskScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<ActiveTaskScreen> createState() => _ActiveTaskScreenState();
}

class _ActiveTaskScreenState extends ConsumerState<ActiveTaskScreen> {
  ContractorTaskStatus _currentStatus = ContractorTaskStatus.accepted;
  bool _isUpdating = false;
  bool _hasFetchedTask = false;
  bool _wasTaskCancelled = false;

  @override
  void initState() {
    super.initState();
    // Fetch task if not already in provider
    Future.microtask(() {
      final currentTask = ref.read(activeTaskProvider).task;
      if (currentTask == null || currentTask.id != widget.taskId) {
        ref.read(activeTaskProvider.notifier).fetchTask(widget.taskId);
      } else {
        // Sync local status with task status
        setState(() {
          _currentStatus = currentTask.status;
        });
      }
      _hasFetchedTask = true;
    });

    // Listen for task cancellation (e.g., client cancelled the task)
    Future.microtask(() {
      ref.listenManual(activeTaskProvider, (previous, next) {
        // If task was present before but is now null, it was cancelled
        if (previous?.task != null && next.task == null && !_wasTaskCancelled) {
          _wasTaskCancelled = true;
          _showTaskCancelledDialog();
        }
      });
    });
  }

  /// Show dialog when task is cancelled by client
  void _showTaskCancelledDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: AppSpacing.gapSM),
            const Text('Zlecenie anulowane'),
          ],
        ),
        content: const Text(
          'Klient anulował to zlecenie. Zostaniesz przekierowany do listy dostępnych zleceń.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Refresh available tasks and go home
              ref.read(availableTasksProvider.notifier).refresh();
              context.go(Routes.contractorHome);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Navigate back safely - use go() if nothing to pop
  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.contractorHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(activeTaskProvider);
    final task = taskState.task;

    // Show loading while fetching
    if (taskState.isLoading || (!_hasFetchedTask && task == null)) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: Text('Aktywne zlecenie', style: AppTypography.h4),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if task not found
    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: Text('Aktywne zlecenie', style: AppTypography.h4),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              SizedBox(height: AppSpacing.gapMD),
              Text(
                'Nie znaleziono zlecenia',
                style: AppTypography.bodyLarge,
              ),
              if (taskState.error != null) ...[
                SizedBox(height: AppSpacing.gapSM),
                Text(
                  taskState.error!,
                  style: AppTypography.caption.copyWith(color: AppColors.gray500),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: AppSpacing.gapLG),
              ElevatedButton(
                onPressed: () => _navigateBack(context),
                child: const Text('Wróć'),
              ),
            ],
          ),
        ),
      );
    }

    final categoryData = TaskCategoryData.fromCategory(task.category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        title: Text(
          'Aktywne zlecenie',
          style: AppTypography.h4,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTask,
            tooltip: 'Odśwież',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map placeholder
          Expanded(
            flex: 2,
            child: _buildMapSection(task),
          ),

          // Task details and actions
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray900.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius: AppRadius.radiusSM,
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.space4),

                    // Progress steps
                    _buildProgressSteps(),

                    SizedBox(height: AppSpacing.space6),

                    // Task info card
                    _buildTaskInfoCard(task, categoryData),

                    SizedBox(height: AppSpacing.space4),

                    // Client info
                    _buildClientCard(task),

                    SizedBox(height: AppSpacing.space4),

                    // Action button
                    _buildActionButton(task),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(ContractorTask task) {
    return Stack(
      children: [
        // Real map showing task location
        SFMapView(
          center: LatLng(task.latitude, task.longitude),
          zoom: 15,
          markers: [
            TaskMarker(
              position: LatLng(task.latitude, task.longitude),
            ),
          ],
          interactive: true,
          showZoomControls: true,
        ),

        // Navigate button overlay
        Positioned(
          bottom: AppSpacing.paddingMD,
          right: AppSpacing.paddingMD,
          child: FloatingActionButton.extended(
            onPressed: () => _openNavigation(task),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.navigation),
            label: const Text('Nawiguj'),
          ),
        ),

        // Distance badge
        Positioned(
          top: AppSpacing.paddingMD,
          left: AppSpacing.paddingMD,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingMD,
              vertical: AppSpacing.paddingSM,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.radiusMD,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray900.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car,
                  size: 16,
                  color: AppColors.gray600,
                ),
                SizedBox(width: AppSpacing.gapSM),
                Text(
                  '${task.formattedDistance} • ${task.formattedEta}',
                  style: AppTypography.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    // 4-step flow: Oczekuje → Potwierdzone → W trakcie → Zakończono
    final steps = [
      _StepData('Oczekuje', ContractorTaskStatus.accepted),
      _StepData('Potwierdzone', ContractorTaskStatus.confirmed),
      _StepData('W trakcie', ContractorTaskStatus.inProgress),
      _StepData('Zakończono', ContractorTaskStatus.completed),
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = _currentStatus.index > step.status.index;
        final isCurrent = _currentStatus == step.status;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : AppColors.gray200,
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? Icon(Icons.check, size: 18, color: AppColors.white)
                        : isCurrent
                            ? Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                  ),
                  SizedBox(height: 6),
                  Text(
                    step.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isCurrent
                          ? AppColors.primary
                          : isCompleted
                              ? AppColors.gray700
                              : AppColors.gray400,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(bottom: 24),
                    color: isCompleted ? AppColors.primary : AppColors.gray200,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskInfoCard(ContractorTask task, TaskCategoryData categoryData) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusLG,
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
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    task.formattedEarnings,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'zarobek',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            task.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(ContractorTask task) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gray200,
            child: Text(
              task.clientName.isNotEmpty ? task.clientName[0] : '?',
              style: AppTypography.h4.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.clientName,
                  style: AppTypography.labelLarge,
                ),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.warning),
                    SizedBox(width: 2),
                    Text(
                      task.clientRating.toStringAsFixed(1),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.gray100,
            ),
          ),
          SizedBox(width: AppSpacing.gapSM),
          IconButton(
            onPressed: _callClient,
            icon: const Icon(Icons.phone_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              foregroundColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ContractorTask task) {
    String buttonText;
    VoidCallback? onPressed;
    bool isWaiting = false;

    // Status flow: accepted (waiting) → confirmed → inProgress → completed
    switch (_currentStatus) {
      case ContractorTaskStatus.accepted:
        // Waiting for client to confirm - cannot start yet
        buttonText = 'Oczekuje na potwierdzenie';
        onPressed = null;
        isWaiting = true;
      case ContractorTaskStatus.confirmed:
        // Client confirmed - can now start work
        buttonText = 'Rozpocznij';
        onPressed = () => _startTask();
      case ContractorTaskStatus.inProgress:
        buttonText = 'Zakończ zlecenie';
        onPressed = () => _completeTask(task);
      default:
        buttonText = 'Zakończono';
        onPressed = null;
    }

    // Show cancel button for accepted and confirmed tasks (before work starts)
    final showCancelButton = _currentStatus == ContractorTaskStatus.accepted ||
        _currentStatus == ContractorTaskStatus.confirmed;

    return Column(
      children: [
        // Info message when waiting for client confirmation
        if (isWaiting) ...[
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty, color: AppColors.warning, size: 20),
                SizedBox(width: AppSpacing.gapSM),
                Expanded(
                  child: Text(
                    'Klient musi potwierdzić przyjęcie zlecenia. Poczekaj na potwierdzenie.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.gapMD),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingLG),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusLG,
              ),
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            ),
            child: _isUpdating
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        if (showCancelButton) ...[
          SizedBox(height: AppSpacing.gapMD),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUpdating ? null : _showCancelConfirmation,
              icon: Icon(Icons.cancel_outlined, color: AppColors.error),
              label: Text(
                'Anuluj',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusLG,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Refresh task data from backend
  Future<void> _refreshTask() async {
    await ref.read(activeTaskProvider.notifier).fetchTask(widget.taskId);
    final task = ref.read(activeTaskProvider).task;
    if (task != null && mounted) {
      setState(() {
        _currentStatus = task.status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zlecenie odświeżone'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Start the task - transitions from accepted to in_progress
  Future<void> _startTask() async {
    setState(() => _isUpdating = true);

    try {
      // Call backend to start task (sets status to in_progress)
      await ref.read(activeTaskProvider.notifier).updateStatus(
        widget.taskId,
        'start',
      );

      setState(() {
        _currentStatus = ContractorTaskStatus.inProgress;
        _isUpdating = false;
      });
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _completeTask(ContractorTask task) {
    // Navigate to completion screen
    context.push(
      '/contractor/task/${widget.taskId}/complete',
      extra: task,
    );
  }

  Future<void> _openNavigation(ContractorTask task) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${task.latitude},${task.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChat() {
    context.push(Routes.contractorTaskChatRoute(widget.taskId));
  }

  Future<void> _callClient() async {
    // TODO: Get client phone number from task/backend
    final uri = Uri(scheme: 'tel', path: '+48123456789');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Pomoc'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show help
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: AppColors.error),
              title: Text(
                'Anuluj zlecenie',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCancelConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anulować zlecenie?'),
        content: const Text(
          'Anulowanie zaakceptowanego zlecenia może wpłynąć na Twoją ocenę i ranking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nie'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(activeTaskProvider.notifier).updateStatus(
                  widget.taskId,
                  'cancel',
                );
                // Clear contractor's active task
                ref.read(activeTaskProvider.notifier).clearTask();
                // Refresh available tasks so the released task appears in "nearby tasks"
                ref.read(availableTasksProvider.notifier).refresh();
                if (mounted) {
                  context.go(Routes.contractorHome);
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
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Tak, anuluj'),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final String label;
  final ContractorTaskStatus status;

  _StepData(this.label, this.status);
}
