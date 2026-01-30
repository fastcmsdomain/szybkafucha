# Contractor Profile – Architecture & Data Flow (2026-01-30)

## Domain Model
- **User** (`users` table)  
  - Core identity for both clients/contractors.  
  - Key fields used by profile: `id`, `name`, `email`, `phone`, `avatarUrl`, `address`, `bio`, `type`, `status`.
- **ContractorProfile** (`contractor_profiles` table)  
  - Contractor-specific extensions: `bio`, `categories`, `serviceRadiusKm`, `ratingAvg`, `ratingCount`, `completedTasksCount`, KYC flags, last known location, Stripe account.
- **Ratings** (task reviews)  
  - Stored in `tasks_rating` (entity `Rating`), aggregated into `ContractorProfile.ratingAvg` / `ratingCount`.

## Backend Interfaces
- **Endpoints**
  - `GET /users/me` – fetch current user (name, email, phone, avatarUrl, address, bio).
  - `PUT /users/me` – update profile fields accepted by `UpdateUserDto` (name, phone, email, address, bio, avatarUrl, fcmToken).  
  - `POST /users/me/avatar` – multipart upload; returns `avatarUrl`.
  - Read-only profile data exposed to clients via task/contractor endpoints that serialize `ContractorProfile` + `User`.
- **DTOs**
  - `UpdateUserDto` (backend/src/users/dto/update-user.dto.ts) validates: `name`, `avatarUrl`, `fcmToken`, `phone`, `email`, `address`, `bio`.
- **Services**
  - `UsersService.update` persists into `users`.  
  - Ratings aggregation handled in `ContractorProfile` (fields `ratingAvg`, `ratingCount`, `completedTasksCount`).

## Mobile App (Flutter)
- **Screens**
  - `ProfileScreen` (shared tab) – shows summary; contractor taps “Edytuj profil” → `Routes.contractorProfileEdit`.
  - `ContractorProfileScreen` (mobile/lib/features/contractor/screens/contractor_profile_screen.dart) – editable form:
    - Image (change stub), name, phone (editable), email (read-only), address, bio.
    - Ratings summary placeholder.
    - `PUT /users/me` on save.
- **Models**
  - `User` (mobile/lib/core/providers/auth_provider.dart) includes `address`, `bio`, `avatarUrl`, `phone`, `email`.
- **Routing**
  - `Routes.contractorProfile` → legacy read-only profile.  
  - `Routes.contractorProfileEdit` → editable contractor profile screen.

## Data Flow (Edit Profile)
1. Screen loads with current `User` from `authProvider`.
2. User edits fields (except email).  
3. Save → `PUT /users/me` with `name`, `phone`, `address`, `bio` (+avatarUrl when implemented).  
4. Backend validates via `UpdateUserDto`, writes to `users`.  
5. Client can call `GET /users/me` (or rely on websocket/user refresh) to update local state.

## Storage & Media
- Avatar stored via `POST /users/me/avatar` → returns `avatarUrl` persisted in `users.avatarUrl`.
- Other profile fields stored directly in `users` row.

## Migrations Needed
- `users` table must contain `address` (varchar 255) and `bio` (text).  
  - If missing, add migration: `add_address_bio_to_users`.

## Security / Permissions
- All profile endpoints require JWT (`JwtAuthGuard`).  
- `PUT /users/me` only updates the authenticated user id.
- Email kept read-only in UI to avoid collisions; backend still validates unique constraint.

## Future Enhancements
- Wire avatar upload in mobile via multipart → `POST /users/me/avatar`.
- Surface real ratings/reviews list (fetch from tasks/ratings endpoint).
- Add contractor-specific fields (categories, radius) into edit form once exposed by API.
