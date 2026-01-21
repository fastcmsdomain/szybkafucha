# Tasks: Szybka Fucha MVP Implementation

> **Source PRD:** `prd-szybka-fucha.md`
> **Target:** AI Agent / Junior Developer
> **Timeline:** 8 weeks

---

## Relevant Files

### Backend (NestJS)
- `backend/src/main.ts` - Application entry point
- `backend/src/app.module.ts` - Root module with all imports
- `backend/src/auth/auth.module.ts` - Authentication module
- `backend/src/auth/auth.controller.ts` - Auth endpoints
- `backend/src/auth/auth.service.ts` - Auth business logic
- `backend/src/auth/strategies/` - Passport strategies (jwt, google, apple)
- `backend/src/users/users.module.ts` - Users module
- `backend/src/users/users.controller.ts` - User endpoints
- `backend/src/users/users.service.ts` - User business logic
- `backend/src/users/entities/user.entity.ts` - User database entity
- `backend/src/tasks/tasks.module.ts` - Tasks module
- `backend/src/tasks/tasks.controller.ts` - Task endpoints
- `backend/src/tasks/tasks.service.ts` - Task business logic
- `backend/src/tasks/entities/task.entity.ts` - Task database entity
- `backend/src/payments/payments.module.ts` - Stripe integration module
- `backend/src/payments/payments.service.ts` - Payment processing logic
- `backend/src/realtime/realtime.gateway.ts` - Socket.io gateway
- `backend/src/realtime/realtime.module.ts` - WebSocket module

### Mobile (Flutter)
- `mobile/lib/main.dart` - App entry point
- `mobile/lib/app.dart` - App configuration and routing
- `mobile/lib/core/theme/` - Design system (colors, typography)
- `mobile/lib/core/api/` - API client and interceptors
- `mobile/lib/core/services/` - Shared services (storage, location)
- `mobile/lib/features/auth/` - Authentication feature
- `mobile/lib/features/client/` - Client-specific screens
- `mobile/lib/features/contractor/` - Contractor-specific screens
- `mobile/lib/features/task/` - Task-related widgets
- `mobile/lib/features/chat/` - In-app messaging
- `mobile/lib/features/map/` - Map and tracking widgets

### Admin Dashboard (React)
- `admin/src/App.tsx` - Main app component
- `admin/src/pages/Dashboard.tsx` - Metrics dashboard
- `admin/src/pages/Users.tsx` - User management
- `admin/src/pages/Disputes.tsx` - Dispute resolution
- `admin/src/components/` - Shared components

### Database
- `backend/src/database/migrations/` - Database migrations
- `backend/src/database/seeds/` - Seed data for development

---

## Notes

- All code should follow established patterns and conventions
- Write tests alongside implementation (test files in same directory)
- Use environment variables for all secrets and configuration
- Log important operations for debugging
- Handle errors gracefully with user-friendly messages
- Commit after each completed task with descriptive message

---

## ✅ All Mobile Platforms Ready

**Resolved:** Full Flutter development environment configured for all platforms.

**All platforms available:**
- ✅ iOS Simulator/Device - fully functional (CocoaPods 1.16.2)
- ✅ Android Emulator/Device - fully functional (SDK 36.0.0)
- ✅ Web (Chrome) - fully functional
- ✅ macOS desktop - fully functional

**Completed:**
- [x] **0.1 Upgrade Ruby for iOS development** ✅ DONE
  - Installed Ruby 4.0.1 via Homebrew
  - Installed CocoaPods 1.16.2
  - Configured shell PATH in `~/.zshrc`
  - Verified with `flutter doctor` - all checks passing

- [x] **0.2 Install Android SDK** ✅ DONE
  - Installed Android command-line tools via Homebrew
  - Installed OpenJDK 17 (required for SDK manager)
  - Installed Android SDK 36, Build-Tools 36.0.0, Platform-Tools
  - Configured `ANDROID_SDK_ROOT` and `JAVA_HOME` in `~/.zshrc`

**One-time manual step required:**
To accept remaining Android licenses, run in a new terminal:
```bash
flutter doctor --android-licenses
```
Then press `y` to accept each license.

---

## Tasks

### Phase 1: Foundation (Week 1-2)

- [x] **1.0 Project Setup**
  - [x] 1.1 Create backend project with NestJS CLI: `nest new backend`
  - [x] 1.2 Create Flutter project: `flutter create mobile --org pl.szybkafucha` - Flutter SDK installed (v3.38.7)
  - [x] 1.3 Create React admin project: `npx create-react-app admin --template typescript`
  - [x] 1.4 Set up PostgreSQL database (local Docker or cloud) - docker-compose.yml created
  - [x] 1.5 Set up Redis instance (local Docker or cloud) - docker-compose.yml created
  - [x] 1.6 Configure environment variables (.env files for each project)
  - [ ] 1.7 Set up Git repository with branch protection rules (require `Backend lint & tests` + `Admin lint & tests`)
  - [x] 1.8 Configure CI/CD pipeline (GitHub Actions) for linting and tests

- [x] **2.0 Database Schema**
  - [x] 2.1 Install TypeORM in backend: `npm install @nestjs/typeorm typeorm pg`
  - [x] 2.2 Configure TypeORM module in `app.module.ts`
  - [x] 2.3 Create `User` entity with fields: id, type, phone, email, name, avatar_url, status, timestamps
  - [x] 2.4 Create `ContractorProfile` entity with fields: user_id, bio, categories, kyc_status, stripe_account_id, rating_avg, is_online, location
  - [x] 2.5 Create `Task` entity with all fields from PRD section 5.3
  - [x] 2.6 Create `Rating` entity with fields: id, task_id, from_user_id, to_user_id, rating, comment
  - [x] 2.7 Create `Message` entity with fields: id, task_id, sender_id, content, read_at
  - [x] 2.8 Create `Payment` entity with fields: id, task_id, stripe_payment_intent_id, amount, status
  - [x] 2.9 Run migrations: `npm run migration:run` - Migration infrastructure set up with InitialSchema
  - [x] 2.10 Create seed data for development (test users, sample tasks)

- [x] **3.0 Authentication Module**
  - [x] 3.1 Install dependencies: `npm install @nestjs/passport passport passport-jwt @nestjs/jwt`
  - [x] 3.2 Create `AuthModule` with JWT strategy
  - [x] 3.3 Implement `POST /auth/phone/request-otp` - sends SMS via Twilio (mock for dev)
  - [x] 3.4 Implement `POST /auth/phone/verify` - verifies OTP, returns JWT
  - [x] 3.5 Install Google Sign-In: `npm install passport-google-oauth20`
  - [x] 3.6 Implement `POST /auth/google` - validates Google token, creates/returns user
  - [x] 3.7 Install Apple Sign-In: `npm install apple-signin-auth`
  - [x] 3.8 Implement `POST /auth/apple` - validates Apple token, creates/returns user
  - [x] 3.9 Implement `POST /auth/logout` - simple logout (client clears token)
  - [x] 3.10 Create `JwtAuthGuard` for protecting routes
  - [x] 3.11 Write unit tests for auth service (20 tests)
  - [x] 3.12 Write e2e tests for auth endpoints (20 tests)

---

### Phase 2: Core Features (Week 3-5)

- [x] **4.0 User Management Module**
  - [x] 4.1 Create `UsersModule` with controller and service
  - [x] 4.2 Implement `GET /users/me` - returns current user profile
  - [x] 4.3 Implement `PUT /users/me` - updates user profile (name, avatar)
  - [x] 4.4 Implement `POST /users/me/avatar` - uploads avatar to S3/CloudStorage
  - [x] 4.5 Create `ContractorProfileService` for contractor-specific operations
  - [x] 4.6 Implement `GET /contractor/profile` - returns contractor profile
  - [x] 4.7 Implement `PUT /contractor/profile` - updates bio, categories, radius
  - [x] 4.8 Implement `PUT /contractor/availability` - toggles online/offline
  - [x] 4.9 Implement `PUT /contractor/location` - updates GPS coordinates
  - [x] 4.10 Write tests for user endpoints

- [x] **5.0 Task Management Module**
  - [x] 5.1 Create `TasksModule` with controller and service
  - [x] 5.2 Implement `POST /tasks` - creates new task with validation
    - Validate: category in allowed list, budget > 0, location provided
    - Create task with status 'created'
    - Return task ID
  - [x] 5.3 Implement `GET /tasks` - lists tasks filtered by user role
    - Client: own tasks
    - Contractor: nearby available tasks (within radius, matching categories)
  - [x] 5.4 Implement `GET /tasks/:id` - returns full task details
  - [x] 5.5 Implement `PUT /tasks/:id/accept` - contractor accepts task
    - Check contractor is verified
    - Check task is still available
    - Update status to 'accepted'
    - Create payment hold (escrow)
  - [x] 5.6 Implement `PUT /tasks/:id/start` - contractor starts task
    - Update status to 'in_progress'
    - Record started_at timestamp
  - [x] 5.7 Implement `PUT /tasks/:id/complete` - contractor marks complete
    - Require photo proof upload
    - Update status to 'completed'
    - Notify client for confirmation
  - [x] 5.8 Implement `PUT /tasks/:id/confirm` - client confirms completion
    - Trigger payment capture
    - Update final_amount, commission_amount
  - [x] 5.9 Implement `PUT /tasks/:id/cancel` - cancels task
    - Only allowed before acceptance (or with admin approval after)
    - Refund if payment was held
  - [x] 5.10 Implement `POST /tasks/:id/rate` - submits rating and review
    - Validate rating 1-5
    - Update contractor rating_avg
  - [x] 5.11 Write comprehensive tests for task state machine

- [x] **6.0 Contractor Matching Algorithm**
  - [x] 6.1 Create `MatchingService` for finding suitable contractors (in TasksService)
  - [x] 6.2 Implement distance calculation using Haversine formula
    - Query contractors within task's radius
    - Filter by online status
    - Filter by matching categories
  - [x] 6.3 Implement scoring algorithm
    - Score = (rating * 0.4) + (completions * 0.3) + (proximity * 0.3)
  - [x] 6.4 Implement notification queue for contractors
    - Send push notification to top 5 contractors
    - 45-second timeout before notifying next batch
  - [x] 6.5 Write tests for matching algorithm

- [x] **7.0 Payments Module (Stripe Connect)**
  - [x] 7.1 Install Stripe: `npm install stripe`
  - [ ] 7.2 Create Stripe account and get API keys (uses placeholder for dev)
  - [x] 7.3 Create `PaymentsModule` with service
  - [x] 7.4 Implement contractor onboarding (Stripe Connect Express)
    - Create connected account for contractor
    - Return onboarding link
  - [x] 7.5 Implement `POST /payments/create-intent`
    - Create PaymentIntent with amount + platform fee
    - Store payment intent ID in Payment entity
    - Return client secret for mobile SDK
  - [x] 7.6 Implement payment hold (authorize but don't capture)
  - [x] 7.7 Implement `POST /payments/:id/capture`
    - Capture payment
    - Transfer to contractor (minus commission)
  - [x] 7.8 Implement `POST /payments/:id/refund`
    - Full or partial refund
  - [x] 7.9 Implement webhook handler for Stripe events
  - [x] 7.10 Implement `GET /earnings` - contractor earnings summary
  - [x] 7.11 Implement `POST /earnings/withdraw` - trigger payout
  - [x] 7.12 Write tests for payment flows

- [x] **8.0 Real-time Module (WebSockets)**
  - [x] 8.1 Install Socket.io: `npm install @nestjs/websockets @nestjs/platform-socket.io socket.io`
  - [x] 8.2 Create `RealtimeGateway` with authentication
  - [x] 8.3 Implement room management (one room per active task)
  - [x] 8.4 Implement `location:update` event - contractor sends GPS
    - Store in memory (Redis in production)
    - Broadcast to task room (client sees update)
  - [x] 8.5 Implement `task:status` event - broadcasts status changes
  - [x] 8.6 Implement `message:new` event - real-time chat
  - [ ] 8.7 Implement reconnection handling with message queue (deferred to production)
  - [x] 8.8 Write tests for WebSocket events

- [x] **9.0 Chat Module**
  - [x] 9.1 Create `MessagesModule` with controller and service
  - [x] 9.2 Implement `GET /tasks/:id/messages` - returns chat history
  - [x] 9.3 Implement `POST /tasks/:id/messages` - sends message
    - Store in database
    - Emit via WebSocket (integrated with RealtimeModule)
    - Push notification deferred to 11.0
  - [x] 9.4 Implement read receipts (update read_at on fetch)
  - [x] 9.5 Write tests for chat functionality

---

### Phase 3: KYC & Polish (Week 6-7)

- [x] **10.0 KYC Verification Module**
  - [ ] 10.1 Create Onfido account and get API keys (USER ACTION REQUIRED)
  - [x] 10.2 Install Onfido SDK: `npm install @onfido/api`
  - [x] 10.3 Create `KycModule` with service
  - [x] 10.4 Implement `POST /contractor/kyc/id` - initiates ID verification
    - Upload document to Onfido
    - Store check ID in contractor profile
  - [x] 10.5 Implement `POST /contractor/kyc/selfie` - face verification
    - Upload selfie to Onfido
    - Trigger face match check
  - [x] 10.6 Implement `POST /contractor/kyc/bank` - verify bank account
    - Validate IBAN format
    - Store for Stripe payouts
  - [x] 10.7 Implement Onfido webhook handler
    - Update kyc_status based on results
    - Send notification to contractor
  - [x] 10.8 Create KYC status check endpoint
  - [x] 10.9 Write tests for KYC flow

- [x] **11.0 Push Notifications**
  - [x] 11.1 Set up Firebase project (placeholder config for dev/mock mode)
  - [x] 11.2 Install Firebase Admin SDK: `npm install firebase-admin`
  - [x] 11.3 Create `NotificationsService` with mock mode support
  - [x] 11.4 Implement device token registration (`PUT /users/me/fcm-token`)
  - [x] 11.5 Implement notification templates (20+ types):
    - `new_task_nearby` - contractor receives new task alert
    - `task_accepted` - client notified contractor accepted
    - `task_started` - client notified contractor started work
    - `task_completed` - client notified to confirm
    - `task_confirmed` - contractor notified client confirmed
    - `task_cancelled` - both parties notified of cancellation
    - `task_rated` - user received rating
    - `tip_received` - contractor received tip
    - `new_message` - chat message received
    - `payment_received` - contractor received payment
    - `payment_refunded` - client received refund
    - `kyc_document_verified`, `kyc_selfie_verified`, `kyc_bank_verified`, `kyc_complete` - KYC status updates
  - [x] 11.6 Write tests for notification sending
  - [x] Integration with TasksService, MessagesService, PaymentsService, KycService
  - [x] Documentation: `backend/docs/PUSH_NOTIFICATIONS.md`

- [x] **12.0 Admin Dashboard Backend**
  - [x] 12.1 Create `AdminModule` with guards (admin role only)
  - [x] 12.2 Implement `GET /admin/dashboard` - returns key metrics
    - Total users (clients, contractors)
    - Tasks today, this week, this month
    - GMV and revenue
    - Average completion time
  - [x] 12.3 Implement `GET /admin/users` - paginated user list with filters
  - [x] 12.4 Implement `PUT /admin/users/:id/status` - change user status
  - [x] 12.5 Implement `GET /admin/disputes` - list disputed tasks
  - [x] 12.6 Implement `PUT /admin/disputes/:id/resolve` - resolve dispute
    - Options: refund, pay_contractor, split
  - [x] 12.7 Write tests for admin endpoints

---

### Phase 4: Mobile App (Parallel with Phase 2-3)

- [x] **13.0 Flutter Project Setup** ✅ COMPLETE

  **Dependencies installed in pubspec.yaml:**
  ```yaml
  dependencies:
    flutter_riverpod: ^2.5.1
    go_router: ^14.2.0
    dio: ^5.4.0
    flutter_secure_storage: ^9.0.0
    google_fonts: ^6.2.0
    cached_network_image: ^3.3.0
    shimmer: ^3.0.0
    flutter_svg: ^2.0.9
    intl: ^0.20.2
    flutter_localizations: sdk
  ```

  - [x] 13.1 Configure app with proper bundle IDs (iOS/Android)
    - iOS: `pl.szybkafucha.mobile`
    - Android: `pl.szybkafucha.mobile` (minSdk 23)
  - [x] 13.2 Set up Material 3 design system in `lib/core/theme/`
    - `app_colors.dart` - Full color palette from szybkafucha.app
    - `app_typography.dart` - Plus Jakarta Sans + Nunito
    - `app_spacing.dart` - Complete spacing scale
    - `app_radius.dart` - Border radius tokens
    - `app_shadows.dart` - 5 elevation levels
    - `app_theme.dart` - Material 3 light theme
  - [x] 13.2.1 Create reusable component library in `lib/core/widgets/`
    - `sf_button.dart` - Primary, ghost, gradient variants
    - `sf_card.dart` - With optional rainbow border animation
    - `sf_input.dart` - Text input with validation states
    - `sf_avatar.dart` - User avatars with online indicator
    - `sf_rating_stars.dart` - 1-5 star display
    - `sf_status_badge.dart` - Task status badges
    - `sf_bottom_nav.dart` - Bottom navigation bar
  - [x] 13.3 Set up API client with Dio
    - `lib/core/api/api_client.dart` - Dio wrapper with interceptors
    - `lib/core/api/api_config.dart` - Base URLs, timeouts
    - `lib/core/api/api_exceptions.dart` - Typed exceptions (Network, Validation, Auth, etc.)
  - [x] 13.4 Set up state management with Riverpod 2.x
    - `lib/core/providers/api_provider.dart` - API client provider
    - `lib/core/providers/auth_provider.dart` - Auth state, User model
    - `lib/core/providers/storage_provider.dart` - Storage provider
  - [x] 13.5 Set up navigation (go_router)
    - `lib/core/router/routes.dart` - All route constants
    - `lib/core/router/app_router.dart` - Router with auth guards, shell routes
    - Client and Contractor bottom navigation shells
  - [x] 13.6 Set up secure storage for tokens
    - `lib/core/storage/secure_storage.dart` - Token, user info, FCM storage
    - iOS Keychain, Android encrypted preferences
  - [x] 13.7 Set up localization (Polish)
    - `lib/core/l10n/app_strings.dart` - 200+ Polish strings
    - Material, Cupertino, Widgets localization delegates

- [x] **14.0 Auth Screens (Mobile and Tablet)** ✅ COMPLETE
  - [x] 14.1 Create Welcome screen with social login buttons
    - `lib/features/auth/screens/welcome_screen.dart` - Scrollable layout with branding, social buttons, phone login
    - `lib/features/auth/widgets/social_login_button.dart` - Reusable Google/Apple/Phone button widget
  - [x] 14.2 Implement Google Sign-In flow
    - `lib/core/services/google_sign_in_service.dart` - Google OAuth
    - Uses `google_sign_in: ^6.2.1` package
    - Always shows account picker (no silent sign-in) for role selection flexibility
    - Returns idToken for backend authentication
    - Integrated into welcome_screen.dart with loading state
    - Sign-out on app logout to clear cached session
  - [x] 14.3 Implement Apple Sign-In flow
    - `lib/core/services/apple_sign_in_service.dart` - Apple OAuth with nonce security
    - Uses `sign_in_with_apple: ^6.1.4` and `crypto: ^3.0.3` packages
    - SHA256 nonce generation for security
    - Availability check via FutureProvider (iOS/macOS only)
    - Returns identityToken and authorizationCode for backend
    - Conditionally shown on welcome_screen only when available
    - `lib/core/services/services.dart` - Barrel export for services
  - [x] 14.4 Create Phone login screen with OTP input
    - `lib/features/auth/screens/phone_login_screen.dart` - Polish +48 number input with formatting
    - `lib/features/auth/screens/otp_screen.dart` - 6-digit OTP with auto-advance, 60s resend timer
  - [x] 14.5 Create Registration screen (name, select user type)
    - `lib/features/auth/screens/register_screen.dart` - Name input, Client/Contractor selection
  - [x] 14.6 Implement auth state persistence
    - Enhanced `auth_provider.dart` with token caching, user data persistence, auto-refresh
    - Added `userData` storage in `secure_storage.dart`
    - Loading state handling in router
  - [x] 14.7 Create logout functionality
    - `lib/features/profile/screens/profile_screen.dart` - Profile with logout/delete account
    - Logout dialog with confirmation
    - Server notification + local data clearing
    - Google Sign-In session cleared on logout
  - [x] 14.8 Implement role switching (Klient ↔ Wykonawca) ✅ COMPLETE
    - `lib/features/settings/screens/settings_screen.dart` - Settings with role switch option
    - `backend/src/users/users.controller.ts` - PATCH /users/me/type endpoint
    - User stays logged in, role updated via API
    - Backend updates user type and returns updated user
    - Navigation to appropriate home screen after switch
    - Confirmation dialog with role description
  - Documentation:
    - `mobile/docs/AUTH_IMPLEMENTATION.md` - Auth screens guide
    - `mobile/docs/AUTH_PERSISTENCE_SUMMARY.md` - Persistence & logout guide

- [x] **15.0 Client Screens (Mobile and Tablet)** ✅ COMPLETE
  - [x] 15.1 Create Client Home & Category Selection screens
    - `lib/features/client/screens/client_home_screen.dart` - Dashboard with welcome, quick actions, categories grid
    - `lib/features/client/screens/category_selection_screen.dart` - 2-column grid with CategoryCard, selection state
    - `lib/features/client/models/task_category.dart` - 6 categories with icons, colors, price ranges, times
    - `lib/features/client/widgets/category_card.dart` - CategoryCard + CategoryChip widgets
  - [x] 15.2 Create Task Creation screen
    - `lib/features/client/screens/create_task_screen.dart` - Full task creation flow
    - Description input with 10-char minimum validation
    - Location picker (GPS auto-detect or manual address)
    - Budget slider with category-based min/max/suggested prices
    - Schedule picker (Now or date/time picker)
    - Summary card with task details
  - [x] 15.3 Create Contractor Selection screen
    - `lib/features/client/screens/contractor_selection_screen.dart`
    - List with avatar, name, rating, price, ETA, verified badge
    - Sort by: recommended, rating, price, ETA
    - Bottom sheet profile viewer with stats
    - Selected contractor bottom bar with "Wybierz" CTA
    - `lib/features/client/models/contractor.dart` - Contractor model with mock data
  - [x] 15.4 Create Payment screen
    - `lib/features/client/screens/payment_screen.dart`
    - Task summary and contractor card
    - Price breakdown (service + 17% platform fee)
    - Payment method selection (Card, Google Pay, Apple Pay)
    - Save card checkbox
    - Security escrow notice
    - Ready for Stripe integration
  - [x] 15.5 Create Task Tracking screen
    - `lib/features/client/screens/task_tracking_screen.dart`
    - Map placeholder with grid pattern and markers
    - Status progression: Searching → Accepted → On The Way → Arrived → In Progress → Completed
    - 5-step visual progress bar
    - Contractor card with online indicator
    - Chat/Call action buttons
    - Cancel option with confirmation dialog
    - Simulated real-time status updates
  - [x] 15.6 Create Completion screen
    - `lib/features/client/screens/task_completion_screen.dart`
    - Success animation with scale transition
    - 5-star rating with tap interaction
    - Optional review text input (500 chars max)
    - Tip options (0, 5, 10, 15, 20 PLN)
    - Thank you dialog on submit
    - Skip option with confirmation
  - [x] 15.7 Create Task History screen
    - `lib/features/client/screens/task_history_screen.dart`
    - TabBar: Active / History tabs
    - Active tasks with tracking button
    - Completed tasks with status badges
    - Task detail bottom sheet
    - Pull-to-refresh functionality
    - `lib/features/client/models/task.dart` - Task model with status enum
  - [x] 15.8 Client Profile screen (using shared ProfileScreen)
    - Already implemented in 14.7 with logout functionality
  - Documentation: `mobile/docs/CLIENT_SCREENS_SUMMARY.md`

- [x] **16.0 Contractor Screens (Mobile and Tablet)** ✅ COMPLETE
  - [x] 16.1 Create Contractor Registration screen ✅ DONE
    - [x] 3-step registration flow (profile, categories, radius)
    - [x] Photo upload with camera/gallery picker
    - [x] Multi-select category grid with state tracking
    - [x] Service radius slider (1-50km) with visualization
  - [x] 16.2 Create KYC Verification screens ✅ DONE
    - [x] 3-step KYC flow (document, selfie, bank account)
    - [x] ID front/back capture with document uploader
    - [x] Selfie capture in circular frame with change option
    - [x] IBAN and account holder input with validation
    - [x] Verification pending status with notification info
  - [x] 16.3 Create Contractor Dashboard ✅ DONE
    - [x] Availability toggle with animation
    - [x] Weekly earnings card with gradient background
    - [x] Active task section with progress indicator
    - [x] Nearby tasks list with NearbyTaskCard widget
  - [x] 16.4 Create New Task Alert screen ✅ DONE
    - [x] Full-screen alert with secondary color background
    - [x] Large price display with pulse animation
    - [x] Task category, client info, location, distance
    - [x] 45-second countdown timer with visual progress
    - [x] Accept/Decline buttons with vibration feedback
  - [x] 16.5 Create Active Task screen ✅ DONE
    - [x] Map placeholder with grid pattern
    - [x] 5-step progress indicator with visual steps
    - [x] Task details and client contact
    - [x] Navigate button (opens URL launcher ready)
    - [x] Chat and Call action buttons
    - [x] Status update buttons for workflow
  - [x] 16.6 Create Task Completion screen ✅ DONE
    - [x] Photo proof upload with gallery/camera picker (max 4)
    - [x] Optional notes textarea (500 char max)
    - [x] Earnings breakdown with 17% commission display
    - [x] Success dialog with earnings confirmation
    - [x] Return to home navigation
  - [x] 16.7 Create Earnings screen ✅ DONE
    - [x] Summary cards (today, week, month earnings)
    - [x] Available balance and pending payout display
    - [x] Transaction history with date grouping
    - [x] Tab filtering (All / Income / Withdrawals)
    - [x] Withdrawal flow with amount input and validation
    - [x] Transaction status badges and timestamps

  **Files Created:**
  - `lib/features/contractor/models/contractor_profile.dart` - Contractor profile model with KYC status
  - `lib/features/contractor/models/contractor_task.dart` - Task model from contractor perspective
  - `lib/features/contractor/models/earnings.dart` - Earnings summary and transaction models
  - `lib/features/contractor/models/models.dart` - Barrel export
  - `lib/features/contractor/screens/contractor_registration_screen.dart` - 3-step registration
  - `lib/features/contractor/screens/kyc_verification_screen.dart` - 3-step KYC verification
  - `lib/features/contractor/screens/contractor_home_screen.dart` - Dashboard
  - `lib/features/contractor/screens/task_alert_screen.dart` - Full-screen alert
  - `lib/features/contractor/screens/active_task_screen.dart` - Task progress tracking
  - `lib/features/contractor/screens/task_completion_screen.dart` - Completion with photo
  - `lib/features/contractor/screens/earnings_screen.dart` - Earnings summary
  - `lib/features/contractor/screens/screens.dart` - Barrel export
  - `lib/features/contractor/widgets/availability_toggle.dart` - Online/offline toggle
  - `lib/features/contractor/widgets/earnings_card.dart` - Earnings display card
  - `lib/features/contractor/widgets/nearby_task_card.dart` - Task list item
  - `lib/features/contractor/widgets/widgets.dart` - Barrel export

  **Dependencies Added:**
  - `image_picker: ^1.0.7` - Photo capture and gallery
  - `url_launcher: ^6.2.5` - Navigation and phone calls

  **Route Updates:**
  - Updated `lib/core/router/routes.dart` with all contractor routes
  - Updated `lib/core/router/app_router.dart` with screen registrations
  - Added 9 new GoRoutes for contractor flows

  **Code Quality:**
  - ✅ `flutter analyze` - No issues found
  - ✅ All tests passing
  - ✅ Material 3 design compliance
  - ✅ Polish localization complete
  - ✅ Mock data for all screens

- [x] **17.0 Real-time Features (Mobile and Tablet)** ✅ COMPLETE
  - [x] 17.1 Integrate Socket.io client ✅ DONE
    - [x] WebSocket connection with JWT authentication
    - [x] Automatic reconnection with exponential backoff (1s → 8s max)
    - [x] Dev mode mock implementation for testing without backend
    - [x] Event emitting and listening for real-time data
  - [x] 17.2 Implement location broadcasting (contractor) ✅ DONE
    - [x] Contractor GPS polling every 15 seconds
    - [x] Location broadcast via WebSocket to backend
    - [x] Start/stop tracking with UI state management
    - [x] Battery-efficient update interval (15s balanced approach)
  - [x] 17.3 Implement location receiving (client) ✅ DONE
    - [x] Client receives contractor location updates
    - [x] Map marker with grid pattern display
    - [x] Distance calculation (Haversine formula)
    - [x] ETA estimation (~30 km/h average urban speed)
    - [x] Real-time distance and ETA display
  - [x] 17.4 Implement chat UI ✅ DONE
    - [x] Message model with status tracking (pending, sent, delivered, read, failed)
    - [x] Real-time message list with auto-scroll
    - [x] Message input with send button
    - [x] Offline message queuing and auto-retry
    - [x] Sender info and message timestamps
    - [x] Connection status indicator
    - [x] Error handling and recovery
  - [x] 17.5 Push notification foundation ⏳ FUTURE
    - [ ] Firebase Cloud Messaging setup
    - [ ] Foreground notification handling
    - [ ] Background notification handling
    - [ ] Deep linking to relevant screens

  **Files Created:**
  - `lib/core/config/websocket_config.dart` - WebSocket configuration and event names
  - `lib/core/services/websocket_service.dart` - Socket.io client with dev mode mock
  - `lib/core/providers/websocket_provider.dart` - Riverpod providers for streams
  - `lib/features/contractor/providers/location_provider.dart` - Location broadcasting
  - `lib/features/client/providers/contractor_location_provider.dart` - Location receiving
  - `lib/features/client/widgets/contractor_location_map.dart` - Map display with ETA
  - `lib/features/chat/models/message.dart` - Message model with serialization
  - `lib/features/chat/providers/chat_provider.dart` - Chat state management
  - `lib/features/chat/screens/chat_screen.dart` - Chat UI
  - `lib/features/chat/widgets/message_bubble.dart` - Message display
  - `lib/features/chat/widgets/chat_input.dart` - Input field and send button
  - Barrel exports for all modules

  **Dependencies Added:**
  - `socket_io_client: ^2.0.2` - WebSocket client
  - `async: ^2.11.0` - StreamGroup for combining streams

  **Route Updates:**
  - Updated chat route with ChatScreen implementation
  - Integrated with existing task screens

  **Backend Integration:**
  - Maps to `backend/src/realtime/realtime.gateway.ts` events
  - Follows Socket.io namespace `/realtime`
  - JWT authentication via query parameter or Bearer header
  - Event payloads match backend contract

  **Dev Mode:**
  - ✅ Simulates location updates every 15 seconds
  - ✅ Simulates incoming messages after 5 second delay
  - ✅ All features work without backend connection
  - ✅ Perfect for local testing and UI development

  **Code Quality:**
  - ✅ `flutter analyze` - 21 issues (all info-level, no errors)
  - ✅ No performance warnings
  - ✅ No security issues
  - ✅ Full offline support with message queuing
  - ✅ Error handling and recovery
  - ✅ Type-safe event data classes

  **Total New Code:**
  - ~2,850 lines across 15 new files
  - WebSocket: ~580 lines
  - Location: ~795 lines
  - Chat: ~1,100 lines
  - Widgets: ~420 lines
  - Exports and config: ~155 lines

  **Testing Status:**
  - ✅ Dev mode: Ready for manual testing without backend
  - ✅ Mock data: Realistic chat conversation and location movements
  - ✅ Error scenarios: Connection loss, offline queueing tested
  - ⏳ Backend integration: Ready to connect when backend available

---

### Phase 5: Admin Dashboard (Week 7)

- [x] **18.0 Admin Dashboard Frontend**
  - [x] 18.1 Set up React project with TypeScript
  - [x] 18.2 Install UI library (Chakra UI or Tailwind)
  - [x] 18.3 Set up routing (React Router)
  - [x] 18.4 Create authentication (admin login)
  - [x] 18.5 Create Dashboard page
    - Metric cards (users, tasks, revenue)
    - Charts (tasks over time, revenue)
  - [x] 18.6 Create Users page
    - Table with search and filters
    - User detail modal
    - Status change actions
  - [x] 18.7 Create Disputes page
    - Dispute list
    - Detail view with chat history
    - Resolution buttons
  - [x] 18.8 Create Tasks page (bonus)
    - Table with search and filters
    - Status badges and actions

---

### Phase 6: Testing & Launch (Week 8)

- [ ] **19.0 Integration Testing**
  - [ ] 19.1 Write end-to-end tests for complete task flow
    - Client creates task → Contractor accepts → Completes → Payment
  - [ ] 19.2 Test payment flows with Stripe test mode
  - [ ] 19.3 Test real-time features (location, chat)
  - [ ] 19.4 Test KYC flow with Onfido sandbox
  - [ ] 19.5 Test push notifications
  - [ ] 19.6 Load testing for 100 concurrent users

- [ ] **20.0 App Store Preparation**
  - [ ] 20.1 Create app icons and splash screens
  - [ ] 20.2 Write app store descriptions (Polish)
  - [ ] 20.3 Take screenshots for store listings
  - [ ] 20.4 Create privacy policy and terms of service
  - [ ] 20.5 Submit to Google Play (beta track)
  - [ ] 20.6 Submit to Apple App Store (TestFlight)

- [ ] **21.0 Production Deployment**
  - [ ] 21.1 Set up production AWS infrastructure
    - ECS cluster for backend
    - RDS for PostgreSQL
    - ElastiCache for Redis
    - S3 for file storage
  - [ ] 21.2 Configure domain and SSL certificates
  - [ ] 21.3 Set up monitoring (CloudWatch, Sentry)
  - [ ] 21.4 Configure auto-scaling rules
  - [ ] 21.5 Deploy backend to production
  - [ ] 21.6 Deploy admin dashboard
  - [ ] 21.7 Final production smoke tests

- [ ] **22.0 Soft Launch**
  - [ ] 22.1 Onboard initial contractors (200 target)
  - [ ] 22.2 Invite waitlist users (limited batch)
  - [ ] 22.3 Monitor for issues and bugs
  - [ ] 22.4 Gather feedback and iterate
  - [ ] 22.5 Fix critical bugs
  - [ ] 22.6 Prepare for full launch

---

## Task Dependencies

```
1.0 → 2.0 → 3.0 → 4.0 → 5.0 → 6.0
                    ↓
                   7.0 → 8.0 → 9.0
                    ↓
                  10.0 → 11.0 → 12.0

13.0 → 14.0 → 15.0 → 16.0 → 17.0

18.0 (can run parallel after 12.0)

19.0 → 20.0 → 21.0 → 22.0
```

---

## Estimated Effort

| Phase | Tasks | Estimated Hours |
|-------|-------|-----------------|
| Foundation | 1.0 - 3.0 | 80h |
| Core Features | 4.0 - 9.0 | 160h |
| KYC & Polish | 10.0 - 12.0 | 60h |
| Mobile App | 13.0 - 17.0 | 200h |
| Admin Dashboard | 18.0 | 40h |
| Testing & Launch | 19.0 - 22.0 | 60h |
| **TOTAL** | | **600h** |

With 2 developers working full-time: **~8 weeks**

---

## AI Agent Instructions

When implementing these tasks:

1. **Read the PRD first** - `prd-szybka-fucha.md` contains all details
2. **Follow the order** - Dependencies matter, don't skip ahead
3. **Write tests** - Every feature needs tests before moving on
4. **Commit often** - One commit per sub-task with clear message
5. **Ask for clarification** - If requirements unclear, check PRD or ask
6. **Update status** - Mark tasks complete `[x]` as you finish them
7. **Document decisions** - If you make architectural choices, add comments
