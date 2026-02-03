# Current Update Log

This file tracks all changes made by Claude in the repository. New entries are added at the top (most recent first).

Each entry documents:
- What was changed
- Which files were modified
- System impact
- Potential conflicts or risks

**Important**: Claude must read this file before starting any new task to avoid conflicts and regressions.

---

## [2026-02-02] Fix PostgreSQL Connection Pool Configuration

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed "too many clients already" PostgreSQL error by adding proper connection pool configuration to TypeORM
- **Files Changed**:
  - `backend/src/app.module.ts` – Added connection pool settings (max: 10, min: 2, idle timeout, connection timeout), retry configuration, and keepConnectionAlive option
- **System Impact**:
  - TypeORM now properly manages database connections with a maximum of 10 concurrent connections
  - Idle connections are closed after 30 seconds to prevent connection leaks
  - Connection retry logic added (3 attempts with 3-second delay)
  - Prevents "too many clients already" errors during hot reloading and development
- **Related Tasks/PRD**: Backend infrastructure, database configuration
- **Potential Conflicts/Risks**:
  - Connection pool settings may need adjustment in production based on load
  - If multiple backend instances are deployed, ensure total connections across all instances don't exceed PostgreSQL's max_connections (100)
  - Consider monitoring connection pool metrics in production

---

## [2026-02-02] MVP Job Flow Implementation

- **Developer/Agent**: Claude
- **Scope of Changes**: Implemented new job flow per `tasks/job_flow.md` requirements including rainbow progress dots, payment popup, dual-rating tracking, and UI enhancements for both client and contractor screens.
- **Files Changed**:
  - `backend/src/tasks/dto/create-task.dto.ts` – Updated minimum budget from 30 to 35 PLN
  - `backend/src/tasks/entities/task.entity.ts` – Added `clientRated` and `contractorRated` boolean fields for dual-rating tracking
  - `backend/src/tasks/tasks.service.ts` – Updated `rateTask()` to set clientRated/contractorRated flags when each party rates
  - `mobile/lib/core/widgets/sf_rainbow_progress.dart` – NEW: Rainbow progress dots widget with colorful step indicators
  - `mobile/lib/core/widgets/widgets.dart` – Exported new rainbow progress widget
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Added rainbow progress, payment popup dialog when confirming contractor
  - `mobile/lib/features/contractor/screens/active_task_screen.dart` – Added rainbow progress (smaller), simplified to 4 steps
  - `mobile/lib/features/contractor/screens/review_client_screen.dart` – Connected rating submission to backend API
  - `docs/qa/job-flow-testing-guide.md` – NEW: Comprehensive QA testing guide for job flow
- **System Impact**:
  - Budget validation now requires minimum 35 PLN (was 30 PLN)
  - Task entity has new columns: `clientRated`, `contractorRated` (booleans, default false)
  - Rating submission now tracks which party has rated
  - UI shows rainbow-colored progress indicators instead of plain blue
  - Client sees payment method popup (cash/card placeholders) before confirming contractor
  - Contractor progress simplified to 4 steps (removed "Do potwierdzenia")
- **Related Tasks/PRD**: `tasks/job_flow.md`, Task lifecycle management
- **Potential Conflicts/Risks**:
  - Database migration needed for new `clientRated`/`contractorRated` columns in production
  - Budget minimum change may affect existing task creation flows - verify mobile app validation matches backend

---

## [2026-02-01] Implement PENDING_COMPLETE Task Status Flow

- **Developer/Agent**: Claude
- **Scope of Changes**: Added new `pending_complete` task status to implement proper two-step task completion flow where client confirms first, then contractor finalizes.
- **Files Changed**:
  - `backend/src/tasks/entities/task.entity.ts` – Added `PENDING_COMPLETE` to TaskStatus enum
  - `backend/src/tasks/tasks.controller.ts` – Added `/confirm-completion` endpoint for client to confirm job completion
  - `backend/src/tasks/tasks.service.ts` – Added `confirmCompletion()` method, updated `completeTask()` to require `PENDING_COMPLETE` status, updated `rateTask()` and `addTip()` to accept `PENDING_COMPLETE` status
  - `mobile/lib/features/client/screens/client_home_screen.dart` – Added missing `pendingComplete` case to switch statement
  - `mobile/lib/features/contractor/screens/task_completion_screen.dart` – Updated success message text
- **System Impact**:
  - New task completion flow: `IN_PROGRESS` → (client confirms) → `PENDING_COMPLETE` → (contractor finalizes) → `COMPLETED`
  - Client can now rate and tip when task is in `PENDING_COMPLETE` status
  - WebSocket broadcasts `pending_complete` status updates to both parties
- **Related Tasks/PRD**: Task lifecycle management, payment flow
- **Potential Conflicts/Risks**:
  - Database enum change requires migration for production (PostgreSQL enum)
  - Existing tasks in `IN_PROGRESS` status cannot be completed directly by contractor - they need client confirmation first

---

## [2026-01-29] Initial currentupdate.md Setup

- **Developer/Agent**: Claude
- **Scope of Changes**: Created `currentupdate.md` file and added change tracking rules to `CLAUDE.md`
- **Files Changed**:
  - `currentupdate.md` – Created new change log file
  - `CLAUDE.md` – Added "Change Tracking with currentupdate.md" section with mandatory workflow rules
- **System Impact**: Establishes change tracking system to prevent regressions and identify conflicts
- **Related Tasks/PRD**: Documentation standards implementation
- **Potential Conflicts/Risks**: None (initial setup)

---
