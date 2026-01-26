# Szybka Fucha Mobile App - Testing Guide

> Comprehensive guide for testing the Flutter mobile app on all platforms

## Quick Start

### Running the App

```bash
cd mobile

# Install dependencies (first time or after pubspec changes)
flutter pub get

# Run on current device/simulator
flutter run

# Run on specific platform
flutter run -d ios              # iOS Simulator
flutter run -d android          # Android Emulator
flutter run -d macos            # macOS Desktop
flutter run -d chrome           # Web Browser
```

### Available Devices

Check what devices are available:
```bash
flutter devices
```

---

## Development Mode (UI Testing without Backend)

The app includes a **dev mode** that allows you to test all UI screens without running the backend server.

### Enabling Dev Mode

Dev mode is controlled by `ApiConfig.devModeEnabled` in `lib/core/api/api_config.dart`:

```dart
static const bool devModeEnabled = true;  // Set to false for production
```

When enabled, the Welcome screen shows two additional buttons:
- **Klient** (Client) - Login as a test client user
- **Wykonawca** (Contractor) - Login as a test contractor user

### Mock Users

| Role | Name | Email | User Type |
|------|------|-------|-----------|
| Client | Jan Kowalski | client@test.pl | client |
| Contractor | Anna Nowak | contractor@test.pl | contractor |

---

## Testing Flows

### 1. Client Flow (Zleceniodawca)

#### 1.1 Login as Client
1. Open app on Welcome screen
2. Scroll down to "Tryb deweloperski" (Dev Mode) section
3. Tap "Klient" button
4. You'll be redirected to Client Home

#### 1.2 Create a Task
1. From Client Home, tap a category card (e.g., "Sprzątanie")
2. Or tap "Kategorie" in bottom nav → Select category
3. Fill in task details:
   - Description (min 10 characters)
   - Location (tap "Użyj mojej lokalizacji" or enter address)
   - Budget (use slider, respects category min/max)
   - Schedule ("Teraz" or pick date/time)
4. Tap "Przejdź dalej" to continue
5. Review task summary
6. Tap "Znajdź pomocnika"

#### 1.3 Select Contractor
1. Browse contractor list with:
   - Ratings and reviews count
   - Proposed price
   - Estimated arrival time (ETA)
   - Verified badge
2. Tap contractor card to view profile sheet
3. Sort by: Polecane, Ocena, Cena, Czas dojazdu
4. Select contractor and tap "Wybierz"

#### 1.4 Payment
1. Review task summary and contractor info
2. Check price breakdown (service + 17% platform fee)
3. Select payment method:
   - Karta płatnicza
   - Google Pay
   - Apple Pay
4. Toggle "Zapamiętaj metodę płatności"
5. Tap "Zapłać X.XX PLN"

#### 1.5 Task Tracking
1. Watch task progress through stages:
   - Szukamy pomocnika...
   - Zlecenie zaakceptowane
   - Pomocnik w drodze
   - Pomocnik na miejscu
   - Praca w toku
   - Zakończono
2. View contractor card with contact options
3. Tap "Czat" or "Zadzwoń" to contact
4. Tap "Anuluj zlecenie" to cancel (with confirmation)

#### 1.6 Task Completion
1. After task completes, rate the service (1-5 stars)
2. Optionally write a review (max 500 chars)
3. Optionally add a tip (0, 5, 10, 15, 20 PLN)
4. Tap "Wyślij ocenę" or "Pomiń ocenę"

#### 1.7 Task History
1. Tap "Historia" in bottom nav
2. Switch between:
   - **Aktywne** - Tasks in progress
   - **Historia** - Completed tasks
3. Tap task card to view details
4. Pull down to refresh

### 2. Contractor Flow (Wykonawca)

#### 2.1 Login as Contractor
1. Open app on Welcome screen
2. Scroll to "Tryb deweloperski" section
3. Tap "Wykonawca" button
4. You'll be redirected to Contractor Home

#### 2.2 Dashboard
1. View earnings summary card
2. Toggle availability (online/offline)
3. View nearby task opportunities

#### 2.3 Profile & Settings
1. Tap "Profil" in bottom nav
2. View/edit profile information
3. Access settings
4. Logout or delete account

> **Note:** Contractor screens (16.0) are partially implemented.
> Full task acceptance and completion flows are pending.

### 3. Logout Flow

#### 3.1 Logout
1. Navigate to Profile screen
2. Tap "Wyloguj się"
3. Confirm in dialog
4. You'll be redirected to Welcome screen

#### 3.2 Delete Account
1. Navigate to Profile screen
2. Tap "Usuń konto"
3. Read warning message
4. Confirm deletion
5. Account deleted, redirected to Welcome

---

## Platform-Specific Testing

### iOS Simulator

```bash
# List available simulators
xcrun simctl list devices

# Run on specific simulator
flutter run -d "iPhone 15 Pro"

# Run on iPad
flutter run -d "iPad Pro (12.9-inch)"
```

**Test these iOS-specific features:**
- Apple Sign-In button visibility (should show)
- Keyboard behavior and input handling
- Safe area insets (notch, home indicator)
- Navigation gestures (swipe back)

### Android Emulator

```bash
# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# Run on device
flutter run -d <device_id>
```

**Test these Android-specific features:**
- Apple Sign-In button visibility (should be hidden)
- Material You theming
- Back button behavior
- Keyboard behavior

### macOS Desktop

```bash
flutter run -d macos
```

**Test these desktop-specific features:**
- Window resizing (check responsive layouts)
- Keyboard navigation
- Mouse hover states
- Apple Sign-In (should work on macOS)

### Web (Chrome)

```bash
flutter run -d chrome
```

**Test these web-specific features:**
- Responsive layouts at different widths
- Browser back/forward navigation
- Social login buttons (may have limitations)

---

## Screen Checklist

### Auth Screens (14.0) ✅
| Screen | Route | Status |
|--------|-------|--------|
| Welcome | `/welcome` | ✅ Complete |
| Phone Login | `/phone-login` | ✅ Complete |
| OTP Verification | `/otp` | ✅ Complete |
| Registration | `/register` | ✅ Complete |

### Client Screens (15.0) ✅
| Screen | Route | Status |
|--------|-------|--------|
| Client Home | `/client` | ✅ Complete |
| Category Selection | `/client/categories` | ✅ Complete |
| Create Task | `/client/task/create` | ✅ Complete |
| Contractor Selection | `/client/task/contractors` | ✅ Complete |
| Payment | `/client/task/payment` | ✅ Complete |
| Task Tracking | `/client/task/:id/track` | ✅ Complete |
| Task Completion | `/client/task/:id/complete` | ✅ Complete |
| Task History | `/client/history` | ✅ Complete |
| Profile | `/client/profile` | ✅ Complete |

### Contractor Screens (16.0) 🚧
| Screen | Route | Status |
|--------|-------|--------|
| Contractor Home | `/contractor` | 🚧 Placeholder |
| Task List | `/contractor/tasks` | 🚧 Placeholder |
| Earnings | `/contractor/earnings` | 🚧 Placeholder |
| Profile | `/contractor/profile` | ✅ Complete |

---

## Common Test Scenarios

### 1. Form Validation
- [ ] Task description requires minimum 10 characters
- [ ] Phone number validates Polish format (+48)
- [ ] OTP requires 6 digits
- [ ] Budget slider respects category min/max

### 2. Navigation
- [ ] Back button returns to previous screen
- [ ] Deep links work correctly
- [ ] Auth guard redirects unauthenticated users
- [ ] User type routing (client vs contractor home)

### 3. State Persistence
- [ ] Login state persists after app restart
- [ ] Logout clears all user data
- [ ] User type stored correctly

### 4. UI/UX
- [ ] Loading indicators show during async operations
- [ ] Error messages display in snackbars
- [ ] Buttons disable during loading
- [ ] Animations play smoothly

### 5. Responsive Layout
- [ ] Works on small phones (320px width)
- [ ] Works on tablets (768px+ width)
- [ ] Works on desktop (1024px+ width)
- [ ] Safe areas respected on notched devices

---

## Debugging Tips

### View Debug Logs
```bash
flutter run --verbose
```

### Hot Reload vs Hot Restart
- **Hot Reload (r)**: Fast, keeps app state
- **Hot Restart (R)**: Full restart, clears state

### Clear App Data
```bash
# iOS Simulator
xcrun simctl erase all

# Android (specific app)
adb shell pm clear pl.szybkafucha.mobile
```

### Check Secure Storage
On iOS Simulator, secure storage uses Keychain.
On Android Emulator, uses encrypted shared preferences.

To reset stored auth data, logout from the app or clear app data.

---

## Running with Backend

When you're ready to test with the real backend:

1. **Start Backend Services**
   ```bash
   cd ..
   docker-compose up -d  # PostgreSQL + Redis
   cd backend
   npm run start:dev
   ```

2. **Disable Dev Mode**
   ```dart
   // lib/core/api/api_config.dart
   static const bool devModeEnabled = false;
   ```

3. **Configure API URL**
   - For iOS Simulator: `http://localhost:3000/api/v1`
   - For Android Emulator: `http://10.0.2.2:3000/api/v1`
   - For physical device: Use your machine's IP address

4. **Test Real Auth Flows**
   - Google Sign-In (requires Google Cloud Console setup)
   - Apple Sign-In (requires Apple Developer account)
   - Phone OTP (requires Twilio configuration)

---

## Admin Panel Testing

The admin panel is separate from the mobile app:

```bash
cd admin
npm install
npm start
```

Access at: `http://localhost:3000`

**Admin features to test:**
- User management
- Task overview
- Dispute resolution
- Newsletter subscribers
- Statistics dashboard

---

## Known Limitations (Dev Mode)

1. **No real payment processing** - Payment screen simulates success
2. **No real location tracking** - Uses mock locations
3. **No real-time updates** - Status changes are simulated
4. **No backend sync** - All data is local/mocked
5. **No push notifications** - Not implemented yet
6. **Contractor screens incomplete** - Only placeholders

---

## Next Steps for Full Testing

1. [ ] Start backend server
2. [ ] Configure Stripe test keys
3. [ ] Set up Twilio for OTP
4. [ ] Configure Google OAuth credentials
5. [ ] Configure Apple Sign-In
6. [ ] Complete Contractor screens (16.0)
7. [ ] Implement real-time features (17.0)
