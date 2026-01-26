import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';

/// Registration screen
/// Collects user name and type (client or contractor)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedUserType = 'client';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.register,
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.space4),

                // Name input
                Text(
                  AppStrings.yourName,
                  style: AppTypography.labelLarge,
                ),
                SizedBox(height: AppSpacing.gapSM),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: AppStrings.enterYourName,
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.gray400),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wprowadź swoje imię';
                    }
                    if (value.length < 2) {
                      return 'Imię musi mieć co najmniej 2 znaki';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.space8),

                // User type selection
                Text(
                  AppStrings.selectUserType,
                  style: AppTypography.labelLarge,
                ),
                SizedBox(height: AppSpacing.gapMD),

                // Client option
                _buildUserTypeOption(
                  type: 'client',
                  icon: Icons.search,
                  title: AppStrings.iAmClient,
                  description: AppStrings.clientDescription,
                ),

                SizedBox(height: AppSpacing.gapMD),

                // Contractor option
                _buildUserTypeOption(
                  type: 'contractor',
                  icon: Icons.handyman,
                  title: AppStrings.iAmContractor,
                  description: AppStrings.contractorDescription,
                ),

                const Spacer(),

                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.white),
                          ),
                        )
                      : Text(
                          AppStrings.register,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption({
    required String type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedUserType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedUserType = type),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Call API to complete registration
      // await ref.read(authProvider.notifier).completeRegistration(
      //   name: _nameController.text,
      //   userType: _selectedUserType,
      // );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejestracja zakończona!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigation will be handled by auth state change
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
        setState(() => _isLoading = false);
      }
    }
  }
}
