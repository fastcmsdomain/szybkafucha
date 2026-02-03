import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/task_provider.dart';

/// Task completion and rating screen
class TaskCompletionScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskCompletionScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskCompletionScreen> createState() =>
      _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends ConsumerState<TaskCompletionScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _reviewController = TextEditingController();
  int? _selectedTip;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<int> _tipOptions = [0, 5, 10, 15, 20];

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
              // Success animation
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

              SizedBox(height: AppSpacing.space6),

              // Tip section
              _buildTipSection(),

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
        SizedBox(height: AppSpacing.gapSM),
        Text(
          'Dziękujemy za skorzystanie z Szybka Fucha',
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
          Text(
            'Jak oceniasz usługę?',
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
        return 'Bardzo słabo';
      case 2:
        return 'Słabo';
      case 3:
        return 'Przeciętnie';
      case 4:
        return 'Dobrze';
      case 5:
        return 'Doskonale!';
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
                'Zostaw opinię',
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
              hintText: 'Opisz swoje doświadczenie z wykonawcą...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray400,
              ),
              counterText: '',
            ),
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Twoja opinia pomoże innym użytkownikom',
            style: AppTypography.caption.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
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
              Icon(
                Icons.favorite,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: AppSpacing.gapSM),
              Text(
                'Chcesz dodać napiwek?',
                style: AppTypography.labelLarge,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            '100% napiwku trafia do wykonawcy',
            style: AppTypography.caption.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.space4),
          Row(
            children: _tipOptions.map((tip) {
              final isSelected = _selectedTip == tip;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTip = tip),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.paddingMD,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray50,
                        borderRadius: AppRadius.radiusMD,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.gray200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            tip == 0 ? 'Bez' : '$tip zł',
                            style: AppTypography.bodySmall.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.gray700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
              _selectedTip != null && _selectedTip! > 0
                  ? 'Wyślij ocenę i napiwek'
                  : 'Wyślij ocenę',
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
      final tasksNotifier = ref.read(clientTasksProvider.notifier);

      // 1) Client confirms completion (moves task to pending_complete)
      await tasksNotifier.confirmTask(widget.taskId);

      // 2) Send rating + optional comment
      await tasksNotifier.rateTask(
        widget.taskId,
        rating: _rating,
        comment: _reviewController.text.isNotEmpty ? _reviewController.text : null,
      );

      // 3) Optional tip
      if (_selectedTip != null && _selectedTip! > 0) {
        await tasksNotifier.addTip(widget.taskId, _selectedTip!.toDouble());
      }

      // Refresh cached tasks
      await tasksNotifier.refresh();

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
              _selectedTip != null && _selectedTip! > 0
                  ? 'Twoja ocena i napiwek zostały wysłane'
                  : 'Twoja ocena została wysłana',
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
                context.go(Routes.clientHome);
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
          'Twoja opinia pomaga innym użytkownikom i nagradza wykonawców.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zostań i oceń'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(clientTasksProvider.notifier).confirmTask(widget.taskId);
              await ref.read(clientTasksProvider.notifier).refresh();
              context.go(Routes.clientHome);
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
