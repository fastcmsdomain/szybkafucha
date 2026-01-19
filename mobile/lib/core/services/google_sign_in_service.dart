import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In service for handling Google OAuth authentication
class GoogleSignInService {
  // Configure scopes needed for the app
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Check if user is already signed in with Google
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Get currently signed in account (if any)
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Sign in with Google
  /// Returns the ID token for backend authentication
  Future<GoogleSignInResult> signIn() async {
    try {
      // Attempt to sign in silently first (for returning users)
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      // If silent sign-in failed, show the sign-in dialog
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        return GoogleSignInResult.cancelled();
      }

      // Get authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        return GoogleSignInResult.error('Failed to get ID token from Google');
      }

      return GoogleSignInResult.success(
        idToken: auth.idToken!,
        accessToken: auth.accessToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      return GoogleSignInResult.error(e.toString());
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Disconnect (revoke access) from Google
  /// This removes the app's access to the user's Google account
  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
  }
}

/// Result of Google Sign-In operation
class GoogleSignInResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? error;
  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  GoogleSignInResult._({
    required this.isSuccess,
    this.isCancelled = false,
    this.error,
    this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  factory GoogleSignInResult.success({
    required String idToken,
    String? accessToken,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return GoogleSignInResult._(
      isSuccess: true,
      idToken: idToken,
      accessToken: accessToken,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  factory GoogleSignInResult.cancelled() {
    return GoogleSignInResult._(
      isSuccess: false,
      isCancelled: true,
    );
  }

  factory GoogleSignInResult.error(String message) {
    return GoogleSignInResult._(
      isSuccess: false,
      error: message,
    );
  }
}

/// Provider for Google Sign-In service
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
