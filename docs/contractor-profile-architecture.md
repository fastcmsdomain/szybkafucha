# Contractor Profile – Architecture & Data Flow (2026-01-31)

## Domain Model
- **User** (`users` table)
  - Core identity for both clients/contractors.
  - Key fields used by profile: `id`, `name`, `email`, `phone`, `avatarUrl`, `address`, `bio`, `type`, `status`.
- **ContractorProfile** (`contractor_profiles` table)
  - Contractor-specific extensions: `bio`, `categories`, `serviceRadiusKm`, `ratingAvg`, `ratingCount`, `completedTasksCount`, KYC flags, last known location, Stripe account.
- **Ratings** (task reviews)
  - Stored in `tasks_rating` (entity `Rating`), aggregated into `ContractorProfile.ratingAvg` / `ratingCount`.

## Backend Interfaces

### Endpoints
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/users/me` | GET | JWT | Fetch current user profile |
| `/users/me` | PUT | JWT | Update profile (name, phone, address, bio, avatarUrl) |
| `/users/me/avatar` | POST | JWT | Upload avatar image |
| `/contractor/profile` | GET | JWT | Get current contractor's ContractorProfile |
| `/contractor/:userId/public` | GET | JWT | **NEW** - Get public contractor profile for clients |

### Public Profile Response (`/contractor/:userId/public`)
```json
{
  "id": "uuid",
  "name": "string",
  "avatarUrl": "string | null",
  "bio": "string | null",
  "ratingAvg": "number (0-5)",
  "ratingCount": "number",
  "completedTasksCount": "number",
  "categories": "string[]",
  "isVerified": "boolean",
  "memberSince": "ISO date string"
}
```

### DTOs
- `UpdateUserDto` (backend/src/users/dto/update-user.dto.ts) validates: `name`, `avatarUrl`, `fcmToken`, `phone`, `email`, `address`, `bio`.

### Services
- `UsersService.update` persists into `users`.
- `ContractorService.getPublicProfile` returns combined User + ContractorProfile data for client viewing.
- Ratings aggregation handled in `ContractorProfile` (fields `ratingAvg`, `ratingCount`, `completedTasksCount`).

## Mobile App (Flutter)

### Screens
- `ProfileScreen` (shared tab) – shows summary; contractor taps "Edytuj profil" → `Routes.contractorProfileEdit`.
- `ContractorProfileScreen` (mobile/lib/features/contractor/screens/contractor_profile_screen.dart) – editable form:
  - Image (change stub), name, phone (editable), email (read-only), address, bio.
  - **Real ratings from database** (fetches from `/contractor/profile`).
  - `PUT /users/me` on save.
- `TaskTrackingScreen` – Client task tracking with "Profil" button:
  - `_ContractorProfileSheet` widget fetches `/contractor/:userId/public`
  - Shows contractor bio, ratings, and review count

### Models
- `User` (mobile/lib/core/providers/auth_provider.dart) includes `address`, `bio`, `avatarUrl`, `phone`, `email`.
- `Contractor` (mobile/lib/features/client/models/contractor.dart) includes `bio` field for client-facing views.
- `ContractorInfo` (mobile/lib/core/services/websocket_service.dart) includes `bio` for WebSocket events.

### Routing
- `Routes.contractorProfile` → legacy read-only profile.
- `Routes.contractorProfileEdit` → editable contractor profile screen.

## Data Flow

### Edit Profile (Contractor)
1. Screen loads with current `User` from `authProvider`.
2. Screen fetches `GET /contractor/profile` for ratings data.
3. User edits fields (except email).
4. Save → `PUT /users/me` with `name`, `phone`, `address`, `bio` (+avatarUrl when implemented).
5. Backend validates via `UpdateUserDto`, writes to `users`.

### View Profile (Client)
1. Client is on TaskTrackingScreen with assigned contractor.
2. Client taps "Profil" button on contractor card.
3. `_ContractorProfileSheet` opens with initial contractor data.
4. Sheet fetches `GET /contractor/:contractorId/public`.
5. Bio and ratings update from API response.

### WebSocket Task Acceptance
1. Contractor accepts task via `PUT /tasks/:id/accept`.
2. Backend fetches ContractorProfile with User relation.
3. `broadcastTaskStatusWithContractor` sends status + contractor info (including bio).
4. Client receives WebSocket event with contractor bio.
5. Client can display bio immediately without extra API call.

## Storage & Media
- Avatar stored via `POST /users/me/avatar` → returns `avatarUrl` persisted in `users.avatarUrl`.
- Bio stored in `users.bio` (preferred) or `contractor_profiles.bio` (fallback).
- Service uses: `profile.bio || profile.user.bio || null`

## Security / Permissions
- All profile endpoints require JWT (`JwtAuthGuard`).
- `PUT /users/me` only updates the authenticated user id.
- `GET /contractor/:userId/public` requires JWT but returns only public-safe fields.
- Email kept read-only in UI to avoid collisions; backend still validates unique constraint.

## Testing

See `CLAUDE.md` section "Test Contractor Profile Integration" for quick test steps.

Full documentation: `docs/task-summaries/contractor-profile-integration-2026-01-31.md`

### Quick Backend Test
```bash
curl -X GET http://localhost:3000/api/v1/contractor/{userId}/public \
  -H "Authorization: Bearer {jwt_token}"
```

## Future Enhancements
- Wire avatar upload in mobile via multipart → `POST /users/me/avatar`.
- Surface reviews list in profile popup (fetch from tasks/ratings endpoint).
- Add contractor-specific fields (categories, radius) into edit form.
- Cache contractor profiles in mobile app to reduce API calls.
