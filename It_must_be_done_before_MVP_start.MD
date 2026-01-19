# IT MUST BE DONE BEFORE MVP START

**Document Status**: MVP Production Readiness Prerequisites
**Last Updated**: 2026-01-19
**Timeline**: 7-11 days to MVP launch
**Audience**: Development team, DevOps, Product

---

## Executive Summary

This document lists all tasks that **MUST** be completed before the Szybka Fucha MVP can launch with real backend integration (no developer mode). The MVP currently has ~95% backend code readiness and ~60% mobile code readiness, but is 0% production-ready due to missing external service configuration and mobile app hardening.

**Total Prerequisites**: 23 critical tasks organized in 6 phases
**Must-Have Tasks**: 19 (blockers for MVP launch)
**Nice-to-Have Tasks**: 6 (can be added post-launch)

---

## PHASE 1: BACKEND EXTERNAL SERVICE SETUP (Days 1-3)

### Why This Phase is Critical
The backend currently implements all services in **mock mode**, which means:
- Twilio SMS returns a fixed OTP `123456` instead of sending real SMS
- Stripe returns fake payment intents instead of real charges
- Firebase logs to console instead of sending notifications
- Onfido auto-approves verification after 5 seconds

**Without Phase 1 completion, the MVP cannot function with real users.**

---

### Task 1.1: Twilio SMS Configuration (Phone Authentication)

**What it does**: Enables phone-based user registration via SMS OTP
**Current Status**: Mock mode - fixed OTP `123456`
**Required For**: User authentication (AUTH-03, AUTH-04 in PRD)
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 4.1 Authentication Module

#### Example Flow (Chat Integration - Phone Registration)
```
User Flow:
1. User enters phone number in mobile app
2. App calls: POST /api/v1/auth/phone/request-otp
3. Backend sends SMS via Twilio with random 6-digit OTP
4. User receives SMS: "Twój kod: 459283"
5. User enters code in app
6. App calls: POST /api/v1/auth/phone/verify with code
7. Backend validates code against Twilio records
8. User authenticated → JWT token returned → Can chat and post tasks

Mock Mode (Current):
- User enters phone number
- Backend ignores Twilio
- Backend returns fixed OTP "123456"
- User can only use OTP "123456" to login
```

#### Setup Steps

**Step 1: Create Twilio Account**
1. Visit https://www.twilio.com/
2. Sign up for free trial account
3. Verify email address
4. Complete onboarding

**Step 2: Purchase Polish Phone Number**
1. Log into Twilio Console
2. Navigate to "Phone Numbers" → "Buy a Number"
3. Select country: Poland (+48)
4. Select number capabilities: SMS (must have SMS capability)
5. Purchase number (cost: ~$1/month)
6. Example: +48123456789

**Step 3: Get API Credentials**
1. Log into Twilio Console
2. Go to "Account" menu
3. Note down:
   - Account SID: `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Auth Token: `your_auth_token_here`
   - Phone Number: `+48123456789`

**Step 4: Update Backend Environment**
```bash
# Edit backend/.env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+48123456789
```

**Step 5: Verify Implementation**
1. Start backend: `cd backend && npm run start:dev`
2. Check logs for: `"Twilio SMS service initialized"` (or similar)
3. Test with Postman:
   ```
   POST http://localhost:3000/api/v1/auth/phone/request-otp
   Body: { "phoneNumber": "+48123456789" }
   ```
4. Check your phone - should receive real SMS with OTP code

**Reference Code**:
- File: `backend/src/auth/auth.service.ts` lines 37-48
  ```typescript
  async requestOTP(phoneNumber: string): Promise<{ success: boolean }> {
    // Line 37-48: Checks if TWILIO_ACCOUNT_SID exists
    // If missing → uses mock OTP "123456"
    // If exists → sends real SMS via Twilio
  }
  ```
- File: `backend/src/auth/auth.service.ts` lines 253-272
  ```typescript
  // Twilio SMS sending logic
  ```

---

### Task 1.2: Stripe Payment Configuration (Payments & Contractor Payouts)

**What it does**: Enables payment processing for tasks and contractor earnings
**Current Status**: Mock mode - returns fake payment intents
**Required For**: Payment processing (PAY-01 through PAY-07 in PRD)
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 4.4 Payment Module

#### Example Flow (Chat Integration - Payment Processing)
```
Client Payment Flow:
1. Client creates task for "Help organize closet" - Price: 100 PLN
2. App calls: POST /api/v1/payments/create-payment-intent
3. Backend creates Stripe payment intent for 100 PLN
4. Client enters credit card details
5. Payment authorized → Contractor accepts task
6. Contractor completes task → Client confirms
7. Backend calls: POST /api/v1/payments/capture-payment
8. Payment captured → Released to contractor (83 PLN)
9. Platform keeps 17 PLN commission

Mock Mode (Current):
- Payment intent always created with fake ID
- No real charge attempted
- No contractor payout happens
```

#### Setup Steps

**Step 1: Create Stripe Account**
1. Visit https://stripe.com/
2. Sign up for free account
3. Verify email and set up business details
4. Complete identity verification

**Step 2: Enable Stripe Connect (Contractor Accounts)**
1. Log into Stripe Dashboard
2. Go to "Settings" → "Connect Settings"
3. Enable Connect for your platform (Stripe needs platform setup)
4. Configure branding and terms

**Step 3: Configure Webhook**
1. Go to "Developers" → "Webhooks"
2. Create webhook endpoint
3. Webhook URL: `https://api.szybkafucha.pl/api/v1/payments/webhook`
4. Events to receive: `payment_intent.succeeded`, `payment_intent.payment_failed`

**Step 4: Get API Credentials**
1. Go to "Developers" → "API Keys"
2. Note down:
   - Publishable Key: `pk_test_xxxxxxxxxxxxxxxxxxxx` (or `pk_live_...` for production)
   - Secret Key: `sk_test_xxxxxxxxxxxxxxxxxxxx` (or `sk_live_...` for production)
3. Copy Webhook Secret from webhook configuration

**Step 5: Update Backend Environment**
```bash
# Edit backend/.env
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxx
STRIPE_PLATFORM_FEE_PERCENT=17
```

**Step 6: Verify Implementation**
1. Start backend: `cd backend && npm run start:dev`
2. Test with Postman:
   ```
   POST http://localhost:3000/api/v1/payments/create-payment-intent
   Body: {
     "amount": 100,
     "currency": "pln",
     "taskId": "task-123"
   }
   Response should have: "client_secret": "pi_test_xxxxxxxxxxxx_secret_xxxxxxx"
   ```
3. Use Stripe test card: `4242 4242 4242 4242` (valid test card)

**Reference Code**:
- File: `backend/src/payments/payments.service.ts` lines 41-48
  ```typescript
  // Mock check: if STRIPE_SECRET_KEY missing, returns fake payment intent
  // If exists: creates real payment intent via Stripe API
  ```

---

### Task 1.3: Firebase Cloud Messaging Configuration (Push Notifications)

**What it does**: Enables push notifications for tasks, messages, and status updates
**Current Status**: Mock mode - logs to console instead of sending
**Required For**: Notifications (RT-04 in PRD)
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 4.5 Real-time Module

#### Example Flow (Chat Integration - Incoming Message Notification)
```
When Contractor Sends Message to Client:
1. Contractor types message in chat: "I'll be there in 5 minutes"
2. App calls: POST /api/v1/messages/send
3. Backend broadcasts via WebSocket (real-time)
4. Backend also sends push notification:
   - Notification: "New message from John: 'I'll be there in 5 minutes'"
   - Sends to client's phone using Firebase Cloud Messaging (FCM)
5. Client's phone receives notification even if app is closed
6. Client taps notification → App opens chat screen

Mock Mode (Current):
- Notification just logged to backend console
- Client's phone receives nothing
- Client must have app open to see messages
```

#### Setup Steps

**Step 1: Create Firebase Project**
1. Visit https://console.firebase.google.com/
2. Click "Create project"
3. Project name: "Szybka Fucha"
4. Accept analytics terms
5. Create project (takes 1-2 minutes)

**Step 2: Enable Cloud Messaging**
1. Open Firebase project
2. Go to "Project Settings" (gear icon)
3. Go to "Service Accounts" tab
4. Click "Generate New Private Key"
5. Save JSON file securely

**Step 3: Extract Credentials from JSON**
Open the downloaded JSON file and extract:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "...",
  "token_uri": "...",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
}
```

**Step 4: Update Backend Environment**
```bash
# Edit backend/.env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE_WITH_\n_ESCAPED_NEWLINES\n-----END PRIVATE KEY-----\n"
```

**Step 5: Verify Implementation**
1. Start backend: `cd backend && npm run start:dev`
2. Check logs for: Firebase initialization message
3. Backend will now send real notifications to mobile apps

**Reference Code**:
- File: `backend/src/notifications/notifications.service.ts` lines 33-44
  ```typescript
  // Mock check: if FIREBASE_PROJECT_ID missing, logs to console
  // If exists: sends real notification via Firebase Admin SDK
  ```

---

### Task 1.4: JWT Secret Configuration (Security)

**What it does**: Secures user authentication tokens
**Current Status**: Weak development secret
**Required For**: Session security
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 5.3 Database Schema

#### Why This Matters
```
Weak JWT Secret (Current - UNSAFE):
- Can be easily brute-forced
- Attackers could forge fake authentication tokens
- Users' sessions could be hijacked

Strong JWT Secret (Production - SECURE):
- 48+ random characters
- Cannot be brute-forced
- Only valid tokens are those signed by backend
```

#### Setup Steps

**Step 1: Generate Strong Secret**
```bash
# Generate 48-character random secret
openssl rand -base64 48
# Output: eXample+outputOf/random+secretHere==...
```

**Step 2: Update Backend Environment**
```bash
# Edit backend/.env
JWT_SECRET=<PASTE_GENERATED_SECRET_HERE>
JWT_EXPIRES_IN=30d
```

**Step 3: Verify Implementation**
1. Start backend: `cd backend && npm run start:dev`
2. JWT will now use strong secret for all token generation

---

### Task 1.5: PostgreSQL Database Configuration (Data Persistence)

**What it does**: Stores all application data (users, tasks, messages, payments)
**Current Status**: Configured for localhost development
**Required For**: Data persistence
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 5.3 Database Schema

#### Setup Steps

**Step 1: Provision PostgreSQL 15+ with PostGIS**

Choose one of these providers:
- **AWS RDS** (if using AWS ECS)
- **DigitalOcean Managed Database**
- **Azure Database for PostgreSQL**
- **Render.com PostgreSQL**
- **Railway.app PostgreSQL**

Common settings to request:
- PostgreSQL version: 15+
- Region: Closest to your users (EU recommended for Poland)
- Extensions: PostGIS (required for location queries)
- Backup: Daily automated backups

**Step 2: Create Database and User**
```sql
-- Connect to PostgreSQL and run:
CREATE DATABASE szybkafucha_prod;
CREATE USER szybkafucha_prod WITH PASSWORD '<STRONG_PASSWORD>';
ALTER ROLE szybkafucha_prod CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE szybkafucha_prod TO szybkafucha_prod;

-- Enable PostGIS extension
\c szybkafucha_prod
CREATE EXTENSION IF NOT EXISTS postgis;
```

**Step 3: Update Backend Environment**
```bash
# Edit backend/.env
DATABASE_HOST=your-db-host.com
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha_prod
DATABASE_PASSWORD=<STRONG_PASSWORD_HERE>
DATABASE_NAME=szybkafucha_prod
```

**Step 4: CRITICAL - Disable TypeORM Synchronization**
```typescript
// Edit backend/src/app.module.ts
// Find TypeOrmModule.forRoot() configuration
TypeOrmModule.forRoot({
  // ... other config
  synchronize: false,  // CRITICAL: Must be false in production
})
```

**Step 5: Verify Connection**
1. Start backend: `cd backend && npm run start:dev`
2. Check logs for: `"TypeORM connection initialized"` (or similar)
3. Verify in database: Should see tables created (users, tasks, messages, payments, etc.)

---

### Task 1.6: Redis Configuration (Caching & Sessions)

**What it does**: Stores OTP codes, user sessions, and cached data
**Current Status**: Configured for localhost without password
**Required For**: OTP storage, rate limiting
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 5.1 System Overview

#### Setup Steps

**Step 1: Provision Redis 7+**

Choose one of these providers:
- **AWS ElastiCache**
- **DigitalOcean Redis**
- **Azure Cache for Redis**
- **Redis Cloud**
- **Upstash**

Common settings to request:
- Redis version: 7+
- Memory: 1GB minimum
- Password: Required (not optional)
- Region: Same as PostgreSQL

**Step 2: Update Backend Environment**
```bash
# Edit backend/.env
REDIS_HOST=your-redis-host.com
REDIS_PORT=6379
REDIS_PASSWORD=<STRONG_PASSWORD_HERE>
```

**Step 3: Verify Connection**
1. Start backend: `cd backend && npm run start:dev`
2. Check logs for: Redis connection message
3. Test OTP storage: Request OTP via `/auth/phone/request-otp` - should be stored in Redis

---

## PHASE 2: MOBILE APP PRODUCTION CONFIGURATION (Days 1-2, Parallel with Phase 1)

### Why This Phase is Critical
The mobile app currently has **two hardcoded development URLs** that must be changed to production URLs before it can communicate with the real backend. Additionally, **developer mode must be disabled** to test real authentication flows.

---

### Task 2.1: API Base URL Configuration

**What it does**: Tells mobile app where to find the backend API
**Current Status**: Hardcoded to `http://localhost:3000/api/v1`
**Required For**: All API communication
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 5.4 API Endpoints

#### Setup Steps

**Step 1: Edit API Configuration**
```dart
// File: mobile/lib/core/api/api_config.dart
// Line 5: DISABLE dev mode
static const bool devModeEnabled = false;  // Change from: true

// Line 17: Change to production URL
static const String baseUrl = 'https://api.szybkafucha.pl/api/v1';  // Change from: 'http://localhost:3000/api/v1'
```

**Step 2: Rebuild Mobile App**
```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

**Step 3: Verify Configuration**
- Open mobile app
- App should now attempt to connect to production API
- If production backend is not yet running, app will show connection errors (expected)

**Reference Code**:
- File: `mobile/lib/core/api/api_config.dart` lines 5, 17

---

### Task 2.2: WebSocket URL Configuration

**What it does**: Tells mobile app where to find the real-time WebSocket server
**Current Status**: Hardcoded to `ws://localhost:3000`
**Required For**: Chat, location tracking, status updates
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 4.5 Real-time Module

#### Example Flow (Chat Integration - Real-time Message Delivery)
```
With Dev Mode Enabled (Current):
1. Contractor types message
2. WebSocket connects to localhost:3000 (doesn't exist if not running locally)
3. App simulates incoming message after 5-second delay
4. Message appears in chat (but not real - from other user's perspective)

With Dev Mode Disabled (Production):
1. Contractor types message
2. WebSocket connects to wss://api.szybkafucha.pl
3. Message sent to real backend via WebSocket
4. Backend broadcasts to all users in task room
5. Client's app receives real message instantly
6. Both users see conversation synchronized
```

#### Setup Steps

**Step 1: Edit WebSocket Configuration**
```dart
// File: mobile/lib/core/config/websocket_config.dart
// Line 9: Change to production WebSocket URL
static const String webSocketUrl = 'wss://api.szybkafucha.pl';  // Change from: 'ws://localhost:3000'

// Line 52: DISABLE dev mode
static const bool devModeEnabled = false;  // Change from: true
```

**Step 2: Rebuild Mobile App**
```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

**Step 3: Verify Configuration**
- Open mobile app
- Chat screen should now use real WebSocket connection
- Messages will synchronize in real-time with backend

**Reference Code**:
- File: `mobile/lib/core/config/websocket_config.dart` lines 9, 52

---

### Task 2.3: Google Sign-In Configuration (Phone Registration Alternative)

**What it does**: Allows users to register and login via Google account
**Current Status**: No client IDs configured
**Required For**: OAuth authentication (AUTH-01 in PRD)
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 4.1 Authentication Module

#### Example Flow (Chat Integration - User Registration via Google)
```
User Registration Flow:
1. New user opens app
2. Taps "Sign in with Google"
3. Browser opens Google login
4. User enters Google email and password
5. User taps "Allow" to give app permission to email/profile
6. App receives ID token from Google
7. App sends token to backend: POST /api/v1/auth/google
8. Backend verifies token with Google
9. User authenticated → JWT token returned
10. User can now post tasks and chat
```

#### Setup Steps - iOS

**Part A: Google Cloud Console Setup**
1. Visit https://console.cloud.google.com/
2. Create new project or select existing
3. Enable Google Sign-In API:
   - Search for "Google+ API"
   - Click "Enable"
4. Create OAuth 2.0 credentials:
   - Go to "Credentials" in left menu
   - Click "Create Credentials" → "OAuth 2.0 Client ID"
   - Application type: "iOS"
   - Bundle ID: `pl.szybkafucha.mobile`
   - Copy the Client ID

**Part B: iOS Configuration**
1. Open Xcode: `mobile/ios/Runner.xcworkspace`
2. Select Runner project
3. Edit `Info.plist` in Runner target
4. Add URL scheme for Google Sign-In:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   <key>GIDClientID</key>
   <string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
   ```
5. Replace `YOUR_IOS_CLIENT_ID` with your actual Client ID

#### Setup Steps - Android

**Part A: Get SHA-1 Certificate Fingerprint**
```bash
cd mobile/android
# For debug keystore (dev):
./gradlew signingReport

# Or manually:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Part B: Google Cloud Console Setup**
1. Create OAuth 2.0 credentials for Android:
   - Application type: "Android"
   - Package name: `pl.szybkafucha.mobile`
   - SHA-1 certificate fingerprint: (from step A)
   - Copy the Client ID

**Part C: Android Configuration**
1. Android automatically configured via `google-services.json` (see Task 2.5)

---

### Task 2.4: Apple Sign-In Configuration (Phone Registration Alternative)

**What it does**: Allows users to register and login via Apple account
**Current Status**: Implementation complete, needs Apple Developer setup
**Required For**: OAuth authentication (AUTH-02 in PRD)
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 4.1 Authentication Module

#### Example Flow (Chat Integration - User Registration via Apple)
```
Similar to Google Sign-In but using Apple ID
- User taps "Sign in with Apple"
- System shows Apple ID login dialog
- User authenticates with Face ID / Touch ID / Password
- App receives ID token from Apple
- Backend verifies token with Apple
- User authenticated → Can use app
```

#### Setup Steps

**Part A: Apple Developer Portal**
1. Visit https://developer.apple.com/
2. Go to "Certificates, Identifiers & Profiles"
3. Create App ID:
   - Type: App IDs
   - Bundle ID: `pl.szybkafucha.mobile`
4. Create Service ID: `pl.szybkafucha.mobile`
5. Configure "Sign in with Apple":
   - Email domain: `szybkafucha.pl`
   - Return URL: `https://api.szybkafucha.pl/api/v1/auth/apple/callback`
6. Create Key for "Sign in with Apple":
   - Save Key ID and Team ID securely

**Part B: iOS Configuration**
1. Open Xcode: `mobile/ios/Runner.xcworkspace`
2. Select Runner project
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Sign in with Apple" capability
6. Build app: `flutter build ios`

---

### Task 2.5: Firebase Configuration (Mobile)

**What it does**: Enables push notifications and Google Sign-In integration on mobile
**Current Status**: Configuration files missing
**Required For**: Push notifications, Google Sign-In
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 4.5 Real-time Module

#### Setup Steps - iOS

**Step 1: Create Firebase iOS App**
1. Open Firebase Console (same project from Task 1.3)
2. Go to "Project Settings" (gear icon)
3. Click "Add app" → Select iOS
4. Bundle ID: `pl.szybkafucha.mobile`
5. App nickname: "Szybka Fucha iOS"
6. Click "Register app"
7. Download `GoogleService-Info.plist`

**Step 2: Add to Xcode**
1. Open Xcode: `mobile/ios/Runner.xcworkspace`
2. Drag and drop `GoogleService-Info.plist` into Xcode
3. Check "Copy items if needed"
4. Select Runner target
5. Build app: `flutter build ios`

#### Setup Steps - Android

**Step 1: Create Firebase Android App**
1. Open Firebase Console (same project)
2. Go to "Project Settings"
3. Click "Add app" → Select Android
4. Package name: `pl.szybkafucha.mobile`
5. App nickname: "Szybka Fucha Android"
6. Upload `SHA-1 certificate fingerprint` (from Task 2.3)
7. Click "Register app"
8. Download `google-services.json`

**Step 2: Add to Android Project**
1. Copy `google-services.json` to: `mobile/android/app/`
2. Build app: `flutter build apk`

---

### Task 2.6: Android Release Signing (Google Play Store)

**What it does**: Signs app for Google Play Store release
**Current Status**: Using debug keystore (TODO comment)
**Required For**: Google Play Store release
**PRD Reference**: `tasks/prd-szybka-fucha.md` Section 6.1 Design System

#### Setup Steps

**Step 1: Generate Release Keystore**
```bash
cd mobile/android
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias szybkafucha
# Follow prompts to enter passwords and info
```

**Step 2: Create `key.properties` File**
```bash
# Create file: mobile/android/key.properties
# Content:
cat > key.properties << EOF
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=szybkafucha
storeFile=release-keystore.jks
EOF
```

**Step 3: Add to .gitignore**
```bash
# Edit mobile/.gitignore and add:
android/key.properties
android/release-keystore.jks
```

**Step 4: Update build.gradle.kts**
```kotlin
// File: mobile/android/app/build.gradle.kts
// Add BEFORE android block:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**Step 5: Build Signed Release APK**
```bash
cd mobile
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## PHASE 3: SPECIFIC INTEGRATION EXAMPLES

### Example 1: Phone Number Verification (SMS OTP)

**Requirement**: User can register via phone number with SMS OTP verification

**What happens step-by-step**:

```
1. USER ENTERS PHONE NUMBER
   Mobile App → TextField shows "+48"
   User types: "123456789"

2. REQUEST OTP
   Mobile App → POST /api/v1/auth/phone/request-otp
   Body: { "phoneNumber": "+48123456789" }

3. BACKEND VALIDATES
   Backend receives phone number
   Checks if phone not already registered
   Generates random 6-digit OTP (e.g., "459283")
   Stores OTP in Redis: key="otp:+48123456789" value="459283" (expires 10 min)

4. TWILIO SENDS SMS (REQUIRES TASK 1.1 COMPLETE)
   Backend calls Twilio API with:
   - To: "+48123456789"
   - From: "+48xxxxxxxxx" (your Polish Twilio number)
   - Body: "Kod weryfikacyjny Szybka Fucha: 459283"

5. USER RECEIVES SMS
   Phone buzzes with notification:
   "Kod weryfikacyjny Szybka Fucha: 459283"

6. USER ENTERS OTP IN APP
   User types "459283" in TextField
   Mobile App → POST /api/v1/auth/phone/verify
   Body: { "phoneNumber": "+48123456789", "otp": "459283" }

7. BACKEND VERIFIES
   Backend retrieves OTP from Redis
   Compares with user input
   If match:
     - Create User record
     - Generate JWT token
     - Return token to app
   If no match:
     - Return 401 error

8. APP STORES JWT
   Mobile app receives token
   Stores in secure storage
   Includes token in all future API requests
   User is authenticated

9. USER CAN NOW
   - Post tasks
   - Send messages (requires WebSocket connection)
   - Accept contractor jobs
   - Track contractor location
```

**Files Involved**:
- Mobile: `mobile/lib/features/auth/screens/phone_auth_screen.dart`
- Backend: `backend/src/auth/auth.service.ts` lines 37-48 (request), lines 253-272 (verify)
- Backend: `backend/src/auth/auth.controller.ts` (endpoints)
- Infrastructure: Twilio account with phone number (Task 1.1)

**Testing Steps**:
1. Complete Task 1.1 (Twilio setup)
2. Start backend: `npm run start:dev`
3. Open mobile app
4. Go to auth screen
5. Enter your real phone number
6. Wait for SMS
7. Enter OTP from SMS
8. Should be authenticated

---

### Example 2: Chat Integration (Real-time Messages)

**Requirement**: Users can send and receive real-time messages

**What happens step-by-step**:

```
USER 1 (CLIENT) SENDS MESSAGE:
1. Client posts task for "Help move furniture"
2. Contractor accepts task
3. Both users open chat screen
4. Client types: "I'll be home at 3pm"
5. Client taps Send button

MOBILE APP (CLIENT SIDE):
1. Creates Message object
2. Stores in local database (offline support)
3. Connects to WebSocket (requires Task 2.2 complete):
   - Namespace: /realtime
   - Room: task-{taskId}
   - Auth: JWT token in headers
4. Emits event: "message:send"
   {
     "taskId": "task-123",
     "content": "I'll be home at 3pm",
     "senderId": "user-client-1",
     "senderName": "Anna",
     "timestamp": "2026-01-19T14:30:00Z"
   }

BACKEND (SERVER SIDE):
1. Receives message event via WebSocket
2. Validates JWT token (user is authenticated)
3. Creates Message record in database
4. Changes message status: "pending" → "sent"
5. Broadcasts to all users in room: "message:received"
   {
     "messageId": "msg-456",
     "taskId": "task-123",
     "content": "I'll be home at 3pm",
     "senderId": "user-client-1",
     "senderName": "Anna",
     "status": "sent",
     "timestamp": "2026-01-19T14:30:00Z"
   }

USER 2 (CONTRACTOR) RECEIVES MESSAGE:
1. Contractor's app receives "message:received" event
2. Adds message to chat list in UI
3. Plays notification sound (if not in chat)
4. Contractor's app emits "message:read"
5. Backend updates message status: "sent" → "delivered" → "read"

PUSH NOTIFICATION (IF APP CLOSED):
1. Backend sends Firebase Cloud Messaging (requires Task 1.3 complete)
2. Sends to contractor's device token
3. Notification: "New message from Anna: 'I'll be home at 3pm'"
4. Contractor sees notification on home screen
5. Taps notification → App opens → Chat screen shows message
```

**Files Involved**:
- Mobile: `mobile/lib/features/chat/screens/chat_screen.dart`
- Mobile: `mobile/lib/features/chat/providers/chat_provider.dart`
- Mobile: `mobile/lib/core/config/websocket_config.dart` (WebSocket config)
- Backend: `backend/src/realtime/realtime.gateway.ts` (WebSocket server)
- Backend: `backend/src/messages/messages.service.ts` (message logic)
- Infrastructure: Firebase setup (Task 1.3), WebSocket configuration (Task 2.2)

**Testing Steps**:
1. Complete Tasks 1.3, 2.2 (Firebase, WebSocket URLs)
2. Start backend: `npm run start:dev`
3. Open mobile app as User 1
4. Create task
5. Open second mobile instance as User 2 (or use multiple devices)
6. User 2 accepts task
7. Both open chat
8. Send message from User 1
9. Should appear instantly on User 2 (if dev mode disabled)
10. Should see status change: pending → sent → delivered → read

---

### Example 3: Google Sign-In (OAuth)

**Requirement**: Users can register/login via Google account

**What happens step-by-step**:

```
USER TAPS "SIGN IN WITH GOOGLE":
1. Mobile app shows dialog
2. Redirects to Google Sign-In page

GOOGLE AUTHENTICATION:
1. User enters Google email (e.g., user@gmail.com)
2. User enters Google password
3. User grants permission to app:
   "Szybka Fucha wants to:
   - Access your email address
   - Access your profile information"
4. User taps "Allow"

GOOGLE RETURNS ID TOKEN:
1. Google generates ID token (signed JWT with user info)
2. Returns to mobile app

MOBILE APP SENDS TO BACKEND:
1. Mobile app receives ID token
2. Calls: POST /api/v1/auth/google
   Body: { "idToken": "eyJhbGc..." }

BACKEND VALIDATES TOKEN:
1. Backend receives ID token
2. Makes request to Google: "Is this token valid?"
3. Google verifies signature and returns:
   {
     "email": "user@gmail.com",
     "name": "John Doe",
     "picture": "https://...",
     "sub": "1234567890" (Google user ID)
   }
4. Backend checks: Is user with this email already registered?
   - If YES: Return existing JWT token
   - If NO: Create new User record, return JWT token

MOBILE APP NOW AUTHENTICATED:
1. Receives JWT token from backend
2. Stores in secure storage
3. User can access all features
```

**Files Involved**:
- Mobile: `mobile/lib/core/services/google_sign_in_service.dart`
- Backend: `backend/src/auth/auth.service.ts` (Google verification logic)
- Backend: `backend/src/auth/auth.controller.ts` (POST /auth/google endpoint)
- Infrastructure: Google OAuth credentials (Task 2.3)

**Testing Steps**:
1. Complete Task 2.3 (Google Sign-In setup)
2. Start backend: `npm run start:dev`
3. Open mobile app
4. Tap "Sign in with Google"
5. Select Google account (or log in)
6. Grant permission
7. Should be authenticated and in main app

---

### Example 4: Push Notifications (New Task)

**Requirement**: Contractor receives notification when new task matches their profile

**What happens step-by-step**:

```
CLIENT POSTS NEW TASK:
1. Client: "I need help cleaning apartment - 200 PLN"
2. Client selects services: "Cleaning"
3. Client selects location: "Warsaw, Centrum"
4. Client submits task

BACKEND PROCESSES TASK:
1. Task created in database
2. Backend searches contractors with:
   - Service = "Cleaning"
   - Location within 5km of task
   - Status = "Available"
3. Finds matching contractors: Anna, Piotr, Magda

FIREBASE CLOUD MESSAGING:
1. For each matching contractor:
   - Backend retrieves device token from User record
   - Sends push notification via Firebase (requires Task 1.3)
   - Notification:
     {
       "title": "Nowe zlecenie!",
       "body": "Sprzątanie - 200 PLN, Centrum Warszawy",
       "taskId": "task-123"
     }

CONTRACTOR'S PHONE (IF APP CLOSED):
1. Receives notification: "Nowe zlecenie! Sprzątanie - 200 PLN..."
2. Phone vibrates/sounds
3. Contractor sees notification on home screen
4. Taps notification

MOBILE APP:
1. Receives notification tap
2. Deep links to task details screen
3. Shows: "Sprzątanie - 200 PLN, Centrum Warszawy, Klient: Anna"
4. Contractor can tap "Accept" to take the task

IF APP ALREADY OPEN:
1. Notification arrives via WebSocket (real-time)
2. In-app banner shows: "Nowe zlecenie!"
3. Tasks list auto-refreshes
4. New task appears at top
5. Contractor taps to view details
6. Taps "Accept"
```

**Files Involved**:
- Backend: `backend/src/notifications/notifications.service.ts` (notification sending)
- Backend: `backend/src/tasks/tasks.service.ts` (matching logic)
- Mobile: `mobile/lib/core/providers/websocket_provider.dart` (notification reception)
- Infrastructure: Firebase Cloud Messaging (Task 1.3)

**Testing Steps**:
1. Complete Task 1.3 (Firebase setup)
2. Have mobile app open on device 1 (as Contractor)
3. Post task from device 2 (as Client)
4. Close device 1 app
5. Post matching task from device 2
6. Device 1 should receive notification
7. Tap notification → Should open task details

---

## PHASE 4: TESTING & VALIDATION (Days 3-5)

### Task 4.1: Backend Integration Testing

**What it tests**: All external services work correctly with production credentials

#### Test 1: Twilio SMS Delivery
```bash
# Start backend with production Twilio credentials
npm run start:dev

# Test with Postman:
POST http://localhost:3000/api/v1/auth/phone/request-otp
Body: { "phoneNumber": "+48123456789" }  # Use your real phone number

# Expected:
- Response: { "success": true }
- Your phone: Receives SMS with OTP code
```

#### Test 2: Stripe Payment Processing
```bash
POST http://localhost:3000/api/v1/payments/create-payment-intent
Body: {
  "amount": 10000,  # 100.00 PLN in cents
  "currency": "pln",
  "taskId": "task-123"
}

# Expected:
- Response includes "client_secret": "pi_test_xxx_secret_xxx"
- Can use Stripe test card: 4242 4242 4242 4242
```

#### Test 3: Firebase Notifications
```typescript
// Backend sends notification via Stripe webhook
// Contractor should receive push notification on phone
// Check Firebase Console: Logs show notification delivery
```

#### Test 4: WebSocket Connection
```bash
# Connect to WebSocket from mobile app or Postman
ws://localhost:3000/realtime
# With JWT token in headers

# Should connect successfully and receive location/message events
```

---

### Task 4.2: Mobile End-to-End Testing

**Registration Flow**:
- [ ] Phone OTP registration works
- [ ] Google Sign-In works
- [ ] Apple Sign-In works (iOS only)
- [ ] JWT token stored and persisted

**Task Creation Flow**:
- [ ] Create task with all 6 categories
- [ ] Select location on map
- [ ] Set price
- [ ] Task appears in contractor list

**Payment Flow**:
- [ ] Enter credit card details
- [ ] Payment processed successfully
- [ ] Contractor can accept task

**Chat Flow**:
- [ ] Two users can open chat
- [ ] Send message appears instantly
- [ ] Message status changes: pending → sent → delivered → read
- [ ] Can send messages offline and they queue

**Location Tracking Flow**:
- [ ] Contractor enables location sharing
- [ ] Client sees real-time location on map
- [ ] Distance and ETA calculated correctly

---

## PHASE 5: DEPLOYMENT & LAUNCH (Days 6-8)

### Task 5.1: Backend Deployment

**Choose Deployment Platform**:
- AWS ECS (recommended in PRD)
- Heroku with add-ons
- Railway.app
- DigitalOcean App Platform
- Render.com

**Deployment Steps**:
1. Deploy backend with production environment variables
2. Configure domain: `api.szybkafucha.pl`
3. Set up SSL certificate (Let's Encrypt, free)
4. Run health check: `GET /health`

---

### Task 5.2: Mobile App Release

**iOS App Store**:
1. Create App Store Connect account
2. Create app listing with screenshots and description
3. Upload build via Xcode or Transporter
4. Wait for Apple review (24-48 hours)

**Android Google Play Store**:
1. Create Google Play Developer account ($25 one-time)
2. Create app listing with screenshots and feature graphics
3. Upload signed APK
4. Launch to production

---

## PHASE 6: MONITORING & SUPPORT (Ongoing)

### Task 6.1: Error Tracking

Set up **Sentry** for production error tracking:
```bash
# Install in backend
npm install @sentry/node

# Configure in backend/src/main.ts
import * as Sentry from '@sentry/node';
Sentry.init({
  dsn: 'your_sentry_dsn_here',
  environment: 'production',
});
```

### Task 6.2: Performance Monitoring

Recommended: New Relic, DataDog, or similar

---

## PHASE 7: SOFT LAUNCH (Days 9-11)

### Soft Launch Checklist

- [ ] Launch to 50-100 users (week 1)
- [ ] Monitor error rates in Sentry
- [ ] Check WebSocket stability
- [ ] Verify payment success rate > 95%
- [ ] Monitor SMS delivery rate > 98%
- [ ] Collect user feedback
- [ ] Fix critical bugs immediately
- [ ] Gradually expand to more users (week 2)

---

## QUICK REFERENCE: Environment Variables

### Backend (.env)

```env
# Server
NODE_ENV=production
PORT=3000
API_PREFIX=api/v1

# Database
DATABASE_HOST=your-db-host.com
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha_prod
DATABASE_PASSWORD=<STRONG_PASSWORD>
DATABASE_NAME=szybkafucha_prod

# Redis
REDIS_HOST=your-redis-host.com
REDIS_PORT=6379
REDIS_PASSWORD=<STRONG_PASSWORD>

# JWT
JWT_SECRET=<48_CHARACTER_RANDOM_STRING>
JWT_EXPIRES_IN=30d

# Twilio (SMS)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+48123456789

# Stripe (Payments)
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxx
STRIPE_PLATFORM_FEE_PERCENT=17

# Firebase (Notifications)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Onfido (KYC - Optional for MVP)
ONFIDO_API_TOKEN=api_live_xxxxxxxxxxxxxxxxxxxxxxxx
```

### Mobile Configuration

**api_config.dart**:
```dart
devModeEnabled = false
baseUrl = 'https://api.szybkafucha.pl/api/v1'
```

**websocket_config.dart**:
```dart
devModeEnabled = false
webSocketUrl = 'wss://api.szybkafucha.pl'
```

---

## SUMMARY: WHAT MUST BE DONE BEFORE MVP START

### Critical Tasks (Must Complete):

**Backend Setup (3 days)**:
1. ✅ Twilio SMS account + credentials
2. ✅ Stripe account + API keys + Stripe Connect
3. ✅ Firebase project + service account
4. ✅ JWT secret generation
5. ✅ PostgreSQL database provisioning
6. ✅ Redis instance provisioning

**Mobile Configuration (1-2 days)**:
1. ✅ Change API URL from localhost
2. ✅ Change WebSocket URL from localhost
3. ✅ Disable dev mode flags
4. ✅ Google Sign-In credentials + config
5. ✅ Apple Sign-In setup
6. ✅ Firebase config files (google-services.json, GoogleService-Info.plist)
7. ✅ Android release signing setup

**Testing (2-3 days)**:
1. ✅ Backend integration tests with real services
2. ✅ Mobile E2E tests through all user flows
3. ✅ Payment testing with real Stripe test cards

**Deployment (2-3 days)**:
1. ✅ Choose deployment platform
2. ✅ Deploy backend to production
3. ✅ Set up SSL certificates
4. ✅ Deploy mobile apps to app stores

**Total Time**: 7-11 days

---

## NEXT STEPS

1. **Start with Phase 1** (Backend setup) immediately - can be parallelized
2. **Simultaneously start Phase 2** (Mobile configuration) - quick 1-2 day task
3. **Phase 3-7** follow sequentially as dependencies complete
4. **Keep team informed** of external service setup progress

**Question for Product/PM**: Do we have external service budget approved (Twilio, Stripe, Firebase)?

---

**Document Version**: 1.0
**Date Created**: 2026-01-19
**Status**: Ready for Implementation
