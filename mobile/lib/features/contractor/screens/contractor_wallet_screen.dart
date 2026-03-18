import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/credits_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ContractorWalletScreen extends ConsumerStatefulWidget {
  const ContractorWalletScreen({super.key});

  @override
  ConsumerState<ContractorWalletScreen> createState() =>
      _ContractorWalletScreenState();
}

class _ContractorWalletScreenState
    extends ConsumerState<ContractorWalletScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(creditsProvider.notifier).fetchBalance();
      ref.read(creditsProvider.notifier).fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(creditsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wroc',
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(creditsProvider.notifier).fetchBalance();
          await ref.read(creditsProvider.notifier).fetchTransactions();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.paddingMD),
          children: [
            _buildInfoBanner(),
            const SizedBox(height: AppSpacing.paddingMD),
            _buildBalanceCard(credits),
            const SizedBox(height: AppSpacing.paddingMD),
            _buildTopUpButton(credits),
            const SizedBox(height: AppSpacing.paddingLG),
            _buildTransactionsHeader(credits),
            const SizedBox(height: AppSpacing.paddingSM),
            if (credits.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (credits.transactions.isEmpty)
              _buildEmptyTransactions()
            else
              ...credits.transactions.map(_buildTransactionTile),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingSM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          SizedBox(width: AppSpacing.paddingSM),
          Expanded(
            child: Text(
              '10 zl zostanie pobrane z Twojego konta gdy klient Cie wybierze.',
              style: TextStyle(
                color: AppColors.gray700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(CreditsState credits) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Twoje saldo',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.gapSM),
          Text(
            '${credits.balance.toStringAsFixed(2)} zl',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (credits.balance < 10) ...[
            const SizedBox(height: AppSpacing.gapSM),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingSM,
                  vertical: AppSpacing.gapXS),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Niewystarczajace srodki na dopasowanie',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopUpButton(CreditsState credits) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: credits.isTopUpLoading ? null : () => _showTopUpSheet(),
        icon: credits.isTopUpLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Doładuj konto'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TopUpSheet(
        onTopUp: (amount) async {
          Navigator.pop(ctx);
          await ref.read(creditsProvider.notifier).initiateTopUp(amount);
        },
      ),
    );
  }

  Widget _buildTransactionsHeader(CreditsState credits) {
    return Row(
      children: [
        const Text(
          'Historia transakcji',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const Spacer(),
        Text(
          '${credits.totalTransactions}',
          style: const TextStyle(fontSize: 14, color: AppColors.gray500),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, size: 48, color: AppColors.gray300),
          SizedBox(height: AppSpacing.paddingSM),
          Text(
            'Brak transakcji',
            style: TextStyle(fontSize: 16, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(CreditTransaction tx) {
    final isCredit = tx.isCredit;
    final icon = switch (tx.type) {
      'topup' => Icons.add_circle,
      'deduction' => Icons.remove_circle,
      'refund' => Icons.replay,
      'bonus' => Icons.card_giftcard,
      _ => Icons.swap_horiz,
    };
    final color = isCredit ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gapSM),
      padding: const EdgeInsets.all(AppSpacing.paddingSM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.paddingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(tx.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${tx.amount.toStringAsFixed(2)} zl',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TopUpSheet extends StatefulWidget {
  final void Function(double amount) onTopUp;

  const _TopUpSheet({required this.onTopUp});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  double? _selectedAmount;
  final _customController = TextEditingController();

  static const _presets = [20.0, 50.0, 100.0];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingMD,
        AppSpacing.paddingMD,
        AppSpacing.paddingMD,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.paddingMD,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.paddingMD),
          const Text(
            'Doladuj konto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSpacing.gapXS),
          const Text(
            'Minimalna kwota: 20 zl',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.paddingMD),
          Row(
            children: _presets.map((amount) {
              final isSelected = _selectedAmount == amount;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedAmount = amount;
                      _customController.clear();
                    }),
                    child: Semantics(
                      label: '${amount.toInt()} zlotych',
                      button: true,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.gray300,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${amount.toInt()} zl',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.gray900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.paddingSM),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Inna kwota (min. 20 zl)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingSM,
                vertical: AppSpacing.paddingSM,
              ),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              setState(() {
                _selectedAmount = parsed;
              });
            },
          ),
          const SizedBox(height: AppSpacing.paddingMD),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedAmount != null && _selectedAmount! >= 20
                  ? () => widget.onTopUp(_selectedAmount!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedAmount != null && _selectedAmount! >= 20
                    ? 'Doladuj ${_selectedAmount!.toStringAsFixed(0)} zl'
                    : 'Wybierz kwote',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.paddingSM),
        ],
      ),
    );
  }
}
