import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';

/// Reusable widget for selecting user type (client or contractor)
/// Used in both WelcomeScreen and RegisterScreen
class UserTypeSelector extends StatefulWidget {
  /// Initial selected user type ('client' or 'contractor')
  final String initialType;

  /// Callback when user type is selected
  final ValueChanged<String> onTypeSelected;

  /// Whether to show this widget in a compact form (for WelcomeScreen)
  /// or full form (for RegisterScreen)
  final bool compact;

  const UserTypeSelector({
    super.key,
    this.initialType = 'client',
    required this.onTypeSelected,
    this.compact = true,
  });

  @override
  State<UserTypeSelector> createState() => _UserTypeSelectorState();
}

class _UserTypeSelectorState extends State<UserTypeSelector> {
  late String _selectedUserType;

  @override
  void initState() {
    super.initState();
    _selectedUserType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // Compact form for WelcomeScreen - horizontal buttons
      return Row(
        children: [
          Expanded(
            child: _buildCompactButton(
              type: 'client',
              label: AppStrings.iAmClient,
              icon: Icons.search,
            ),
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: _buildCompactButton(
              type: 'contractor',
              label: AppStrings.iAmContractor,
              icon: Icons.handyman,
            ),
          ),
        ],
      );
    } else {
      // Full form for RegisterScreen - vertical cards with descriptions
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFullOption(
            type: 'client',
            icon: Icons.search,
            title: AppStrings.iAmClient,
            description: AppStrings.clientDescription,
          ),
          SizedBox(height: AppSpacing.gapMD),
          _buildFullOption(
            type: 'contractor',
            icon: Icons.handyman,
            title: AppStrings.iAmContractor,
            description: AppStrings.contractorDescription,
          ),
        ],
      );
    }
  }

  /// Compact button for WelcomeScreen
  Widget _buildCompactButton({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedUserType == type;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedUserType = type);
        widget.onTypeSelected(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.paddingMD,
          horizontal: AppSpacing.paddingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.gray100,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.gray600,
              size: 24,
            ),
            SizedBox(height: AppSpacing.gapXS),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.white : AppColors.gray800,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// Full card option for RegisterScreen
  Widget _buildFullOption({
    required String type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedUserType == type;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedUserType = type);
        widget.onTypeSelected(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.1) : AppColors.gray50,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.gray200,
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.gray600,
                size: 28,
              ),
            ),
            SizedBox(width: AppSpacing.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.gray800,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapXS),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            // Custom radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gray300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
