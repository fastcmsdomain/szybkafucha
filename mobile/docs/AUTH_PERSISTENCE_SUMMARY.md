# Auth State Persistence & Logout - Implementation Summary

## Tasks Completed
- **14.6** Implement auth state persistence
- **14.7** Create logout functionality

---

## 14.6 Auth State Persistence

### Overview
Implemented comprehensive auth state persistence that:
- Saves tokens and user data on login
- Restores session on app startup
- Validates tokens with backend
- Supports automatic token refresh
- Handles expired/invalid tokens gracefully

### Files Modified

#### [auth_provider.dart](../lib/core/providers/auth_provider.dart)

**New AuthStatus enum values:**
```dart
enum AuthStatus {
  initial,        // App just started
  loading,        // Checking stored credentials
  authenticated,  // User logged in
  unauthenticated,// User not logged in
  error,          // Auth error occurred
}
```

**Key Methods:**

| Method | Description |
|--------|-------------|
| `_initializeAuth()` | Called on startup - checks for stored tokens, loads cached user, validates with backend |
| `_validateAndRefreshUser()` | Fetches fresh user data from `/users/me` endpoint |
| `_tryRefreshToken()` | Attempts to refresh access token using refresh token |
| `_clearAuthData()` | Clears all auth data from storage |
| `_saveAuthData()` | Saves tokens and user data after successful login |

**Initialization Flow:**
```
App Start
    │
    ▼
Check stored token
    │
    ├── No token → Set unauthenticated
    │
    └── Has token
           │
           ├── Load cached user → Show authenticated immediately
           │                      │
           │                      ▼
           │              Validate token in background
           │                      │
           │                      ├── Valid → Update user data
           │                      │
           │                      └── Invalid → Try refresh token
           │                                    │
           │                                    ├── Success → Retry validation
           │                                    │
           │                                    └── Fail → Logout
           │
           └── No cached user → Validate token (blocking)
```

**User Data Caching:**
- User data is serialized to JSON and stored in secure storage
- Enables instant app launch with cached data
- Fresh data fetched in background
- Invalid cache gracefully ignored

#### [secure_storage.dart](../lib/core/storage/secure_storage.dart)

**New Storage Key:**
```dart
static const String userData = 'user_data';
```

**New Methods:**
```dart
Future<void> saveUserData(String userData);  // Save JSON string
Future<String?> getUserData();               // Get JSON string
Future<void> deleteUserData();               // Clear cached data
```

#### [app_router.dart](../lib/core/router/app_router.dart)

**Updated Redirect Logic:**
```dart
redirect: (context, state) {
  final isLoading = authState.isLoading;

  // While checking auth state, stay on current route
  if (isLoading) {
    return null;
  }

  // ... rest of redirect logic
}
```

### Convenience Providers

```dart
// Check if auth is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

// Check if user is client
final isClientProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.isClient ?? true;
});

// Check if user is contractor
final isContractorProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.isContractor ?? false;
});
```

---

## 14.7 Logout Functionality

### Overview
Implemented complete logout with:
- Server notification (optional)
- Local data clearing
- UI with confirmation dialog
- Account deletion option

### Files Created

#### [profile_screen.dart](../lib/features/profile/screens/profile_screen.dart)

**Features:**
- User avatar and info display
- Account settings section
- Preferences section
- Support section
- Logout button with confirmation dialog
- Delete account with confirmation dialog
- App version display

**Logout Flow:**
```
User taps Logout
        │
        ▼
Show confirmation dialog
        │
        ├── Cancel → Close dialog
        │
        └── Confirm
               │
               ▼
        Notify server (POST /auth/logout)
               │ (errors ignored)
               ▼
        Clear local auth data
               │
               ▼
        Reset auth state → unauthenticated
               │
               ▼
        Router redirects to welcome screen
```

**Account Deletion Flow:**
```
User taps "Usuń konto"
        │
        ▼
Show warning dialog
        │
        ├── Cancel → Close dialog
        │
        └── Confirm
               │
               ▼
        DELETE /users/me
               │
               ├── Success → Clear all data → Redirect to welcome
               │
               └── Error → Show error snackbar
```

### AuthNotifier Methods

```dart
/// Logout user
Future<void> logout() async {
  // Notify server (optional, errors ignored)
  try {
    await api.post('/auth/logout', data: {});
  } catch (_) {}

  // Clear local data
  await _clearAuthData();

  // Reset state
  state = const AuthState(status: AuthStatus.unauthenticated);
}

/// Delete user account
Future<void> deleteAccount() async {
  await api.delete('/users/me');
  await _storage.clearAll();
  state = const AuthState(status: AuthStatus.unauthenticated);
}
```

### Router Updates

Profile routes now use `ProfileScreen` instead of placeholder:
- `/client/profile` → `ProfileScreen`
- `/contractor/profile` → `ProfileScreen`

---

## File Structure

```
lib/
├── core/
│   ├── providers/
│   │   └── auth_provider.dart    # Enhanced with persistence + logout
│   ├── storage/
│   │   └── secure_storage.dart   # Added userData methods
│   └── router/
│       └── app_router.dart       # Loading state handling
└── features/
    └── profile/
        ├── profile.dart          # Barrel export
        └── screens/
            └── profile_screen.dart # Profile with logout
```

---

## Testing

All tests pass:
```
flutter test
00:07 +2: All tests passed!
```

Static analysis clean:
```
flutter analyze
No issues found!
```

---

## Tasks File Updates

Updated `tasks/tasks-prd-szybka-fucha.md`:
- [x] 14.6 Implement auth state persistence
- [x] 14.7 Create logout functionality

---

## Next Steps

1. **15.0 Client Screens** - Category selection, task creation, contractor selection
2. **16.0 Contractor Screens** - Task list, task details, navigation, earnings
3. **Backend Integration** - Connect auth methods to actual NestJS endpoints

---

*Last updated: January 2026*
