import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Review client screen - contractors rate clients after task completion
class ReviewClientScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String? clientName;
  final int? earnings;

  const ReviewClientScreen({
    super.key,
    required this.taskId,
    this.clientName,
    this.earnings,
  });

  @override
  ConsumerState<ReviewClientScreen> createState() => _ReviewClientScreenState();
}

class _ReviewClientScreenState extends ConsumerState<ReviewClientScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success header
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildSuccessHeader(),
              ),

              SizedBox(height: AppSpacing.space8),

              // Rating section
              _buildRatingSection(),

              SizedBox(height: AppSpacing.space6),

              // Review section
              _buildReviewSection(),

              SizedBox(height: AppSpacing.space8),

              // Submit button
              _buildSubmitButton(),

              SizedBox(height: AppSpacing.space4),

              // Skip button
              TextButton(
                onPressed: () => _finishWithoutRating(),
                child: Text(
                  'Pomiń ocenę',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 64,
          ),
        ),
        SizedBox(height: AppSpacing.space4),
        Text(
          'Zlecenie zakończone!',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        if (widget.earnings != null) ...[
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Zarobiłeś ${widget.earnings} zł',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: AppSpacing.gapSM),
        Text(
          'Oceń swojego klienta',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.gray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          if (widget.clientName != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.gray200,
                  child: Text(
                    widget.clientName![0].toUpperCase(),
                    style: AppTypography.h4.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.gapMD),
                Text(
                  widget.clientName!,
                  style: AppTypography.labelLarge,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.space4),
          ],
          Text(
            'Jak oceniasz współpracę z klientem?',
            style: AppTypography.labelLarge,
          ),
          SizedBox(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starNumber),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: _rating >= starNumber ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _rating >= starNumber ? Icons.star : Icons.star_border,
                      color: _rating >= starNumber
                          ? AppColors.warning
                          : AppColors.gray300,
                      size: 48,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            _getRatingText(),
            style: AppTypography.bodySmall.copyWith(
              color: _rating > 0 ? AppColors.gray700 : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Bardzo słaba współpraca';
      case 2:
        return 'Słaba współpraca';
      case 3:
        return 'Przeciętna współpraca';
      case 4:
        return 'Dobra współpraca';
      case 5:
        return 'Doskonała współpraca!';
      default:
        return 'Kliknij gwiazdkę, aby ocenić';
    }
  }

  Widget _buildReviewSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dodaj komentarz',
                style: AppTypography.labelLarge,
              ),
              SizedBox(width: AppSpacing.gapSM),
              Text(
                '(opcjonalnie)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapMD),
          TextFormField(
            controller: _reviewController,
            maxLines: 4,
            maxLength: 500,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText:
                  'Opisz swoje doświadczenie z klientem (jasność instrukcji, komunikacja, warunki pracy...)',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray400,
              ),
              counterText: '',
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Twoja opinia pomoże innym wykonawcom',
            style: AppTypography.caption.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingLG),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
        disabledBackgroundColor: AppColors.gray300,
      ),
      child: _isSubmitting
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.white),
              ),
            )
          : Text(
              'Wyślij ocenę',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      // TODO: Call backend API to submit rating
      // await ref.read(apiClientProvider).post('/tasks/${widget.taskId}/rate', data: {
      //   'rating': _rating,
      //   'comment': _reviewController.text.isNotEmpty ? _reviewController.text : null,
      // });

      // Simulate API call for now
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        _showThankYouDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.thumb_up,
                color: AppColors.success,
                size: 48,
              ),
            ),
            SizedBox(height: AppSpacing.space4),
            Text(
              'Dziękujemy!',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.gapSM),
            Text(
              'Twoja ocena została wysłana',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(Routes.contractorHome);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text('Wróć do strony głównej'),
            ),
          ),
        ],
      ),
    );
  }

  void _finishWithoutRating() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pominąć ocenę?'),
        content: Text(
          'Twoja opinia pomaga innym wykonawcom poznać klientów.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zostań i oceń'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(Routes.contractorHome);
            },
            child: Text(
              'Pomiń',
              style: TextStyle(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}
