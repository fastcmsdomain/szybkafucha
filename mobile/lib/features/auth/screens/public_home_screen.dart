import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Public home screen for non-authenticated users.
/// Dedicated landing for the "Główna" tab.
class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  static const String _profileLoginRoute = '${Routes.welcome}?tab=profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavigation(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.paddingLG),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.space12),
                _buildLogo(),
                SizedBox(height: AppSpacing.space8),
                Text(
                  AppStrings.welcomeTitle,
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space3),
                Text(
                  AppStrings.welcomeSubtitle,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space12),
                FilledButton.icon(
                  onPressed: () => context.go(Routes.browse),
                  icon: const Icon(Icons.work_outline),
                  label: Text(
                    AppStrings.menuTasks,
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.gapMD),
                OutlinedButton.icon(
                  onPressed: () => context.go(_profileLoginRoute),
                  icon: const Icon(Icons.person_outline),
                  label: Text(
                    AppStrings.login,
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMD,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.space6),
                _buildLegalConsent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: AppRadius.radiusMD,
          child: Image.asset(
            'assets/images/szybkafucha_logo_1024.png',
            height: 56,
            width: 56,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: AppSpacing.gapMD),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Szybka',
                style: AppTypography.h3,
              ),
              TextSpan(
                text: 'Fucha',
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          context.go(Routes.browse);
        } else if (index == 2) {
          context.go(_profileLoginRoute);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: AppStrings.menuHome,
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: AppStrings.menuTasks,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: AppStrings.menuProfile,
        ),
      ],
    );
  }

  Widget _buildLegalConsent(BuildContext context) {
    final baseStyle = AppTypography.caption.copyWith(
      color: AppColors.gray500,
    );
    final linkStyle = AppTypography.caption.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Dołączając, akceptując ',
            style: baseStyle,
            textAlign: TextAlign.center,
          ),
          GestureDetector(
            onTap: () => context.push(Routes.termsOfService),
            child: Text('Regulamin', style: linkStyle),
          ),
          Text(' i ', style: baseStyle),
          GestureDetector(
            onTap: () => context.push(Routes.privacyPolicy),
            child: Text('Politykę Prywatności', style: linkStyle),
          ),
          Text('.', style: baseStyle),
        ],
      ),
    );
  }
}
