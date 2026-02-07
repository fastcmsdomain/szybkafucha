import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exceptions.dart';
import 'api_provider.dart';
import 'auth_provider.dart';
import 'storage_provider.dart';

/// Contractor availability state
class ContractorAvailabilityState {
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const ContractorAvailabilityState({
    this.isOnline = false,
    this.isLoading = false,
    this.error,
  });

  ContractorAvailabilityState copyWith({
    bool? isOnline,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ContractorAvailabilityState(
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing contractor availability status
class ContractorAvailabilityNotifier
    extends StateNotifier<ContractorAvailabilityState> {
  final Ref _ref;

  ContractorAvailabilityNotifier(this._ref)
      : super(const ContractorAvailabilityState()) {
    _initialize();
  }

  /// Initialize availability status from local storage and sync with backend
  Future<void> _initialize() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated ||
        !(authState.user?.userTypes.contains('contractor') ?? false)) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // First load from local storage for instant UI
      final storage = _ref.read(secureStorageProvider);
      final localStatus = await storage.getContractorOnlineStatus();
      state = state.copyWith(isOnline: localStatus);

      // Then sync with backend
      await _syncWithBackend();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Sync availability status with backend
  Future<void> _syncWithBackend() async {
    try {
      final api = _ref.read(apiClientProvider);
      final response =
          await api.get<Map<String, dynamic>>('/contractor/profile');

      final isOnline = response['isOnline'] as bool? ?? false;

      // Update local storage
      final storage = _ref.read(secureStorageProvider);
      await storage.saveContractorOnlineStatus(isOnline);

      state = state.copyWith(
        isOnline: isOnline,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      // Keep local status if backend sync fails
      state = state.copyWith(isLoading: false);
    }
  }

  /// Toggle availability status
  Future<void> toggleAvailability(bool value) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final api = _ref.read(apiClientProvider);
      await api.put<Map<String, dynamic>>(
        '/contractor/availability',
        data: {'isOnline': value},
      );

      // Update local storage
      final storage = _ref.read(secureStorageProvider);
      await storage.saveContractorOnlineStatus(value);

      state = state.copyWith(
        isOnline: value,
        isLoading: false,
      );
    } on ApiException catch (e) {
      // Translate KYC error to Polish
      String errorMessage = e.message;
      if (e.message.contains('KYC') ||
          e.message.contains('verification')) {
        errorMessage =
            'Aby przejść w tryb online, musisz najpierw ukończyć weryfikację tożsamości (KYC).';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Nie udało się zmienić statusu dostępności',
      );
      rethrow;
    }
  }

  /// Set availability to offline (used during logout)
  Future<void> setOffline() async {
    if (!state.isOnline) return;

    try {
      final api = _ref.read(apiClientProvider);
      await api.put<Map<String, dynamic>>(
        '/contractor/availability',
        data: {'isOnline': false},
      );
    } catch (_) {
      // Ignore errors during logout
    }

    final storage = _ref.read(secureStorageProvider);
    await storage.saveContractorOnlineStatus(false);

    state = const ContractorAvailabilityState(isOnline: false);
  }

  /// Reset state (used during logout)
  void reset() {
    state = const ContractorAvailabilityState();
  }

  /// Refresh status from backend
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _syncWithBackend();
  }
}

/// Provider for contractor availability
final contractorAvailabilityProvider = StateNotifierProvider<
    ContractorAvailabilityNotifier, ContractorAvailabilityState>((ref) {
  return ContractorAvailabilityNotifier(ref);
});

/// Convenience provider for checking if contractor is online
final isContractorOnlineProvider = Provider<bool>((ref) {
  return ref.watch(contractorAvailabilityProvider).isOnline;
});
