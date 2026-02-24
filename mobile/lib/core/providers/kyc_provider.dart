import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import 'api_provider.dart';

/// State for KYC (Know Your Customer) identity verification
class KycState {
  final String overallStatus; // 'pending', 'verified', 'rejected'
  final bool idVerified;
  final bool selfieVerified;
  final bool bankVerified;
  final bool canAcceptTasks;
  final bool isLoading;
  final bool isPolling;
  final String? pollingStep; // 'document' or 'selfie'
  final String? error;

  const KycState({
    this.overallStatus = 'pending',
    this.idVerified = false,
    this.selfieVerified = false,
    this.bankVerified = false,
    this.canAcceptTasks = false,
    this.isLoading = false,
    this.isPolling = false,
    this.pollingStep,
    this.error,
  });

  bool get isBusy => isLoading || isPolling;

  KycState copyWith({
    String? overallStatus,
    bool? idVerified,
    bool? selfieVerified,
    bool? bankVerified,
    bool? canAcceptTasks,
    bool? isLoading,
    bool? isPolling,
    String? pollingStep,
    bool clearPollingStep = false,
    String? error,
    bool clearError = false,
  }) {
    return KycState(
      overallStatus: overallStatus ?? this.overallStatus,
      idVerified: idVerified ?? this.idVerified,
      selfieVerified: selfieVerified ?? this.selfieVerified,
      bankVerified: bankVerified ?? this.bankVerified,
      canAcceptTasks: canAcceptTasks ?? this.canAcceptTasks,
      isLoading: isLoading ?? this.isLoading,
      isPolling: isPolling ?? this.isPolling,
      pollingStep: clearPollingStep ? null : (pollingStep ?? this.pollingStep),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class KycNotifier extends StateNotifier<KycState> {
  KycNotifier(this._ref) : super(const KycState());

  final Ref _ref;
  bool _pollingActive = false;

  @override
  void dispose() {
    _pollingActive = false;
    super.dispose();
  }

  /// Fetch current KYC status from backend
  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = _ref.read(apiClientProvider);
      final data =
          await api.get<Map<String, dynamic>>('/contractor/kyc/status');
      state = _parseStatus(data).copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// Upload ID document (front + optional back) for verification
  Future<void> uploadIdDocument({
    required File frontFile,
    File? backFile,
    String documentType = 'national_identity_card',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = _ref.read(apiClientProvider);
      final frontBase64 = base64Encode(await frontFile.readAsBytes());
      String? backBase64;
      if (backFile != null) {
        backBase64 = base64Encode(await backFile.readAsBytes());
      }

      await api.post<Map<String, dynamic>>(
        '/contractor/kyc/id',
        data: {
          'documentType': documentType,
          'documentFront': frontBase64,
          if (backBase64 != null) 'documentBack': backBase64,
        },
      );

      state = state.copyWith(
        isLoading: false,
        isPolling: true,
        pollingStep: 'document',
        clearError: true,
      );
      _pollingActive = true;
      await _pollUntilVerified(
        field: 'idVerified',
        timeout: const Duration(seconds: 90),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPolling: false,
        clearPollingStep: true,
        error: _parseError(e),
      );
    }
  }

  /// Upload selfie for facial similarity verification
  Future<void> uploadSelfie(File selfieFile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = _ref.read(apiClientProvider);
      final selfieBase64 = base64Encode(await selfieFile.readAsBytes());

      await api.post<Map<String, dynamic>>(
        '/contractor/kyc/selfie',
        data: {'selfieImage': selfieBase64},
      );

      state = state.copyWith(
        isLoading: false,
        isPolling: true,
        pollingStep: 'selfie',
        clearError: true,
      );
      _pollingActive = true;
      await _pollUntilVerified(
        field: 'selfieVerified',
        timeout: const Duration(seconds: 90),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPolling: false,
        clearPollingStep: true,
        error: _parseError(e),
      );
    }
  }

  /// Verify Polish bank account (IBAN) for payouts
  Future<void> verifyBankAccount({
    required String iban,
    required String accountHolderName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = _ref.read(apiClientProvider);
      final cleanIban = iban.replaceAll(' ', '').toUpperCase();

      await api.post<Map<String, dynamic>>(
        '/contractor/kyc/bank',
        data: {
          'iban': cleanIban,
          'accountHolderName': accountHolderName,
        },
      );

      // Bank verification is synchronous — refresh status immediately
      await fetchStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// Poll GET /contractor/kyc/status until the given field becomes true or timeout
  Future<void> _pollUntilVerified({
    required String field,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (_pollingActive && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 3));
      if (!_pollingActive) break;

      try {
        final api = _ref.read(apiClientProvider);
        final data =
            await api.get<Map<String, dynamic>>('/contractor/kyc/status');
        final newState = _parseStatus(data);

        final isVerified = (field == 'idVerified' && newState.idVerified) ||
            (field == 'selfieVerified' && newState.selfieVerified);

        if (isVerified) {
          _pollingActive = false;
          state = newState.copyWith(isPolling: false, clearPollingStep: true);
          return;
        }

        if (newState.overallStatus == 'rejected') {
          _pollingActive = false;
          state = newState.copyWith(
            isPolling: false,
            clearPollingStep: true,
            error: 'Weryfikacja odrzucona. Skontaktuj się z nami.',
          );
          return;
        }

        // Keep polling – update visible state but preserve pollingStep
        state = newState.copyWith(
          isPolling: true,
          pollingStep: state.pollingStep,
        );
      } catch (_) {
        // Continue polling on transient network errors
      }
    }

    // Timeout reached
    if (_pollingActive) {
      _pollingActive = false;
      state = state.copyWith(
        isPolling: false,
        clearPollingStep: true,
        error: 'Weryfikacja trwa zbyt długo. Spróbuj ponownie.',
      );
    }
  }

  KycState _parseStatus(Map<String, dynamic> data) {
    return KycState(
      overallStatus: data['overallStatus'] as String? ?? 'pending',
      idVerified: data['idVerified'] as bool? ?? false,
      selfieVerified: data['selfieVerified'] as bool? ?? false,
      bankVerified: data['bankVerified'] as bool? ?? false,
      canAcceptTasks: data['canAcceptTasks'] as bool? ?? false,
    );
  }

  String _parseError(dynamic e) {
    if (e is ApiException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already verified')) {
        return 'Ten krok jest już zweryfikowany';
      }
      if (msg.contains('must be completed first')) {
        return 'Najpierw zweryfikuj dokument tożsamości';
      }
      if (msg.contains('only polish') || msg.contains('unsupported country')) {
        return 'Nieprawidłowy lub nieobsługiwany kod kraju IBAN';
      }
      if (msg.contains('invalid iban')) {
        return 'Nieprawidłowy numer IBAN';
      }
      if (msg.contains('contractor profile not found')) {
        return 'Profil wykonawcy nie istnieje. Dokończ rejestrację.';
      }
      return e.message;
    }
    return 'Wystąpił błąd. Spróbuj ponownie.';
  }
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref);
});
