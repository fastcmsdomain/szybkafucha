import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import 'api_provider.dart';

/// Credit transaction model
class CreditTransaction {
  final String id;
  final String userId;
  final double amount;
  final String type; // topup, deduction, refund, bonus
  final String? taskId;
  final String description;
  final DateTime createdAt;

  const CreditTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.taskId,
    required this.description,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] is String)
          ? double.parse(json['amount'] as String)
          : (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      taskId: json['taskId'] as String?,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;
}

/// State for credits/wallet
class CreditsState {
  final double balance;
  final bool isLoading;
  final bool isTopUpLoading;
  final List<CreditTransaction> transactions;
  final int totalTransactions;
  final String? error;

  const CreditsState({
    this.balance = 0,
    this.isLoading = false,
    this.isTopUpLoading = false,
    this.transactions = const [],
    this.totalTransactions = 0,
    this.error,
  });

  CreditsState copyWith({
    double? balance,
    bool? isLoading,
    bool? isTopUpLoading,
    List<CreditTransaction>? transactions,
    int? totalTransactions,
    String? error,
    bool clearError = false,
  }) {
    return CreditsState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      isTopUpLoading: isTopUpLoading ?? this.isTopUpLoading,
      transactions: transactions ?? this.transactions,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Credits provider for balance, top-up, and transaction history
final creditsProvider =
    StateNotifierProvider<CreditsNotifier, CreditsState>((ref) {
  return CreditsNotifier(ref);
});

class CreditsNotifier extends StateNotifier<CreditsState> {
  final Ref _ref;

  CreditsNotifier(this._ref) : super(const CreditsState());

  /// Fetch current credit balance
  Future<void> fetchBalance() async {
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get('/payments/credits/balance');
      final data = response as Map<String, dynamic>;

      final credits = (data['credits'] is String)
          ? double.parse(data['credits'] as String)
          : (data['credits'] as num).toDouble();

      state = state.copyWith(balance: credits, clearError: true);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  /// Fetch credit transaction history
  Future<void> fetchTransactions({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api
          .get('/payments/credits/transactions?page=$page&limit=$limit');
      final data = response as Map<String, dynamic>;

      final txList = (data['transactions'] as List)
          .map((json) =>
              CreditTransaction.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        transactions: txList,
        totalTransactions: data['total'] as int? ?? 0,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Initiate credit top-up via Stripe
  /// Returns clientSecret for Stripe payment sheet, or null in mock mode
  Future<Map<String, dynamic>?> initiateTopUp(double amount) async {
    state = state.copyWith(isTopUpLoading: true, clearError: true);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post('/payments/credits/topup', data: {
        'amount': amount,
      });
      final data = response as Map<String, dynamic>;

      // In mock mode, credits are added immediately
      final clientSecret = data['clientSecret'] as String;
      if (clientSecret.startsWith('mock_')) {
        // Mock mode — credits already added on backend
        await fetchBalance();
        await fetchTransactions();
        state = state.copyWith(isTopUpLoading: false);
        return null; // No Stripe sheet needed
      }

      state = state.copyWith(isTopUpLoading: false);
      return data;
    } on ApiException catch (e) {
      state = state.copyWith(isTopUpLoading: false, error: e.message);
      return null;
    }
  }

  /// Confirm top-up after Stripe payment
  Future<void> confirmTopUp(String paymentIntentId) async {
    state = state.copyWith(isTopUpLoading: true, clearError: true);
    try {
      final api = _ref.read(apiClientProvider);
      final response =
          await api.post('/payments/credits/topup/confirm', data: {
        'paymentIntentId': paymentIntentId,
      });
      final data = response as Map<String, dynamic>;

      final credits = (data['credits'] is String)
          ? double.parse(data['credits'] as String)
          : (data['credits'] as num).toDouble();

      state = state.copyWith(
        isTopUpLoading: false,
        balance: credits,
      );
      await fetchTransactions();
    } on ApiException catch (e) {
      state = state.copyWith(isTopUpLoading: false, error: e.message);
    }
  }

  /// Check if user has sufficient balance for matching
  bool hasSufficientBalance(double requiredAmount) {
    return state.balance >= requiredAmount;
  }
}
