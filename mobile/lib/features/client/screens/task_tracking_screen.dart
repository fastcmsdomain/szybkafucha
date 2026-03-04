import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/credits_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/websocket_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/widgets/sf_map_view.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../../../core/widgets/sf_rainbow_progress.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../../../core/widgets/sf_chat_badge.dart';
import '../models/contractor.dart';
import '../models/task.dart';
import '../models/task_application.dart';
import '../widgets/application_card.dart';

/// Task tracking status (5 states - bidding system with rating step)
enum TrackingStatus {
  applications, // Waiting for contractor applications (bidding)
  confirmed, // Client accepted an application - contractor confirmed
  inProgress,
  rating, // Awaiting ratings from both parties
  completed,
}

enum _TaskOptionsAction { details, edit, map, reportProblem, cancel }

extension TrackingStatusExtension on TrackingStatus {
  String get title {
    switch (this) {
      case TrackingStatus.applications:
        return 'Zgłoszenia wykonawców';
      case TrackingStatus.confirmed:
        return 'Wykonawca potwierdzony';
      case TrackingStatus.inProgress:
        return 'Praca w toku';
      case TrackingStatus.rating:
        return 'Ocena';
      case TrackingStatus.completed:
        return 'Zakończone';
    }
  }

  String get subtitle {
    switch (this) {
      case TrackingStatus.applications:
        return 'Czekamy na zgłoszenia...';
      case TrackingStatus.confirmed:
        return 'Czekamy na rozpoczęcie pracy';
      case TrackingStatus.inProgress:
        return 'Zadanie jest realizowane';
      case TrackingStatus.rating:
        return 'Oceń wykonawcę aby zakończyć';
      case TrackingStatus.completed:
        return 'Zadanie zostało ukończone';
    }
  }

  int get stepIndex {
    switch (this) {
      case TrackingStatus.applications:
        return 0;
      case TrackingStatus.confirmed:
        return 1;
      case TrackingStatus.inProgress:
        return 2;
      case TrackingStatus.rating:
        return 3;
      case TrackingStatus.completed:
        return 4;
    }
  }
}

/// Task tracking screen with map and status updates
class TaskTrackingScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskTrackingScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskTrackingScreen> createState() => _TaskTrackingScreenState();
}

class _TaskTrackingScreenState extends ConsumerState<TaskTrackingScreen> {
  static const String _supportEmail = 'kontakt@szybkafucha.app';

  TrackingStatus _status = TrackingStatus.applications;
  Contractor? _contractor;
  Task? _task;

  // Task location
  double? _taskLat;
  double? _taskLng;

  // Track contractor whose real stats have been fetched
  String? _fetchedStatsContractorId;

  // Loading state
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    _joinTaskRoom();
    ref.read(creditsProvider.notifier).fetchBalance();
  }

  @override
  void dispose() {
    // NOTE: Do NOT leave the task room on dispose. The room must remain joined
    // so that the unread badge works on the home screen after navigating away.
    // Rooms are cleaned up on WS disconnect and re-joined via auto-join on reconnect.
    super.dispose();
  }

  /// Load initial task data from provider
  void _loadTaskData() {
    final tasksState = ref.read(clientTasksProvider);
    final task = tasksState.tasks
        .where((t) => t.id == widget.taskId)
        .firstOrNull;
    if (task != null) {
      _updateFromTask(task);
    }
  }

  /// Update UI from task data
  void _updateFromTask(Task task) {
    setState(() {
      _task = task;
      _status = _mapTaskStatus(task.status);
      if (task.contractor != null) {
        // Don't overwrite contractor if we already fetched real stats for this one
        if (_fetchedStatsContractorId != task.contractor!.id) {
          _contractor = task.contractor;
        }
      }
      _taskLat = task.latitude;
      _taskLng = task.longitude;
    });

    // Fetch real stats if we haven't yet for this contractor
    if (task.contractor != null &&
        _fetchedStatsContractorId != task.contractor!.id) {
      _fetchContractorStats(task.contractor!.id);
    }
  }

  /// Map TaskStatus to TrackingStatus (4 states - bidding system)
  TrackingStatus _mapTaskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.posted:
        return TrackingStatus.applications;
      case TaskStatus.accepted:
        // Backward compat: accepted maps to confirmed in new flow
        return TrackingStatus.confirmed;
      case TaskStatus.confirmed:
        return TrackingStatus.confirmed;
      case TaskStatus.inProgress:
        return TrackingStatus.inProgress;
      case TaskStatus.pendingComplete:
        return TrackingStatus.rating;
      case TaskStatus.completed:
        return TrackingStatus.completed;
      case TaskStatus.cancelled:
      case TaskStatus.disputed:
        return TrackingStatus.applications;
    }
  }

  /// Fetch real contractor stats (rating, reviewCount, completedTasks) from backend.
  /// Uses both /public and /reviews endpoints because /public returns stale
  /// cached values from contractor_profiles table (defaults to 0).
  Future<void> _fetchContractorStats(String contractorId) async {
    try {
      final api = ref.read(apiClientProvider);

      // Fetch profile and reviews in parallel
      final results = await Future.wait([
        api.get('/contractor/$contractorId/public'),
        api.get('/contractor/$contractorId/reviews'),
      ]);
      if (!mounted) return;

      final profileData = results[0] as Map<String, dynamic>;
      final reviewsData = results[1] as Map<String, dynamic>;

      // Override stale rating from profile with real computed values from reviews
      final realRatingAvg =
          double.tryParse(reviewsData['ratingAvg']?.toString() ?? '') ?? 0.0;
      final realRatingCount =
          int.tryParse(reviewsData['ratingCount']?.toString() ?? '') ?? 0;

      profileData['ratingAvg'] = realRatingAvg;
      profileData['ratingCount'] = realRatingCount;
      profileData['rating'] = realRatingAvg;
      profileData['review_count'] = realRatingCount;

      setState(() {
        _contractor = Contractor.fromJson(profileData);
        _fetchedStatsContractorId = contractorId;
      });
      debugPrint(
        '✅ Contractor stats fetched: rating=${_contractor?.rating}, reviews=${_contractor?.reviewCount}',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to fetch contractor stats: $e');
    }
  }

  /// Map string status from WebSocket to TrackingStatus
  TrackingStatus _mapStringStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return TrackingStatus
            .confirmed; // In new bidding flow, accepted → confirmed
      case 'confirmed':
        return TrackingStatus.confirmed;
      case 'in_progress':
        return TrackingStatus.inProgress;
      case 'pending_complete':
        return TrackingStatus.rating;
      case 'completed':
        return TrackingStatus.completed;
      default:
        return TrackingStatus.applications;
    }
  }

  /// Join WebSocket task room for real-time updates
  void _joinTaskRoom() {
    final wsService = ref.read(webSocketServiceProvider);
    wsService.joinTask(widget.taskId);
  }

  /// Manual refresh for user-triggered reload
  Future<void> _refreshTask() async {
    // Reload task and applications in parallel
    await Future.wait([
      ref.read(clientTasksProvider.notifier).refresh(),
      ref
          .read(taskApplicationsProvider(widget.taskId).notifier)
          .loadApplications(),
    ]);
    // After refresh, update local state from latest data
    final tasksState = ref.read(clientTasksProvider);
    final task = tasksState.tasks
        .where((t) => t.id == widget.taskId)
        .firstOrNull;
    if (task != null) {
      _updateFromTask(task);
    }
  }

  /// Handle WebSocket task status update
  void _handleStatusUpdate(TaskStatusEvent event) {
    if (event.taskId != widget.taskId) return;

    // Update UI immediately
    setState(() {
      _status = _mapStringStatus(event.status);

      // Update contractor info if provided (only if we haven't fetched real stats yet)
      if (event.contractor != null &&
          _fetchedStatsContractorId != event.contractor!.id) {
        _contractor = Contractor(
          id: event.contractor!.id,
          name: event.contractor!.name,
          avatarUrl: event.contractor!.avatarUrl,
          rating: event.contractor!.rating,
          completedTasks: event.contractor!.completedTasks,
          isVerified: true,
          isOnline: true,
          bio: event.contractor!.bio,
        );
      }
    });

    // Fetch real contractor stats from public profile endpoint
    if (event.contractor != null &&
        _fetchedStatsContractorId != event.contractor!.id) {
      _fetchContractorStats(event.contractor!.id);
    }

    // Refresh task data from provider to ensure consistency
    // This ensures the UI is updated with the latest data from the backend
    Future.microtask(() {
      ref.read(clientTasksProvider.notifier).refresh();
    });
  }

  void _showContractorProfile() {
    if (_contractor == null) return;
    _showContractorProfileSheet(
      contractorId: _contractor!.id,
      initialContractor: _contractor!,
    );
  }

  void _showApplicationContractorProfile(TaskApplication application) {
    final initialContractor = Contractor(
      id: application.contractorId,
      name: application.contractorName,
      avatarUrl: application.contractorAvatarUrl,
      rating: application.contractorRating,
      completedTasks: application.contractorCompletedTasks,
      reviewCount: application.contractorReviewCount,
      isVerified: true,
      isOnline: true,
      proposedPrice: application.proposedPrice.round(),
      bio: application.contractorBio,
    );

    _showContractorProfileSheet(
      contractorId: application.contractorId,
      initialContractor: initialContractor,
    );
  }

  void _showContractorProfileSheet({
    required String contractorId,
    required Contractor initialContractor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: _ContractorProfileSheet(
            contractorId: contractorId,
            initialContractor: initialContractor,
            taskId: widget.taskId,
          ),
        );
      },
    );
  }

  void _openChatWithContractor() {
    if (_task == null) return;
    final currentUser = ref.read(currentUserProvider);
    final title = _task!.title.trim();
    final description = _task!.description.trim();
    context.push(
      Routes.clientTaskChatRoute(_task!.id),
      extra: {
        'otherUserId': _contractor?.id ?? _task!.contractorId ?? '',
        'taskTitle': title.isNotEmpty
            ? title
            : (description.isNotEmpty ? description : 'Czat'),
        'otherUserName': _contractor?.name ?? 'Wykonawca',
        'otherUserAvatarUrl': _contractor?.avatarUrl,
        'currentUserId': currentUser?.id ?? '',
        'currentUserName': currentUser?.name ?? 'Ty',
      },
    );
  }

  void _attachRealtimeListeners() {
    // Listen for WebSocket task status updates
    ref.listen<AsyncValue<TaskStatusEvent>>(taskStatusUpdatesProvider, (
      previous,
      next,
    ) {
      next.whenData((event) {
        if (event.taskId == widget.taskId) {
          debugPrint(
            '📡 WebSocket status update received: ${event.status} for task ${event.taskId}',
          );
          _handleStatusUpdate(event);
        }
      });
    });

    // Listen for application updates (new bids, withdrawals)
    ref.listen<AsyncValue<Map<String, dynamic>>>(applicationUpdatesProvider, (
      previous,
      next,
    ) {
      next.whenData((event) {
        final eventTaskId = event['taskId'] as String?;
        if (eventTaskId == widget.taskId &&
            _status == TrackingStatus.applications) {
          debugPrint(
            '📩 Application update for task ${widget.taskId}, reloading...',
          );
          ref
              .read(taskApplicationsProvider(widget.taskId).notifier)
              .loadApplications();
        }
      });
    });

    // Also listen for task provider updates (fallback and real-time sync)
    ref.listen<ClientTasksState>(clientTasksProvider, (previous, next) {
      final task = next.tasks.where((t) => t.id == widget.taskId).firstOrNull;
      if (task != null) {
        final newStatus = _mapTaskStatus(task.status);
        // Only update if status changed or contractor changed (compare by ID, not reference)
        if (newStatus != _status || task.contractor?.id != _contractor?.id) {
          debugPrint(
            '🔄 Task provider update: status=${task.status}, hasContractor=${task.contractor != null}',
          );
          _updateFromTask(task);
        }
      }
    });
  }

  AppBar _buildTopAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Routes.clientHome),
        tooltip: 'Wróć',
      ),
      title: SFRainbowText('Aktywne zlecenie'),
      centerTitle: true,
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Odśwież status',
          onPressed: _refreshTask,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showOptionsMenu,
          tooltip: 'Więcej opcji',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _attachRealtimeListeners();

    return Scaffold(
      appBar: _buildTopAppBar(context),
      body: _buildBottomPanel(),
    );
  }

  Widget _buildBottomPanel() {
    // Add bottom safe area as scroll padding instead of wrapping in SafeArea
    // to avoid layout conflicts with NavigationBar in _ClientShell
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.paddingMD,
          AppSpacing.paddingMD,
          AppSpacing.paddingMD,
          AppSpacing.paddingMD + bottomSafe,
        ),
        child: Column(
          children: [
            // Status header
            _buildStatusHeader(),

            SizedBox(height: AppSpacing.space4),

            // Progress steps
            _buildProgressSteps(),

            SizedBox(height: AppSpacing.space4),

            // Task details section (same placement as contractor active task screen)
            _buildTaskDetailsSection(),

            SizedBox(height: AppSpacing.space4),

            // Application list (when waiting for bids)
            if (_status == TrackingStatus.applications) _buildApplicationsList(),

            // Contractor card (if assigned)
            if (_contractor != null && _status != TrackingStatus.applications)
              _buildContractorCard(),

            // Complete button (when in progress)
            if (_status == TrackingStatus.inProgress) _buildCompleteButton(),

            // Cancel button (hide for rating and completed stages)
            if (_status != TrackingStatus.completed &&
                _status != TrackingStatus.rating)
              _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailsSection() {
    if (_task == null) return const SizedBox.shrink();

    final task = _task!;
    final categoryData = task.categoryData;

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Szczegóły zlecenia', style: AppTypography.labelLarge),
          SizedBox(height: AppSpacing.gapMD),
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
                    Text(categoryData.name, style: AppTypography.labelLarge),
                    Text(
                      task.address?.trim().isNotEmpty == true
                          ? task.address!
                          : 'Brak adresu',
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
                    '${task.budget} PLN',
                    style: AppTypography.h4.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    'budżet',
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
            task.title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray800,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.description.trim().isNotEmpty) ...[
            SizedBox(height: AppSpacing.gapXS),
            Text(
              task.description,
              style: AppTypography.bodySmall.copyWith(color: AppColors.gray600),
            ),
          ],
          SizedBox(height: AppSpacing.gapMD),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: task.isImmediate ? AppColors.warning : AppColors.primary,
              ),
              SizedBox(width: AppSpacing.gapXS),
              Expanded(
                child: Text(
                  task.isImmediate
                      ? 'Termin: Teraz'
                      : task.scheduledAt != null
                      ? 'Termin: ${_formatScheduledTime(task.scheduledAt!)}'
                      : 'Termin: Nie określono',
                  style: AppTypography.caption.copyWith(
                    color: task.isImmediate
                        ? AppColors.warning
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.paddingSM),
          decoration: BoxDecoration(
            color: _status == TrackingStatus.applications ||
                    _status == TrackingStatus.rating
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: _status == TrackingStatus.applications
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.warning),
                  ),
                )
              : Icon(
                  _getStatusIcon(),
                  color: _status == TrackingStatus.rating
                      ? AppColors.warning
                      : AppColors.success,
                  size: 24,
                ),
        ),
        SizedBox(width: AppSpacing.gapMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_status.title, style: AppTypography.h5),
              Text(
                _status.subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case TrackingStatus.applications:
        return Icons.people;
      case TrackingStatus.confirmed:
        return Icons.check_circle;
      case TrackingStatus.inProgress:
        return Icons.handyman;
      case TrackingStatus.rating:
        return Icons.star_outline;
      case TrackingStatus.completed:
        return Icons.check_circle;
    }
  }

  Widget _buildProgressSteps() {
    // 5 steps - rainbow colored
    const steps = ['Zgłoszenia', 'Zaakceptowane', 'W trakcie', 'Ocena', 'Gotowe'];
    final currentStep = _status.stepIndex;

    return SFRainbowProgress(steps: steps, currentStep: currentStep);
  }

  /// Build the applications list for bidding system
  Widget _buildApplicationsList() {
    if (_task == null) return const SizedBox.shrink();

    final applicationsState = ref.watch(
      taskApplicationsProvider(widget.taskId),
    );

    if (applicationsState.isLoading && applicationsState.applications.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingLG),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: AppSpacing.paddingSM),
              Text(
                'Ładowanie zgłoszeń...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (applicationsState.error != null &&
        applicationsState.applications.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingLG),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              SizedBox(height: AppSpacing.paddingSM),
              Text(
                'Błąd ładowania zgłoszeń',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(height: AppSpacing.paddingXS),
              Text(
                applicationsState.error!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.paddingSM),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(taskApplicationsProvider(widget.taskId).notifier)
                      .loadApplications();
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    final applications = applicationsState.pendingApplications;

    if (applications.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingLG),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.hourglass_empty, size: 48, color: AppColors.gray300),
              SizedBox(height: AppSpacing.paddingSM),
              Text(
                'Czekamy na zgłoszenia wykonawców...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.paddingXS),
              Text(
                'Wykonawcy z Twojej okolicy będą się zgłaszać z proponowaną ceną',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "10 zł" info banner
        Container(
          padding: EdgeInsets.all(AppSpacing.paddingSM),
          margin: EdgeInsets.only(bottom: AppSpacing.paddingSM),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusMD,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              SizedBox(width: AppSpacing.gapSM),
              Expanded(
                child: Text(
                  'Wejście jest darmowe. Płacisz 10 zł tylko gdy wybierzesz pomocnika.',
                  style: AppTypography.caption.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),

        // Header with count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zgłoszenia (${applications.length}/${_task!.maxApplications})',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ref
                    .read(taskApplicationsProvider(widget.taskId).notifier)
                    .loadApplications();
              },
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Odśwież'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gray600,
                textStyle: AppTypography.bodySmall,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.paddingSM),

        // Applications list
        ...applications.map(
          (app) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.paddingSM),
            child: ApplicationCard(
              application: app,
              taskBudget: _task!.budget,
              onViewProfile: () => _showApplicationContractorProfile(app),
              onChat: () => _openChatWithApplicant(app),
              onAccept: () => _acceptApplication(app.id),
              onKick: () => _kickFromRoom(app.id, app.contractorName),
            ),
          ),
        ),
      ],
    );
  }

  /// Open chat with a specific applicant in the room
  void _openChatWithApplicant(TaskApplication app) {
    if (_task == null) return;
    final currentUser = ref.read(currentUserProvider);
    final title = _task!.title.trim();
    final description = _task!.description.trim();
    context.push(
      Routes.clientTaskChatRoute(_task!.id),
      extra: {
        'otherUserId': app.contractorId,
        'taskTitle': title.isNotEmpty
            ? title
            : (description.isNotEmpty ? description : 'Czat'),
        'otherUserName': app.contractorName,
        'otherUserAvatarUrl': app.contractorAvatarUrl,
        'currentUserId': currentUser?.id ?? '',
        'currentUserName': currentUser?.name ?? 'Ty',
      },
    );
  }

  /// Kick a contractor from the room
  Future<void> _kickFromRoom(String applicationId, String contractorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zwolnij z pokoju?'),
        content: Text('Czy na pewno chcesz usunąć $contractorName z pokoju?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Zwolnij'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/tasks/${widget.taskId}/applications/$applicationId/kick');

      // Reload applications
      ref.read(taskApplicationsProvider(widget.taskId).notifier).loadApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$contractorName został usunięty z pokoju'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg.contains('429') || errorMsg.contains('Too many')
                  ? 'Zbyt wiele usunięć. Spróbuj ponownie za chwilę.'
                  : 'Nie udało się usunąć: $errorMsg',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Accept an application (bidding system) — with balance gate
  Future<void> _acceptApplication(String applicationId) async {
    // Balance gate: check if client has at least 10 zł
    final credits = ref.read(creditsProvider);
    if (credits.balance < 10) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Niewystarczające środki'),
          content: Text(
            'Potrzebujesz minimum 10 zł na koncie, aby wybrać wykonawcę.\n\n'
            'Twoje saldo: ${credits.balance.toStringAsFixed(2)} zł',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(Routes.clientWallet);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Doładuj portfel'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await ref
          .read(taskApplicationsProvider(widget.taskId).notifier)
          .acceptApplication(applicationId);

      // Refresh credits balance after acceptance deduction
      ref.read(creditsProvider.notifier).fetchBalance();

      // Reload the task to get updated status
      await ref.read(clientTasksProvider.notifier).loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się zaakceptować: $e')),
        );
      }
    }
  }

  /// Reject an application (bidding system)
  Widget _buildContractorCard() {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.gapMD),
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusMD,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              // Show photo if available, otherwise initials
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.gray200,
                backgroundImage: _contractor!.avatarUrl != null
                    ? NetworkImage(_contractor!.avatarUrl!)
                    : null,
                child: _contractor!.avatarUrl == null
                    ? Text(
                        _contractor!.name[0].toUpperCase(),
                        style: AppTypography.h4.copyWith(
                          color: AppColors.gray600,
                        ),
                      )
                    : null,
              ),
              // Online indicator
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _contractor!.isOnline
                        ? AppColors.success
                        : AppColors.gray400,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _contractor!.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_contractor!.isVerified) ...[
                      SizedBox(width: AppSpacing.gapXS),
                      Icon(Icons.verified, size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
                SizedBox(height: AppSpacing.gapXS),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.warning),
                        SizedBox(width: AppSpacing.gapXS),
                        Text(
                          _contractor!.formattedRating,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.gapXS),
                    Text(
                      '${_contractor!.reviewCount} opinii',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Pokaż profil wykonawcy',
            button: true,
            child: IconButton(
              onPressed: _showContractorProfile,
              tooltip: 'Pokaż profil wykonawcy',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: const CircleBorder(),
                padding: EdgeInsets.all(AppSpacing.paddingSM),
              ),
              icon: const Icon(Icons.person_outline, color: AppColors.white),
            ),
          ),
          SizedBox(width: AppSpacing.gapSM),
          SFChatBadge(
            taskId: widget.taskId,
            otherUserId: _contractor?.id ?? _task?.contractorId,
            child: IconButton(
              onPressed: _openChatWithContractor,
              icon: const Icon(Icons.chat_outlined, color: AppColors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: const CircleBorder(),
                padding: EdgeInsets.all(AppSpacing.paddingSM),
              ),
              tooltip: 'Otwórz czat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.gapMD),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to completion/rating screen
            context.push(Routes.clientTaskComplete(widget.taskId));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
          child: Text(
            'Potwierdź zakończenie',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.gapMD),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isCancelling ? null : _showCancelDialog,
          icon: _isCancelling
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Icon(Icons.cancel_outlined),
          label: Text(_isCancelling ? 'Anulowanie...' : 'Anuluj zlecenie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
          ),
        ),
      ),
    );
  }

  Future<void> _showOptionsMenu() async {
    final action = await showModalBottomSheet<_TaskOptionsAction>(
      context: context,
      builder: (bottomSheetContext) => Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Szczegóły zlecenia'),
              onTap: () {
                Navigator.of(
                  bottomSheetContext,
                ).pop(_TaskOptionsAction.details);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edytuj zlecenie'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop(_TaskOptionsAction.edit);
              },
            ),
            ListTile(
              leading: Icon(Icons.map_outlined),
              title: Text('Mapa zlecenia'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop(_TaskOptionsAction.map);
              },
            ),
            ListTile(
              leading: Icon(Icons.report_outlined, color: AppColors.warning),
              title: Text('Zgłoś problem'),
              onTap: () {
                Navigator.of(
                  bottomSheetContext,
                ).pop(_TaskOptionsAction.reportProblem);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: AppColors.error),
              title: Text(
                'Anuluj zlecenie',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.of(bottomSheetContext).pop(_TaskOptionsAction.cancel);
              },
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _TaskOptionsAction.details:
        _showTaskDetails();
        break;
      case _TaskOptionsAction.edit:
        context.push(Routes.clientTaskEditRoute(widget.taskId));
        break;
      case _TaskOptionsAction.map:
        _openTaskLocationMap();
        break;
      case _TaskOptionsAction.reportProblem:
        await _openSupportEmailClient();
        break;
      case _TaskOptionsAction.cancel:
        _showCancelDialog();
        break;
    }
  }

  void _openTaskLocationMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TaskLocationMapScreen(
          latitude: _taskLat,
          longitude: _taskLng,
          taskAddress: _task?.address,
        ),
      ),
    );
  }

  Future<void> _openSupportEmailClient() async {
    final task = _task;
    final subject = 'Zgloszenie problemu - zlecenie ${widget.taskId}';
    final body = StringBuffer()
      ..writeln('Opisz problem:')
      ..writeln()
      ..writeln()
      ..writeln('--- Kontekst ---')
      ..writeln('Task ID: ${widget.taskId}')
      ..writeln('Status: ${_status.name}')
      ..writeln('Kategoria: ${task?.categoryData.name ?? 'brak'}');

    final mailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': subject, 'body': body.toString()},
    );

    try {
      final didLaunch = await launchUrl(
        mailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nie udało się otworzyć aplikacji pocztowej'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się otworzyć aplikacji pocztowej: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showTaskDetails() {
    if (_task == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.space4),

              // Title
              Text(
                'Szczegóły zlecenia',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.space6),

              // Category
              _buildDetailRow(
                icon: _task!.categoryData.icon,
                iconColor: _task!.categoryData.color,
                label: 'Kategoria',
                value: _task!.categoryData.name,
              ),

              _buildDetailRow(
                icon: Icons.title,
                label: 'Tytuł',
                value: _task!.title,
              ),

              // Description
              _buildDetailRow(
                icon: Icons.description_outlined,
                label: 'Opis',
                value: _task!.description.trim().isEmpty
                    ? 'Brak opisu'
                    : _task!.description,
              ),

              // Address
              if (_task!.address != null)
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Lokalizacja',
                  value: _task!.address!,
                ),

              // Budget
              _buildDetailRow(
                icon: Icons.payments_outlined,
                iconColor: AppColors.success,
                label: 'Budżet',
                value: '${_task!.budget} PLN',
                valueStyle: AppTypography.labelLarge.copyWith(
                  color: AppColors.success,
                ),
              ),

              // Scheduled time
              _buildDetailRow(
                icon: Icons.schedule_outlined,
                iconColor: _task!.isImmediate
                    ? AppColors.warning
                    : AppColors.primary,
                label: 'Termin',
                value: _task!.isImmediate
                    ? 'Teraz'
                    : _task!.scheduledAt != null
                    ? _formatScheduledTime(_task!.scheduledAt!)
                    : 'Nie określono',
              ),

              // Images
              if (_task!.imageUrls != null && _task!.imageUrls!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.space4),
                Text('Zdjęcia', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.gapMD),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _task!.imageUrls!.length,
                    itemBuilder: (context, index) {
                      final imageUrl = _task!.imageUrls![index];
                      return Semantics(
                        label: 'Pokaż zdjęcie zlecenia',
                        button: true,
                        child: GestureDetector(
                          onTap: () => _showFullImage(imageUrl),
                          child: Container(
                            width: 120,
                            height: 120,
                            margin: EdgeInsets.only(right: AppSpacing.gapSM),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.radiusMD,
                              border: Border.all(color: AppColors.gray200),
                            ),
                            child: ClipRRect(
                              borderRadius: AppRadius.radiusMD,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stackTrace) =>
                                    Container(
                                      color: AppColors.gray100,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.gray400,
                                      ),
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

              SizedBox(height: AppSpacing.space8),

              // Close button
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                ),
                child: Text('Zamknij'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingXS),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.gray600).withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusSM,
            ),
            child: Icon(icon, size: 20, color: iconColor ?? AppColors.gray600),
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                SizedBox(height: AppSpacing.gapXS),
                Text(value, style: valueStyle ?? AppTypography.bodyMedium),
              ],
            ),
          ),
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
        backgroundColor: AppColors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Zamknij podgląd zdjęcia',
                icon: Container(
                  padding: EdgeInsets.all(AppSpacing.paddingXS),
                  decoration: BoxDecoration(
                    color: AppColors.gray900.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: AppColors.white),
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anuluj zlecenie?'),
        content: Text(
          'Czy na pewno chcesz anulować to zlecenie? Może to wiązać się z opłatą.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Nie')),
          TextButton(
            onPressed: () {
              context.pop();
              _cancelTask();
            },
            child: Text(
              'Tak, anuluj',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Cancel the task via backend API
  Future<void> _cancelTask() async {
    setState(() => _isCancelling = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.put('/tasks/${widget.taskId}/cancel');

      // Refresh tasks list
      ref.invalidate(clientTasksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zlecenie zostało anulowane'),
            backgroundColor: AppColors.warning,
          ),
        );
        context.go(Routes.clientHome);
      }
    } catch (e) {
      setState(() => _isCancelling = false);
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
}

class _TaskLocationMapScreen extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? taskAddress;

  const _TaskLocationMapScreen({
    required this.latitude,
    required this.longitude,
    required this.taskAddress,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa zlecenia'),
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
      ),
      body: hasLocation
          ? Stack(
              children: [
                Positioned.fill(
                  child: SFMapView(
                    center: LatLng(latitude!, longitude!),
                    zoom: 15,
                    markers: [TaskMarker(position: LatLng(latitude!, longitude!))],
                    interactive: true,
                    showZoomControls: true,
                  ),
                ),
                Positioned(
                  left: AppSpacing.paddingMD,
                  right: AppSpacing.paddingMD,
                  bottom: AppSpacing.paddingMD,
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.radiusMD,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gray900.withValues(alpha: 0.12),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place_outlined, color: AppColors.primary),
                        SizedBox(width: AppSpacing.gapSM),
                        Expanded(
                          child: Text(
                            taskAddress?.trim().isNotEmpty == true
                                ? taskAddress!
                                : 'Lokalizacja zlecenia',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.paddingLG),
                child: Text(
                  'Brak współrzędnych lokalizacji dla tego zlecenia.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}

/// Contractor profile bottom sheet that fetches full profile data
class _ContractorProfileSheet extends ConsumerStatefulWidget {
  final String contractorId;
  final Contractor initialContractor;
  final String? taskId;

  const _ContractorProfileSheet({
    required this.contractorId,
    required this.initialContractor,
    this.taskId,
  });

  @override
  ConsumerState<_ContractorProfileSheet> createState() =>
      _ContractorProfileSheetState();
}

class _ContractorProfileSheetState
    extends ConsumerState<_ContractorProfileSheet> {
  Contractor? _fullProfile;
  bool _isLoading = true;
  bool _isReviewsLoading = true;
  String? _error;
  double _ratingAvg = 0.0;
  int _ratingCount = 0;
  List<_ContractorPublicReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchFullProfile();
  }

  Future<void> _fetchFullProfile() async {
    final api = ref.read(apiClientProvider);
    Contractor? fullProfile;
    String? profileError;
    var ratingAvg = widget.initialContractor.rating;
    var ratingCount = widget.initialContractor.reviewCount;
    List<_ContractorPublicReview> reviews = const [];

    try {
      final taskIdParam = widget.taskId != null ? '?taskId=${widget.taskId}' : '';
      final response = await api.get(
        '/contractor/${widget.contractorId}/public$taskIdParam',
      );
      final data = response as Map<String, dynamic>;
      fullProfile = Contractor.fromJson(data);
    } catch (e) {
      profileError = e.toString();
    }

    try {
      final reviewsResponse = await api.get(
        '/contractor/${widget.contractorId}/reviews',
      );
      final reviewsData = reviewsResponse as Map<String, dynamic>;

      final ratingAvgValue = reviewsData['ratingAvg'];
      final ratingCountValue = reviewsData['ratingCount'];

      ratingAvg = ratingAvgValue != null
          ? (double.tryParse(ratingAvgValue.toString()) ?? 0.0)
          : 0.0;
      ratingCount = ratingCountValue is int
          ? ratingCountValue
          : (int.tryParse(ratingCountValue?.toString() ?? '') ?? 0);

      reviews = (reviewsData['reviews'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_ContractorPublicReview.fromJson)
          .toList();
    } catch (_) {
      // Keep fallback values from initial contractor card if reviews endpoint fails.
    }

    if (!mounted) return;

    setState(() {
      _fullProfile = fullProfile;
      _error = profileError;
      _ratingAvg = ratingAvg;
      _ratingCount = ratingCount;
      _reviews = reviews;
      _isLoading = false;
      _isReviewsLoading = false;
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }

  Widget _buildReviewCard(_ContractorPublicReview review) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppColors.warning, size: 18),
              SizedBox(width: AppSpacing.gapXS),
              Text(
                review.rating.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: AppTypography.caption.copyWith(color: AppColors.gray500),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            review.comment?.trim().isNotEmpty == true
                ? review.comment!.trim()
                : 'Brak komentarza.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.gray700),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_isReviewsLoading) {
      return SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, size: 18, color: AppColors.warning),
            SizedBox(width: AppSpacing.gapXS),
            Text(
              _ratingAvg.toStringAsFixed(1),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: AppSpacing.gapSM),
            Text(
              'na podstawie $_ratingCount opinii',
              style: AppTypography.caption.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapSM),
        if (_reviews.isEmpty)
          Text(
            'Brak opinii do wyświetlenia.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.gray500),
          )
        else
          ..._reviews
              .take(5)
              .map(
                (review) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.gapSM),
                  child: _buildReviewCard(review),
                ),
              ),
      ],
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingMD,
        AppSpacing.paddingSM,
        AppSpacing.paddingMD,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Profil wykonawcy', style: AppTypography.h4),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
            tooltip: 'Zamknij',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.gray700,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAvatarAndNameRow(Contractor contractor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.gray200,
          backgroundImage: contractor.avatarUrl != null
              ? NetworkImage(contractor.avatarUrl!)
              : null,
          child: contractor.avatarUrl == null
              ? Text(
                  contractor.name.isNotEmpty
                      ? contractor.name[0].toUpperCase()
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
                contractor.name,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.gapXS),
              Row(
                children: [
                  Icon(Icons.star, size: 18, color: AppColors.warning),
                  SizedBox(width: AppSpacing.gapXS),
                  Text(
                    contractor.formattedRating,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.gapXS),
              Text(
                '${contractor.reviewCount} opinii',
                style: AppTypography.caption.copyWith(color: AppColors.gray500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(Contractor contractor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Opis'),
        SizedBox(height: AppSpacing.gapXS),
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
                contractor.bio?.isNotEmpty == true
                    ? contractor.bio!
                    : 'Brak opisu wykonawcy.',
                style: AppTypography.bodySmall.copyWith(
                  color: contractor.bio?.isNotEmpty == true
                      ? AppColors.gray600
                      : AppColors.gray400,
                  fontStyle: contractor.bio?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
      ],
    );
  }

  Widget _buildDateOfBirthSection(Contractor contractor) {
    if (contractor.dateOfBirth == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data urodzenia'),
        SizedBox(height: AppSpacing.gapXS),
        Text(
          contractor.formattedDateOfBirth,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(Contractor contractor) {
    final hasContact = contractor.email != null || contractor.phone != null;
    if (!hasContact) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Congratulatory banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.paddingMD),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusMD,
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.celebration, color: AppColors.success, size: 24),
              SizedBox(width: AppSpacing.gapSM),
              Expanded(
                child: Text(
                  'Gratulacje! Otrzymałeś dostęp do danych kontaktowych pracownika',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.gapMD),
        _buildSectionTitle('Dane kontaktowe'),
        SizedBox(height: AppSpacing.gapXS),
        if (contractor.email != null)
          Semantics(
            label: 'Wyślij email do wykonawcy',
            button: true,
            child: InkWell(
              onTap: () => launchUrl(
                Uri(scheme: 'mailto', path: contractor.email),
                mode: LaunchMode.externalApplication,
              ),
              borderRadius: AppRadius.radiusSM,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingSM),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.gapMD),
                    Expanded(
                      child: Text(
                        contractor.email!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
          ),
        if (contractor.phone != null)
          Semantics(
            label: 'Zadzwoń do wykonawcy',
            button: true,
            child: InkWell(
              onTap: () => launchUrl(
                Uri(scheme: 'tel', path: contractor.phone),
                mode: LaunchMode.externalApplication,
              ),
              borderRadius: AppRadius.radiusSM,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingSM),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.gapMD),
                    Expanded(
                      child: Text(
                        contractor.phone!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileContent(Contractor contractor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.gapMD),
        _buildAvatarAndNameRow(contractor),
        SizedBox(height: AppSpacing.gapMD),
        _buildContactSection(contractor),
        SizedBox(height: AppSpacing.gapMD),
        _buildBioSection(contractor),
        if (contractor.dateOfBirth != null) ...[
          SizedBox(height: AppSpacing.gapMD),
          _buildDateOfBirthSection(contractor),
        ],
        SizedBox(height: AppSpacing.gapMD),
        _buildSectionTitle('Opinie'),
        SizedBox(height: AppSpacing.gapXS),
        _buildReviewsSection(),
        SizedBox(height: AppSpacing.gapMD),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractor = _fullProfile ?? widget.initialContractor;

    return SafeArea(
      child: Column(
        children: [
          _buildSheetHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.paddingMD,
                0,
                AppSpacing.paddingMD,
                AppSpacing.paddingMD,
              ),
              child: _buildProfileContent(contractor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractorPublicReview {
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const _ContractorPublicReview({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory _ContractorPublicReview.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    return _ContractorPublicReview(
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString(),
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
