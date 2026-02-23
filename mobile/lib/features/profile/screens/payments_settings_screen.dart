import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/kyc_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';

class PaymentsSettingsScreen extends ConsumerStatefulWidget {
  const PaymentsSettingsScreen({super.key});

  @override
  ConsumerState<PaymentsSettingsScreen> createState() =>
      _PaymentsSettingsScreenState();
}

class _PaymentsSettingsScreenState extends ConsumerState<PaymentsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user?.isContractor == true) {
        ref.read(kycProvider.notifier).fetchStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isContractor = user?.isContractor == true;
    final kycState = ref.watch(kycProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Wróć',
        ),
        title: SFRainbowText('Płatności'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Metody płatności',
              children: [
                _buildMenuItem(
                  icon: Icons.credit_card,
                  title: 'Karty',
                  subtitle: 'Dodaj, usuń lub zmień kartę',
                  onTap: () => _showComingSoon(
                    context,
                    'Zarządzanie kartami',
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.space4),
            _buildSection(
              title: 'Wypłaty',
              children: [
                _buildMenuItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Numer konta do wypłat',
                  subtitle: isContractor
                      ? (kycState.bankVerified
                          ? 'Konto zweryfikowane'
                          : 'Wymaga weryfikacji (KYC)')
                      : 'Dostępne tylko dla wykonawców',
                  onTap: () {
                    if (!isContractor) {
                      _showInfo(context, 'Ta opcja jest dostępna tylko dla wykonawców.');
                      return;
                    }
                    context.push(Routes.contractorKyc);
                  },
                ),
                if (isContractor) ...[
                  _buildMenuItem(
                    icon: Icons.payments_outlined,
                    title: 'Wypłaty i saldo',
                    subtitle: 'Sprawdź saldo i wypłać środki',
                    onTap: () => context.push(Routes.contractorEarnings),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.info,
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

