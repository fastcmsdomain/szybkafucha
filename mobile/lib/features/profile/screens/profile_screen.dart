import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
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
    final activeLanguageCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profile, style: AppTypography.h4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User avatar and name
            _buildUserHeader(context, user),

            SizedBox(height: AppSpacing.space8),

            // Account section
            _buildSection(
              title: context.l10n.accountSection,
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: context.l10n.editProfile,
                  onTap: () {
                    if (user?.isContractor == true) {
                      context.push(Routes.contractorProfileEdit);
                    } else {
                      context.push(Routes.clientProfileEdit);
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.payments_outlined,
                  title: context.l10n.payments,
                  subtitle: context.l10n.paymentsCardsPayouts,
                  onTap: () {
                    if (user?.isContractor == true) {
                      context.push(Routes.contractorProfilePayments);
                    } else {
                      context.push(Routes.clientProfilePayments);
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.reviews_outlined,
                  title: context.l10n.reviews,
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
                  title: context.l10n.notifications,
                  onTap: () => context.push(Routes.notifications),
                ),
                _buildMenuItem(
                  icon: Icons.security_outlined,
                  title: context.l10n.security,
                  onTap: () {
                    // TODO: Navigate to security settings
                    _showComingSoon(context, context.l10n.security);
                  },
                ),
              ],
            ),

            SizedBox(height: AppSpacing.space4),

            // Preferences section
            _buildSection(
              title: context.l10n.preferences,
              children: [
                _buildMenuItem(
                  icon: Icons.language_outlined,
                  title: context.l10n.language,
                  subtitle: activeLanguageCode == 'uk'
                      ? context.l10n.languageUkrainian
                      : context.l10n.languagePolish,
                  onTap: () {
                    _showLanguageSelector(context, ref, activeLanguageCode);
                  },
                ),
                // MVP: Dark mode hidden - not needed for MVP
              ],
            ),

            SizedBox(height: AppSpacing.space4),

            // Support section
            _buildSection(
              title: context.l10n.support,
              children: [
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: context.l10n.help,
                  onTap: () {
                    if (user?.isContractor == true) {
                      context.push(Routes.contractorProfileHelp);
                    } else {
                      context.push(Routes.clientProfileHelp);
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: context.l10n.termsOfService,
                  onTap: () {
                    context.push(Routes.termsOfService);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: context.l10n.privacyPolicy,
                  onTap: () {
                    context.push(Routes.privacyPolicy);
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
                  context.l10n.deleteAccount,
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
                context.l10n.versionWithNumber,
                style: AppTypography.caption.copyWith(color: AppColors.gray400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User? user) {
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
              ? Icon(Icons.person, size: 50, color: AppColors.gray400)
              : null,
        ),

        SizedBox(height: AppSpacing.gapMD),

        // Name
        Text(user?.name ?? context.l10n.userFallback, style: AppTypography.h4),

        SizedBox(height: AppSpacing.gapXS),

        // Email or phone
        Text(
          user?.email ?? user?.phone ?? '',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray600),
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
            user?.isContractor == true
                ? context.l10n.contractorLabel
                : context.l10n.clientLabel,
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
          style: AppTypography.labelLarge.copyWith(color: AppColors.gray500),
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
            Icon(icon, color: AppColors.gray600, size: 24),
            SizedBox(width: AppSpacing.gapMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
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
            Icon(Icons.chevron_right, color: AppColors.gray400),
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      icon: const Icon(Icons.logout),
      label: Text(
        context.l10n.logout,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
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
              context.l10n.logout,
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
        title: Text(context.l10n.deleteAccount),
        content: Text(context.l10n.accountDeleteLongWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
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
                      content: Text(
                        context.l10n.genericErrorWithPrefix(e.toString()),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              context.l10n.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    String activeLanguageCode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(context.l10n.chooseLanguage)),
              RadioListTile<String>(
                value: 'pl',
                groupValue: activeLanguageCode,
                title: Text(context.l10n.languagePolish),
                onChanged: (value) {
                  if (value == null) return;
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('pl'));
                  Navigator.pop(sheetContext);
                },
              ),
              RadioListTile<String>(
                value: 'uk',
                groupValue: activeLanguageCode,
                title: Text(context.l10n.languageUkrainian),
                onChanged: (value) {
                  if (value == null) return;
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('uk'));
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.comingSoon(feature)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}
