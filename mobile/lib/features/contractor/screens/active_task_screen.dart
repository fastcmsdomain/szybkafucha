import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/task_provider.dart';
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
            onPressed: () => context.pop(),
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
            onPressed: () => context.pop(),
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
                onPressed: () => context.pop(),
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Aktywne zlecenie',
          style: AppTypography.h4,
        ),
        centerTitle: true,
        actions: [
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
        // Map placeholder
        Container(
          color: AppColors.gray200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: AppColors.gray400,
                ),
                SizedBox(height: AppSpacing.gapMD),
                Text(
                  'Mapa trasy',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                SizedBox(height: AppSpacing.gapSM),
                Text(
                  task.address,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
    // Simplified 3-step flow: Zaakceptowano → W trakcie → Zakończono
    final steps = [
      _StepData('Zaakceptowano', ContractorTaskStatus.accepted),
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

    // Simplified 2-button flow: "Rozpocznij zadanie" → "Zakończ zlecenie"
    switch (_currentStatus) {
      case ContractorTaskStatus.accepted:
        buttonText = 'Rozpocznij zadanie';
        onPressed = () => _startTask();
      case ContractorTaskStatus.inProgress:
        buttonText = 'Zakończ zlecenie';
        onPressed = () => _completeTask(task);
      default:
        buttonText = 'Zakończono';
        onPressed = null;
    }

    return SizedBox(
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
    );
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
                ref.read(activeTaskProvider.notifier).clearTask();
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
