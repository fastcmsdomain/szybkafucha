# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Szybka Fucha** is a mobile marketplace platform connecting busy professionals with local helpers for immediate small tasks (micro-gigs). The platform consists of three main components:

1. **Landing Page** - Static HTML/CSS/JS for pre-launch newsletter collection
2. **Backend** - NestJS REST API with TypeORM and PostgreSQL
3. **Admin Panel** - React + Chakra UI dashboard for user management
4. **Mobile App** (Future) - Flutter application (not yet in repo)

## Tech Stack

### Backend (NestJS)
- **Framework**: NestJS v11
- **Database**: PostgreSQL with PostGIS extension
- **ORM**: TypeORM with entity synchronization
- **Authentication**: JWT + Passport (supports Google, Apple, Phone/OTP)
- **Real-time**: Socket.io (WebSockets)
- **Payments**: Stripe integration
- **KYC**: Onfido integration for identity verification
- **Language**: TypeScript with strict validation (class-validator, class-transformer)

### Admin Panel (React)
- **Framework**: React 19 + TypeScript
- **UI Library**: Chakra UI v3
- **State/Data**: TanStack Query (React Query)
- **Routing**: React Router v7
- **HTTP Client**: Axios

### Landing Page
- **Pure**: Vanilla HTML5, CSS3, JavaScript
- **No frameworks**: Zero dependencies for maximum performance
- **Responsive**: Mobile-first design with WCAG 2.2 compliance

## Repository Structure

```
/
├── backend/          # NestJS API server
│   ├── src/
│   │   ├── auth/            # Authentication (JWT, Google, Apple, Phone)
│   │   ├── users/           # User management
│   │   ├── tasks/           # Task management & ratings
│   │   ├── contractor/      # Contractor profiles
│   │   ├── payments/        # Stripe payment processing
│   │   ├── messages/        # In-app messaging
│   │   ├── realtime/        # WebSocket gateway
│   │   ├── kyc/             # Onfido KYC verification
│   │   ├── newsletter/      # Newsletter subscriber management
│   │   ├── admin/           # Admin-only endpoints
│   │   └── database/seeds/  # Database seeding scripts
│   └── DEPLOYMENT.md        # Production deployment guide
├── admin/            # React admin dashboard
│   └── src/
│       ├── pages/           # Dashboard, Users, Tasks, Disputes
│       └── components/      # Reusable UI components
├── api/              # Legacy PHP endpoints (to be replaced)
├── assets/           # Landing page images
├── tasks/            # Project documentation
│   ├── prd-szybka-fucha.md            # Product Requirements Document
│   └── tasks-prd-szybka-fucha.md      # Development progress tracker
├── index.html        # Landing page
├── styles.css        # Landing page styles
├── script.js         # Landing page JS (form validation, analytics)
└── docker-compose.yml # Local development environment
```

## Development Commands

### Backend Development

```bash
cd backend

# Install dependencies
npm install

# Development server with hot-reload
npm run start:dev

# Production build
npm run build
npm run start:prod

# Testing
npm test                    # Unit tests
npm run test:watch          # Watch mode
npm run test:e2e            # End-to-end tests
npm run test:cov            # Coverage report

# Code quality
npm run lint                # ESLint with auto-fix
npm run format              # Prettier formatting

# Database seeding
npm run seed                # Seed database with test data
npm run seed:fresh          # Drop and recreate with fresh data
```

### Admin Panel Development

```bash
cd admin

# Install dependencies
npm install

# Development server (port 3000)
npm start

# Production build
npm run build

# Testing
npm test
```

### Landing Page Development

```bash
# Serve static files with Python
python3 -m http.server 8000

# Or with Node.js
npx serve
```

### Docker Development Environment

```bash
# Start PostgreSQL + Redis + pgAdmin
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f
```

**Docker Services:**
- PostgreSQL (PostGIS): `localhost:5432` (user: szybkafucha, pass: szybkafucha_dev_password)
- Redis: `localhost:6379`
- pgAdmin: `http://localhost:5050` (admin@szybkafucha.pl / admin123)

## Architecture Patterns

### Backend Module Structure

Each feature follows NestJS modular architecture:

```
feature/
├── feature.module.ts        # Module definition with imports/exports
├── feature.controller.ts    # HTTP endpoints (REST API)
├── feature.service.ts       # Business logic
├── entities/
│   └── feature.entity.ts    # TypeORM entity (database model)
└── dto/                     # Data Transfer Objects for validation
    ├── create-feature.dto.ts
    └── update-feature.dto.ts
```

**Key Principles:**
- Controllers handle HTTP/WebSocket requests only
- Services contain all business logic
- DTOs use class-validator decorators for automatic validation
- Entities define database schema with TypeORM decorators
- Guards protect routes (JWT authentication, role-based access)

### Database Entity Relationships

```
User (1) ──< (n) Task
User (1) ──< (1) ContractorProfile
Task (1) ──< (n) Rating
Task (1) ──< (n) Message
User (1) ──< (n) Payment
User (1) ──< (1) KycCheck
```

### Real-time Architecture

- WebSocket gateway in `realtime/` module
- Events: task updates, new messages, location tracking
- Rooms: per-task chat rooms, user notification rooms
- All socket events require JWT authentication

### Payment Flow (Stripe Escrow)

1. Client posts task → Payment authorized (hold)
2. Contractor accepts → Payment held in escrow
3. Task completed → Client confirms → Release to contractor (83%, 17% commission)
4. Dispute → Admin resolution → Manual release/refund

## Configuration

### Backend Environment Variables

Create `backend/.env`:

```bash
NODE_ENV=development
PORT=3000
API_PREFIX=api/v1

# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha
DATABASE_PASSWORD=szybkafucha_dev_password
DATABASE_NAME=szybkafucha

# CORS
LANDING_PAGE_URL=http://localhost:8000
FRONTEND_URL=http://localhost:3001
ADMIN_URL=http://localhost:3002

# JWT
JWT_SECRET=your_dev_jwt_secret_at_least_32_characters

# Stripe (for payments module)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Onfido (for KYC module)
ONFIDO_API_TOKEN=api_token_...
```

### Landing Page API Configuration

Update `script.js` CONFIG object:

```javascript
const CONFIG = {
  apiEndpoint: '/api/newsletter/subscribe', // or full URL for production
  maxServices: 10,
  minServices: 1
};
```

## Important Conventions

### Code Language Rules

- **User-facing strings**: Always in Polish (UI labels, validation messages, emails)
- **Code**: Always in English (variables, functions, classes, comments, commit messages)
- **Documentation**: PRD and task tracking in English, README files context-dependent

### Testing Requirements

- Every REST endpoint must have corresponding test coverage
- Use Jest for unit tests, Supertest for e2e tests
- Test file naming: `*.spec.ts` (unit), `*.e2e-spec.ts` (e2e)

### API Response Format

All endpoints return consistent JSON structure:

```typescript
// Success
{ "success": true, "message": "...", "data": {...} }

// Error (handled by NestJS exception filters)
{ "statusCode": 400, "message": ["..."], "error": "Bad Request" }
```

### Entity Soft Deletes

Use `isActive` flag instead of hard deletes for user data:

```typescript
@Column({ default: true })
isActive: boolean;

@Column({ nullable: true })
deletedAt: Date;
```

## Key Business Logic

### User Types

1. **Client (Zleceniodawca)**: Posts tasks, pays for services
2. **Contractor (Wykonawca)**: Accepts tasks, earns money (verified via KYC)
3. **Admin**: Platform operator, dispute resolution

### Task Categories

Six core categories defined in PRD:
- Paczki (Packages)
- Zakupy (Shopping)
- Kolejki (Queues/Waiting)
- Montaż (Assembly)
- Przeprowadzki (Moving)
- Sprzątanie (Cleaning)

### Task Lifecycle

```
POSTED → ACCEPTED → IN_PROGRESS → COMPLETED → RATED
           ↓
       DISPUTED → RESOLVED
```

### Commission Model

- Platform takes 17% commission
- Contractor receives 83% of task value
- Payment held in Stripe escrow until completion

## Development Workflow

### Working with Database

**Development**: TypeORM synchronize is enabled (auto-creates tables)
**Production**: Manual migrations required (disable synchronize)

Seed development data:
```bash
cd backend
npm run seed        # Add test users, tasks, contractors
npm run seed:fresh  # Drop everything and recreate
```

### Running Full Stack Locally

1. Start database: `docker-compose up -d postgres redis`
2. Start backend: `cd backend && npm run start:dev`
3. Start admin panel: `cd admin && npm start`
4. Serve landing page: `python3 -m http.server 8000` (from root)

### API Endpoints Overview

**Base URL**: `http://localhost:3000/api/v1`

**Public Endpoints**:
- `POST /auth/phone/request-otp` - Request SMS OTP
- `POST /auth/phone/verify` - Verify OTP and login
- `POST /auth/google` - Google OAuth
- `POST /auth/apple` - Apple Sign In
- `POST /newsletter/subscribe` - Newsletter signup (landing page)

**Protected Endpoints** (require JWT):
- `/users/*` - User profile management
- `/tasks/*` - Task CRUD operations
- `/contractor/*` - Contractor profile, availability
- `/payments/*` - Payment operations
- `/messages/*` - In-app messaging
- `/kyc/*` - Identity verification

**Admin Only**:
- `/admin/*` - Admin operations
- `/newsletter/subscribers` - View all newsletter subscribers
- `/newsletter/stats` - Newsletter statistics

## Project Status & Roadmap

Refer to `/tasks/tasks-prd-szybka-fucha.md` for current progress and remaining tasks.

**Completed**:
- Landing page with newsletter collection
- Backend API structure with all core modules
- Admin panel with user management dashboard
- Database schema and relationships

**In Progress/Planned**:
- Flutter mobile app
- Real-time location tracking
- Payment integration testing
- KYC verification flow
- Production deployment

## Additional Resources

- **PRD**: `/tasks/prd-szybka-fucha.md` - Complete product requirements
- **Deployment Guide**: `/backend/DEPLOYMENT.md` - Production deployment steps
- **Admin Guide**: `/admin/README.md` - Admin panel documentation (in Polish)
- **Project Rules**: `/.cursorrules` - Code style and conventions

## Common Tasks

### Add New Endpoint

1. Create DTO in `dto/` folder with validation decorators
2. Add method to service with business logic
3. Add route to controller with proper guards
4. Write tests in `*.spec.ts` file
5. Update this documentation if needed

### Add New Entity

1. Create entity file in `entities/` folder
2. Add entity to `app.module.ts` TypeORM entities array
3. Run in dev mode to auto-create table (or write migration for production)
4. Create corresponding module/service/controller

### Debug Issues

- Check backend logs: `npm run start:dev` (console output)
- Check database: Connect to pgAdmin at `localhost:5050`
- Check API responses: Use Postman or `curl` commands
- Enable TypeORM logging: Set `logging: true` in `app.module.ts`
