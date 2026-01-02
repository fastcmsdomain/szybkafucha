# PRD: Szybka Fucha - Platforma Mikro-zleceń

> **Wersja:** 1.0  
> **Status:** Ready for Development  
> **Target:** AI Agent Implementation  

---

## 1. Overview

### 1.1 What is this?
**Szybka Fucha** = Mobile marketplace connecting busy professionals with local helpers for immediate small tasks.

### 1.2 Core Value Proposition
```
USER PROBLEM:  "I don't have time to pick up my package / do shopping / wait in line"
SOLUTION:      "Someone nearby does it for you within 2 hours"
DIFFERENTIATOR: Speed (2h vs 24-72h competitors) + GPS tracking + In-app payments
```

### 1.3 Key Numbers
| Metric | Value |
|--------|-------|
| Target market | Poland (Warsaw first) |
| Commission | 17% of transaction |
| Avg task value | 80 PLN |
| MVP timeline | 8-10 weeks |

---

## 2. User Types

### 2.1 CLIENT (Zleceniodawca)
```yaml
WHO: Busy professional, 25-45 years old, urban
GOAL: Delegate small tasks to save time
PAIN: No time for errands, packages waiting, queues
PAYS: Task value + platform fee
```

### 2.2 CONTRACTOR (Wykonawca)  
```yaml
WHO: Student, gig worker, part-time earner
GOAL: Flexible income from nearby tasks
PAIN: Finding reliable gig work
EARNS: 83% of task value (after 17% commission)
```

### 2.3 ADMIN
```yaml
WHO: Platform operator
GOAL: Manage users, resolve disputes, monitor metrics
ACCESS: Web dashboard only
```

---

## 3. User Stories

### 3.1 Client Stories

```gherkin
CLIENT-001: Registration
AS A new client
I WANT TO sign up with Google/Apple or phone number
SO THAT I can quickly start posting tasks

ACCEPTANCE CRITERIA:
- [ ] Social login (Google, Apple) works in 1 tap
- [ ] Phone login sends SMS OTP within 10 seconds
- [ ] OTP has 6 digits, expires in 5 minutes
- [ ] After login, user sees category selection screen
```

```gherkin
CLIENT-002: Post Task
AS A client
I WANT TO describe my task with category, location, and budget
SO THAT nearby contractors can see and accept it

ACCEPTANCE CRITERIA:
- [ ] 6 categories available: Paczki, Zakupy, Kolejki, Montaż, Przeprowadzki, Sprzątanie
- [ ] Location uses GPS auto-detect or manual address input
- [ ] Budget slider shows suggested price for category
- [ ] Task can be "Now" or scheduled for future time
- [ ] Estimated time shown based on category
```

```gherkin
CLIENT-003: Select Contractor
AS A client
I WANT TO see available contractors with ratings and prices
SO THAT I can choose the best person for my task

ACCEPTANCE CRITERIA:
- [ ] List shows: Avatar, Name, Rating (stars), Completed tasks count, ETA, Price
- [ ] Contractors sorted by relevance (distance + rating)
- [ ] Can view contractor profile with reviews
- [ ] Accept button triggers payment hold (escrow)
```

```gherkin
CLIENT-004: Track Task
AS A client
I WANT TO see contractor location on map in real-time
SO THAT I know when they will arrive

ACCEPTANCE CRITERIA:
- [ ] Map shows contractor marker moving
- [ ] 4-step progress: Zaakceptowane → W drodze → Na miejscu → Zakończone
- [ ] Chat button opens in-app messaging
- [ ] Call button (masked number for privacy)
- [ ] ETA countdown updates every 30 seconds
```

```gherkin
CLIENT-005: Complete & Rate
AS A client
I WANT TO confirm task completion and rate the contractor
SO THAT I release payment and help others choose

ACCEPTANCE CRITERIA:
- [ ] "Confirm completion" button releases escrow
- [ ] 5-star rating system (tap to select)
- [ ] Optional text review (max 500 chars)
- [ ] Optional tip (10%, 15%, 20%, custom)
- [ ] Success animation plays after submission
```

### 3.2 Contractor Stories

```gherkin
CONTRACTOR-001: Registration with Verification
AS A new contractor
I WANT TO create profile and verify my identity
SO THAT I can be trusted by clients

ACCEPTANCE CRITERIA:
- [ ] Profile requires: Photo, Name, Phone, Selected categories
- [ ] 3-step KYC: Upload ID → Take selfie → Add bank account
- [ ] Each step shows status: Pending / Verified / Rejected
- [ ] Cannot accept tasks until all 3 verified
- [ ] Verification takes max 24 hours
```

```gherkin
CONTRACTOR-002: Browse & Accept Tasks
AS A contractor
I WANT TO see nearby tasks and accept them quickly
SO THAT I can earn money

ACCEPTANCE CRITERIA:
- [ ] Dashboard shows: Earnings card, Availability toggle, Task list
- [ ] Task list filtered by: Selected categories + Distance (max 10km)
- [ ] New task notification: Full-screen, shows price prominently
- [ ] 45-second countdown to accept before task goes to next person
- [ ] Accept/Reject buttons clearly visible
```

```gherkin
CONTRACTOR-003: Complete Task
AS A contractor
I WANT TO navigate to location, complete task, and mark done
SO THAT I receive payment

ACCEPTANCE CRITERIA:
- [ ] Map shows route to task location
- [ ] "Start navigation" opens Google Maps / Apple Maps
- [ ] Checklist shows task steps
- [ ] Can chat/call client during task
- [ ] "Upload photo" for proof of completion
- [ ] Earnings shown: Amount - 17% commission = Net
- [ ] "Mark complete" triggers client confirmation
```

```gherkin
CONTRACTOR-004: Manage Earnings
AS A contractor
I WANT TO see my earnings and withdraw to bank
SO THAT I get paid for my work

ACCEPTANCE CRITERIA:
- [ ] Dashboard shows: This week earnings, Total completed tasks, Average rating
- [ ] Earnings history with date, task, amount, status
- [ ] Withdraw button (min 50 PLN)
- [ ] Payout to bank account within 2-3 business days
- [ ] Push notification when payout sent
```

### 3.3 Admin Stories

```gherkin
ADMIN-001: Dashboard
AS AN admin
I WANT TO see key metrics at a glance
SO THAT I can monitor platform health

ACCEPTANCE CRITERIA:
- [ ] Metrics: Active users, Tasks today, GMV, Avg completion time
- [ ] Charts: Tasks over time, Revenue over time
- [ ] Alerts: Disputes, Failed verifications, Low-rated contractors
```

```gherkin
ADMIN-002: User Management
AS AN admin  
I WANT TO view and manage users
SO THAT I can maintain platform quality

ACCEPTANCE CRITERIA:
- [ ] Search users by name, email, phone
- [ ] View user profile: Type, Status, Rating, Task history
- [ ] Actions: Verify, Suspend, Ban, Send message
- [ ] Audit log of all admin actions
```

```gherkin
ADMIN-003: Dispute Resolution
AS AN admin
I WANT TO review and resolve disputes
SO THAT both parties are treated fairly

ACCEPTANCE CRITERIA:
- [ ] Dispute list with: Task ID, Client, Contractor, Status, Date
- [ ] View dispute: Task details, Chat history, Photos
- [ ] Actions: Refund client, Pay contractor, Split, Escalate
- [ ] Notification sent to both parties on resolution
```

---

## 4. Functional Requirements

### 4.1 Authentication Module

| ID | Requirement | Priority |
|----|-------------|----------|
| AUTH-01 | System MUST support Google Sign-In | Must |
| AUTH-02 | System MUST support Apple Sign-In | Must |
| AUTH-03 | System MUST support phone + SMS OTP login | Must |
| AUTH-04 | OTP MUST be 6 digits, expire in 5 minutes | Must |
| AUTH-05 | Session MUST persist for 30 days | Should |
| AUTH-06 | User MUST be able to logout from all devices | Should |

### 4.2 Task Management Module

| ID | Requirement | Priority |
|----|-------------|----------|
| TASK-01 | Client MUST select category from predefined list | Must |
| TASK-02 | Client MUST provide task description (min 10 chars) | Must |
| TASK-03 | Client MUST provide location (GPS or address) | Must |
| TASK-04 | Client MUST set budget (or accept suggested) | Must |
| TASK-05 | Client MAY schedule task for future (max 7 days) | Should |
| TASK-06 | Task MUST show status: Created → Accepted → In Progress → Completed | Must |
| TASK-07 | Task MUST be cancellable before contractor accepts | Must |
| TASK-08 | Cancelled task after acceptance requires admin approval | Should |

### 4.3 Matching Module

| ID | Requirement | Priority |
|----|-------------|----------|
| MATCH-01 | System MUST notify contractors within 10km | Must |
| MATCH-02 | System MUST filter by contractor's selected categories | Must |
| MATCH-03 | System MUST show contractor ETA based on distance | Should |
| MATCH-04 | New task notification MUST timeout after 45 seconds | Must |
| MATCH-05 | If declined, task MUST go to next available contractor | Must |
| MATCH-06 | Premium contractors get notifications 30 seconds earlier | Could |

### 4.4 Payment Module

| ID | Requirement | Priority |
|----|-------------|----------|
| PAY-01 | System MUST use Stripe Connect for marketplace payments | Must |
| PAY-02 | Client payment MUST be held in escrow until completion | Must |
| PAY-03 | Commission (17%) MUST be deducted automatically | Must |
| PAY-04 | Contractor payout MUST be within 3 business days | Must |
| PAY-05 | System MUST support card payments (Visa, MC, Maestro) | Must |
| PAY-06 | System SHOULD support BLIK for Polish market | Should |
| PAY-07 | Tip MUST go 100% to contractor (no commission) | Must |

### 4.5 Real-time Module

| ID | Requirement | Priority |
|----|-------------|----------|
| RT-01 | Contractor location MUST update every 15 seconds during task | Must |
| RT-02 | Client MUST see contractor on map in real-time | Must |
| RT-03 | Chat messages MUST deliver within 2 seconds | Must |
| RT-04 | Task status changes MUST push to both parties instantly | Must |
| RT-05 | System MUST handle offline/reconnection gracefully | Should |

### 4.6 Verification Module (KYC)

| ID | Requirement | Priority |
|----|-------------|----------|
| KYC-01 | Contractor MUST upload government ID (front) | Must |
| KYC-02 | Contractor MUST take live selfie for face match | Must |
| KYC-03 | Contractor MUST provide bank account for payouts | Must |
| KYC-04 | Verification MUST complete within 24 hours | Should |
| KYC-05 | Failed verification MUST show reason and retry option | Must |
| KYC-06 | Use Onfido or Veriff API for automated verification | Should |

---

## 5. Technical Architecture

### 5.1 System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                  │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐           │
│   │  iOS App    │   │ Android App │   │  Admin Web  │           │
│   │  (Flutter)  │   │  (Flutter)  │   │   (React)   │           │
│   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘           │
└──────────┼─────────────────┼─────────────────┼──────────────────┘
           │                 │                 │
           └────────────┬────┴─────────────────┘
                        │ HTTPS/WSS
           ┌────────────┴────────────┐
           │      API GATEWAY        │
           │   (Authentication,      │
           │    Rate Limiting)       │
           └────────────┬────────────┘
                        │
           ┌────────────┴────────────┐
           │    APPLICATION LAYER    │
           │  ┌──────────────────┐   │
           │  │   Node.js API    │   │
           │  │   (NestJS)       │   │
           │  └────────┬─────────┘   │
           │           │             │
           │  ┌────────┴─────────┐   │
           │  │ WebSocket Server │   │
           │  │  (Socket.io)     │   │
           │  └──────────────────┘   │
           └────────────┬────────────┘
                        │
           ┌────────────┴────────────┐
           │      DATA LAYER         │
           │  ┌────────┐ ┌────────┐  │
           │  │PostgreSQL│ │ Redis │  │
           │  │(Primary)│ │(Cache) │  │
           │  └────────┘ └────────┘  │
           └─────────────────────────┘

EXTERNAL SERVICES:
├── Stripe Connect (payments)
├── Firebase (push notifications)
├── Google Maps API (geocoding, routing)
├── Onfido (KYC verification)
└── Twilio (SMS OTP)
```

### 5.2 Tech Stack Decision

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Mobile | Flutter | Single codebase for iOS + Android, fast development |
| Backend | Node.js + NestJS | Good for real-time, large ecosystem, team familiarity |
| Database | PostgreSQL | Relational data, transactions, proven reliability |
| Cache | Redis | Real-time data, sessions, pub/sub for websockets |
| Real-time | Socket.io | Mature, fallback support, rooms for task channels |
| Payments | Stripe Connect | Marketplace payments, Polish support, escrow |
| Maps | Google Maps | Best accuracy for Poland, familiar UX |
| Push | Firebase Cloud Messaging | Free, reliable, both platforms |
| Hosting | AWS (ECS + RDS) | Auto-scaling, managed services |

### 5.3 Database Schema (Core Tables)

```sql
-- Users (both clients and contractors)
CREATE TABLE users (
  id UUID PRIMARY KEY,
  type ENUM('client', 'contractor') NOT NULL,
  phone VARCHAR(15) UNIQUE,
  email VARCHAR(255) UNIQUE,
  name VARCHAR(100),
  avatar_url TEXT,
  status ENUM('pending', 'active', 'suspended', 'banned') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Contractor profiles (extends users)
CREATE TABLE contractor_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  bio TEXT,
  categories TEXT[], -- ['paczki', 'zakupy', 'kolejki']
  service_radius_km INT DEFAULT 10,
  kyc_status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
  kyc_id_verified BOOLEAN DEFAULT FALSE,
  kyc_selfie_verified BOOLEAN DEFAULT FALSE,
  kyc_bank_verified BOOLEAN DEFAULT FALSE,
  stripe_account_id VARCHAR(255),
  rating_avg DECIMAL(3,2) DEFAULT 0,
  rating_count INT DEFAULT 0,
  is_online BOOLEAN DEFAULT FALSE,
  last_location GEOGRAPHY(POINT, 4326),
  last_location_at TIMESTAMP
);

-- Tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY,
  client_id UUID REFERENCES users(id) NOT NULL,
  contractor_id UUID REFERENCES users(id),
  category VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  address TEXT NOT NULL,
  budget_amount DECIMAL(10,2) NOT NULL,
  final_amount DECIMAL(10,2),
  commission_amount DECIMAL(10,2),
  tip_amount DECIMAL(10,2) DEFAULT 0,
  status ENUM('created', 'accepted', 'in_progress', 'completed', 'cancelled', 'disputed') DEFAULT 'created',
  scheduled_at TIMESTAMP,
  accepted_at TIMESTAMP,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Ratings
CREATE TABLE ratings (
  id UUID PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) NOT NULL,
  from_user_id UUID REFERENCES users(id) NOT NULL,
  to_user_id UUID REFERENCES users(id) NOT NULL,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Messages (chat)
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) NOT NULL,
  sender_id UUID REFERENCES users(id) NOT NULL,
  content TEXT NOT NULL,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Payments
CREATE TABLE payments (
  id UUID PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) NOT NULL,
  stripe_payment_intent_id VARCHAR(255),
  amount DECIMAL(10,2) NOT NULL,
  status ENUM('pending', 'held', 'captured', 'refunded', 'failed') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 5.4 API Endpoints (Core)

```yaml
# Authentication
POST /auth/phone/request-otp     # Send SMS OTP
POST /auth/phone/verify          # Verify OTP, return JWT
POST /auth/google                # Google Sign-In
POST /auth/apple                 # Apple Sign-In
POST /auth/logout                # Invalidate session

# Users
GET  /users/me                   # Get current user profile
PUT  /users/me                   # Update profile
POST /users/me/avatar            # Upload avatar

# Contractor Profile
GET  /contractor/profile         # Get contractor profile
PUT  /contractor/profile         # Update profile
POST /contractor/kyc/id          # Upload ID document
POST /contractor/kyc/selfie      # Upload selfie
POST /contractor/kyc/bank        # Add bank account
PUT  /contractor/availability    # Toggle online/offline
PUT  /contractor/location        # Update GPS location

# Tasks
POST /tasks                      # Create new task
GET  /tasks                      # List tasks (filtered by role)
GET  /tasks/:id                  # Get task details
PUT  /tasks/:id/accept           # Contractor accepts
PUT  /tasks/:id/start            # Contractor starts
PUT  /tasks/:id/complete         # Contractor completes
PUT  /tasks/:id/confirm          # Client confirms
PUT  /tasks/:id/cancel           # Cancel task
POST /tasks/:id/rate             # Submit rating

# Messages
GET  /tasks/:id/messages         # Get chat history
POST /tasks/:id/messages         # Send message

# Payments
POST /payments/create-intent     # Create Stripe PaymentIntent
POST /payments/:id/capture       # Capture payment (on completion)
POST /payments/:id/refund        # Refund payment

# Contractor Earnings
GET  /earnings                   # Get earnings summary
GET  /earnings/history           # Get payout history
POST /earnings/withdraw          # Request payout

# Admin
GET  /admin/dashboard            # Get metrics
GET  /admin/users                # List users with filters
PUT  /admin/users/:id/status     # Change user status
GET  /admin/disputes             # List disputes
PUT  /admin/disputes/:id/resolve # Resolve dispute
```

---

## 6. UI/UX Specifications

### 6.1 Design System

```yaml
Colors:
  Primary:    "#E94560"  # Coral red - CTAs, branding
  Secondary:  "#16213E"  # Dark navy - headers, text
  Accent:     "#0F3460"  # Medium navy - secondary elements
  Success:    "#10B981"  # Green - confirmations
  Warning:    "#F59E0B"  # Orange - warnings
  Error:      "#EF4444"  # Red - errors
  Background: "#FFFFFF"  # White - main background
  Surface:    "#F1F5F9"  # Light gray - cards, inputs

Typography:
  Headings: "Plus Jakarta Sans" (600-700 weight)
  Body:     "Plus Jakarta Sans" (400-500 weight)
  Sizes:    12px (caption), 14px (body), 16px (large), 20px (h3), 24px (h2), 32px (h1)

Spacing:
  Base unit: 4px
  Common:    8px, 12px, 16px, 24px, 32px

Border Radius:
  Small:  8px  (buttons, inputs)
  Medium: 12px (cards)
  Large:  16px (modals, sheets)
  Full:   9999px (pills, avatars)

Shadows:
  Card:   0 2px 8px rgba(0,0,0,0.08)
  Modal:  0 4px 24px rgba(0,0,0,0.12)
```

### 6.2 Screen Flow Reference

Reference wireframes: `/mnt/user-data/outputs/szybka-fucha-ux.html`

```
CLIENT FLOW:
Welcome → Registration → Categories → Task Details → Contractor Selection → Payment → Tracking → Completion

CONTRACTOR FLOW:
Registration → Verification (3 steps) → Dashboard → New Task Alert → Active Task → Completion
```

---

## 7. Non-Goals (Out of Scope for MVP)

| Feature | Reason | Future Phase |
|---------|--------|--------------|
| B2B accounts | Focus on B2C first | Phase 2 |
| Multi-language | Polish only for MVP | Phase 2 |
| Recurring tasks | Complexity | Phase 2 |
| Favorites list | Nice-to-have | Phase 2 |
| Referral program | Post-product-market-fit | Phase 2 |
| Insurance integration | Legal complexity | Phase 3 |
| AI task matching | Need data first | Phase 3 |
| Web client app | Mobile-first market | Phase 3 |

---

## 8. Success Metrics

### 8.1 Launch Criteria (Week 1)
- [ ] 200+ verified contractors in Warsaw
- [ ] 1,000+ registered clients
- [ ] Payment flow works end-to-end
- [ ] GPS tracking accurate to 50m
- [ ] App crash rate < 1%

### 8.2 MVP Success (Month 3)
| Metric | Target |
|--------|--------|
| Completed tasks | 1,000 |
| NPS score | > 40 |
| Avg completion time | < 2 hours |
| 30-day retention | > 25% |
| App store rating | > 4.0 |

### 8.3 Growth Metrics (Month 6)
| Metric | Target |
|--------|--------|
| Active users | 4,000 |
| Monthly tasks | 2,500 |
| GMV | 200,000 PLN |
| Revenue | 34,000 PLN |

---

## 9. Development Phases

### Phase 1: Foundation (Weeks 1-2)
```
□ Project setup (Flutter, NestJS, PostgreSQL)
□ Authentication module (Google, Apple, Phone)
□ User management (CRUD, profiles)
□ Basic API structure and error handling
□ Database migrations
```

### Phase 2: Core Features (Weeks 3-5)
```
□ Task creation flow
□ Contractor matching algorithm
□ Real-time location tracking
□ In-app chat
□ Push notifications
□ Stripe Connect integration
□ Payment escrow flow
```

### Phase 3: Verification & Polish (Weeks 6-7)
```
□ KYC flow (Onfido integration)
□ Rating system
□ Admin dashboard
□ UI polish and animations
□ Error handling improvements
□ Performance optimization
```

### Phase 4: Testing & Launch (Week 8)
```
□ Integration testing
□ User acceptance testing
□ App store submissions
□ Soft launch (limited users)
□ Bug fixes and monitoring
```

---

## 10. Open Questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | Final commission rate: 15% or 17%? | Business | Decided: 17% |
| 2 | BLIK integration in MVP or Phase 2? | Tech | TBD |
| 3 | Insurance requirements for contractors? | Legal | TBD |
| 4 | Minimum task value to prevent abuse? | Product | TBD (suggest 30 PLN) |
| 5 | Maximum service radius for contractors? | Product | Decided: 10km |

---

## 11. Appendix

### A. Category Details

| Category | Icon | Description | Suggested Price Range |
|----------|------|-------------|----------------------|
| Paczki | 📦 | Package pickup/delivery | 30-60 PLN |
| Zakupy | 🛒 | Shopping errands | 40-80 PLN |
| Kolejki | ⏰ | Waiting in lines | 50-100 PLN/h |
| Montaż | 🔧 | Simple assembly | 60-120 PLN |
| Przeprowadzki | 📦 | Moving help | 80-150 PLN/h |
| Sprzątanie | 🧹 | Express cleaning | 100-180 PLN |

### B. Status State Machine

```
TASK STATUS FLOW:
created → accepted → in_progress → completed
    ↓         ↓           ↓
cancelled  cancelled   disputed → resolved
```

### C. Error Codes

| Code | Message | Action |
|------|---------|--------|
| E001 | OTP expired | Request new OTP |
| E002 | User not found | Register first |
| E003 | Task not available | Already accepted |
| E004 | Payment failed | Retry with different card |
| E005 | KYC rejected | Contact support |
| E006 | Insufficient funds | Add money or different card |

---

**Document Status:** Ready for AI Agent Task Generation

**Next Step:** Use `prd-task-generator` skill to create implementation task list
