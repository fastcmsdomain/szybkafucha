import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isSubmitting = false;

  Future<void> _selectRole(String role) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authProvider.notifier).selectInitialRole(role);
      // Router redirect handles navigation after state update.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_isSubmitting) return;
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.space8),
                Text(
                  'Wybierz jak chcesz korzystać z aplikacji',
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.gapSM),
                Text(
                  'Ten wybór jest wymagany przy pierwszym logowaniu.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space8),
                _RoleOptionCard(
                  icon: Icons.search,
                  title: 'Chcę zlecać',
                  subtitle: 'Szukam wykonawców i zlecam zadania.',
                  onTap: _isSubmitting ? null : () => _selectRole('client'),
                ),
                SizedBox(height: AppSpacing.gapMD),
                _RoleOptionCard(
                  icon: Icons.handyman,
                  title: 'Chcę wykonywać zlecenia',
                  subtitle: 'Przyjmuję zlecenia i realizuję usługi.',
                  onTap: _isSubmitting ? null : () => _selectRole('contractor'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isSubmitting ? null : _logout,
                  child: const Text('Wyloguj'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _RoleOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusLG,
      child: Ink(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: AppColors.gray300),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            SizedBox(width: AppSpacing.gapMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapXS),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.gray500),
          ],
        ),
      ),
    );
  }
}
