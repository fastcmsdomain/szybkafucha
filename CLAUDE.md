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
- **Multi-language**: Polish (index.html), English (index-en.html), Ukrainian (index-ua.html)

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
├── assets/           # Landing page images & videos
├── tasks/            # Project documentation
│   ├── prd-szybka-fucha.md            # Product Requirements Document
│   └── tasks-prd-szybka-fucha.md      # Development progress tracker
├── index.html        # Landing page (Polish)
├── index-en.html     # Landing page (English/British)
├── index-ua.html     # Landing page (Ukrainian)
├── privacy.html      # Privacy policy
├── terms.html        # Terms of service
├── cookies.html      # Cookie policy
├── styles.css        # Shared landing page styles
├── script.js         # Shared landing page JS (form validation, analytics)
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

# Access different language versions:
# Polish: http://localhost:8000/index.html
# English: http://localhost:8000/index-en.html
# Ukrainian: http://localhost:8000/index-ua.html
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

- **User-facing strings**: Language-specific per target audience
  - Polish for Polish users (index.html)
  - British English for English-speaking users (index-en.html)
  - Ukrainian for Ukrainian users (index-ua.html)
- **Code**: Always in English (variables, functions, classes, comments, commit messages)
- **Documentation**: PRD and task tracking in English, README files context-dependent

### Multi-Language Landing Page Structure

The landing page exists in three language versions with shared assets:

**Shared Resources:**
- `styles.css` - Single stylesheet for all language versions
- `script.js` - Single JavaScript file (form validation works across all languages)
- `assets/` - Images, videos, and icons are language-agnostic

**Language-Specific Files:**
- `index.html` - Polish version (primary)
- `index-en.html` - British English translation
- `index-ua.html` - Ukrainian translation

**Key Implementation Details:**
- All three versions share identical HTML structure and CSS classes
- Language switcher in header/footer links between versions (PL | UA | EN)
- Meta tags (title, description, og:locale) are localized per language
- Structured data (JSON-LD) is translated for each version
- Form validation messages come from `script.js` (currently Polish, can be extended)

**When Updating Landing Page Content:**
1. Make changes to `index.html` (Polish version) first
2. Translate and sync changes to `index-en.html` (British English spelling)
3. Translate and sync changes to `index-ua.html` (Ukrainian)
4. Verify all three versions maintain identical structure and styling
5. Test language switcher links work correctly across all pages

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

### Newsletter/Market Research Form

The landing page includes a comprehensive signup form that serves dual purposes:

**Form Fields:**
1. **Name** (required) - Full name
2. **Email** (required) - Email address for contact
3. **User Type** (required) - Radio buttons:
   - "Chcę zlecać" (I want to hire) - Client
   - "Chcę zarabiać" (I want to earn) - Contractor
4. **Services** (optional) - 12 checkboxes for service preferences:
   - Cleaning, Shopping & delivery, Minor repairs, Garden work
   - Pet care, Furniture assembly, Moving assistance, Queue waiting
   - Transport help, Tech support (IT), Tutoring, Event planning
5. **Comments** (optional) - Textarea for user ideas and suggestions (max 500 chars)
6. **Consent** (required) - Checkbox for marketing communications

**Purpose:**
- Originally: Simple newsletter signup for early adopters
- Current: Market research + newsletter combined
- Collects user preferences and feedback to shape product development
- Emphasizes co-creation: "Your opinion creates the app!"

**Form Submission:**
- Validates all required fields
- POSTs to backend `/api/v1/newsletter/subscribe` endpoint
- Success: Shows confirmation message
- Form data includes services array and comments for market insights

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
- Multi-language landing page (Polish, English, Ukrainian)
- Market research form with service preferences and feedback collection
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

### Update Landing Page Content

When syncing changes across language versions:

1. **Modify Polish version** (`index.html`) first - this is the source of truth
2. **Identify changed sections** - look for new HTML elements, updated copy, or structural changes
3. **Translate to English** (`index-en.html`):
   - Use British English spellings (organise, whilst, colour)
   - Keep brand name "Szybka Fucha" untranslated
   - Maintain engaging, conversational tone
   - Update meta tags, structured data, and all user-facing strings
4. **Translate to Ukrainian** (`index-ua.html`):
   - Use appropriate Ukrainian translations
   - Keep brand name "Szybka Fucha" untranslated
   - Update meta tags and structured data
5. **Test all versions**:
   - Visual inspection in browser (desktop + mobile)
   - Language switcher links work correctly
   - Forms submit successfully
   - No layout breaks or missing translations

**Common elements to translate:**
- Meta tags (`<title>`, `<meta name="description">`, Open Graph tags)
- Structured data (JSON-LD schemas for MobileApplication and FAQPage)
- Navigation labels
- Hero section (heading, subtitle, CTA buttons)
- Feature lists and benefits
- Form labels, placeholders, and button text
- FAQ questions and answers
- Footer content

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

## Documentation Standards
After completing any significant task:
1. Generate a summary document 
2. Include changed files, key decisions, and next steps
3. Save to docs/task-summaries-name/ with timestamp

## Skill: Task Completion Documentation

**When to use**: Every time a task, feature, or significant code change is completed.

**Purpose**: Ensure all completed work is properly documented with code examples, testing evidence, and clear explanations for future reference and team collaboration.

### Required Documentation Components

Every task completion documentation must include:

#### 1. Documentation and Code Examples

**What to include:**
- **Overview**: Brief description of what was implemented or changed
- **Code Examples**: 
  - Show key code snippets with file paths and line numbers
  - Include before/after comparisons when refactoring
  - Demonstrate usage examples for new functions/classes/endpoints
  - Show configuration changes if applicable
- **File Changes**: List all modified, created, or deleted files
- **Architecture Decisions**: Explain why certain approaches were chosen
- **Dependencies**: Note any new packages, libraries, or external services added

**Example Structure:**
```markdown
## Task: [Task Name]

### Overview
[Brief description of what was accomplished]

### Files Changed
- `backend/src/feature/feature.service.ts` - Added new method
- `backend/src/feature/dto/create-feature.dto.ts` - New DTO created
- `backend/src/feature/feature.controller.ts` - New endpoint added

### Code Examples

#### New Service Method
```typescript
// backend/src/feature/feature.service.ts
async createFeature(dto: CreateFeatureDto): Promise<Feature> {
  // Implementation details
}
```

#### New Endpoint
```typescript
// backend/src/feature/feature.controller.ts
@Post()
@UseGuards(JwtAuthGuard)
async create(@Body() dto: CreateFeatureDto) {
  return this.featureService.createFeature(dto);
}
```

### Usage Example
[Show how to use the new feature/endpoint]
```

#### 2. Testing

**What to include:**
- **Test Coverage**: List all test files created or updated
- **Test Cases**: Document what scenarios are covered
- **Test Results**: Include test execution results (pass/fail counts, coverage percentages)
- **Manual Testing**: Document any manual testing steps performed
- **Edge Cases**: Note any edge cases tested or identified

**Example Structure:**
```markdown
### Testing

#### Unit Tests
- `backend/src/feature/feature.service.spec.ts` - Service method tests
  - ✅ Test case: Successfully creates feature with valid data
  - ✅ Test case: Throws error with invalid input
  - ✅ Test case: Handles database errors gracefully

#### E2E Tests
- `backend/test/feature.e2e-spec.ts` - Endpoint integration tests
  - ✅ POST /api/v1/feature - Creates feature successfully
  - ✅ POST /api/v1/feature - Returns 400 for invalid data
  - ✅ POST /api/v1/feature - Returns 401 without authentication

#### Test Results
```
Test Suites: 2 passed, 2 total
Tests:       15 passed, 15 total
Coverage:    92% (feature.service.ts)
```

#### Manual Testing
1. Tested endpoint via Postman with valid JWT token
2. Verified error handling with invalid payloads
3. Confirmed database records are created correctly
```

#### 3. Clear Explanations

**What to include:**
- **Problem Statement**: What problem does this solve?
- **Solution Approach**: How was the problem solved?
- **Implementation Details**: Step-by-step explanation of the implementation
- **Trade-offs**: Any compromises or considerations made
- **Future Improvements**: Known limitations or planned enhancements
- **Related Documentation**: Links to relevant PRD sections, API docs, or other resources

**Example Structure:**
```markdown
### Explanation

#### Problem Statement
[What issue or requirement this addresses]

#### Solution Approach
[High-level approach taken to solve the problem]

#### Implementation Details
1. [Step 1 explanation]
2. [Step 2 explanation]
3. [Step 3 explanation]

#### Trade-offs
- [Any compromises made and why]

#### Future Improvements
- [Known limitations or planned enhancements]

#### Related Documentation
- PRD Section: [Link or reference]
- API Documentation: [Link if applicable]
```

### Documentation Template

Use this template for consistent documentation:

```markdown
# Task Completion: [Task Name]

**Date**: [YYYY-MM-DD]
**Developer**: [Name or identifier]
**Related Issue/Task**: [Link or reference]

## Overview
[Brief description of what was accomplished]

## Files Changed
- [List all modified/created/deleted files]

## Code Examples

### [Component/Feature Name]
[Code examples with explanations]

## Testing

### Test Coverage
[Test files and coverage]

### Test Results
[Execution results]

### Manual Testing
[Manual testing steps and results]

## Explanation

### Problem Statement
[What this solves]

### Solution Approach
[How it was solved]

### Implementation Details
[Step-by-step explanation]

### Trade-offs
[Any compromises]

### Future Improvements
[Known limitations or enhancements]

## Next Steps
[What should be done next, if anything]
```

### Documentation Location

Save documentation in:
- **Path**: `docs/task-summaries/[task-name]-[YYYY-MM-DD].md`
- **Format**: Markdown (.md)
- **Naming**: Use kebab-case, include date

**Example**: `docs/task-summaries/contractor-matching-2024-01-15.md`

### Quality Checklist

Before considering documentation complete, verify:

- [ ] Overview clearly explains what was done
- [ ] All changed files are listed
- [ ] Code examples are included with file paths
- [ ] Code examples show actual implementation (not pseudocode)
- [ ] Test files are documented
- [ ] Test results are included
- [ ] Manual testing steps are documented
- [ ] Problem statement is clear
- [ ] Solution approach is explained
- [ ] Implementation details are step-by-step
- [ ] Trade-offs are acknowledged
- [ ] Future improvements are noted
- [ ] Documentation is saved in correct location
- [ ] Documentation follows the template structure

### Integration with Development Workflow

1. **During Development**: Take notes on decisions and approaches
2. **After Implementation**: Write code examples and test results
3. **Before Commit**: Complete documentation using the template
4. **After Review**: Update documentation based on feedback if needed

### Benefits

Following this skill ensures:
- **Knowledge Preservation**: Future developers understand what was done and why
- **Onboarding**: New team members can quickly understand the codebase
- **Debugging**: Clear documentation helps identify issues faster
- **Refactoring**: Understanding original decisions aids safe refactoring
- **Testing**: Test documentation ensures coverage is maintained
- **Compliance**: Meets project requirements for documentation standards