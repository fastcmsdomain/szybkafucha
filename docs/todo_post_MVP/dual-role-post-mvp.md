# Dual-Role Post-MVP: Implementation Guide

**Date**: 2026-02-09
**Status**: Disabled in MVP (ready for re-enablement)
**Priority**: Post-MVP feature

## Context

In MVP, users are locked to a single role selected during registration:
- **Client (szef)** - can only create tasks
- **Contractor (pracownik)** - can only accept tasks

This document describes how to safely re-enable dual-role functionality, allowing users to operate as both client and contractor from a single account.

---

## Current State (MVP)

### What's Blocked

| Layer | File | What's Blocked |
|-------|------|----------------|
| Backend Auth | `backend/src/auth/auth.service.ts` | Auto-adding roles on subsequent logins |
| Backend API | `backend/src/users/users.controller.ts` | `PATCH /users/me/type` and `POST /users/me/add-role` endpoints |
| Mobile UI | `mobile/lib/features/settings/screens/settings_screen.dart` | Role switch tile removed |
| Mobile Router | `mobile/lib/core/router/app_router.dart` | Settings route removed |

### What's Already Built (Ready to Use)

The entire dual-role infrastructure remains in codebase:

**Backend:**
- `User.types` field is `simple-array` in `backend/src/users/entities/user.entity.ts:36` - already supports `['client', 'contractor']`
- `UsersService.addRole()` method in `backend/src/users/users.service.ts:105-120` - adds role to types array
- `AddRoleDto` in `backend/src/users/dto/add-role.dto.ts` - validated DTO
- `UpdateUserTypeDto` in `backend/src/users/dto/update-user-type.dto.ts` - validated DTO
- Lazy profile creation - ClientProfile/ContractorProfile created on first edit

**Mobile:**
- `User.hasBothRoles` getter in `mobile/lib/core/providers/auth_provider.dart:100`
- `AuthNotifier.switchUserType()` in `mobile/lib/core/providers/auth_provider.dart:604-637`
- `AuthNotifier.addRole()` in `mobile/lib/core/providers/auth_provider.dart:681-702`
- `AuthNotifier.setActiveRole()` in `mobile/lib/core/providers/auth_provider.dart:704-710`
- `AuthState.activeRole` field in `mobile/lib/core/providers/auth_provider.dart:134`

---

## Step-by-Step Re-enablement

### Step 1: Backend - Restore Auth Service Auto-Add

**File**: `backend/src/auth/auth.service.ts`

**Current code** (3 places - phone, Google, Apple auth):
```typescript
} else if (userType && user.types.length === 0) {
  // MVP: Only add role if user has no roles yet (prevents role switching)
  user = await this.usersService.addRole(user.id, userType);
}
```

**Change to** (restore original):
```typescript
} else if (userType && !user.types.includes(userType)) {
  // User wants to add a new role - use addRole method
  user = await this.usersService.addRole(user.id, userType);
}
```

**Locations** (all three must be updated):
1. `verifyPhoneOtp()` - line ~155
2. `authenticateWithGoogle()` - line ~198
3. `authenticateWithApple()` - line ~243

**Effect**: When a client logs in and selects "contractor" on welcome screen, the contractor role will be added to their types array automatically.

---

### Step 2: Backend - Remove Controller Guards

**File**: `backend/src/users/users.controller.ts`

**Remove the MVP guards from two endpoints:**

#### Endpoint 1: `PATCH /users/me/type`

**Current code** (lines ~74-79):
```typescript
// MVP: Prevent role changes for users who already have roles
if (req.user.types && req.user.types.length > 0) {
  throw new BadRequestException(
    'Role changes are not allowed in MVP. Please contact support if you need to change your role.',
  );
}
```

**Action**: Delete these 5 lines entirely.

#### Endpoint 2: `POST /users/me/add-role`

**Current code** (lines ~164-169):
```typescript
// MVP: Prevent adding roles for users who already have roles
if (req.user.types && req.user.types.length > 0) {
  throw new BadRequestException(
    'Adding roles is not allowed in MVP. Please contact support if you need to add a role.',
  );
}
```

**Action**: Delete these 5 lines entirely.

---

### Step 3: Mobile - Restore Role Switch UI in Settings

Create a new settings section in the profile screen or restore the dedicated settings screen.

**Option A: Add role switch to profile screen** (recommended)

Add to `mobile/lib/features/profile/screens/profile_screen.dart` in the "Konto" section:

```dart
// In _buildSection 'Konto' children list, add before 'Edytuj profil':
if (user != null && !user.hasBothRoles)
  _buildMenuItem(
    icon: Icons.swap_horiz,
    title: 'Dodaj rolę',
    subtitle: user.isContractor ? 'Dodaj rolę Klienta' : 'Dodaj rolę Wykonawcy',
    onTap: () => _showAddRoleDialog(context, ref, user),
  ),
if (user != null && user.hasBothRoles)
  _buildMenuItem(
    icon: user.isContractor ? Icons.work : Icons.attach_money,
    title: 'Zmień rolę',
    subtitle: user.isContractor ? 'Przełącz na Klienta' : 'Przełącz na Wykonawcę',
    onTap: () => _showSwitchRoleDialog(context, ref, user),
  ),
```

**Option B: Restore settings screen and route**

Restore the settings route in `app_router.dart`:
```dart
// Import
import '../../features/settings/screens/settings_screen.dart';

// In routes list
GoRoute(
  path: Routes.settings,
  name: 'settings',
  builder: (context, state) => const SettingsScreen(),
),
```

Restore the settings icon in profile AppBar:
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => context.push(Routes.settings),
  ),
],
```

Then restore the role switch tile in `settings_screen.dart` (see git history, commit before `0594674`).

---

### Step 4: Handle Login/Registration Conflicts

This is the critical part to handle safely.

#### Problem: User logs in with different role than registered

**Scenario**: User registered as client, logs out, then logs in selecting "contractor".

**Current flow after re-enablement** (Step 1):
1. Backend auto-adds "contractor" to types array
2. JWT token now contains both roles
3. Router redirect checks `user.isContractor == true` → routes to contractor home
4. User is now a contractor without completing contractor profile

#### Solution: Add onboarding flow for new role

After adding a new role, redirect user to profile completion screen:

**Backend** - Add profile completion check in `addRole()`:

```typescript
// In backend/src/users/users.service.ts - addRole method
async addRole(userId: string, role: 'client' | 'contractor'): Promise<User> {
  const user = await this.findByIdOrFail(userId);

  if (user.types.includes(role)) {
    return user; // Already has role
  }

  user.types.push(role);
  const savedUser = await this.usersRepository.save(user);

  // Return user with flag indicating new role was added
  // Frontend can use this to show onboarding for the new role
  return savedUser;
}
```

**Mobile** - After role switch, check profile completion:

```dart
// In auth_provider.dart - switchUserType method
Future<void> switchUserType(String newUserType) async {
  // ... existing code ...

  // After successful switch, check if profile needs completion
  if (newUserType == 'contractor') {
    // Check contractor profile completion
    final api = _ref.read(apiClientProvider);
    final profileComplete = await api.get('/contractor/profile/complete');
    if (profileComplete['isComplete'] != true) {
      // Navigate to contractor profile edit for setup
      // This should be handled by the calling code
    }
  }
}
```

#### Solution: Router redirect for dual-role users

Update `app_router.dart` redirect logic to handle `activeRole`:

```dart
// Current (MVP):
final destination = user?.isContractor == true
    ? Routes.contractorHome
    : Routes.clientHome;

// Post-MVP (dual-role aware):
final authState = ref.read(authProvider);
final activeRole = authState.activeRole;
final destination = activeRole == 'contractor'
    ? Routes.contractorHome
    : Routes.clientHome;
```

---

### Step 5: UI Considerations for Dual-Role Users

#### Bottom Navigation
When user has both roles, add a role indicator or switcher:

```dart
// Option: Add role badge to profile tab
NavigationDestination(
  icon: Stack(
    children: [
      Icon(Icons.person_outline),
      if (user.hasBothRoles)
        Positioned(
          right: 0, bottom: 0,
          child: Icon(Icons.swap_horiz, size: 12),
        ),
    ],
  ),
  label: 'Profil',
),
```

#### Profile Screen Header
Show current role and switch option:

```dart
// Add under user type badge in _buildUserHeader()
if (user.hasBothRoles)
  TextButton.icon(
    onPressed: () => _quickSwitchRole(context, ref, user),
    icon: Icon(Icons.swap_horiz, size: 16),
    label: Text('Przełącz na ${user.isContractor ? "Klienta" : "Wykonawcę"}'),
  ),
```

---

## Critical Considerations

### 1. Contractor Profile Completion

Contractors must complete their profile before accepting tasks. When a client adds the contractor role:
- They need: name, address, bio, categories (min 1), service radius
- KYC verification may also be required
- **Block task acceptance** until profile is complete (this guard already exists in `tasks.service.ts`)

### 2. Active Role State

The `AuthState.activeRole` field determines which home screen and UI flow the user sees.

**Important**: When switching roles:
- Save `activeRole` to local storage so it persists across app restarts
- Update all providers that depend on role (task providers, availability)
- Set contractor offline when switching to client role
- Refresh task lists for the new role

### 3. Notifications

Dual-role users may receive notifications for both roles:
- Task creation notifications (as client)
- Available task notifications (as contractor)
- Consider adding role context to notifications

### 4. WebSocket Rooms

When switching roles, the user needs to:
- Leave current role's WebSocket rooms
- Join new role's WebSocket rooms
- This is handled by `WebSocketService` reconnection

### 5. Data Separation

Client and contractor data are already separated:
- `client_profiles` table for client bio/ratings
- `contractor_profiles` table for contractor bio/ratings/categories
- `ratings` table has `role` field ('client' or 'contractor')
- Task ownership is tracked by `clientId` and `contractorId` columns

### 6. Payment Flow

When user is dual-role:
- As client: Can create tasks and pay
- As contractor: Can accept tasks and receive payments
- **Rule**: User CANNOT accept their own tasks (add validation in `tasks.service.ts`)

```typescript
// backend/src/tasks/tasks.service.ts - acceptTask method
if (task.clientId === contractorUserId) {
  throw new BadRequestException('Cannot accept your own task');
}
```

---

## Testing Plan

### Backend Tests

```bash
# 1. New user registration (should work as before)
POST /api/v1/auth/phone/verify
{ "phoneNumber": "+48111111111", "code": "123456", "userType": "client" }
# Expected: types: ['client']

# 2. Same user adds contractor role via login
POST /api/v1/auth/phone/verify
{ "phoneNumber": "+48111111111", "code": "123456", "userType": "contractor" }
# Expected: types: ['client', 'contractor']

# 3. Add role via endpoint
POST /api/v1/users/me/add-role
Authorization: Bearer <token>
{ "role": "contractor" }
# Expected: types: ['client', 'contractor']

# 4. Switch active role
PATCH /api/v1/users/me/type
Authorization: Bearer <token>
{ "type": "contractor" }
# Expected: types includes 'contractor', user can access contractor features

# 5. Prevent self-acceptance
# Create task as client, then try to accept as contractor (same user)
PUT /api/v1/tasks/:id/accept
Authorization: Bearer <same-user-token>
# Expected: 400 Bad Request - "Cannot accept your own task"
```

### Mobile Tests

1. **Add role flow**: Client taps "Add contractor role" → Profile completion → Can now accept tasks
2. **Switch role flow**: Dual-role user switches → Correct home screen shows → Correct tasks load
3. **Profile isolation**: Edit client profile → Switch to contractor → Contractor profile shows different data
4. **Persistence**: Switch to contractor → Close app → Reopen → Still on contractor home
5. **Notifications**: Receive notifications for both roles

---

## Files Reference

### Files to Modify

| File | Change |
|------|--------|
| `backend/src/auth/auth.service.ts` | Restore `!user.types.includes(userType)` check (3 places) |
| `backend/src/users/users.controller.ts` | Remove MVP guards (2 endpoints) |
| `mobile/lib/features/profile/screens/profile_screen.dart` | Add role switch UI |
| `mobile/lib/core/router/app_router.dart` | Update redirect to use `activeRole` |

### Files to Potentially Modify

| File | Change |
|------|--------|
| `mobile/lib/core/providers/auth_provider.dart` | Persist `activeRole` to storage |
| `backend/src/tasks/tasks.service.ts` | Add self-acceptance guard |
| `mobile/lib/features/settings/screens/settings_screen.dart` | Optionally restore settings screen |

### Files That Already Support Dual-Role (No Changes Needed)

| File | Why |
|------|-----|
| `backend/src/users/entities/user.entity.ts` | `types` is already `simple-array` |
| `backend/src/users/users.service.ts` | `addRole()` already works correctly |
| `mobile/lib/core/providers/auth_provider.dart` | `switchUserType()`, `addRole()`, `setActiveRole()` already exist |
| `backend/src/tasks/tasks.service.ts` | Profile completion guard already exists |
| `backend/src/contractor/contractor.service.ts` | Role-based ratings already separated |
| `backend/src/client/client.service.ts` | Role-based ratings already separated |

---

## Estimated Effort

| Task | Effort |
|------|--------|
| Backend: Remove MVP guards | ~15 min |
| Mobile: Add role switch UI | ~1-2 hours |
| Mobile: Router activeRole logic | ~30 min |
| Self-acceptance guard | ~15 min |
| Testing | ~2-3 hours |
| **Total** | **~4-6 hours** |
