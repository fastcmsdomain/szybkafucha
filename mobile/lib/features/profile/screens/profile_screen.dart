import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Profile screen showing user info and settings
/// Used for both client and contractor profiles
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.profile,
          style: AppTypography.h4,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User avatar and name
            _buildUserHeader(user),

            SizedBox(height: AppSpacing.space8),

            // Account section
            _buildSection(
              title: 'Konto',
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Edytuj profil',
                  onTap: () {
                    if (user?.isContractor == true) {
                      context.push(Routes.contractorProfileEdit);
                    } else {
                      context.push(Routes.clientProfileEdit);
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.reviews_outlined,
                  title: 'Opinie',
                  onTap: () {
                    if (user?.isContractor == true) {
                      context.push(Routes.contractorReviews);
                    } else {
                      context.push(Routes.clientReviews);
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: AppStrings.notifications,
                  onTap: () => context.push(Routes.notifications),
                ),
                _buildMenuItem(
                  icon: Icons.security_outlined,
                  title: 'Bezpieczeństwo',
                  onTap: () {
                    // TODO: Navigate to security settings
                    _showComingSoon(context, 'Bezpieczeństwo');
                  },
                ),
              ],
            ),

            SizedBox(height: AppSpacing.space4),

            // Preferences section
            _buildSection(
              title: 'Preferencje',
              children: [
                _buildMenuItem(
                  icon: Icons.language_outlined,
                  title: 'Język',
                  subtitle: 'Polski',
                  onTap: () {
                    // TODO: Language selection
                    _showComingSoon(context, 'Wybór języka');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tryb ciemny',
                  subtitle: 'Wyłączony',
                  onTap: () {
                    // TODO: Dark mode toggle
                    _showComingSoon(context, 'Tryb ciemny');
                  },
                ),
              ],
            ),

            SizedBox(height: AppSpacing.space4),

            // Support section
            _buildSection(
              title: 'Wsparcie',
              children: [
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Pomoc',
                  onTap: () {
                    // TODO: Navigate to help
                    _showComingSoon(context, 'Pomoc');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Regulamin',
                  onTap: () {
                    // TODO: Navigate to terms
                    _showComingSoon(context, 'Regulamin');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Polityka prywatności',
                  onTap: () {
                    // TODO: Navigate to privacy
                    _showComingSoon(context, 'Polityka prywatności');
                  },
                ),
              ],
            ),

            SizedBox(height: AppSpacing.space8),

            // Logout button
            _buildLogoutButton(context, ref),

            SizedBox(height: AppSpacing.space4),

            // Delete account link
            Center(
              child: TextButton(
                onPressed: () => _showDeleteAccountDialog(context, ref),
                child: Text(
                  'Usuń konto',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.space4),

            // App version
            Center(
              child: Text(
                'Wersja 1.0.0',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(User? user) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.gray200,
            shape: BoxShape.circle,
            image: user?.avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(user!.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user?.avatarUrl == null
              ? Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.gray400,
                )
              : null,
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Name
        Text(
          user?.name ?? 'Użytkownik',
          style: AppTypography.h4,
        ),

        SizedBox(height: AppSpacing.gapXS),

        // Email or phone
        Text(
          user?.email ?? user?.phone ?? '',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.gray600,
          ),
        ),

        SizedBox(height: AppSpacing.gapSM),

        // User type badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingSM,
            vertical: AppSpacing.paddingXS,
          ),
          decoration: BoxDecoration(
            color: user?.isContractor == true
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusSM,
          ),
          child: Text(
            user?.isContractor == true ? 'Wykonawca' : 'Klient',
            style: AppTypography.caption.copyWith(
              color: user?.isContractor == true
                  ? AppColors.primary
                  : AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.gray500,
          ),
        ),
        SizedBox(height: AppSpacing.gapSM),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.radiusMD,
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.gray600,
              size: 24,
            ),
            SizedBox(width: AppSpacing.gapMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showLogoutDialog(context, ref),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
      ),
      icon: const Icon(Icons.logout),
      label: Text(
        AppStrings.logout,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.logout),
        content: const Text('Czy na pewno chcesz się wylogować?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.gray600),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              // Router will automatically redirect to welcome
            },
            child: Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń konto'),
        content: const Text(
          'Czy na pewno chcesz usunąć swoje konto? Ta operacja jest nieodwracalna i wszystkie Twoje dane zostaną trwale usunięte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.gray600),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                // Router will automatically redirect to welcome
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Błąd: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Usuń',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - wkrótce dostępne'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}
