import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme.dart';
import '../../client/models/task_category.dart';
import '../models/contractor_task.dart';

/// Full-screen task alert with countdown timer
class TaskAlertScreen extends ConsumerStatefulWidget {
  final String taskId;
  final ContractorTask? task;

  const TaskAlertScreen({
    super.key,
    required this.taskId,
    this.task,
  });

  @override
  ConsumerState<TaskAlertScreen> createState() => _TaskAlertScreenState();
}

class _TaskAlertScreenState extends ConsumerState<TaskAlertScreen>
    with SingleTickerProviderStateMixin {
  static const _countdownSeconds = 45;
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAccepting = false;
  bool _isDeclining = false;

  // Get task from widget or use mock
  ContractorTask get _task =>
      widget.task ?? ContractorTask.mockNearbyTasks().first;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _countdownSeconds;
    _startCountdown();

    // Pulse animation for the price
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Vibrate to alert
    HapticFeedback.heavyImpact();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds == 10) {
          HapticFeedback.mediumImpact();
        }
      } else {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = TaskCategoryData.fromCategory(_task.category);

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            children: [
              // Header with countdown
              _buildHeader(),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category icon
                        Container(
                          padding: EdgeInsets.all(AppSpacing.paddingLG),
                          decoration: BoxDecoration(
                            color: categoryData.color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            categoryData.icon,
                            color: categoryData.color,
                            size: 48,
                          ),
                        ),

                        SizedBox(height: AppSpacing.space4),

                        // Category name
                        Text(
                          categoryData.name.toUpperCase(),
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.white.withValues(alpha: 0.7),
                            letterSpacing: 2,
                          ),
                        ),

                        SizedBox(height: AppSpacing.space4),

                        // Price with pulse animation
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            _task.formattedEarnings,
                            style: AppTypography.h1.copyWith(
                              color: AppColors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        Text(
                          'do zarobienia',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                        ),

                        SizedBox(height: AppSpacing.space8),

                        // Task details card
                        _buildTaskDetails(categoryData),

                        SizedBox(height: AppSpacing.space8),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final progress = _remainingSeconds / _countdownSeconds;
    final isUrgent = _remainingSeconds <= 10;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NOWE ZLECENIE',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
                letterSpacing: 2,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingMD,
                vertical: AppSpacing.paddingSM,
              ),
              decoration: BoxDecoration(
                color: isUrgent
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.white.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: isUrgent ? AppColors.error : AppColors.white,
                  ),
                  SizedBox(width: AppSpacing.gapSM),
                  Text(
                    '$_remainingSeconds s',
                    style: AppTypography.labelLarge.copyWith(
                      color: isUrgent ? AppColors.error : AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapMD),
        ClipRRect(
          borderRadius: AppRadius.radiusSM,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              isUrgent ? AppColors.error : AppColors.primary,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetails(TaskCategoryData categoryData) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            _task.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: AppSpacing.space4),

          Divider(color: AppColors.white.withValues(alpha: 0.1)),

          SizedBox(height: AppSpacing.gapMD),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
              SizedBox(width: AppSpacing.gapSM),
              Expanded(
                child: Text(
                  _task.address,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.gapMD),

          // Distance and ETA
          Row(
            children: [
              _buildInfoChip(
                Icons.directions_walk,
                _task.formattedDistance,
              ),
              SizedBox(width: AppSpacing.gapMD),
              _buildInfoChip(
                Icons.access_time,
                _task.formattedEta,
              ),
            ],
          ),

          SizedBox(height: AppSpacing.space4),

          // Client info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                child: Text(
                  _task.clientName[0],
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.gapSM),
              Expanded(
                child: Text(
                  _task.clientName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              Icon(
                Icons.star,
                size: 16,
                color: AppColors.warning,
              ),
              SizedBox(width: 4),
              Text(
                _task.clientRating.toStringAsFixed(1),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingSM,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Accept button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAccepting || _isDeclining ? null : _handleAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingLG),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusLG,
              ),
              disabledBackgroundColor: AppColors.success.withValues(alpha: 0.5),
            ),
            child: _isAccepting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 24),
                      SizedBox(width: AppSpacing.gapMD),
                      Text(
                        'PRZYJMIJ ZLECENIE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Decline button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isAccepting || _isDeclining ? null : _handleDecline,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white.withValues(alpha: 0.7),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
            ),
            child: _isDeclining
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : const Text('Odrzuć'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);
    _timer?.cancel();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      HapticFeedback.mediumImpact();
      context.pop(true); // Return true to indicate acceptance
    }
  }

  Future<void> _handleDecline() async {
    setState(() => _isDeclining = true);
    _timer?.cancel();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      context.pop(false); // Return false to indicate decline
    }
  }

  void _handleTimeout() {
    if (mounted) {
      context.pop(null); // Return null to indicate timeout
    }
  }
}
