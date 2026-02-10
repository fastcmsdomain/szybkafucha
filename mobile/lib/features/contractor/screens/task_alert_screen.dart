import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_map_view.dart';
import '../../../core/widgets/sf_location_marker.dart';
import '../../client/models/task_category.dart';
import '../models/contractor_task.dart';

/// Task details screen for contractor to view and accept tasks
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

class _TaskAlertScreenState extends ConsumerState<TaskAlertScreen> {
  bool _isAccepting = false;
  double? _clientRatingAvg;
  int? _clientRatingCount;

  // Get task from widget or use mock
  ContractorTask get _task =>
      widget.task ?? ContractorTask.mockNearbyTasks().first;

  @override
  void initState() {
    super.initState();
    _fetchClientRatingSummary();
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
    final categoryData = TaskCategoryData.fromCategory(_task.category);
    final rating = _clientRatingAvg ?? _task.clientRating;
    final reviewCount = _clientRatingCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () => _navigateBack(context),
        ),
        title: Text(
          'Szczegóły zlecenia',
          style: AppTypography.h4.copyWith(color: AppColors.gray900),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category and price
            _buildHeader(categoryData),

            // Task details
            Padding(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description section
                  _buildSection(
                    title: 'Opis zlecenia',
                    child: Text(
                      _task.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray700,
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.space4),

                  // Time and Images section
                  _buildSection(
                    title: 'Szczegóły',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Created time
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.gray500,
                            ),
                            SizedBox(width: AppSpacing.gapXS),
                            Text(
                              'Utworzono: ${_getTimeAgo(_task.createdAt)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                          ],
                        ),

                        // Estimated duration
                        if (_task.estimatedDurationHours != null) ...[
                          SizedBox(height: AppSpacing.gapSM),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: AppColors.info,
                              ),
                              SizedBox(width: AppSpacing.gapXS),
                              Text(
                                'Szacowany czas: ${_formatDuration(_task.estimatedDurationHours!)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Scheduled time
                        if (_task.scheduledAt != null) ...[
                          SizedBox(height: AppSpacing.gapSM),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: AppSpacing.gapXS),
                              Text(
                                'Zaplanowane: ${_formatScheduledTime(_task.scheduledAt!)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(height: AppSpacing.gapSM),
                          Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: AppSpacing.gapXS),
                              Text(
                                'Natychmiast',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Images
                        if (_task.imageUrls != null && _task.imageUrls!.isNotEmpty) ...[
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
                              itemCount: _task.imageUrls!.length,
                              itemBuilder: (context, index) {
                                final imageUrl = _task.imageUrls![index];
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
                  ),

                  SizedBox(height: AppSpacing.space4),

                  // Location section with map
                  _buildSection(
                    title: 'Lokalizacja',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map preview
                        ClipRRect(
                          borderRadius: AppRadius.radiusMD,
                          child: SizedBox(
                            height: 150,
                            child: Stack(
                              children: [
                                SFMapView(
                                  center: LatLng(_task.latitude, _task.longitude),
                                  zoom: 15,
                                  markers: [
                                    TaskMarker(
                                      position: LatLng(_task.latitude, _task.longitude),
                                    ),
                                  ],
                                  interactive: false,
                                  showZoomControls: false,
                                ),
                                // Navigate button overlay
                                Positioned(
                                  right: AppSpacing.paddingSM,
                                  bottom: AppSpacing.paddingSM,
                                  child: Material(
                                    color: AppColors.primary,
                                    borderRadius: AppRadius.radiusMD,
                                    elevation: 2,
                                    child: InkWell(
                                      onTap: _openNavigation,
                                      borderRadius: AppRadius.radiusMD,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.paddingMD,
                                          vertical: AppSpacing.paddingSM,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.navigation,
                                              color: AppColors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Nawiguj',
                                              style: AppTypography.labelMedium.copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.gapMD),
                        // Address info
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppSpacing.paddingSM),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.radiusMD,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: AppSpacing.gapMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _task.address,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        size: 14,
                                        color: AppColors.gray500,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${_task.formattedDistance} • ${_task.formattedEta}',
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
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacing.space4),

                  // Client section
                  _buildSection(
                    title: 'Zleceniodawca',
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.gray200,
                          child: Text(
                            _task.clientName[0].toUpperCase(),
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
                                _task.clientName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.gray600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 6),
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
                        SizedBox(width: AppSpacing.gapMD),
                        TextButton.icon(
                          onPressed: _showClientProfilePopup,
                          icon: const Icon(
                            Icons.person_outline,
                            color: AppColors.white,
                            size: 18,
                          ),
                          label: Text(
                            'Profil',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            shape: const StadiumBorder(),
                            minimumSize: const Size(88, 44),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.paddingSM,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_task.isUrgent) ...[
                    SizedBox(height: AppSpacing.space4),
                    // Urgent badge
                    Container(
                      padding: EdgeInsets.all(AppSpacing.paddingMD),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: AppRadius.radiusLG,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: AppSpacing.gapMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilne zlecenie',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                                Text(
                                  'Zleceniodawca potrzebuje szybkiej pomocy',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(TaskCategoryData categoryData) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category icon
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
                      style: AppTypography.h4.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getTimeAgo(_task.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space4),
          // Price
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
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
                  _task.formattedEarnings,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapMD),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAccepting ? null : _handleAccept,
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
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);

    try {
      final acceptedTask = await ref
          .read(availableTasksProvider.notifier)
          .acceptTask(_task.id);

      // Set as active task
      ref.read(activeTaskProvider.notifier).setTask(acceptedTask);

      if (mounted) {
        HapticFeedback.mediumImpact();
        // Navigate to active task screen - success feedback shown there
        context.go(Routes.contractorTask(_task.id));
      }
    } catch (e) {
      setState(() => _isAccepting = false);
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

  /// Open navigation to task location in default map app
  Future<void> _openNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_task.latitude},${_task.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie można otworzyć nawigacji'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Przed chwilą';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min temu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} godz. temu';
    } else {
      return '${difference.inDays} dni temu';
    }
  }

  String _formatScheduledTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year o $hour:$minute';
  }

  String _formatDuration(double hours) {
    if (hours < 1) {
      // Less than 1 hour - show in minutes
      final minutes = (hours * 60).round();
      return '$minutes min';
    } else if (hours == hours.floor()) {
      // Whole hours (1.0, 2.0, etc.)
      return '${hours.toInt()}h';
    } else {
      // Hours with minutes (1.5, 2.5, etc.)
      final wholeHours = hours.floor();
      final remainingMinutes = ((hours - wholeHours) * 60).round();
      return '${wholeHours}h ${remainingMinutes}min';
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.gray100,
                    child: Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray900.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchClientRatingSummary() async {
    if (_task.clientId.isEmpty) return;

    final api = ref.read(apiClientProvider);

    try {
      final response = await api.get('/client/${_task.clientId}/public');
      final data = response as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _clientRatingAvg = (data['ratingAvg'] as num?)?.toDouble();
        _clientRatingCount = data['ratingCount'] as int?;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clientRatingAvg = _task.clientRating;
        _clientRatingCount = _clientRatingCount ?? 0;
      });
    }
  }

  void _showClientProfilePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.5,
        child: _TaskAlertClientProfileSheet(
          clientId: _task.clientId,
          clientName: _task.clientName,
          clientRating: _task.clientRating,
          clientAvatarUrl: _task.clientAvatarUrl,
        ),
      ),
    );
  }
}

class _TaskAlertClientProfileSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final double clientRating;
  final String? clientAvatarUrl;

  const _TaskAlertClientProfileSheet({
    required this.clientId,
    required this.clientName,
    required this.clientRating,
    this.clientAvatarUrl,
  });

  @override
  ConsumerState<_TaskAlertClientProfileSheet> createState() =>
      _TaskAlertClientProfileSheetState();
}

class _TaskAlertClientProfileSheetState
    extends ConsumerState<_TaskAlertClientProfileSheet> {
  String? _bio;
  double? _ratingAvg;
  int? _ratingCount;
  String? _avatarUrl;
  bool _isLoading = true;
  bool _isReviewsLoading = true;
  String? _error;
  List<_TaskAlertClientPublicReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchFullProfile();
  }

  Future<void> _fetchFullProfile() async {
    final api = ref.read(apiClientProvider);
    String? bio;
    double? ratingAvg;
    int? ratingCount;
    String? avatarUrl;
    String? error;
    List<_TaskAlertClientPublicReview> reviews = const [];

    try {
      final response = await api.get('/client/${widget.clientId}/public');
      final data = response as Map<String, dynamic>;

      bio = data['bio'] as String?;
      ratingAvg = (data['ratingAvg'] as num?)?.toDouble();
      ratingCount = data['ratingCount'] as int?;
      avatarUrl = data['avatarUrl'] as String?;
    } catch (e) {
      error = e.toString();
    }

    try {
      final reviewsResponse = await api.get('/client/${widget.clientId}/reviews');
      final reviewsData = reviewsResponse as Map<String, dynamic>;
      final reviewsList = (reviewsData['reviews'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_TaskAlertClientPublicReview.fromJson)
          .toList();

      reviews = reviewsList;
      ratingAvg ??= (reviewsData['ratingAvg'] as num?)?.toDouble();
      ratingCount ??= reviewsData['ratingCount'] as int?;
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _bio = bio;
      _ratingAvg = ratingAvg;
      _ratingCount = ratingCount;
      _avatarUrl = avatarUrl;
      _error = error;
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

  Widget _buildReviewCard(_TaskAlertClientPublicReview review) {
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
              SizedBox(width: 4),
              Text(
                review.rating.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            review.comment?.trim().isNotEmpty == true
                ? review.comment!.trim()
                : 'Brak komentarza.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray700,
            ),
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

    final reviewCount = _ratingCount ?? 0;
    final rating = _ratingAvg ?? widget.clientRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, size: 18, color: AppColors.warning),
            SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'na podstawie $reviewCount opinii',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.gapSM),
        if (_reviews.isEmpty)
          Text(
            'Brak opinii do wyświetlenia.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
          )
        else
          ..._reviews.take(5).map(
                (review) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.gapSM),
                  child: _buildReviewCard(review),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rating = _ratingAvg ?? widget.clientRating;
    final reviewCount = _ratingCount ?? 0;
    final avatarUrl = _avatarUrl ?? widget.clientAvatarUrl;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.paddingLG,
              AppSpacing.paddingSM,
              AppSpacing.paddingLG,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profil klienta', style: AppTypography.h4),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.paddingLG,
                0,
                AppSpacing.paddingLG,
                AppSpacing.paddingLG,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.gapMD),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.gray200,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
                                Icon(
                                  Icons.star,
                                  size: 18,
                                  color: AppColors.warning,
                                ),
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
                  Text(
                    'Opinie',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskAlertClientPublicReview {
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const _TaskAlertClientPublicReview({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory _TaskAlertClientPublicReview.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    return _TaskAlertClientPublicReview(
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString(),
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
