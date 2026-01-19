# Backend Authentication Setup Guide

> Complete guide to running the Szybka Fucha mobile app with the backend server, including Google, Apple, and Phone authentication.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Mobile App Configuration](#mobile-app-configuration)
4. [Phone OTP Authentication](#phone-otp-authentication)
5. [Google Sign-In Setup](#google-sign-in-setup)
6. [Apple Sign-In Setup](#apple-sign-in-setup)
7. [Testing the Complete Flow](#testing-the-complete-flow)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Node.js** 18+
- **Docker** (for PostgreSQL and Redis)
- **Flutter** 3.x
- **Xcode** (for iOS/macOS development)
- **Android Studio** (for Android development)

### Required Accounts (for production auth)
- **Google Cloud Console** account (for Google Sign-In)
- **Apple Developer** account (for Apple Sign-In)
- **Twilio** account (for SMS OTP) - optional for development

---

## Backend Setup

### Step 1: Start Database Services

```bash
# From project root
docker-compose up -d
```

This starts:
- **PostgreSQL** on port 5432
- **Redis** on port 6379
- **pgAdmin** on port 5050 (optional)

### Step 2: Configure Backend Environment

```bash
cd backend
cp .env.example .env
```

Edit `.env` with your values:

```bash
# Required for basic functionality
NODE_ENV=development
PORT=3000

# Database (from docker-compose)
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha
DATABASE_PASSWORD=szybkafucha_dev_password
DATABASE_NAME=szybkafucha

# Redis (from docker-compose)
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT Secret (generate a secure random string)
JWT_SECRET=your-super-secret-jwt-key-at-least-32-characters-long
JWT_EXPIRES_IN=30d

# CORS (mobile apps connect via IP or localhost)
CORS_ORIGIN=http://localhost:3000,http://localhost:8080

# --- Optional for development ---

# Twilio (for real SMS OTP)
# Leave empty to use dev mode with fixed code 123456
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# Google OAuth (for verifying Google tokens)
GOOGLE_CLIENT_ID=

# Apple OAuth (for verifying Apple tokens)
APPLE_CLIENT_ID=
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=
```

### Step 3: Install Dependencies & Start Backend

```bash
cd backend
npm install
npm run start:dev
```

The backend will be available at `http://localhost:3000/api/v1`

### Step 4: Seed Test Data (Optional)

```bash
npm run seednpm run seed
```

This creates test users, tasks, and contractors for development.

---

## Mobile App Configuration

### Step 1: Disable Dev Mode

Edit `mobile/lib/core/api/api_config.dart`:

```dart
static const bool devModeEnabled = false;  // Change from true to false
```

### Step 2: Configure API URL

For different platforms, you may need different base URLs:

```dart
// For iOS Simulator
static const String devBaseUrl = 'http://localhost:3000/api/v1';

// For Android Emulator (uses special IP)
static const String devBaseUrl = 'http://10.0.2.2:3000/api/v1';

// For Physical Device (use your computer's IP)
static const String devBaseUrl = 'http://192.168.1.XXX:3000/api/v1';
```

**Tip:** Find your computer's IP with `ifconfig` (macOS) or `ipconfig` (Windows).

### Step 3: Run the App

```bash
cd mobile
flutter pub get
flutter run
```

---

## Phone OTP Authentication

Phone authentication is the easiest to set up for development.

### Development Mode (No Twilio Required)

When `NODE_ENV=development` and Twilio credentials are not set:
- OTP is NOT sent via SMS
- OTP code is always `123456`
- OTP is logged to backend console

### Testing Phone Login

1. Open the app
2. Tap "Kontynuuj z numerem telefonu"
3. Enter any Polish phone number (e.g., `+48 123 456 789`)
4. Tap "Wyślij kod"
5. On OTP screen, enter: `123456`
6. You're logged in!

### Production Mode (Real SMS)

For real SMS delivery, configure Twilio:

1. Create account at [twilio.com](https://www.twilio.com)
2. Get a phone number with SMS capability
3. Add to `.env`:

```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890
```

---

## Google Sign-In Setup

### Overview

The authentication flow:
1. Mobile app shows Google Sign-In UI
2. User authenticates with Google
3. Mobile app receives Google ID token
4. Mobile app sends token to backend
5. Backend verifies token and creates/finds user
6. Backend returns JWT token

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (e.g., "Szybka Fucha")
3. Enable **Google Sign-In API**

### Step 2: Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** user type
3. Fill in app information:
   - App name: `Szybka Fucha`
   - User support email: your email
   - Developer contact: your email
4. Add scopes: `email`, `profile`, `openid`
5. Add test users (for development)

### Step 3: Create OAuth Credentials

#### For iOS

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **iOS**
4. Enter Bundle ID: `pl.szybkafucha.mobile`
5. Download the `GoogleService-Info.plist`
6. Place it in `mobile/ios/Runner/`

Add to `mobile/ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Reversed client ID from GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

#### For Android

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **Android**
4. Enter Package name: `pl.szybkafucha.mobile`
5. Get SHA-1 fingerprint:
   ```bash
   cd mobile/android
   ./gradlew signingReport
   ```
6. Download `google-services.json`
7. Place it in `mobile/android/app/`

#### For Web (Optional)

1. Create **Web application** OAuth client ID
2. Add authorized origins: `http://localhost:3000`
3. Note the Client ID for backend verification

### Step 4: Backend Configuration

Add to `backend/.env`:
```bash
GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### Step 5: Update Mobile Auth Provider

The mobile app needs to send the correct data to the backend. Update the `loginWithGoogle` method in `auth_provider.dart`:

```dart
/// Login with Google
Future<void> loginWithGoogle({
  required String googleId,
  required String email,
  String? name,
  String? avatarUrl,
}) async {
  state = state.copyWith(status: AuthStatus.loading, clearError: true);

  try {
    final api = _ref.read(apiClientProvider);
    final response = await api.post<Map<String, dynamic>>(
      '/auth/google',
      data: {
        'googleId': googleId,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
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
```

And update the welcome screen's `_handleGoogleSignIn`:

```dart
Future<void> _handleGoogleSignIn() async {
  setState(() {
    _isLoading = true;
    _loadingProvider = 'google';
  });

  try {
    final googleService = ref.read(googleSignInServiceProvider);
    final result = await googleService.signIn();

    if (!mounted) return;

    if (result.isCancelled) {
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
      });
      return;
    }

    if (!result.isSuccess) {
      _showError(result.error ?? 'Błąd logowania przez Google');
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
      });
      return;
    }

    // Extract Google user ID from ID token (or use email as fallback)
    // The backend will use this to identify the user
    await ref.read(authProvider.notifier).loginWithGoogle(
      googleId: result.email!, // Use email as unique identifier
      email: result.email!,
      name: result.displayName,
      avatarUrl: result.photoUrl,
    );
  } catch (e) {
    if (mounted) {
      _showError('Błąd logowania: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
      });
    }
  }
}
```

---

## Apple Sign-In Setup

### Overview

Apple Sign-In is only available on iOS and macOS devices.

### Step 1: Apple Developer Setup

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID (or create one)
4. Enable **Sign in with Apple** capability

### Step 2: Configure Xcode

1. Open `mobile/ios/Runner.xcworkspace` in Xcode
2. Select Runner target > **Signing & Capabilities**
3. Click **+ Capability** > **Sign in with Apple**
4. Ensure your Team is selected

### Step 3: Create Service ID (for backend verification)

1. In Apple Developer Portal > **Identifiers**
2. Click **+** > **Services IDs**
3. Register a new Service ID:
   - Description: `Szybka Fucha Backend`
   - Identifier: `pl.szybkafucha.service`
4. Enable **Sign in with Apple**
5. Configure domains and return URLs

### Step 4: Create Private Key

1. In Apple Developer Portal > **Keys**
2. Click **+** to create new key
3. Enable **Sign in with Apple**
4. Download the `.p8` file (save it securely!)
5. Note the Key ID

### Step 5: Backend Configuration

Add to `backend/.env`:
```bash
APPLE_CLIENT_ID=pl.szybkafucha.mobile
APPLE_TEAM_ID=YOUR_TEAM_ID
APPLE_KEY_ID=YOUR_KEY_ID
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY_CONTENT\n-----END PRIVATE KEY-----"
```

### Step 6: Update Mobile Auth Provider

Similar to Google, update the `loginWithApple` method:

```dart
/// Login with Apple
Future<void> loginWithApple({
  required String appleId,
  String? email,
  String? name,
}) async {
  state = state.copyWith(status: AuthStatus.loading, clearError: true);

  try {
    final api = _ref.read(apiClientProvider);
    final response = await api.post<Map<String, dynamic>>(
      '/auth/apple',
      data: {
        'appleId': appleId,
        'email': email,
        'name': name,
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
```

---

## Testing the Complete Flow

### Quick Test Checklist

| Auth Method | Platform | Status |
|------------|----------|--------|
| Phone OTP | All | Works immediately with code `123456` |
| Google | iOS | Requires GoogleService-Info.plist |
| Google | Android | Requires google-services.json + SHA-1 |
| Apple | iOS/macOS only | Requires Xcode capability |

### Test Phone OTP (Easiest)

1. Start backend: `cd backend && npm run start:dev`
2. Run app: `cd mobile && flutter run`
3. Disable dev mode in `api_config.dart`
4. Tap "Kontynuuj z numerem telefonu"
5. Enter `+48 123 456 789`
6. Enter OTP: `123456`
7. Complete registration if new user

### Test Google Sign-In

1. Complete Google Cloud setup (above)
2. Add required files (GoogleService-Info.plist / google-services.json)
3. Run app on device/simulator
4. Tap "Kontynuuj z Google"
5. Complete Google authentication
6. Verify user created in database

### Test Apple Sign-In

1. Complete Apple Developer setup (above)
2. Configure Xcode with Sign in with Apple capability
3. Run app on **physical iOS device** or macOS
4. Tap "Kontynuuj z Apple"
5. Complete Apple authentication
6. Verify user created in database

---

## Troubleshooting

### Backend won't start

```bash
# Check if port 3000 is in use
lsof -i :3000

# Check Docker services are running
docker-compose ps

# View backend logs
npm run start:dev
```

### "Connection refused" on Android

Android emulator uses special IP `10.0.2.2` to reach host machine:

```dart
static const String devBaseUrl = 'http://10.0.2.2:3000/api/v1';
```

### "Network error" on physical device

1. Ensure phone and computer are on same WiFi
2. Find computer's IP: `ifconfig | grep "inet "`
3. Update `devBaseUrl` with computer's IP
4. Ensure backend allows connections from that IP

### OTP not received (production)

1. Check Twilio credentials in `.env`
2. Verify Twilio phone number has SMS capability
3. Check Twilio logs for errors
4. Ensure phone number format is correct (+48...)

### Google Sign-In fails

1. Verify OAuth credentials match platform
2. Check SHA-1 fingerprint (Android)
3. Verify Bundle ID matches (iOS)
4. Check Google Cloud Console for errors

### Apple Sign-In fails

1. Must test on real iOS device or macOS
2. Verify Sign in with Apple capability in Xcode
3. Check Apple Developer Portal configuration
4. Verify Team ID and Bundle ID

### JWT errors

1. Ensure `JWT_SECRET` is set in `.env`
2. Secret must be at least 32 characters
3. Clear app data and try again

---

## API Reference

### Auth Endpoints

| Endpoint | Method | Body | Response |
|----------|--------|------|----------|
| `/auth/phone/request-otp` | POST | `{ "phone": "+48123456789" }` | `{ "message": "OTP sent", "expiresIn": 300 }` |
| `/auth/phone/verify` | POST | `{ "phone": "+48...", "code": "123456" }` | `{ "accessToken": "...", "user": {...}, "isNewUser": true }` |
| `/auth/google` | POST | `{ "googleId": "...", "email": "...", "name": "..." }` | `{ "accessToken": "...", "user": {...} }` |
| `/auth/apple` | POST | `{ "appleId": "...", "email": "...", "name": "..." }` | `{ "accessToken": "...", "user": {...} }` |
| `/auth/logout` | POST | - | `{ "message": "Logged out" }` |

### Response Format

**Success:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Jan Kowalski",
    "type": "client",
    "status": "active"
  },
  "isNewUser": false
}
```

**Error:**
```json
{
  "statusCode": 400,
  "message": ["Invalid OTP code"],
  "error": "Bad Request"
}
```

---

## Next Steps

After setting up authentication:

1. **Complete backend integration** - Connect task creation, payments, etc.
2. **Configure Stripe** - For payment processing
3. **Set up Onfido** - For KYC verification (contractors)
4. **Configure Firebase** - For push notifications
5. **Deploy to production** - See `backend/DEPLOYMENT.md`
