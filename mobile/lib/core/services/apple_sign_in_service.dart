import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple Sign-In service for handling Apple OAuth authentication
class AppleSignInService {
  /// Check if Apple Sign-In is available on this device
  /// (Only available on iOS 13+, macOS 10.15+, and web)
  Future<bool> isAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  /// Sign in with Apple
  /// Returns the identity token and authorization code for backend authentication
  Future<AppleSignInResult> signIn() async {
    try {
      // Generate a random nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential from Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Check for required tokens
      if (credential.identityToken == null) {
        return AppleSignInResult.error('Failed to get identity token from Apple');
      }

      if (credential.authorizationCode.isEmpty) {
        return AppleSignInResult.error('Failed to get authorization code from Apple');
      }

      // Construct display name from given name and family name
      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        displayName = [credential.givenName, credential.familyName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
      }

      return AppleSignInResult.success(
        identityToken: credential.identityToken!,
        authorizationCode: credential.authorizationCode,
        email: credential.email,
        displayName: displayName,
        userIdentifier: credential.userIdentifier,
        rawNonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AppleSignInResult.cancelled();
      }
      return AppleSignInResult.error(e.message);
    } catch (e) {
      return AppleSignInResult.error(e.toString());
    }
  }

  /// Generate a random nonce string
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Result of Apple Sign-In operation
class AppleSignInResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? error;
  final String? identityToken;
  final String? authorizationCode;
  final String? email;
  final String? displayName;
  final String? userIdentifier;
  final String? rawNonce;

  AppleSignInResult._({
    required this.isSuccess,
    this.isCancelled = false,
    this.error,
    this.identityToken,
    this.authorizationCode,
    this.email,
    this.displayName,
    this.userIdentifier,
    this.rawNonce,
  });

  /// Alias for displayName for consistency
  String? get fullName => displayName;

  factory AppleSignInResult.success({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? displayName,
    String? userIdentifier,
    String? rawNonce,
  }) {
    return AppleSignInResult._(
      isSuccess: true,
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      email: email,
      displayName: displayName,
      userIdentifier: userIdentifier,
      rawNonce: rawNonce,
    );
  }

  factory AppleSignInResult.cancelled() {
    return AppleSignInResult._(
      isSuccess: false,
      isCancelled: true,
    );
  }

  factory AppleSignInResult.error(String message) {
    return AppleSignInResult._(
      isSuccess: false,
      error: message,
    );
  }
}

/// Provider for Apple Sign-In service
final appleSignInServiceProvider = Provider<AppleSignInService>((ref) {
  return AppleSignInService();
});

/// Provider to check if Apple Sign-In is available
final appleSignInAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(appleSignInServiceProvider);
  // Apple Sign-In is only available on iOS/macOS
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return await service.isAvailable();
  }
  return false;
});
