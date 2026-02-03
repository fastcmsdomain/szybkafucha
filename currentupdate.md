# Current Update Log

This file tracks all changes made by Claude in the repository. New entries are added at the top (most recent first).

Each entry documents:
- What was changed
- Which files were modified
- System impact
- Potential conflicts or risks

**Important**: Claude must read this file before starting any new task to avoid conflicts and regressions.

---

## [2026-02-03] Add Dual-Rating Tracking and PENDING_COMPLETE Status

- **Developer/Agent**: Claude
- **Scope of Changes**: Added missing `clientRated`/`contractorRated` columns and `PENDING_COMPLETE` status to Task entity to fix "column Task.clientRated does not exist" error
- **Files Changed**:
  - `backend/src/tasks/entities/task.entity.ts` – Added `clientRated` (boolean, default false), `contractorRated` (boolean, default false) columns and `PENDING_COMPLETE` enum value
- **System Impact**:
  - Task entity now supports dual-rating tracking (status changes to COMPLETED only when both parties rate)
  - New task status flow: `IN_PROGRESS` → `PENDING_COMPLETE` (client confirms) → `COMPLETED` (after both rate)
  - Database schema auto-synchronized via TypeORM (columns and enum value added)
- **Related Tasks/PRD**: `tasks/job_flow.md`, task completion flow
- **Potential Conflicts/Risks**:
  - Backend service methods that use these fields need to be updated (rateTask, completeTask)
  - Mobile app task models may need `pendingComplete` status handling

---

## [2026-01-31] Fix Avatar URL and Public Profile Endpoint

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed two issues preventing avatar/bio from showing in contractor profile and client popup
- **Files Changed**:
  - `mobile/lib/core/api/api_config.dart` – Added `serverUrl` constants and `getFullMediaUrl()` helper
  - `mobile/lib/core/providers/auth_provider.dart` – Updated User.fromJson to convert relative avatar URLs to full URLs
  - `mobile/lib/features/client/models/contractor.dart` – Updated Contractor.fromJson to convert avatar URLs
  - `mobile/lib/core/services/websocket_service.dart` – Updated ContractorInfo.fromJson to convert avatar URLs
  - `backend/src/contractor/contractor.service.ts` – Added UsersService injection, updated getPublicProfile to fall back to User data
- **System Impact**:
  - Avatar URLs now include full server URL (e.g., `http://localhost:3000/uploads/avatars/file.jpg`)
  - Public profile endpoint no longer throws 404 if contractor_profiles entry doesn't exist
  - Bio and avatar now correctly display in client popup
- **Related Tasks/PRD**: Contractor profile management
- **Potential Conflicts/Risks**: None


1. **Avatar not visible**: Backend returned relative URL `/uploads/avatars/file.jpg`, but NetworkImage needs full URL
2. **Bio/Profile error**: `getPublicProfile` threw 404 if no `contractor_profiles` entry existed - now falls back to User data

---

## [2026-01-31] Contractor Profile Photo Upload

- **Developer/Agent**: Claude
- **Scope of Changes**: Implemented photo upload functionality in contractor profile screen
- **Files Changed**:
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Added photo picker and upload to `POST /users/me/avatar`
- **System Impact**:
  - Contractors can now upload profile photos from camera or gallery
  - Photos are uploaded to backend via multipart form data
  - Avatar displays in contractor profile and client popup (via existing code)
- **Related Tasks/PRD**: Contractor profile management
- **Potential Conflicts/Risks**: None

**Features Added**:
- Bottom sheet with camera/gallery selection
- Image picker with size optimization (1024x1024, 85% quality)
- Upload loading indicator on avatar
- Success/error feedback via SnackBar

---

## [2026-01-31] Bug Fix: Contractor Bio Not Persisting After Save

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed bug where contractor bio ("o mnie") wasn't persisting after save
- **Files Changed**:
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Added `refreshUser()` call after successful profile save
- **System Impact**:
  - After saving profile, authProvider is now refreshed to fetch updated user data from backend
  - Bio field now correctly persists when user exits and re-enters profile screen
- **Related Tasks/PRD**: Contractor profile management
- **Potential Conflicts/Risks**: None

**Root Cause**: After `api.put('/users/me')` succeeded, the `authProvider` was not refreshed. When user re-entered the profile screen, the old bio was loaded from stale authProvider state.

**Fix Applied**:
```dart
await api.put('/users/me', data: payload);
// Refresh user data in authProvider to update local state
await ref.read(authProvider.notifier).refreshUser();
```

---

## [2026-01-31] Contractor Profile Database Integration

- **Developer/Agent**: Claude
- **Scope of Changes**: Integrated contractor profile with database - bio persistence, real ratings display, public profile endpoint, WebSocket bio transmission
- **Files Changed**:
  - `backend/src/contractor/contractor.controller.ts` – Added `GET /:userId/public` endpoint
  - `backend/src/contractor/contractor.service.ts` – Added `getPublicProfile()` method
  - `backend/src/realtime/realtime.gateway.ts` – Added `bio` field to contractor broadcast type
  - `backend/src/tasks/tasks.service.ts` – Include bio when broadcasting task acceptance
  - `mobile/lib/features/client/models/contractor.dart` – Added `bio` field with JSON parsing
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Refactored Profil popup to fetch real data
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Fixed bio initialization, added real ratings fetch
  - `mobile/lib/core/services/websocket_service.dart` – Added `bio` field to `ContractorInfo`
  - `docs/task-summaries/contractor-profile-integration-2026-01-31.md` – Created detailed documentation
- **System Impact**:
  - New API endpoint: `GET /contractor/:userId/public` (requires JWT)
  - Contractor profile screen now shows real ratings from database
  - Client "Profil" popup shows real bio from database
  - WebSocket task acceptance now includes contractor bio
- **Related Tasks/PRD**: Contractor profile management, task tracking UI
- **Potential Conflicts/Risks**:
  - Files modified in contractor module - future changes should check this entry
  - WebSocket message format changed (added bio field) - mobile clients must be updated

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
