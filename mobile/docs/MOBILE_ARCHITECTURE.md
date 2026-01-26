# Szybka Fucha Mobile Architecture

## Overview

The Szybka Fucha mobile app is built with Flutter 3.38+ using Material 3 design system. This document covers the architecture, folder structure, and development guidelines.

## Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Flutter | 3.38.7 |
| Language | Dart | 3.10.7 |
| State Management | Riverpod | 2.x |
| Navigation | go_router | 14.x |
| HTTP Client | Dio | 5.x |
| Secure Storage | flutter_secure_storage | 9.x |
| Fonts | Google Fonts | 6.x |

## Folder Structure

```
lib/
├── core/                    # Core functionality
│   ├── api/                 # HTTP client & API configuration
│   │   ├── api_client.dart      # Dio wrapper with interceptors
│   │   ├── api_config.dart      # Base URLs, timeouts
│   │   └── api_exceptions.dart  # Custom exception types
│   │
│   ├── l10n/               # Localization
│   │   └── app_strings.dart     # Polish strings
│   │
│   ├── providers/          # Riverpod providers
│   │   ├── api_provider.dart    # API client provider
│   │   ├── auth_provider.dart   # Auth state management
│   │   └── storage_provider.dart # Storage provider
│   │
│   ├── router/             # Navigation
│   │   ├── app_router.dart      # GoRouter configuration
│   │   └── routes.dart          # Route constants
│   │
│   ├── storage/            # Persistent storage
│   │   └── secure_storage.dart  # Token & sensitive data storage
│   │
│   ├── theme/              # Design system
│   │   ├── app_colors.dart      # Color palette
│   │   ├── app_typography.dart  # Font styles
│   │   ├── app_spacing.dart     # Spacing scale
│   │   ├── app_radius.dart      # Border radius
│   │   ├── app_shadows.dart     # Elevation shadows
│   │   └── app_theme.dart       # Material 3 theme
│   │
│   ├── widgets/            # Reusable UI components
│   │   ├── sf_button.dart       # Primary, ghost, gradient buttons
│   │   ├── sf_card.dart         # Card with optional rainbow border
│   │   ├── sf_input.dart        # Text input with validation
│   │   ├── sf_avatar.dart       # User avatar with online indicator
│   │   ├── sf_rating_stars.dart # Star rating display/input
│   │   ├── sf_status_badge.dart # Task/KYC status badges
│   │   └── sf_bottom_nav.dart   # Bottom navigation presets
│   │
│   └── core.dart           # Barrel export for all core modules
│
├── features/               # Feature modules (to be added)
│   ├── auth/
│   ├── client/
│   └── contractor/
│
└── main.dart               # App entry point
```

## Architecture Patterns

### State Management (Riverpod)

All state is managed using Riverpod providers:

```dart
// Simple provider
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// State notifier for complex state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage, ref);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
```

### Navigation (go_router)

Routes are defined in `routes.dart` and configured in `app_router.dart`:

```dart
// Navigate programmatically
context.go(Routes.clientHome);
context.push(Routes.clientTask('task-123'));

// With parameters
context.go(Routes.clientTaskTrack(taskId));
```

### API Layer

The API client handles all HTTP communication:

```dart
final api = ref.read(apiClientProvider);

// GET request
final data = await api.get<Map<String, dynamic>>('/users/me');

// POST request with error handling
try {
  await api.post('/tasks', data: taskData);
} on ValidationException catch (e) {
  showError(e.allErrors);
} on NetworkException catch (e) {
  showError('No internet connection');
}
```

### Error Handling

All API errors are converted to typed exceptions:

| Exception | HTTP Status | Description |
|-----------|-------------|-------------|
| `NetworkException` | - | Connection timeout, no internet |
| `ValidationException` | 400, 422 | Invalid request data |
| `UnauthorizedException` | 401 | Token expired |
| `ForbiddenException` | 403 | Access denied |
| `NotFoundException` | 404 | Resource not found |
| `ServerException` | 5xx | Server error |

## Design System

### Colors

Based on szybkafucha.app landing page:

```dart
// Primary
AppColors.primary       // #E94560 - Coral red
AppColors.primaryDark   // #D13A54 - Pressed state
AppColors.primaryLight  // #FF6B7A - Backgrounds

// Secondary
AppColors.secondary     // #1A1A2E - Dark navy
AppColors.secondaryLight // #16213E

// Semantic
AppColors.success       // #10B981
AppColors.warning       // #F59E0B
AppColors.error         // #EF4444

// Grays (Tailwind scale)
AppColors.gray50 - AppColors.gray900
```

### Typography

```dart
// Headings (Nunito 800)
AppTypography.h1  // 48px
AppTypography.h2  // 36px
AppTypography.h3  // 30px
AppTypography.h4  // 24px

// Body (Plus Jakarta Sans)
AppTypography.bodyLarge   // 18px
AppTypography.bodyMedium  // 16px
AppTypography.bodySmall   // 14px
AppTypography.caption     // 12px
```

### Spacing

```dart
// Padding/margins
AppSpacing.paddingSM  // 12
AppSpacing.paddingMD  // 16
AppSpacing.paddingLG  // 24
AppSpacing.paddingXL  // 32

// Gaps between elements
AppSpacing.gapSM  // 8
AppSpacing.gapMD  // 12
AppSpacing.gapLG  // 16
```

## Authentication Flow

1. User opens app → Check for stored token
2. If token exists → Validate with backend → Show appropriate home
3. If no token → Show welcome screen
4. Login options: Google, Apple, Phone OTP
5. After login → Store token securely → Redirect to home

## Route Guards

Routes are protected based on auth state:

```dart
redirect: (context, state) {
  final isAuthenticated = authState.isAuthenticated;
  final isAuthRoute = state.matchedLocation == Routes.welcome;

  // Not authenticated? Go to welcome
  if (!isAuthenticated && !isAuthRoute) {
    return Routes.welcome;
  }

  // Authenticated on auth page? Go to home
  if (isAuthenticated && isAuthRoute) {
    return user.isContractor ? Routes.contractorHome : Routes.clientHome;
  }

  return null;
}
```

## Platform Configuration

### iOS

- Bundle ID: `pl.szybkafucha.mobile`
- Min iOS: 12.0
- Keychain accessibility: First unlock this device

### Android

- Application ID: `pl.szybkafucha.mobile`
- Min SDK: 23 (Android 6.0)
- Encrypted shared preferences enabled

## Development Commands

```bash
# Run app
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d macos
flutter run -d <iOS-simulator-id>

# Run tests
flutter test

# Analyze code
flutter analyze

# Generate code (riverpod, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Next Steps

1. **14.0 Auth Screens** - Welcome, Google/Apple Sign-In, Phone OTP
2. **15.0 Client Screens** - Category selection, task creation, tracking
3. **16.0 Contractor Screens** - Task list, accept, navigation
4. **17.0 Shared Features** - Chat, ratings, profile

## Related Documentation

- [Backend API](../../backend/README.md)
- [Design System Tokens](./DESIGN_TOKENS.md)
- [Task Tracking](../tasks/tasks-prd-szybka-fucha.md)
