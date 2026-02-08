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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/client/profile');
      final data = response as Map<String, dynamic>;

      final ratingAvgValue = data['ratingAvg'];
      final ratingCountValue = data['ratingCount'];

      if (!mounted) return;
      setState(() {
        _ratingAvg = ratingAvgValue != null
            ? (double.tryParse(ratingAvgValue.toString()) ?? 0.0)
            : 0.0;
        _ratingCount = ratingCountValue is int
            ? ratingCountValue
            : (int.tryParse(ratingCountValue?.toString() ?? '') ?? 0);
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
              Container(
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
                    SizedBox(height: AppSpacing.gapSM),
                    Text(
                      'Opinie wkrótce dostępne do podglądu w aplikacji.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
}
