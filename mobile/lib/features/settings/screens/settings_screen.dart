import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/router/routes.dart';

/// Settings screen for user preferences and account management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia', style: AppTypography.h4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account section
            _buildSection(
              title: 'Konto',
              children: [
                // MVP: Role switching disabled
                _buildMenuItem(
                  icon: Icons.logout_outlined,
                  title: 'Wyloguj się',
                  titleColor: AppColors.error,
                  onTap: () => _showLogoutConfirmation(context, ref),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.space4),

            // About section
            _buildSection(
              title: 'Informacje',
              children: [
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Polityka prywatności',
                  onTap: () {
                    // TODO: Navigate to privacy policy
                  },
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Warunki korzystania',
                  onTap: () {
                    // TODO: Navigate to terms of service
                  },
                ),
              ],
            ),

            SizedBox(height: AppSpacing.space4),

            // App version
            Center(
              child: Text(
                'Wersja 1.0.0',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),

            SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Wylogować się?'),
        content: Text(
          'Czy na pewno chcesz się wylogować?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nie'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Wyloguj',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform logout
  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.logout();

      if (context.mounted) {
        // Navigate to welcome screen
        context.go(Routes.welcome);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Błąd podczas wylogowania: ${e.toString()}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Build section header with items
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.paddingMD,
            bottom: AppSpacing.space2,
          ),
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  /// Build menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = AppColors.gray900,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.gray200),
        borderRadius: AppRadius.radiusMD,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(color: titleColor),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.gray500,
        ),
        onTap: onTap,
      ),
    );
  }
}
