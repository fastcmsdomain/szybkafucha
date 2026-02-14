import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/theme/theme.dart';
import '../../client/models/task_category.dart';
import '../models/contractor_task.dart';

/// Nearby task card for contractor dashboard
class NearbyTaskCard extends ConsumerStatefulWidget {
  final ContractorTask task;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDetails;
  /// Show action buttons (accept/details). For client list view we hide them.
  final bool showActions;
  /// Show client info row (avatar, name, rating, reviews).
  final bool showClientInfo;

  const NearbyTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onAccept,
    this.onDetails,
    this.showActions = true,
    this.showClientInfo = true,
  });

  @override
  ConsumerState<NearbyTaskCard> createState() => _NearbyTaskCardState();
}

class _NearbyTaskCardState extends ConsumerState<NearbyTaskCard> {
  static final Map<String, _ClientRatingSummary> _ratingCache = {};

  double? _clientRatingAvg;
  int? _clientRatingCount;

  ContractorTask get task => widget.task;

  @override
  void initState() {
    super.initState();
    _hydrateOrFetchClientRatingSummary();
  }

  @override
  void didUpdateWidget(covariant NearbyTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.clientId != widget.task.clientId) {
      _clientRatingAvg = null;
      _clientRatingCount = null;
      _hydrateOrFetchClientRatingSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = TaskCategoryData.fromCategory(task.category);
    final rating = _clientRatingAvg ?? task.clientRating;
    final reviewCount = _clientRatingCount ?? task.clientReviewCount;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: task.isUrgent ? AppColors.primary : AppColors.gray200,
            width: task.isUrgent ? 2 : 1,
          ),
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
            // Header row
            Row(
              children: [
                // Category icon
                Container(
                  padding: EdgeInsets.all(AppSpacing.paddingSM),
                  decoration: BoxDecoration(
                    color: categoryData.color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Icon(
                    categoryData.icon,
                    color: categoryData.color,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppSpacing.gapMD),

                // Category and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            categoryData.name,
                            style: AppTypography.labelMedium,
                          ),
                          if (task.isUrgent) ...[
                            SizedBox(width: AppSpacing.gapSM),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: AppRadius.radiusSM,
                              ),
                              child: Text(
                                'PILNE',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _getTimeAgo(task.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
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
                      'do zarobienia',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Description
            Text(
              task.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: AppSpacing.gapMD),

            // Location and distance
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.gray500,
                ),
                SizedBox(width: 4),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingSM,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: AppRadius.radiusSM,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 12,
                        color: AppColors.gray600,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${task.formattedDistance} • ${task.formattedEta}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.showClientInfo || widget.showActions) ...[
              SizedBox(height: AppSpacing.gapMD),

              // Client info and accept button
              Row(
                children: [
                  if (widget.showClientInfo) ...[
                    // Client info
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.gray200,
                      child: Text(
                        task.clientName[0],
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.gapSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.clientName,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$reviewCount opinii',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!widget.showClientInfo) const Spacer(),

                  if (widget.showActions) ...[
                    // More info button
                    OutlinedButton(
                      onPressed: widget.onDetails,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray700,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingSM,
                          vertical: AppSpacing.paddingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMD,
                        ),
                        side: BorderSide(color: AppColors.gray300),
                      ),
                      child: const Text('Więcej'),
                    ),
                    SizedBox(width: AppSpacing.gapSM),
                    // Accept button
                    ElevatedButton(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingMD,
                          vertical: AppSpacing.paddingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMD,
                        ),
                      ),
                      child: const Text('Przyjmij'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _hydrateOrFetchClientRatingSummary() {
    if (task.clientId.isEmpty) return;

    final cached = _ratingCache[task.clientId];
    if (cached != null) {
      _clientRatingAvg = cached.ratingAvg;
      _clientRatingCount = cached.ratingCount;
      return;
    }

    _fetchClientRatingSummary();
  }

  Future<void> _fetchClientRatingSummary() async {
    if (task.clientId.isEmpty) return;

    final api = ref.read(apiClientProvider);

    try {
      final response = await api.get('/client/${task.clientId}/public');
      final data = response as Map<String, dynamic>;
      final ratingAvg = (data['ratingAvg'] as num?)?.toDouble();
      final ratingCount = data['ratingCount'] as int?;

      _ratingCache[task.clientId] = _ClientRatingSummary(
        ratingAvg: ratingAvg,
        ratingCount: ratingCount,
      );

      if (!mounted) return;

      setState(() {
        _clientRatingAvg = ratingAvg;
        _clientRatingCount = ratingCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clientRatingAvg = task.clientRating;
        _clientRatingCount = task.clientReviewCount;
      });
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
}

class _ClientRatingSummary {
  final double? ratingAvg;
  final int? ratingCount;

  const _ClientRatingSummary({
    required this.ratingAvg,
    required this.ratingCount,
  });
}
