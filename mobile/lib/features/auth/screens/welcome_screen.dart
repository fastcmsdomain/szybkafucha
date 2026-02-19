import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../widgets/social_login_button.dart';

/// Welcome screen - first screen users see
/// Provides options for login (Google, Apple, Phone) or signup
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;
  String? _loadingProvider; // 'google', 'apple', or null

  /// Returns the role chosen during onboarding, defaulting to 'client'
  String get _userType =>
      ref.read(authProvider).selectedRole ?? 'client';

  @override
  Widget build(BuildContext context) {
    // Check if Apple Sign-In is available
    final appleAvailable = ref.watch(appleSignInAvailableProvider);
    final selectedRole = ref.watch(authProvider).selectedRole ?? 'client';
    final isProfileMode =
        GoRouterState.of(context).uri.queryParameters['tab'] == 'profile';

    return Scaffold(
      bottomNavigationBar: _buildBottomNavigation(isProfileMode),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingLG),
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

                if (!isProfileMode) ...[
                  // Logo and branding
                  _buildLogo(),
                  SizedBox(height: AppSpacing.space8),

                  // Headline
                  Text(
                    AppStrings.welcomeTitle,
                    style: AppTypography.h4,
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
                  SizedBox(height: AppSpacing.space8),
                ],
                if (isProfileMode) ...[
                  Center(
                    child: SFRainbowText(
                      AppStrings.login,
                      style: AppTypography.h2,
                    ),
                  ),
                  SizedBox(height: AppSpacing.space8),
                ],

                // Role selector
                _buildRoleSelector(selectedRole),
                SizedBox(height: AppSpacing.gapMD),

                // Google login button
                SocialLoginButton(
                  type: SocialLoginType.google,
                  isLoading: _loadingProvider == 'google',
                  onPressed: _isLoading ? null : () => _handleGoogleSignIn(),
                ),

                SizedBox(height: AppSpacing.gapMD),

                // Apple login button (only if available)
                appleAvailable.when(
                  data: (isAvailable) => isAvailable
                      ? Column(
                          children: [
                            SocialLoginButton(
                              type: SocialLoginType.apple,
                              isLoading: _loadingProvider == 'apple',
                              onPressed: _isLoading ? null : () => _handleAppleSignIn(),
                            ),
                            SizedBox(height: AppSpacing.gapMD),
                          ],
                        )
                      : const SizedBox.shrink(),
                  loading: () => Column(
                    children: [
                      SocialLoginButton(
                        type: SocialLoginType.apple,
                        isLoading: true,
                      ),
                      SizedBox(height: AppSpacing.gapMD),
                    ],
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // Divider with "or"
                _buildDivider(),

                SizedBox(height: AppSpacing.gapMD),

                // Phone login button
                SocialLoginButton(
                  type: SocialLoginType.phone,
                  onPressed: _isLoading
                      ? null
                      : () {
                          context.push(
                            Routes.phoneLogin,
                            extra: _userType,
                          );
                        },
                ),

                SizedBox(height: AppSpacing.gapMD),

                // Email login button
                SocialLoginButton(
                  type: SocialLoginType.email,
                  onPressed: _isLoading
                      ? null
                      : () {
                          context.push(Routes.emailLogin);
                        },
                ),

                SizedBox(height: AppSpacing.space4),

                // Terms agreement
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Dołączając, akceptujesz ',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(Routes.termsOfService),
                        child: Text(
                          'Regulamin',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        ' i ',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(Routes.privacyPolicy),
                        child: Text(
                          'Politykę Prywatności',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.space4),

                // Dev mode quick login buttons
                if (ApiConfig.devModeEnabled) ...[
                  SizedBox(height: AppSpacing.space8),
                  _buildDevModeSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _loadingProvider = 'google';
    });

    try {
      final googleService = ref.read(googleSignInServiceProvider);
      final result = await googleService.signIn();

      if (!mounted) return;

      if (result.isCancelled) {
        // User cancelled - just reset state
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
        return;
      }

      if (!result.isSuccess || result.email == null) {
        _showError(result.error ?? 'Błąd logowania przez Google');
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
        return;
      }

      // Send user info to backend for authentication
      // Using email as googleId since it's unique per Google account
      await ref.read(authProvider.notifier).loginWithGoogle(
            googleId: result.email!,
            email: result.email!,
            name: result.displayName,
            avatarUrl: result.photoUrl,
            userType: _userType,
          );

      // Router will automatically redirect to appropriate home screen
    } catch (e) {
      if (mounted) {
        _showError('Błąd logowania: ${e.toString()}');
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _loadingProvider = 'apple';
    });

    try {
      final appleService = ref.read(appleSignInServiceProvider);
      final result = await appleService.signIn();

      if (!mounted) return;

      if (result.isCancelled) {
        // User cancelled - just reset state
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
        return;
      }

      if (!result.isSuccess || result.userIdentifier == null) {
        _showError(result.error ?? 'Błąd logowania przez Apple');
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
        return;
      }

      // Send user info to backend for authentication
      await ref.read(authProvider.notifier).loginWithApple(
            appleId: result.userIdentifier!,
            email: result.email,
            name: result.fullName,
            userType: _userType,
          );

      // Router will automatically redirect to appropriate home screen
    } catch (e) {
      if (mounted) {
        _showError('Błąd logowania: ${e.toString()}');
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
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

  Widget _buildBottomNavigation(bool isProfileMode) {
    return NavigationBar(
      selectedIndex: isProfileMode ? 2 : 0,
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go(Routes.publicHome);
        } else if (index == 1) {
          context.go(Routes.browse);
        } else if (index == 2) {
          context.go('${Routes.welcome}?tab=profile');
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

  Widget _buildRoleSelector(String selectedRole) {
    return Row(
      children: [
        Expanded(
          child: _WelcomeRoleBox(
            selected: selectedRole == 'client',
            icon: Icons.manage_search_outlined,
            title: 'Pracodawca',
            subtitle: 'Szukam pomocy',
            onTap: () =>
                ref.read(authProvider.notifier).setSelectedRole('client'),
          ),
        ),
        SizedBox(width: AppSpacing.gapMD),
        Expanded(
          child: _WelcomeRoleBox(
            selected: selectedRole == 'contractor',
            icon: Icons.handyman_outlined,
            title: 'Wykonawca',
            subtitle: 'Chcę pomagać',
            onTap: () =>
                ref.read(authProvider.notifier).setSelectedRole('contractor'),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.gray300,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
          child: Text(
            AppStrings.orContinueWith,
            style: AppTypography.caption.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.gray300,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDevModeSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.developer_mode,
                color: AppColors.warning,
                size: 20,
              ),
              SizedBox(width: AppSpacing.gapSM),
              Text(
                'Tryb deweloperski',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Zaloguj się bez backendu aby testować UI',
            style: AppTypography.caption.copyWith(
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: AppSpacing.gapMD),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _handleDevLogin(isClient: true),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Klient'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.paddingSM,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.gapMD),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _handleDevLogin(isClient: false),
                  icon: const Icon(Icons.build_outlined, size: 18),
                  label: const Text('Wykonawca'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.paddingSM,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapMD),
          // Reset onboarding button
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).resetOnboarding();
              if (mounted) {
                context.go(Routes.onboarding);
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('🔄 Reset Onboarding'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: BorderSide(color: AppColors.info),
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.paddingSM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDevLogin({required bool isClient}) async {

    setState(() {
      _isLoading = true;
      _loadingProvider = isClient ? 'dev-client' : 'dev-contractor';
    });

    try {
      if (isClient) {
        await ref.read(authProvider.notifier).devLoginAsClient();
      } else {
        await ref.read(authProvider.notifier).devLoginAsContractor();
      }
      // Router will automatically redirect to appropriate home screen
    } catch (e) {
      if (mounted) {
        _showError('Błąd logowania: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }
}

class _WelcomeRoleBox extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WelcomeRoleBox({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.paddingLG,
          horizontal: AppSpacing.paddingMD,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.gray100,
          borderRadius: AppRadius.radiusMD,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? AppColors.white : AppColors.gray700,
            ),
            const SizedBox(height: AppSpacing.gapSM),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? AppColors.white : AppColors.gray700,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: selected
                    ? AppColors.white.withValues(alpha: 0.85)
                    : AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
