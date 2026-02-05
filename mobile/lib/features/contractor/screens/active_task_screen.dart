import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/widgets/sf_map_view.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../../../core/widgets/sf_rainbow_progress.dart';
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
          'Zostaniesz przekierowany do listy dostępnych zleceń.',
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
    // Keep local status in sync with provider updates (e.g., client confirmation)
    if (_currentStatus != task.status) {
      _currentStatus = task.status;
    }

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

                    // Task header above progress
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.paddingSM),
                          decoration: BoxDecoration(
                            color: categoryData.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            categoryData.icon,
                            color: categoryData.color,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: AppSpacing.gapMD),
                        Text(
                          'Twoje zlecenie',
                          style: AppTypography.h5,
                        ),
                      ],
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
    // 4-step flow (per job_flow.md - removed "Do potwierdzenia")
    // Oczekuje → Potwierdzone → W trakcie → Zakończono
    const steps = ['Oczekuje', 'Potwierdzone', 'W trakcie', 'Zakończono'];

    // Map current status to step index (0-3)
    int currentStep;
    switch (_currentStatus) {
      case ContractorTaskStatus.accepted:
        currentStep = 0;
        break;
      case ContractorTaskStatus.confirmed:
        currentStep = 1;
        break;
      case ContractorTaskStatus.inProgress:
        currentStep = 2;
        break;
      case ContractorTaskStatus.pendingComplete:
      case ContractorTaskStatus.completed:
        currentStep = 3;
        break;
      default:
        currentStep = 0;
    }

    return SFRainbowProgress(
      steps: steps,
      currentStep: currentStep,
      isSmall: true, // Smaller version for contractor screen per spec
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

          // Scheduled time
          SizedBox(height: AppSpacing.gapMD),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: task.scheduledAt == null ? AppColors.warning : AppColors.primary,
              ),
              SizedBox(width: AppSpacing.gapXS),
              Text(
                task.scheduledAt == null
                    ? 'Teraz'
                    : _formatScheduledTime(task.scheduledAt!),
                style: AppTypography.caption.copyWith(
                  color: task.scheduledAt == null ? AppColors.warning : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Images
          if (task.imageUrls != null && task.imageUrls!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Zdjęcia',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: task.imageUrls!.length,
                itemBuilder: (context, index) {
                  final imageUrl = task.imageUrls![index];
                  return GestureDetector(
                    onTap: () => _showFullImage(imageUrl),
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.only(right: AppSpacing.gapSM),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.radiusSM,
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.radiusSM,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.gray100,
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppColors.gray400,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatScheduledTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year o $hour:$minute';
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray900.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: AppColors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(ContractorTask task) {
    final canContact = _currentStatus != ContractorTaskStatus.accepted;

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
          TextButton.icon(
            onPressed: () => _showClientProfile(task),
            icon: const Icon(Icons.person_outline, color: AppColors.white),
            label: const Text(''),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingMD,
                vertical: AppSpacing.paddingSM,
              ),
            ),
          ),
          if (canContact) ...[
            SizedBox(width: AppSpacing.gapSM),
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
        ],
      ),
    );
  }

  Widget _buildActionButton(ContractorTask task) {
    String buttonText;
    VoidCallback? onPressed;
    bool isWaitingForStart = false;
    bool isWaitingForCompletion = false;

    // Status flow: accepted (waiting) → confirmed → inProgress → completed
    switch (_currentStatus) {
      case ContractorTaskStatus.accepted:
        // Waiting for client to confirm - cannot start yet
        buttonText = 'Oczekuje na potwierdzenie';
        onPressed = null;
        isWaitingForStart = true;
        break;
      case ContractorTaskStatus.confirmed:
        // Client confirmed - can now start work
        buttonText = 'Rozpocznij';
        onPressed = () => _startTask();
        break;
      case ContractorTaskStatus.inProgress:
        // Work is in progress but completion must be confirmed by the client first
        buttonText = 'Zakończ zlecenie';
        onPressed = null;
        isWaitingForCompletion = true;
        break;
      case ContractorTaskStatus.pendingComplete:
        buttonText = 'Zakończ zlecenie';
        onPressed = () => _completeTask(task);
        break;
      default:
        buttonText = 'Zakończono';
        onPressed = null;
        break;
    }

    // Show cancel button for accepted and confirmed tasks (before work starts)
    final showCancelButton = _currentStatus == ContractorTaskStatus.accepted ||
        _currentStatus == ContractorTaskStatus.confirmed;

    return Column(
      children: [
        // Info message when waiting for client confirmation
        if (isWaitingForStart) ...[
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
        if (isWaitingForCompletion) ...[
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: AppColors.info, size: 20),
                SizedBox(width: AppSpacing.gapSM),
                Expanded(
                  child: Text(
                    'Klient musi potwierdzić zakończenie zlecenia. Poczekaj na jego akceptację, zanim zakończysz.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
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

  void _showClientProfile(ContractorTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ClientProfileSheet(
        clientId: task.clientId,
        clientName: task.clientName,
        clientRating: task.clientRating,
        clientAvatarUrl: task.clientAvatarUrl,
      ),
    );
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
              tileColor: AppColors.error,
              leading: const Icon(Icons.cancel_outlined, color: Colors.white),
              title: const Text(
                'Anuluj zlecenie',
                style: TextStyle(color: Colors.white),
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

/// Client profile bottom sheet that fetches full profile data
class _ClientProfileSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final double clientRating;
  final String? clientAvatarUrl;

  const _ClientProfileSheet({
    required this.clientId,
    required this.clientName,
    required this.clientRating,
    this.clientAvatarUrl,
  });

  @override
  ConsumerState<_ClientProfileSheet> createState() =>
      _ClientProfileSheetState();
}

class _ClientProfileSheetState extends ConsumerState<_ClientProfileSheet> {
  String? _bio;
  double? _ratingAvg;
  int? _ratingCount;
  String? _avatarUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFullProfile();
  }

  Future<void> _fetchFullProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/client/${widget.clientId}/public');

      // Backend returns flat structure with bio at root level
      final data = response.data as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _bio = data['bio'] as String?;
          _ratingAvg = (data['ratingAvg'] as num?)?.toDouble();
          _ratingCount = data['ratingCount'] as int?;
          _avatarUrl = data['avatarUrl'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching client profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = _ratingAvg ?? widget.clientRating;
    final reviewCount = _ratingCount ?? 0;
    final avatarUrl = _avatarUrl ?? widget.clientAvatarUrl;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profil klienta', style: AppTypography.h4),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.gapMD),

            // Avatar and name row
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.gray200,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          widget.clientName.isNotEmpty
                              ? widget.clientName[0].toUpperCase()
                              : '?',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.gray600,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: AppSpacing.gapMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.clientName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 18, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$reviewCount opinii',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.gapMD),

            // Bio section
            Text(
              'Opis',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.gray700,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            _isLoading
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : _error != null
                    ? Text(
                        'Nie udało się pobrać pełnego profilu',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray400,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        _bio?.isNotEmpty == true
                            ? _bio!
                            : 'Brak opisu klienta.',
                        style: AppTypography.bodySmall.copyWith(
                          color: _bio?.isNotEmpty == true
                              ? AppColors.gray600
                              : AppColors.gray400,
                          fontStyle: _bio?.isNotEmpty == true
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
            SizedBox(height: AppSpacing.gapMD),

            // Close button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      ),
    );
  }
}
