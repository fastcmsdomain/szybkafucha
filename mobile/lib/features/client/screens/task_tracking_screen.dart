import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/websocket_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/widgets/sf_map_view.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../models/contractor.dart';
import '../models/task.dart';

/// Task tracking status (5 states including confirmation step)
enum TrackingStatus {
  searching,
  accepted, // Contractor accepted - waiting for client confirmation
  confirmed, // Client confirmed contractor - work can start
  inProgress,
  completed,
}

extension TrackingStatusExtension on TrackingStatus {
  String get title {
    switch (this) {
      case TrackingStatus.searching:
        return 'Szukamy pomocnika';
      case TrackingStatus.accepted:
        return 'Pomocnik znaleziony!';
      case TrackingStatus.confirmed:
        return 'Wykonawca potwierdzony';
      case TrackingStatus.inProgress:
        return 'Praca w toku';
      case TrackingStatus.completed:
        return 'Zakończone';
    }
  }

  String get subtitle {
    switch (this) {
      case TrackingStatus.searching:
        return 'Dopasowujemy najlepszego wykonawcę...';
      case TrackingStatus.accepted:
        return 'Sprawdź profil i zatwierdź wykonawcę';
      case TrackingStatus.confirmed:
        return 'Czekamy na rozpoczęcie pracy';
      case TrackingStatus.inProgress:
        return 'Zadanie jest realizowane';
      case TrackingStatus.completed:
        return 'Zadanie zostało ukończone';
    }
  }

  int get stepIndex {
    switch (this) {
      case TrackingStatus.searching:
        return 0;
      case TrackingStatus.accepted:
        return 1;
      case TrackingStatus.confirmed:
        return 2;
      case TrackingStatus.inProgress:
        return 3;
      case TrackingStatus.completed:
        return 4;
    }
  }
}

/// Task tracking screen with map and status updates
class TaskTrackingScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskTrackingScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskTrackingScreen> createState() => _TaskTrackingScreenState();
}

class _TaskTrackingScreenState extends ConsumerState<TaskTrackingScreen> {
  TrackingStatus _status = TrackingStatus.searching;
  Contractor? _contractor;

  // Task location (where the job is)
  double? _taskLat;
  double? _taskLng;
  String? _taskAddress;

  // Contractor location for live tracking
  double? _contractorLat;
  double? _contractorLng;
  DateTime? _lastLocationUpdate;

  // Confirmation loading state
  bool _isConfirming = false;
  bool _isRejecting = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    _joinTaskRoom();
  }

  @override
  void dispose() {
    _leaveTaskRoom();
    super.dispose();
  }

  /// Refresh task data from backend
  Future<void> _refreshTask() async {
    await ref.read(clientTasksProvider.notifier).refresh();
    _loadTaskData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zlecenie odświeżone'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Load initial task data from provider
  void _loadTaskData() {
    final tasksState = ref.read(clientTasksProvider);
    final task = tasksState.tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task != null) {
      _updateFromTask(task);
    }
  }

  /// Update UI from task data
  void _updateFromTask(Task task) {
    setState(() {
      _status = _mapTaskStatus(task.status);
      if (task.contractor != null) {
        _contractor = task.contractor;
      }
      // Store task location
      if (task.latitude != null && task.longitude != null) {
        _taskLat = task.latitude;
        _taskLng = task.longitude;
        _taskAddress = task.address;
      }
    });
  }

  /// Map TaskStatus to TrackingStatus (5 states)
  TrackingStatus _mapTaskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.posted:
        return TrackingStatus.searching;
      case TaskStatus.accepted:
        return TrackingStatus.accepted;
      case TaskStatus.confirmed:
        return TrackingStatus.confirmed;
      case TaskStatus.inProgress:
        return TrackingStatus.inProgress;
      case TaskStatus.completed:
        return TrackingStatus.completed;
      case TaskStatus.cancelled:
      case TaskStatus.disputed:
        return TrackingStatus.searching;
    }
  }

  /// Map string status from WebSocket to TrackingStatus
  TrackingStatus _mapStringStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return TrackingStatus.accepted;
      case 'confirmed':
        return TrackingStatus.confirmed;
      case 'in_progress':
        return TrackingStatus.inProgress;
      case 'completed':
        return TrackingStatus.completed;
      default:
        return TrackingStatus.searching;
    }
  }

  /// Join WebSocket task room for real-time updates
  void _joinTaskRoom() {
    final wsService = ref.read(webSocketServiceProvider);
    wsService.joinTask(widget.taskId);
  }

  /// Leave WebSocket task room
  void _leaveTaskRoom() {
    final wsService = ref.read(webSocketServiceProvider);
    wsService.leaveTask(widget.taskId);
  }

  /// Handle WebSocket task status update
  void _handleStatusUpdate(TaskStatusEvent event) {
    if (event.taskId != widget.taskId) return;

    // Update UI immediately
    setState(() {
      _status = _mapStringStatus(event.status);

      // Update contractor info if provided
      if (event.contractor != null) {
        _contractor = Contractor(
          id: event.contractor!.id,
          name: event.contractor!.name,
          avatarUrl: event.contractor!.avatarUrl,
          rating: event.contractor!.rating,
          completedTasks: event.contractor!.completedTasks,
          isVerified: true,
          isOnline: true,
        );
      }
    });

    // Refresh task data from provider to ensure consistency
    // This ensures the UI is updated with the latest data from the backend
    Future.microtask(() {
      ref.read(clientTasksProvider.notifier).refresh();
    });
  }

  /// Check if contractor location is recent (within 30 seconds)
  bool _isLocationRecent() {
    if (_lastLocationUpdate == null) return false;
    final diff = DateTime.now().difference(_lastLocationUpdate!);
    return diff.inSeconds < 30;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for WebSocket task status updates
    ref.listen<AsyncValue<TaskStatusEvent>>(
      taskStatusUpdatesProvider,
      (previous, next) {
        next.whenData((event) {
          if (event.taskId == widget.taskId) {
            debugPrint('📡 WebSocket status update received: ${event.status} for task ${event.taskId}');
            _handleStatusUpdate(event);
          }
        });
      },
    );

    // Listen for contractor location updates (GPS tracking)
    ref.listen<AsyncValue<LocationUpdateEvent>>(
      locationUpdatesProvider,
      (previous, next) {
        next.whenData((event) {
          // Update contractor position on map
          // Only update if we have a contractor assigned
          if (_contractor != null &&
              (_status == TrackingStatus.accepted ||
                  _status == TrackingStatus.inProgress)) {
            setState(() {
              _contractorLat = event.latitude;
              _contractorLng = event.longitude;
              _lastLocationUpdate = event.timestamp;
            });
            debugPrint(
                '📍 Contractor location updated: ${event.latitude}, ${event.longitude}');
          }
        });
      },
    );

    // Also listen for task provider updates (fallback and real-time sync)
    ref.listen<ClientTasksState>(
      clientTasksProvider,
      (previous, next) {
        final task = next.tasks.where((t) => t.id == widget.taskId).firstOrNull;
        if (task != null) {
          final newStatus = _mapTaskStatus(task.status);
          // Only update if status actually changed to avoid unnecessary rebuilds
          if (newStatus != _status || task.contractor != _contractor) {
            debugPrint('🔄 Task provider update: status=${task.status}, hasContractor=${task.contractor != null}');
            _updateFromTask(task);
          }
        }
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
          _buildMapPlaceholder(),

          // Top bar with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.paddingMD),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.md,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go(Routes.clientHome),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.md,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshTask,
                        tooltip: 'Odśwież',
                      ),
                    ),
                    SizedBox(width: AppSpacing.gapSM),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.md,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: _showOptionsMenu,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    // Default to Warsaw if no task location
    final center = _taskLat != null && _taskLng != null
        ? LatLng(_taskLat!, _taskLng!)
        : const LatLng(52.2297, 21.0122);

    // Build markers list
    final markers = <SFMarker>[];

    // Task location marker (where the job is)
    markers.add(TaskMarker(
      position: center,
      label: 'Lokalizacja zlecenia',
    ));

    // Contractor marker (if assigned and has location)
    if (_contractor != null &&
        _status != TrackingStatus.searching &&
        _contractorLat != null &&
        _contractorLng != null) {
      markers.add(ContractorMarker(
        position: LatLng(_contractorLat!, _contractorLng!),
        name: _contractor!.name,
        isOnline: _isLocationRecent(),
      ));
    }

    return SFMapView(
      center: center,
      zoom: 15,
      markers: markers,
      interactive: true,
      showZoomControls: true,
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusXL.topLeft.x),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
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
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Column(
                children: [
                  // Status header
                  _buildStatusHeader(),

                  SizedBox(height: AppSpacing.space4),

                  // Progress steps
                  _buildProgressSteps(),

                  SizedBox(height: AppSpacing.space4),

                  // Contractor card (if assigned)
                  if (_contractor != null &&
                      _status != TrackingStatus.searching)
                    _buildContractorCard(),

                  // Confirm/Reject buttons (when waiting for client confirmation)
                  if (_status == TrackingStatus.accepted && _contractor != null)
                    _buildConfirmContractorButtons(),

                  // Action buttons (chat, call)
                  if (_status != TrackingStatus.searching &&
                      _status != TrackingStatus.accepted &&
                      _status != TrackingStatus.completed)
                    _buildActionButtons(),

                  // Complete button (when in progress)
                  if (_status == TrackingStatus.inProgress)
                    _buildCompleteButton(),

                  // Cancel button (for all non-completed tasks)
                  if (_status != TrackingStatus.completed)
                    _buildCancelButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.paddingSM),
          decoration: BoxDecoration(
            color: _status == TrackingStatus.searching
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: _status == TrackingStatus.searching
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
                  color: AppColors.success,
                  size: 24,
                ),
        ),
        SizedBox(width: AppSpacing.gapMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _status.title,
                style: AppTypography.h4,
              ),
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
      case TrackingStatus.searching:
        return Icons.search;
      case TrackingStatus.accepted:
        return Icons.person_search;
      case TrackingStatus.confirmed:
        return Icons.check_circle;
      case TrackingStatus.inProgress:
        return Icons.handyman;
      case TrackingStatus.completed:
        return Icons.check_circle;
    }
  }

  Widget _buildProgressSteps() {
    // 5 steps including confirmation
    final steps = ['Szukanie', 'Znaleziony', 'Potwierdz.', 'W trakcie', 'Gotowe'];
    final currentStep = _status.stepIndex;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: isCompleted ? AppColors.primary : AppColors.gray200,
            ),
          );
        } else {
          // Step circle
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? AppColors.primary
                      : AppColors.gray200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.white,
                        )
                      : isCurrent
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: AppTypography.caption.copyWith(
                  color: isCompleted || isCurrent
                      ? AppColors.gray700
                      : AppColors.gray400,
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

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
                    border: Border.all(
                      color: AppColors.white,
                      width: 2,
                    ),
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
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: AppColors.warning),
                    SizedBox(width: 4),
                    Text(
                      _contractor!.formattedRating,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' • ${_contractor!.completedTasks} zleceń',
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
    );
  }

  Widget _buildConfirmContractorButtons() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.gapMD),
      child: Column(
        children: [
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConfirming || _isRejecting ? null : _confirmContractor,
              icon: _isConfirming
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Icon(Icons.check_circle),
              label: Text(_isConfirming ? 'Potwierdzanie...' : 'Zatwierdź wykonawcę'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          // Reject button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isConfirming || _isRejecting ? null : _rejectContractor,
              icon: _isRejecting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : Icon(Icons.close, color: AppColors.error),
              label: Text(
                _isRejecting ? 'Odrzucanie...' : 'Odrzuć i szukaj innego',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm the contractor - triggers payment and allows work to start
  Future<void> _confirmContractor() async {
    setState(() => _isConfirming = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.put('/tasks/${widget.taskId}/confirm-contractor');

      setState(() {
        _status = TrackingStatus.confirmed;
        _isConfirming = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wykonawca zatwierdzony! Praca może się rozpocząć.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isConfirming = false);
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

  /// Reject the contractor - task goes back to searching
  Future<void> _rejectContractor() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Odrzucić wykonawcę?'),
        content: Text(
          'Zadanie wróci do szukania nowego wykonawcy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Odrzuć'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRejecting = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.put('/tasks/${widget.taskId}/reject-contractor');

      setState(() {
        _status = TrackingStatus.searching;
        _contractor = null;
        _isRejecting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wykonawca odrzucony. Szukamy nowego...'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      setState(() => _isRejecting = false);
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to chat
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funkcja czatu wkrótce dostępna')),
              );
            },
            icon: Icon(Icons.chat_bubble_outline),
            label: Text('Czat'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.gapMD),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Call contractor
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funkcja połączenia wkrótce dostępna')),
              );
            },
            icon: Icon(Icons.phone_outlined),
            label: Text('Zadzwoń'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
            ),
          ),
        ),
      ],
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
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.button,
            ),
          ),
          child: Text(
            'Potwierdź zakończenie',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
        child: OutlinedButton.icon(
          onPressed: _isCancelling ? null : _showCancelDialog,
          icon: _isCancelling
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : Icon(Icons.cancel_outlined, color: AppColors.error),
          label: Text(
            _isCancelling ? 'Anulowanie...' : 'Anuluj zlecenie',
            style: TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Szczegóły zlecenia'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show task details
              },
            ),
            ListTile(
              leading: Icon(Icons.report_outlined, color: AppColors.warning),
              title: Text('Zgłoś problem'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show report dialog
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: AppColors.error),
              title: Text('Anuluj zlecenie', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showCancelDialog();
              },
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nie'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelTask();
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
