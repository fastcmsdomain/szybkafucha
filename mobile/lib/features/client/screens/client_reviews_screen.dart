import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_provider.dart';
import '../../../core/theme/theme.dart';

/// Client reviews screen shown from profile menu.
class ClientReviewsScreen extends ConsumerStatefulWidget {
  const ClientReviewsScreen({super.key});

  @override
  ConsumerState<ClientReviewsScreen> createState() => _ClientReviewsScreenState();
}

class _ClientReviewsScreenState extends ConsumerState<ClientReviewsScreen> {
  double _ratingAvg = 0.0;
  int _ratingCount = 0;
  List<_ClientReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/client/reviews');
      final data = response as Map<String, dynamic>;

      final ratingAvgValue = data['ratingAvg'];
      final ratingCountValue = data['ratingCount'];
      final reviewsData = (data['reviews'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_ClientReview.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _ratingAvg = ratingAvgValue != null
            ? (double.tryParse(ratingAvgValue.toString()) ?? 0.0)
            : 0.0;
        _ratingCount = ratingCountValue is int
            ? ratingCountValue
            : (int.tryParse(ratingCountValue?.toString() ?? '') ?? 0);
        _reviews = reviewsData;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Opinie wykonawców',
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(),
              SizedBox(height: AppSpacing.space4),
              Expanded(
                child: _buildReviewsList(),
              ),
              SizedBox(height: AppSpacing.space4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Zamknij'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.paddingMD,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Oceny wykonawców',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          if (_isLoading)
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              children: [
                Icon(Icons.star, color: AppColors.warning, size: 22),
                SizedBox(width: 6),
                Text(
                  _ratingAvg.toStringAsFixed(1),
                  style: AppTypography.h4,
                ),
                SizedBox(width: 6),
                Text(
                  'na podstawie $_ratingCount opinii',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          if (_reviews.isEmpty) ...[
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Opinie wkrótce dostępne do podglądu w aplikacji.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Text(
          'Brak opinii do wyświetlenia.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
        ),
      );
    }

    return ListView.separated(
      itemCount: _reviews.length,
      separatorBuilder: (_, index) => SizedBox(height: AppSpacing.gapSM),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Container(
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
                    style: AppTypography.bodyLarge.copyWith(
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
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }
}

class _ClientReview {
  final int rating;
  final String? comment;
  final DateTime createdAt;

  _ClientReview({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory _ClientReview.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    return _ClientReview(
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString(),
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
