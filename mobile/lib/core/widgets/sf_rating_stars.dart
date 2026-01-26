import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Display mode for rating stars
enum SFRatingDisplayMode { display, input }

/// Star rating widget (1-5 stars)
class SFRatingStars extends StatelessWidget {
  final double rating;
  final SFRatingDisplayMode mode;
  final ValueChanged<int>? onRatingChanged;
  final double size;
  final bool showValue;
  final int? reviewCount;

  const SFRatingStars({
    super.key,
    required this.rating,
    this.mode = SFRatingDisplayMode.display,
    this.onRatingChanged,
    this.size = 20,
    this.showValue = false,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) => _buildStar(index + 1)),
        if (showValue) ...[
          SizedBox(width: AppSpacing.gapSM),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.gray700,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          SizedBox(width: AppSpacing.gapXS),
          Text(
            '($reviewCount)',
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int starNumber) {
    final isFilled = starNumber <= rating;
    final isHalfFilled = !isFilled && starNumber - 0.5 <= rating;

    IconData icon;
    Color color;

    if (isFilled) {
      icon = Icons.star_rounded;
      color = AppColors.starRating;
    } else if (isHalfFilled) {
      icon = Icons.star_half_rounded;
      color = AppColors.starRating;
    } else {
      icon = Icons.star_outline_rounded;
      color = AppColors.gray300;
    }

    if (mode == SFRatingDisplayMode.input) {
      return GestureDetector(
        onTap: () => onRatingChanged?.call(starNumber),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            icon,
            size: size,
            color: color,
          ),
        ),
      );
    }

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}

/// Interactive rating input widget
class SFRatingInput extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const SFRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  State<SFRatingInput> createState() => _SFRatingInputState();
}

class _SFRatingInputState extends State<SFRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= _currentRating;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starNumber;
            });
            widget.onRatingChanged(starNumber);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: widget.size,
              color: isFilled ? AppColors.starRating : AppColors.gray300,
            ),
          ),
        );
      }),
    );
  }
}
