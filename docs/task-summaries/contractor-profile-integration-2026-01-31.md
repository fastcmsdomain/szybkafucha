# Task Completion: Contractor Profile Database Integration

**Date**: 2026-01-31
**Developer**: Claude
**Related Issue/Task**: Contractor profile screen integration with database and client-facing "Profil" popup

## Overview

Integrated the contractor profile screen with the database, enabling:
1. Contractors to edit their profile (bio, address) with data persisting to the database
2. Clients to view contractor bio and real ratings in the task tracking "Profil" popup
3. Real-time bio transmission via WebSocket when contractor accepts a task

## Files Changed

### Backend
- `backend/src/contractor/contractor.controller.ts` - Added `GET /:userId/public` endpoint
- `backend/src/contractor/contractor.service.ts` - Added `getPublicProfile()` method
- `backend/src/realtime/realtime.gateway.ts` - Added `bio` field to contractor type
- `backend/src/tasks/tasks.service.ts` - Include bio when broadcasting task acceptance

### Mobile (Flutter)
- `mobile/lib/features/client/models/contractor.dart` - Added `bio` field
- `mobile/lib/features/client/screens/task_tracking_screen.dart` - Refactored Profil popup to fetch real data
- `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` - Fixed bio init, added real ratings
- `mobile/lib/core/services/websocket_service.dart` - Added `bio` field to `ContractorInfo`

## Code Examples

### Backend: Public Contractor Profile Endpoint

```typescript
// backend/src/contractor/contractor.controller.ts
@Get(':userId/public')
async getPublicProfile(@Param('userId') userId: string) {
  return this.contractorService.getPublicProfile(userId);
}
```

```typescript
// backend/src/contractor/contractor.service.ts
async getPublicProfile(userId: string): Promise<{
  id: string;
  name: string;
  avatarUrl: string | null;
  bio: string | null;
  ratingAvg: number;
  ratingCount: number;
  completedTasksCount: number;
  categories: string[];
  isVerified: boolean;
  memberSince: Date;
}> {
  const profile = await this.contractorRepository.findOne({
    where: { userId },
    relations: ['user'],
  });

  if (!profile || !profile.user) {
    throw new NotFoundException('Contractor profile not found');
  }

  return {
    id: profile.userId,
    name: profile.user.name || 'Wykonawca',
    avatarUrl: profile.user.avatarUrl || null,
    bio: profile.bio || profile.user.bio || null,
    ratingAvg: Number(profile.ratingAvg) || 0,
    ratingCount: profile.ratingCount || 0,
    completedTasksCount: profile.completedTasksCount || 0,
    categories: profile.categories || [],
    isVerified: profile.kycStatus === KycStatus.VERIFIED,
    memberSince: profile.createdAt,
  };
}
```

### Mobile: Contractor Model with Bio

```dart
// mobile/lib/features/client/models/contractor.dart
class Contractor {
  // ... existing fields ...
  final String? bio;

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      // ... existing parsing ...
      bio: json['bio'] as String?,
    );
  }
}
```

### Mobile: Profile Sheet with API Fetch

```dart
// mobile/lib/features/client/screens/task_tracking_screen.dart
class _ContractorProfileSheet extends ConsumerStatefulWidget {
  // Fetches full profile from GET /contractor/:userId/public
  // Shows loading indicator while fetching
  // Displays real bio or placeholder if empty
}
```

## Testing

### Prerequisites
1. Backend running: `cd backend && npm run start:dev`
2. Database seeded: `cd backend && npm run seed`
3. Mobile app running: `cd mobile && flutter run`

### Manual Testing Steps

#### Test 1: Backend Public Profile Endpoint

```bash
# Get a valid JWT token first (login via mobile app or use test token)
# Then test the endpoint:

curl -X GET http://localhost:3000/api/v1/contractor/{contractorUserId}/public \
  -H "Authorization: Bearer {your_jwt_token}" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "id": "contractor-uuid",
  "name": "Contractor Name",
  "avatarUrl": null,
  "bio": "Sample bio text",
  "ratingAvg": 4.5,
  "ratingCount": 10,
  "completedTasksCount": 25,
  "categories": ["paczki", "zakupy"],
  "isVerified": true,
  "memberSince": "2024-01-15T10:00:00.000Z"
}
```

#### Test 2: Contractor Profile Edit (Bio Persistence)

1. Login as contractor in mobile app
2. Navigate to Profile tab → tap "Edytuj profil"
3. Verify bio field shows existing bio (not empty if previously saved)
4. Edit the bio text
5. Tap "Zapisz profil"
6. Exit and re-enter the profile screen
7. **Verify**: Bio text persists

#### Test 3: Client "Profil" Popup (Real Bio Display)

1. Login as client in mobile app
2. Create a new task
3. Wait for contractor to accept (or use test data)
4. On task tracking screen, tap "Profil" button on contractor card
5. **Verify**:
   - Loading indicator appears briefly
   - Bio section shows contractor's actual bio (or "Brak opisu wykonawcy." if empty)
   - Rating and review count match database values

#### Test 4: Contractor Ratings Display

1. Login as contractor in mobile app
2. Navigate to Profile → "Edytuj profil"
3. Scroll to ratings section
4. **Verify**:
   - Loading spinner shows while fetching
   - Rating value matches database (not hardcoded 4.7)
   - Review count matches database (not hardcoded 32)

#### Test 5: WebSocket Bio Transmission

1. Login as client, create a task
2. Login as contractor (different device/simulator), accept the task
3. On client device, observe task tracking screen update
4. Tap "Profil" button
5. **Verify**: Bio is available immediately (from WebSocket) without additional API call

### Automated Testing

```bash
# Run backend tests
cd backend
npm test

# Run specific contractor tests
npm test -- --grep "ContractorService"

# Analyze Flutter code
cd mobile
flutter analyze
```

## Explanation

### Problem Statement

The contractor profile screen was not properly linked to the database:
- Bio field was initialized as empty string instead of loading from user data
- Ratings were hardcoded (4.7 rating, 32 reviews)
- Client's "Profil" popup showed placeholder text instead of real contractor bio
- No API endpoint existed for clients to fetch contractor public profile

### Solution Approach

1. **Backend**: Created new `GET /contractor/:userId/public` endpoint that returns safe public fields
2. **Mobile Model**: Added `bio` field to `Contractor` class with JSON parsing support
3. **Task Tracking**: Refactored popup into `_ContractorProfileSheet` widget that fetches real data
4. **Contractor Profile**: Fixed bio initialization and added API call to fetch real ratings
5. **WebSocket**: Extended contractor info to include bio for real-time updates

### Implementation Details

1. **Backend Endpoint** - Uses existing `ContractorProfile` entity with User relation, excludes sensitive fields (phone, email, KYC details, Stripe ID)
2. **Mobile fromJson** - Supports both snake_case and camelCase for backend compatibility
3. **Profile Sheet** - Uses initial contractor data from WebSocket, then enhances with API fetch
4. **Error Handling** - Shows graceful fallback messages if API fetch fails

### Trade-offs

- **Extra API Call**: Profile popup makes an API call to get full bio. Alternative was to include bio in WebSocket, which we also implemented as Step 6.
- **Dual Storage**: Bio exists in both `User.bio` and `ContractorProfile.bio`. Service prefers ContractorProfile.bio, falls back to User.bio.

### Future Improvements

- Add reviews list to profile popup (fetch from ratings endpoint)
- Cache contractor profiles to reduce API calls
- Add contractor categories to profile popup
- Add "member since" date to profile display

## API Reference

### GET /contractor/:userId/public

**Authentication**: Required (JWT)

**Parameters**:
- `userId` (path): UUID of the contractor user

**Response** (200 OK):
```json
{
  "id": "string (UUID)",
  "name": "string",
  "avatarUrl": "string | null",
  "bio": "string | null",
  "ratingAvg": "number (0-5)",
  "ratingCount": "number",
  "completedTasksCount": "number",
  "categories": "string[]",
  "isVerified": "boolean",
  "memberSince": "string (ISO date)"
}
```

**Errors**:
- 401: Unauthorized (missing/invalid JWT)
- 404: Contractor profile not found

## Next Steps

1. Add unit tests for `getPublicProfile` method
2. Add E2E test for public profile endpoint
3. Implement reviews list fetch in profile popup
4. Consider caching contractor profiles in mobile app
