import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../models/contractor.dart';

/// Task tracking status
enum TrackingStatus {
  searching,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  completed,
}

extension TrackingStatusExtension on TrackingStatus {
  String get title {
    switch (this) {
      case TrackingStatus.searching:
        return 'Szukamy pomocnika';
      case TrackingStatus.accepted:
        return 'Pomocnik znaleziony';
      case TrackingStatus.onTheWay:
        return 'W drodze';
      case TrackingStatus.arrived:
        return 'Na miejscu';
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
        return 'Wykonawca przyjął zlecenie';
      case TrackingStatus.onTheWay:
        return 'Wykonawca jest w drodze do Ciebie';
      case TrackingStatus.arrived:
        return 'Wykonawca dotarł na miejsce';
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
      case TrackingStatus.onTheWay:
        return 1;
      case TrackingStatus.arrived:
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
  int _etaMinutes = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _simulateStatusUpdates();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _simulateStatusUpdates() {
    // Simulate finding a contractor after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _status = TrackingStatus.accepted;
          _contractor = MockContractors.getForTask().first;
          _etaMinutes = 12;
        });
      }
    });

    // Simulate on the way after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _status = TrackingStatus.onTheWay;
          _etaMinutes = 10;
        });
      }
    });

    // Start countdown timer
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _etaMinutes > 0) {
        setState(() => _etaMinutes--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
    return Container(
      color: AppColors.gray100,
      child: Stack(
        children: [
          // Grid pattern to simulate map
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),

          // Center marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.radiusMD,
                    boxShadow: AppShadows.lg,
                  ),
                  child: Text(
                    'Twoja lokalizacja',
                    style: AppTypography.caption,
                  ),
                ),
                SizedBox(height: AppSpacing.gapXS),
                Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 48,
                ),
              ],
            ),
          ),

          // Contractor marker (if assigned)
          if (_contractor != null && _status != TrackingStatus.searching)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              right: MediaQuery.of(context).size.width * 0.25,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.paddingXS),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.radiusSM,
                      boxShadow: AppShadows.md,
                    ),
                    child: Text(
                      _contractor!.name.split(' ').first,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.md,
                    ),
                    child: Icon(
                      Icons.directions_walk,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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

                  // Action buttons
                  if (_status != TrackingStatus.searching &&
                      _status != TrackingStatus.completed)
                    _buildActionButtons(),

                  // Complete button (when arrived or in progress)
                  if (_status == TrackingStatus.arrived ||
                      _status == TrackingStatus.inProgress)
                    _buildCompleteButton(),
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
        if (_etaMinutes > 0 && _status == TrackingStatus.onTheWay)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingSM,
              vertical: AppSpacing.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 4),
                Text(
                  '$_etaMinutes min',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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
        return Icons.check_circle;
      case TrackingStatus.onTheWay:
        return Icons.directions_walk;
      case TrackingStatus.arrived:
        return Icons.location_on;
      case TrackingStatus.inProgress:
        return Icons.handyman;
      case TrackingStatus.completed:
        return Icons.check_circle;
    }
  }

  Widget _buildProgressSteps() {
    final steps = ['Szukanie', 'W drodze', 'Na miejscu', 'Praca', 'Gotowe'];
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
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.gray200,
                child: Text(
                  _contractor!.name[0].toUpperCase(),
                  style: AppTypography.h4.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
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
                    Text(
                      _contractor!.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
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
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.warning),
                    SizedBox(width: 2),
                    Text(
                      _contractor!.formattedRating,
                      style: AppTypography.caption.copyWith(
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
              context.go(Routes.clientHome);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Zlecenie zostało anulowane'),
                  backgroundColor: AppColors.warning,
                ),
              );
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
}

/// Custom painter for map grid pattern
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = 1;

    const spacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
