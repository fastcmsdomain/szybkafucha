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

## Tasks

### Phase 1: Foundation (Week 1-2)

- [x] **1.0 Project Setup**
  - [x] 1.1 Create backend project with NestJS CLI: `nest new backend`
  - [ ] 1.2 Create Flutter project: `flutter create mobile --org pl.szybkafucha` (BLOCKED: Flutter SDK not installed)
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
  - [ ] 4.4 Implement `POST /users/me/avatar` - uploads avatar to S3/CloudStorage
  - [x] 4.5 Create `ContractorProfileService` for contractor-specific operations
  - [x] 4.6 Implement `GET /contractor/profile` - returns contractor profile
  - [x] 4.7 Implement `PUT /contractor/profile` - updates bio, categories, radius
  - [x] 4.8 Implement `PUT /contractor/availability` - toggles online/offline
  - [x] 4.9 Implement `PUT /contractor/location` - updates GPS coordinates
  - [ ] 4.10 Write tests for user endpoints

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
  - [ ] 10.9 Write tests for KYC flow

- [ ] **11.0 Push Notifications**
  - [ ] 11.1 Set up Firebase project
  - [ ] 11.2 Install Firebase Admin SDK: `npm install firebase-admin`
  - [ ] 11.3 Create `NotificationsService`
  - [ ] 11.4 Implement device token registration
  - [ ] 11.5 Implement notification templates:
    - `new_task` - contractor receives new task alert
    - `task_accepted` - client notified contractor accepted
    - `task_completed` - client notified to confirm
    - `payment_received` - contractor received payment
    - `new_message` - chat message received
  - [ ] 11.6 Write tests for notification sending

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

- [ ] **13.0 Flutter Project Setup**
  - [ ] 13.1 Configure app with proper bundle IDs (iOS/Android)
  - [ ] 13.2 Set up design system in `core/theme/`
    - Colors matching PRD (Primary: #E94560, Secondary: #16213E)
    - Typography with Plus Jakarta Sans
    - Common spacing and border radius values
  - [ ] 13.3 Set up API client with Dio
    - Base URL configuration
    - JWT interceptor for auth headers
    - Error handling interceptor
  - [ ] 13.4 Set up state management (Riverpod or Bloc)
  - [ ] 13.5 Set up navigation (go_router)
  - [ ] 13.6 Set up secure storage for tokens
  - [ ] 13.7 Set up localization (Polish)

- [ ] **14.0 Auth Screens (Mobile)**
  - [ ] 14.1 Create Welcome screen with social login buttons
  - [ ] 14.2 Implement Google Sign-In flow
  - [ ] 14.3 Implement Apple Sign-In flow
  - [ ] 14.4 Create Phone login screen with OTP input
  - [ ] 14.5 Create Registration screen (name, select user type)
  - [ ] 14.6 Implement auth state persistence
  - [ ] 14.7 Create logout functionality

- [ ] **15.0 Client Screens (Mobile)**
  - [ ] 15.1 Create Category Selection screen (6 categories grid)
  - [ ] 15.2 Create Task Details screen
    - Description input
    - Location picker (GPS + manual)
    - Budget slider with suggested price
    - Schedule picker (now vs future)
  - [ ] 15.3 Create Contractor Selection screen
    - List with avatar, name, rating, price, ETA
    - Tap to view profile
    - Accept button
  - [ ] 15.4 Create Payment screen
    - Stripe payment sheet integration
    - Order summary
  - [ ] 15.5 Create Task Tracking screen
    - Google Maps with contractor marker
    - Status progress bar (4 steps)
    - Chat/Call buttons
    - ETA display
  - [ ] 15.6 Create Completion screen
    - Success animation
    - Star rating input
    - Review text input
    - Tip option
  - [ ] 15.7 Create Task History screen (list of past tasks)
  - [ ] 15.8 Create Client Profile screen

- [ ] **16.0 Contractor Screens (Mobile)**
  - [ ] 16.1 Create Contractor Registration screen
    - Photo upload
    - Category multi-select
    - Service radius setting
  - [ ] 16.2 Create KYC Verification screens
    - ID upload screen
    - Selfie capture screen
    - Bank account input screen
    - Status overview screen
  - [ ] 16.3 Create Contractor Dashboard
    - Earnings card (weekly)
    - Availability toggle
    - Nearby tasks list
  - [ ] 16.4 Create New Task Alert screen (full-screen)
    - Large price display
    - Task details
    - 45-second countdown
    - Accept/Decline buttons
  - [ ] 16.5 Create Active Task screen
    - Map with route to location
    - Step checklist
    - Navigation button (opens Maps app)
    - Contact client buttons
  - [ ] 16.6 Create Task Completion screen
    - Photo upload (proof)
    - Earnings calculation display
    - Confirm button
  - [ ] 16.7 Create Earnings screen
    - Summary cards
    - Transaction history
    - Withdraw button

- [ ] **17.0 Real-time Features (Mobile)**
  - [ ] 17.1 Integrate Socket.io client
  - [ ] 17.2 Implement location broadcasting (contractor)
    - Get GPS every 15 seconds
    - Send via WebSocket
  - [ ] 17.3 Implement location receiving (client)
    - Update map marker on events
  - [ ] 17.4 Implement chat UI
    - Message list
    - Input field
    - Send button
    - Real-time updates
  - [ ] 17.5 Implement push notification handling
    - Foreground notifications
    - Background handling
    - Deep linking to relevant screens

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
