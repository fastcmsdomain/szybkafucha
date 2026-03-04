import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/credits_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/sf_rainbow_text.dart';
import '../models/task_category.dart';
import 'contractor_selection_screen.dart';

/// Payment screen for task booking
class PaymentScreen extends ConsumerStatefulWidget {
  final PaymentData? paymentData;

  const PaymentScreen({
    super.key,
    this.paymentData,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'card';
  bool _saveCard = true;

  // Fixed matching fee per side
  static const double _matchingFee = 10.0;

  @override
  Widget build(BuildContext context) {
    if (widget.paymentData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Płatność')),
        body: const Center(child: Text('Brak danych płatności')),
      );
    }

    final taskData = widget.paymentData!.taskData;
    final contractor = widget.paymentData!.contractor;
    final categoryData = TaskCategoryData.fromCategory(taskData.category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Wróć',
        ),
        title: SFRainbowText('Podsumowanie'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Task summary card
            _buildTaskSummary(categoryData, taskData),
            SizedBox(height: AppSpacing.space4),

            // Contractor card
            _buildContractorCard(contractor),
            SizedBox(height: AppSpacing.space4),

            // Price breakdown
            _buildPriceBreakdown(contractor.proposedPrice ?? 0),
            SizedBox(height: AppSpacing.space4),

            // Payment method selection
            _buildPaymentMethodSection(),
            SizedBox(height: AppSpacing.space4),

            // Terms notice
            _buildTermsNotice(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTaskSummary(
      TaskCategoryData category, ContractorSelectionData taskData) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.paddingSM),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusMD,
                ),
                child: Icon(category.icon, color: category.color, size: 24),
              ),
              SizedBox(width: AppSpacing.gapMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.labelLarge,
                    ),
                    Text(
                      taskData.isImmediate ? 'Teraz' : 'Zaplanowane',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapMD),
          Text(
            taskData.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (taskData.address != null || taskData.useCurrentLocation) ...[
            SizedBox(height: AppSpacing.gapSM),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.gray500,
                ),
                SizedBox(width: AppSpacing.gapXS),
                Expanded(
                  child: Text(
                    taskData.useCurrentLocation
                        ? 'Moja lokalizacja'
                        : taskData.address!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractorCard(dynamic contractor) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gray200,
            child: Text(
              contractor.name[0].toUpperCase(),
              style: AppTypography.h4.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contractor.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (contractor.isVerified) ...[
                      SizedBox(width: AppSpacing.gapXS),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.warning),
                    SizedBox(width: AppSpacing.gapXS),
                    Text(
                      contractor.formattedRating,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${contractor.reviewCount} opinii',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(int price) {
    final credits = ref.watch(creditsProvider);
    final hasSufficientBalance = credits.balance >= _matchingFee;
    final balanceAfterPayment = credits.balance - _matchingFee;

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szczegóły płatności',
            style: AppTypography.labelLarge,
          ),
          SizedBox(height: AppSpacing.gapMD),

          // Credits balance
          _buildPriceRow(
            'Twoje saldo',
            '${credits.balance.toStringAsFixed(2)} zł',
            valueColor: hasSufficientBalance ? AppColors.success : AppColors.error,
          ),
          SizedBox(height: AppSpacing.gapSM),

          _buildPriceRow(
            'Opłata za pomocnika',
            '${_matchingFee.toStringAsFixed(2)} zł',
          ),
          SizedBox(height: AppSpacing.gapSM),

          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.gapSM),
            child: Divider(color: AppColors.gray200),
          ),

          _buildPriceRow(
            'Saldo po akceptacji',
            '${balanceAfterPayment.toStringAsFixed(2)} zł',
            isBold: true,
            valueColor: balanceAfterPayment >= 0 ? null : AppColors.error,
          ),

          SizedBox(height: AppSpacing.gapMD),

          // Insufficient balance warning
          if (!hasSufficientBalance) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusSM,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                  SizedBox(width: AppSpacing.gapSM),
                  Expanded(
                    child: Text(
                      'Niewystarczające środki. Potrzebujesz ${_matchingFee.toStringAsFixed(2)} zł.',
                      style: AppTypography.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.gapSM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(Routes.clientWallet),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Doładuj portfel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],

          // Info banner
          if (hasSufficientBalance)
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusSM,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  SizedBox(width: AppSpacing.gapSM),
                  Expanded(
                    child: Text(
                      'Opłata ${_matchingFee.toStringAsFixed(0)} zł zostanie pobrana z Twojego portfela. Wykonawca również płaci ${_matchingFee.toStringAsFixed(0)} zł.',
                      style: AppTypography.caption.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isSubtle = false, bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isSubtle
              ? AppTypography.bodySmall.copyWith(color: AppColors.gray500)
              : isBold
                  ? AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)
                  : AppTypography.bodySmall,
        ),
        Text(
          value,
          style: isBold
              ? AppTypography.h4.copyWith(color: valueColor ?? AppColors.primary)
              : isSubtle
                  ? AppTypography.bodySmall.copyWith(color: valueColor ?? AppColors.gray500)
                  : AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w500, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metoda płatności',
            style: AppTypography.labelLarge,
          ),
          SizedBox(height: AppSpacing.gapMD),

          // Card option
          _buildPaymentOption(
            'card',
            Icons.credit_card,
            'Karta płatnicza',
            'Visa, Mastercard, BLIK',
          ),

          SizedBox(height: AppSpacing.gapSM),

          // Google Pay option
          _buildPaymentOption(
            'gpay',
            Icons.g_mobiledata,
            'Google Pay',
            'Szybka płatność',
          ),

          SizedBox(height: AppSpacing.gapSM),

          // Apple Pay option
          _buildPaymentOption(
            'apple',
            Icons.apple,
            'Apple Pay',
            'Szybka płatność',
          ),

          SizedBox(height: AppSpacing.gapMD),

          // Save card checkbox
          Semantics(
            label: 'Zapamiętaj metodę płatności',
            button: true,
            child: GestureDetector(
              onTap: () => setState(() => _saveCard = !_saveCard),
              child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _saveCard ? AppColors.primary : AppColors.white,
                    borderRadius: AppRadius.radiusSM,
                    border: Border.all(
                      color: _saveCard ? AppColors.primary : AppColors.gray400,
                    ),
                  ),
                  child: _saveCard
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.white,
                        )
                      : null,
                ),
                SizedBox(width: AppSpacing.gapSM),
                Text(
                  'Zapamiętaj metodę płatności',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      String value, IconData icon, String title, String subtitle) {
    final isSelected = _selectedPaymentMethod == value;

    return Semantics(
      label: 'Wybierz metodę płatności: $title',
      button: true,
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        child: Container(
        padding: EdgeInsets.all(AppSpacing.paddingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.gray50,
          borderRadius: AppRadius.radiusMD,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.gray600,
              size: 24,
            ),
            SizedBox(width: AppSpacing.gapMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            _buildRadioIndicator(isSelected),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildRadioIndicator(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.gray400,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTermsNotice() {
    return Text(
      'Potwierdzając wybór, akceptujesz pobranie ${_matchingFee.toStringAsFixed(0)} zł z Twojego portfela zgodnie z Regulaminem Szybka Fucha.',
      style: AppTypography.caption.copyWith(
        color: AppColors.gray500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomBar() {
    final credits = ref.watch(creditsProvider);
    final hasSufficientBalance = credits.balance >= _matchingFee;

    return Container(
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing || !hasSufficientBalance ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.gray300,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                  ),
                ),
                child: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Text(
                        hasSufficientBalance
                            ? 'Potwierdź wybór (${_matchingFee.toStringAsFixed(0)} zł)'
                            : 'Niewystarczające środki',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Show success and navigate to tracking
        // For now, we'll create a mock task ID
        final mockTaskId = 'task_${DateTime.now().millisecondsSinceEpoch}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Płatność zakończona! Szukamy pomocnika...'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to task tracking, replacing the entire flow
        context.go(Routes.clientTaskTrack(mockTaskId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd płatności: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
