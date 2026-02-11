import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_config.dart';
import '../services/google_sign_in_service.dart';
import '../storage/secure_storage.dart';
import 'api_provider.dart';
import 'notification_provider.dart';
import 'storage_provider.dart';

/// Authentication state
enum AuthStatus {
  /// App just started, checking for stored credentials
  initial,
  /// Checking stored token validity with backend
  loading,
  /// User is logged in
  authenticated,
  /// User is not logged in
  unauthenticated,
  /// Auth error occurred
  error,
}

/// User data model
class User {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final List<String> userTypes; // ['client'] or ['contractor'] or ['client', 'contractor']
  final String? avatarUrl;
  final bool isVerified;
  final String? address;
  final String? bio;

  const User({
    required this.id,
    this.email,
    this.name,
    this.phone,
    required this.userTypes,
    this.avatarUrl,
    this.isVerified = false,
    this.address,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Get raw avatar URL and convert to full URL if relative
    final rawAvatarUrl = (json['avatarUrl'] ?? json['avatar_url']) as String?;

    // Parse types array from backend (backend returns 'types' as string array or comma-separated)
    final types = json['types'];
    List<String> userTypes;
    if (types is List) {
      userTypes = types.map((e) => e.toString()).toList();
    } else if (types is String) {
      // Backend may return comma-separated string
      userTypes = types.split(',').map((e) => e.trim()).toList();
    } else {
      // Fallback to single type field for backward compatibility
      final singleType = (json['type'] ?? json['user_type']) as String?;
      userTypes = singleType != null ? [singleType] : ['client'];
    }

    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      userTypes: userTypes,
      // Convert relative avatar URL to full URL
      avatarUrl: ApiConfig.getFullMediaUrl(rawAvatarUrl),
      // Backend returns 'status', check if active
      isVerified: json['is_verified'] as bool? ??
                  (json['status'] == 'active'),
      address: json['address'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'types': userTypes,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
        'address': address,
        'bio': bio,
      };

  bool get isClient => userTypes.contains('client');
  bool get isContractor => userTypes.contains('contractor');
  bool get hasBothRoles => userTypes.length == 2;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    List<String>? userTypes,
    String? avatarUrl,
    bool? isVerified,
    String? address,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userTypes: userTypes ?? this.userTypes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      address: address ?? this.address,
      bio: bio ?? this.bio,
    );
  }
}

/// Auth state
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? error;
  final String activeRole; // 'client' or 'contractor' - current active role
  final bool onboardingComplete; // Track if user completed onboarding

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.refreshToken,
    this.error,
    this.activeRole = 'client', // Default to client
    this.onboardingComplete = false, // Default to not completed
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? refreshToken,
    String? error,
    String? activeRole,
    bool? onboardingComplete,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      error: clearError ? null : (error ?? this.error),
      activeRole: activeRole ?? this.activeRole,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.initial || status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final Ref _ref;

  AuthNotifier(this._storage, this._ref) : super(const AuthState()) {
    _initializeAuth();
  }

  /// Mock users for dev mode testing
  static const _mockClientUser = User(
    id: 'dev-client-001',
    email: 'client@test.pl',
    name: 'Jan Kowalski',
    phone: '+48123456789',
    userTypes: ['client'],
    isVerified: true,
  );

  static const _mockContractorUser = User(
    id: 'dev-contractor-001',
    email: 'contractor@test.pl',
    name: 'Anna Nowak',
    phone: '+48987654321',
    userTypes: ['contractor'],
    isVerified: true,
  );

  /// Login as mock client (dev mode only)
  Future<void> devLoginAsClient() async {
    if (!ApiConfig.devModeEnabled) return;
    await _devLogin(_mockClientUser);
  }

  /// Login as mock contractor (dev mode only)
  Future<void> devLoginAsContractor() async {
    if (!ApiConfig.devModeEnabled) return;
    await _devLogin(_mockContractorUser);
  }

  /// Internal dev login helper
  Future<void> _devLogin(User user) async {
    state = state.copyWith(status: AuthStatus.loading);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    const mockToken = 'dev-mock-token-12345';
    await _storage.saveToken(mockToken);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    await _storage.saveUserId(user.id);
    await _storage.saveUserType(user.userTypes.first);

    state = state.copyWith(
      status: AuthStatus.authenticated,
      token: mockToken,
      user: user,
    );
  }

  /// Initialize auth state from stored credentials
  /// If user has valid stored session, auto-login
  Future<void> _initializeAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Check for stored tokens and onboarding completion
      final token = await _storage.getToken();
      final refreshToken = await _storage.getRefreshToken();
      final onboardingComplete = await _storage.isOnboardingComplete();

      if (token == null) {
        // No stored credentials - user must login
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          onboardingComplete: onboardingComplete,
        );
        return;
      }

      // Set token on API client
      _ref.read(apiClientProvider).setAuthToken(token);

      // Try to load cached user data first (for faster startup)
      final cachedUserJson = await _storage.getUserData();
      User? cachedUser;
      if (cachedUserJson != null) {
        try {
          cachedUser = User.fromJson(jsonDecode(cachedUserJson));
        } catch (_) {
          // Invalid cached data, ignore
        }
      }

      // If we have cached user, show as authenticated immediately
      if (cachedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          refreshToken: refreshToken,
          user: cachedUser,
          onboardingComplete: onboardingComplete,
        );

        // In dev mode with mock token, skip server validation
        if (ApiConfig.devModeEnabled && token == 'dev-mock-token-12345') {
          return;
        }

        // Validate token and refresh user data in background
        _validateAndRefreshUser();
      } else {
        // No cached user, need to fetch from server
        await _validateAndRefreshUser();
      }
    } catch (e) {
      // Error during initialization, clear tokens and show unauthenticated
      await _clearAuthData();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Validate token and refresh user data from server
  Future<void> _validateAndRefreshUser() async {
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>('/users/me');
      final user = User.fromJson(response);

      // Cache user data
      await _storage.saveUserData(jsonEncode(user.toJson()));

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } catch (e) {
      // Token might be expired, try to refresh
      final refreshed = await _tryRefreshToken();
      if (!refreshed) {
        // Refresh failed, logout
        await _clearAuthData();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );
      }
    }
  }

  /// Try to refresh the access token using refresh token
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/auth/refresh',
        // Backend may use camelCase for request body
        data: {'refreshToken': refreshToken},
      );

      // Backend returns camelCase: accessToken, not access_token
      final newToken = response['accessToken'] as String;
      final newRefreshToken = response['refreshToken'] as String?;

      await _storage.saveToken(newToken);
      if (newRefreshToken != null) {
        await _storage.saveRefreshToken(newRefreshToken);
      }

      api.setAuthToken(newToken);

      state = state.copyWith(
        token: newToken,
        refreshToken: newRefreshToken ?? state.refreshToken,
      );

      // Now fetch user data
      await _validateAndRefreshUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear all auth data from storage
  Future<void> _clearAuthData() async {
    await _storage.deleteToken();
    await _storage.deleteRefreshToken();
    await _storage.deleteUserData();
    await _storage.deleteUserId();
    await _storage.deleteUserType();
    _ref.read(apiClientProvider).clearAuthToken();
  }

  /// Save auth tokens and user data after successful login
  Future<void> _saveAuthData({
    required String token,
    String? refreshToken,
    required User user,
  }) async {
    await _storage.saveToken(token);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _storage.saveUserData(jsonEncode(user.toJson()));
    await _storage.saveUserId(user.id);
    await _storage.saveUserType(user.userTypes.first);
    _ref.read(apiClientProvider).setAuthToken(token);
  }

  /// Login with email and password (for testing)
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // Backend returns camelCase: accessToken, not access_token
      final token = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      // DEBUG: Print JWT token for backend API testing
      debugPrint('=== JWT TOKEN FOR API TESTING ===');
      debugPrint('Token: $token');
      debugPrint('User: ${user.email}');
      debugPrint('=================================');

      await _saveAuthData(token: token, refreshToken: refreshToken, user: user);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        refreshToken: refreshToken,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Request phone OTP
  Future<void> requestPhoneOtp(String phone) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/auth/phone/request-otp',
        data: {'phone': phone},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Login with phone OTP
  /// If user exists but selected different role, backend will auto-switch role
  Future<void> verifyPhoneOtp({
    required String phone,
    required String otp,
    String userType = 'client',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/auth/phone/verify',
        // Backend expects 'code' field, not 'otp'
        data: {'phone': phone, 'code': otp, 'userType': userType},
      );

      // Backend returns camelCase: accessToken, not access_token
      final token = response['accessToken'] as String;
      // refresh_token is optional and may not be returned by backend
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _saveAuthData(token: token, refreshToken: refreshToken, user: user);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        refreshToken: refreshToken,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Login with Google
  /// Sends user info to backend for authentication
  /// If user exists but selected different role, backend will auto-switch role
  Future<void> loginWithGoogle({
    required String googleId,
    required String email,
    String? name,
    String? avatarUrl,
    String userType = 'client',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/auth/google',
        data: {
          'googleId': googleId,
          'email': email,
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          'userType': userType,
        },
      );

      final token = response['accessToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _saveAuthData(token: token, refreshToken: null, user: user);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Login with Apple
  /// Sends user info to backend for authentication
  /// If user exists but selected different role, backend will auto-switch role
  Future<void> loginWithApple({
    required String appleId,
    String? email,
    String? name,
    String userType = 'client',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/auth/apple',
        data: {
          'appleId': appleId,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          'userType': userType,
        },
      );

      final token = response['accessToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _saveAuthData(token: token, refreshToken: null, user: user);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Complete registration with user details
  Future<void> completeRegistration({
    required String name,
    required String userType,
  }) async {
    if (!state.isAuthenticated) return;

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.patch<Map<String, dynamic>>(
        '/users/me',
        data: {
          'name': name,
          'user_type': userType,
        },
      );

      final user = User.fromJson(response);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      await _storage.saveUserType(userType);

      state = state.copyWith(user: user);
    } catch (e) {
      rethrow;
    }
  }

  /// Switch user type (client to contractor or vice versa)
  /// User stays logged in, only the role changes
  Future<void> switchUserType(String newUserType) async {
    if (!state.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.patch<Map<String, dynamic>>(
        '/users/me/type',
        data: {'type': newUserType},
      );

      final user = User.fromJson(response);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      await _storage.saveUserType(newUserType);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } catch (e) {
      // Restore authenticated state on error
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    if (!state.isAuthenticated) return;

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.patch<Map<String, dynamic>>(
        '/users/me',
        data: {
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      );

      final user = User.fromJson(response);
      await _storage.saveUserData(jsonEncode(user.toJson()));

      state = state.copyWith(user: user);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>('/users/me');
      final user = User.fromJson(response);

      await _storage.saveUserData(jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
    } catch (_) {
      // Silently fail - user data will be refreshed on next successful request
    }
  }

  /// Add a role to the current user (client or contractor)
  /// Creates empty profile when role is added
  Future<void> addRole(String role) async {
    if (!state.isAuthenticated) return;

    try {
      final api = _ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/users/me/add-role',
        data: {'role': role},
      );

      // Refresh user data to get updated roles
      await refreshUser();
    } catch (e) {
      // Error adding role
      state = state.copyWith(
        error: 'Failed to add role: $e',
      );
      rethrow;
    }
  }

  /// Set the active role for the current session
  /// Only works if user has this role
  void setActiveRole(String role) {
    if (state.user?.userTypes.contains(role) == true) {
      state = state.copyWith(activeRole: role);
    }
  }

  /// Logout user
  Future<void> logout() async {
    // Clear FCM token from backend before logout
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.clearToken();
    } catch (_) {
      // Ignore errors, proceed with logout
    }

    // Optionally notify server about logout
    try {
      final api = _ref.read(apiClientProvider);
      await api.post<void>('/auth/logout', data: {});
    } catch (_) {
      // Ignore errors, proceed with local logout
    }

    // Sign out from Google to clear cached account
    // This ensures user can choose a different role on next login
    try {
      final googleService = _ref.read(googleSignInServiceProvider);
      await googleService.signOut();
    } catch (_) {
      // Ignore errors
    }

    // Clear all local auth data
    await _clearAuthData();

    // Reset notification initialized state
    _ref.read(notificationInitializedProvider.notifier).state = false;

    // Reset state
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    if (!state.isAuthenticated) return;

    try {
      final api = _ref.read(apiClientProvider);
      await api.delete<void>('/users/me');

      // Clear all local data
      await _storage.clearAll();
      _ref.read(apiClientProvider).clearAuthToken();

      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark onboarding as complete
  /// Updates both storage and state
  Future<void> markOnboardingComplete() async {
    print('🔧 AuthProvider: Marking onboarding as complete');
    print('  - Before: onboardingComplete = ${state.onboardingComplete}');
    await _storage.setOnboardingComplete();
    state = state.copyWith(onboardingComplete: true);
    print('  - After: onboardingComplete = ${state.onboardingComplete}');
  }

  /// Reset onboarding flag (dev/testing only)
  /// Use this to test onboarding flow again
  Future<void> resetOnboarding() async {
    await _storage.deleteOnboardingComplete();
    state = state.copyWith(onboardingComplete: false);
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage, ref);
});

/// Convenience provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Convenience provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for auth loading state
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Convenience provider for checking if user is a client
final isClientProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.isClient ?? true;
});

/// Convenience provider for checking if user is a contractor
final isContractorProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.isContractor ?? false;
});

/// Convenience provider for checking if user has completed onboarding
final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).onboardingComplete;
});
