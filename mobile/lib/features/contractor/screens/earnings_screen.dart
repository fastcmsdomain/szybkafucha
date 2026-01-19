import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../models/earnings.dart';

/// Earnings screen for contractors - view earnings summary and transaction history
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd MMM yyyy', 'pl_PL');
  final _timeFormat = DateFormat('HH:mm', 'pl_PL');

  // Mock data - in production this would come from providers
  late EarningsSummary _summary;
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _summary = EarningsSummary.mock();
    _transactions = Transaction.mockList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Zarobki',
          style: AppTypography.h4,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showEarningsInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Earnings summary card
          _buildSummaryCard(),

          // Tab bar
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.gray500,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Wszystko'),
                Tab(text: 'Przychody'),
                Tab(text: 'Wypłaty'),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(null),
                _buildTransactionList(TransactionType.earning),
                _buildTransactionList(TransactionType.withdrawal),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildWithdrawButton(),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.paddingMD),
      padding: EdgeInsets.all(AppSpacing.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusXL,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Dziś',
                '${_summary.todayEarnings.toStringAsFixed(0)} zł',
                Icons.today,
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.white.withValues(alpha: 0.2),
              ),
              _buildSummaryItem(
                'Ten tydzień',
                '${_summary.weekEarnings.toStringAsFixed(0)} zł',
                Icons.date_range,
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.white.withValues(alpha: 0.2),
              ),
              _buildSummaryItem(
                'Ten miesiąc',
                '${_summary.monthEarnings.toStringAsFixed(0)} zł',
                Icons.calendar_month,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapLG),
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dostępne do wypłaty',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_summary.availableBalance.toStringAsFixed(2)} zł',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Oczekujące',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${_summary.pendingPayout.toStringAsFixed(0)} zł',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.white.withValues(alpha: 0.7),
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(TransactionType? filterType) {
    final filtered = filterType == null
        ? _transactions
        : _transactions.where((t) => t.type == filterType).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.gray300,
            ),
            SizedBox(height: AppSpacing.gapMD),
            Text(
              'Brak transakcji',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final transaction in filtered) {
      final dateKey = _dateFormat.format(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []);
      groupedTransactions[dateKey]!.add(transaction);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingMD),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingSM),
              child: Text(
                dateKey,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
            ...transactions.map((t) => _buildTransactionTile(t)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isEarning = transaction.type == TransactionType.earning;
    final isWithdrawal = transaction.type == TransactionType.withdrawal;
    final isRefund = transaction.type == TransactionType.refund;

    IconData icon;
    Color iconColor;
    Color amountColor;
    String prefix;

    if (isEarning) {
      icon = Icons.add_circle_outline;
      iconColor = AppColors.success;
      amountColor = AppColors.success;
      prefix = '+';
    } else if (isWithdrawal) {
      icon = Icons.account_balance_wallet_outlined;
      iconColor = AppColors.primary;
      amountColor = AppColors.gray700;
      prefix = '-';
    } else if (isRefund) {
      icon = Icons.replay;
      iconColor = AppColors.warning;
      amountColor = AppColors.warning;
      prefix = '';
    } else {
      icon = Icons.swap_horiz;
      iconColor = AppColors.gray500;
      amountColor = AppColors.gray700;
      prefix = '';
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.gapSM),
      padding: EdgeInsets.all(AppSpacing.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.paddingSM),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusMD,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: AppSpacing.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTypography.labelMedium,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _timeFormat.format(transaction.date),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray400,
                      ),
                    ),
                    if (transaction.status == TransactionStatus.pending) ...[
                      SizedBox(width: AppSpacing.gapSM),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusSM,
                        ),
                        child: Text(
                          'Oczekuje',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$prefix${transaction.amount.toStringAsFixed(2)} zł',
            style: AppTypography.labelLarge.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton() {
    final canWithdraw = _summary.availableBalance >= 50;

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
            if (!canWithdraw)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.gapSM),
                child: Text(
                  'Minimalna kwota wypłaty: 50 zł',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canWithdraw ? _showWithdrawDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMD,
                  ),
                  disabledBackgroundColor: AppColors.gray300,
                ),
                icon: const Icon(Icons.account_balance),
                label: Text(
                  'Wypłać ${_summary.availableBalance.toStringAsFixed(2)} zł',
                  style: const TextStyle(
                    fontSize: 16,
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

  void _showWithdrawDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _WithdrawBottomSheet(
        availableBalance: _summary.availableBalance,
        onWithdraw: _processWithdraw,
      ),
    );
  }

  Future<void> _processWithdraw(double amount) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zlecono wypłatę ${amount.toStringAsFixed(2)} zł'),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh data
      setState(() {
        _summary = EarningsSummary(
          todayEarnings: _summary.todayEarnings,
          weekEarnings: _summary.weekEarnings,
          monthEarnings: _summary.monthEarnings,
          totalEarnings: _summary.totalEarnings,
          pendingPayout: _summary.pendingPayout + amount,
          availableBalance: _summary.availableBalance - amount,
          completedTasks: _summary.completedTasks,
        );
      });
    }
  }

  void _showEarningsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O zarobkach'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.check_circle_outline,
              'Przychody',
              'Zarobki z ukończonych zleceń',
            ),
            SizedBox(height: AppSpacing.gapMD),
            _buildInfoRow(
              Icons.hourglass_empty,
              'Oczekujące',
              'Środki czekające na potwierdzenie klienta',
            ),
            SizedBox(height: AppSpacing.gapMD),
            _buildInfoRow(
              Icons.account_balance,
              'Wypłaty',
              'Przelewy na Twoje konto bankowe',
            ),
            SizedBox(height: AppSpacing.gapMD),
            _buildInfoRow(
              Icons.info_outline,
              'Prowizja',
              'Platforma pobiera 17% od każdego zlecenia',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rozumiem'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        SizedBox(width: AppSpacing.gapSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium,
              ),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WithdrawBottomSheet extends StatefulWidget {
  final double availableBalance;
  final Future<void> Function(double amount) onWithdraw;

  const _WithdrawBottomSheet({
    required this.availableBalance,
    required this.onWithdraw,
  });

  @override
  State<_WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<_WithdrawBottomSheet> {
  late TextEditingController _amountController;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.availableBalance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.paddingLG,
        right: AppSpacing.paddingLG,
        top: AppSpacing.paddingLG,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.paddingLG,
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
                borderRadius: AppRadius.radiusSM,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.gapLG),
          Text(
            'Wypłata środków',
            style: AppTypography.h4,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Text(
            'Środki zostaną przelane na Twoje konto bankowe w ciągu 1-3 dni roboczych.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
          ),
          SizedBox(height: AppSpacing.gapLG),
          Text(
            'Kwota wypłaty',
            style: AppTypography.labelMedium,
          ),
          SizedBox(height: AppSpacing.gapSM),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: 'zł',
              errorText: _error,
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: _validateAmount,
          ),
          SizedBox(height: AppSpacing.gapSM),
          Row(
            children: [
              Text(
                'Dostępne: ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _amountController.text =
                      widget.availableBalance.toStringAsFixed(2);
                  _validateAmount(_amountController.text);
                },
                child: Text(
                  '${widget.availableBalance.toStringAsFixed(2)} zł',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.gapXL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _error == null && !_isProcessing
                  ? _processWithdraw
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingMD),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMD,
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    )
                  : const Text(
                      'Potwierdź wypłatę',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: AppSpacing.gapMD),
        ],
      ),
    );
  }

  void _validateAmount(String value) {
    final amount = double.tryParse(value.replaceAll(',', '.'));

    setState(() {
      if (amount == null) {
        _error = 'Wprowadź poprawną kwotę';
      } else if (amount < 50) {
        _error = 'Minimalna kwota wypłaty to 50 zł';
      } else if (amount > widget.availableBalance) {
        _error = 'Nie masz wystarczających środków';
      } else {
        _error = null;
      }
    });
  }

  Future<void> _processWithdraw() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null) return;

    setState(() => _isProcessing = true);

    await widget.onWithdraw(amount);
  }
}
