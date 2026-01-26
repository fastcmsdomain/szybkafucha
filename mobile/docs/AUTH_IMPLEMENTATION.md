# Szybka Fucha - Auth Implementation Guide

This document provides a comprehensive guide to the authentication implementation in the Szybka Fucha Flutter mobile app.

## Overview

The auth system supports three authentication methods:
1. **Google Sign-In** - Social login via Google account
2. **Apple Sign-In** - Social login via Apple ID (iOS only)
3. **Phone OTP** - SMS-based verification

## Architecture

```
lib/
├── core/
│   ├── providers/
│   │   └── auth_provider.dart      # Auth state management (Riverpod)
│   ├── router/
│   │   ├── app_router.dart         # Navigation with auth guards
│   │   └── routes.dart             # Route constants
│   └── storage/
│       └── secure_storage.dart     # Token persistence
└── features/
    └── auth/
        ├── auth.dart               # Barrel export
        ├── screens/
        │   ├── welcome_screen.dart      # Entry point
        │   ├── phone_login_screen.dart  # Phone number input
        │   ├── otp_screen.dart          # OTP verification
        │   └── register_screen.dart     # User type selection
        └── widgets/
            └── social_login_button.dart # Reusable login buttons
```

## Auth Flow

### 1. Welcome Screen (`welcome_screen.dart`)

The entry point for unauthenticated users. Displays:
- App branding (logo + name)
- Welcome headline and subtitle
- Illustration placeholder
- Social login buttons (Google, Apple)
- Divider with "or continue with"
- Phone login button
- Terms & Privacy agreement text

**Key implementation details:**
- Uses `SingleChildScrollView` with `ConstrainedBox` for proper layout on all screen sizes
- Social login buttons are reusable via `SocialLoginButton` widget
- "Coming soon" snackbar shown for Google/Apple until implemented

### 2. Phone Login Flow

#### Phone Login Screen (`phone_login_screen.dart`)

- Polish phone number input with +48 prefix
- Custom phone number formatter (XXX XXX XXX format)
- Input validation (must be 9 digits)
- Sends OTP request to backend on submit

**Implementation:**
```dart
final phone = '+48${_phoneController.text.replaceAll(' ', '')}';
// TODO: Call API
await ref.read(authProvider.notifier).requestPhoneOtp(phone);
context.push(Routes.phoneOtp, extra: phone);
```

#### OTP Screen (`otp_screen.dart`)

- 6 individual digit input boxes
- Auto-focus advance (moves to next box after input)
- Auto-submit when all 6 digits entered
- 60-second resend countdown timer
- Verifies OTP with backend

**Key features:**
- `FocusNode` management for each input box
- `Timer` for resend countdown
- Displays phone number at top for confirmation

### 3. Registration Screen (`register_screen.dart`)

After successful phone verification (for new users):
- Name input field
- User type selection (Client or Contractor)
  - Client: "Szukam pomocy" - wants to post tasks
  - Contractor: "Chcę pomagać" - wants to complete tasks
- Custom radio button indicators (no deprecated Radio widget)

**User type impacts:**
- Different home screens after login
- Different bottom navigation items
- Different features available

## State Management (auth_provider.dart)

### AuthState Model

```dart
class AuthState {
  final AuthStatus status;  // initial, authenticated, unauthenticated, loading, error
  final User? user;
  final String? errorMessage;
}
```

### AuthNotifier Methods

| Method | Description |
|--------|-------------|
| `loginWithEmail()` | Email/password login (placeholder) |
| `requestPhoneOtp()` | Request SMS OTP code |
| `verifyPhoneOtp()` | Verify OTP and login |
| `loginWithGoogle()` | Google Sign-In (placeholder) |
| `loginWithApple()` | Apple Sign-In (placeholder) |
| `logout()` | Clear auth state and tokens |

### Auth Status Enum

```dart
enum AuthStatus {
  initial,         // App just started
  authenticated,   // User logged in
  unauthenticated, // User not logged in
  loading,         // Auth operation in progress
  error,           // Auth error occurred
}
```

## Router Guards (app_router.dart)

The router implements automatic redirects based on auth state:

```dart
redirect: (context, state) {
  final isAuthenticated = authState.isAuthenticated;
  final isAuthRoute = state.matchedLocation == Routes.welcome ||
      state.matchedLocation == Routes.login ||
      state.matchedLocation.startsWith('/login');

  // Redirect to welcome if not authenticated
  if (!isAuthenticated && !isAuthRoute) {
    return Routes.welcome;
  }

  // Redirect authenticated users away from auth screens
  if (isAuthenticated && isAuthRoute) {
    final user = authState.user;
    if (user?.isContractor == true) {
      return Routes.contractorHome;
    }
    return Routes.clientHome;
  }

  return null;
}
```

### Route Structure

**Auth Routes (public):**
- `/welcome` - Welcome screen
- `/login` - Alias for welcome
- `/login/phone` - Phone number input
- `/login/phone/otp` - OTP verification
- `/register` - User type selection

**Client Routes (authenticated):**
- `/client` - Client home (with bottom nav shell)
- `/client/categories` - Browse categories
- `/client/history` - Task history
- `/client/profile` - Profile settings

**Contractor Routes (authenticated):**
- `/contractor` - Contractor home (with bottom nav shell)
- `/contractor/tasks` - Available tasks
- `/contractor/earnings` - Earnings dashboard
- `/contractor/profile` - Profile settings

## Secure Storage (secure_storage.dart)

Tokens are persisted securely using `flutter_secure_storage`:

```dart
class SecureStorageService {
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> deleteAuthToken();

  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> deleteRefreshToken();

  Future<void> clearAll();
}
```

**Platform-specific storage:**
- **iOS**: Keychain Services
- **Android**: EncryptedSharedPreferences

## Social Login Button Widget

Reusable button component for social login options:

```dart
enum SocialLoginType { google, apple, phone }

class SocialLoginButton extends StatelessWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;
  // Renders appropriate icon, label, and styling
}
```

**Styling per type:**
| Type | Icon | Label | Background |
|------|------|-------|------------|
| Google | Google logo | "Kontynuuj z Google" | White |
| Apple | Apple logo | "Kontynuuj z Apple" | Black |
| Phone | Phone icon | "Zaloguj przez telefon" | Primary |

## Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| Welcome Screen | ✅ Complete | Scrollable layout, responsive |
| Phone Login | ✅ Complete | Polish format, validation |
| OTP Screen | ✅ Complete | Auto-advance, auto-submit |
| Registration | ✅ Complete | Custom radio indicators |
| Auth Provider | ✅ Complete | Placeholder API calls |
| Router Guards | ✅ Complete | Role-based redirects |
| Secure Storage | ✅ Complete | Token persistence ready |
| Google Sign-In | ⏳ Pending | Needs google_sign_in package |
| Apple Sign-In | ⏳ Pending | Needs sign_in_with_apple package |
| Backend Integration | ⏳ Pending | Connect to NestJS API |

## Next Steps

### 1. Google Sign-In (Task 14.2)

Required dependencies:
```yaml
dependencies:
  google_sign_in: ^6.2.1
```

Implementation steps:
1. Configure Firebase project
2. Add Google Services JSON/plist files
3. Implement `loginWithGoogle()` in auth_provider
4. Handle token exchange with backend

### 2. Apple Sign-In (Task 14.3)

Required dependencies:
```yaml
dependencies:
  sign_in_with_apple: ^6.1.3
```

Implementation steps:
1. Configure Apple Developer account
2. Enable Sign in with Apple capability
3. Implement `loginWithApple()` in auth_provider
4. Handle authorization credentials

### 3. Backend Integration

Connect auth_provider to NestJS backend:

```dart
// In auth_provider.dart
Future<void> verifyPhoneOtp({
  required String phone,
  required String otp,
}) async {
  state = AuthState.loading();

  try {
    final response = await ref.read(apiClientProvider).post(
      '/auth/phone/verify',
      data: {'phone': phone, 'otp': otp},
    );

    final tokens = AuthTokens.fromJson(response.data);
    await ref.read(secureStorageProvider).saveAuthToken(tokens.accessToken);
    await ref.read(secureStorageProvider).saveRefreshToken(tokens.refreshToken);

    state = AuthState.authenticated(User.fromJson(response.data['user']));
  } catch (e) {
    state = AuthState.error(e.toString());
  }
}
```

### 4. Auth State Persistence (Task 14.6)

On app startup, check for stored tokens:

```dart
Future<void> initializeAuth() async {
  final token = await ref.read(secureStorageProvider).getAuthToken();

  if (token != null) {
    // Validate token with backend
    try {
      final response = await ref.read(apiClientProvider).get('/auth/me');
      state = AuthState.authenticated(User.fromJson(response.data));
    } catch (e) {
      // Token expired or invalid
      await ref.read(secureStorageProvider).clearAll();
      state = AuthState.unauthenticated();
    }
  } else {
    state = AuthState.unauthenticated();
  }
}
```

## Testing

Widget tests are in `test/widget_test.dart`:

```dart
testWidgets('App starts and shows Welcome screen', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: SzybkaFuchaApp()),
  );
  await tester.pumpAndSettle();

  // Verify welcome screen headline
  expect(find.text('Pomoc jest bliżej niż myślisz'), findsOneWidget);
  // Verify social login button
  expect(find.textContaining('Google'), findsOneWidget);
});
```

## Design Tokens

Auth screens use the app's design system:

**Colors:**
- Primary: `#E94560` (coral red)
- Gray scale for text hierarchy
- Success/Error for feedback

**Typography:**
- Nunito 800 for headlines
- Plus Jakarta Sans for body text

**Spacing:**
- Consistent padding using `AppSpacing` constants

**Border Radius:**
- `AppRadius.button` for action buttons
- `AppRadius.radiusMD` for input fields

---

*Last updated: January 2026*
*Task reference: 14.0 Authentication Screens*
