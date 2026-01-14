# Contractor Matching Algorithm

> **Implementation Summary for Task 6.0**
> **Completed:** 2026-01-12

---

## Overview

The Contractor Matching Algorithm finds and ranks suitable contractors for tasks based on rating, experience, and proximity. When a client creates a new task, the system automatically notifies the best-matched contractors via WebSocket.

---

## Architecture

### Key Files

| File | Purpose |
|------|---------|
| `backend/src/tasks/tasks.service.ts` | Scoring algorithm, ranking, notifications |
| `backend/src/tasks/tasks.module.ts` | Module dependencies |
| `backend/src/realtime/realtime.gateway.ts` | WebSocket notification delivery |
| `backend/src/tasks/tasks.service.spec.ts` | 23 unit tests |

---

## Scoring Algorithm (6.3)

### Formula

```
Score = (rating * 0.4) + (completions * 0.3) + (proximity * 0.3)
```

### Weight Constants

```typescript
const SCORING_WEIGHTS = {
  RATING: 0.4,      // 40% weight for contractor rating
  COMPLETIONS: 0.3, // 30% weight for completed tasks
  PROXIMITY: 0.3,   // 30% weight for distance from task
};
```

### Normalization

| Factor | Normalization | Range |
|--------|---------------|-------|
| Rating | `rating / 5` | 0-1 (capped at 1) |
| Completions | `min(completedTasks / 100, 1)` | 0-1 (capped at 100 tasks) |
| Proximity | `1 - (distance / maxRadius)` | 0-1 (closer = higher) |

### Example Scores

| Contractor | Rating | Tasks | Distance | Score |
|------------|--------|-------|----------|-------|
| Perfect match | 5.0 | 100+ | 0 km | 1.00 |
| Good match | 4.5 | 75 | 2 km | 0.83 |
| Average match | 3.5 | 30 | 10 km | 0.53 |
| New contractor | 0 | 0 | 20 km | 0.00 |

---

## Distance Calculation (6.2)

Uses the **Haversine formula** for accurate earth-surface distance:

```typescript
calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number
```

### Accuracy

- Warsaw to Krakow (~252km): Calculated within 10% margin
- Short distances (1km): Accurate to 100m
- Cross-hemisphere: Handles equator crossing correctly

---

## Contractor Ranking (6.3)

### Method

```typescript
async findAndRankContractors(
  task: Task,
  maxRadius: number = 20,    // km
  limit: number = 5          // max contractors
): Promise<RankedContractor[]>
```

### Filtering Criteria

1. **Online status**: Must be `isOnline: true`
2. **Category match**: Contractor categories must include task category
3. **KYC verified**: Must have `kycStatus: VERIFIED`
4. **Location available**: Must have `lastLocationLat` and `lastLocationLng`
5. **Within radius**: Distance from task must be ≤ `maxRadius`

### Return Type

```typescript
interface RankedContractor {
  contractorId: string;
  profile: ContractorProfile;
  score: number;    // 0.0 - 1.0
  distance: number; // km
}
```

---

## Notification Queue (6.4)

### Flow

```
Task Created → findAndRankContractors() → Top 5 → WebSocket notification
```

### WebSocket Event

**Event name:** `task:new_available`

**Payload:**

```typescript
{
  task: {
    id: string;
    category: string;
    title: string;
    description: string;
    address: string;
    budgetAmount: number;
    locationLat: number;
    locationLng: number;
  },
  score: number,    // Contractor's match score
  distance: number  // Distance to task in km
}
```

### Implementation Note

The current implementation uses WebSocket for instant notifications. The 45-second batch queue with timeouts (as specified in PRD) is deferred to production phase and will require Bull/Redis queue for proper job scheduling.

---

## API Integration

### Task Creation Flow

When `POST /tasks` is called:

1. Task is created with status `CREATED`
2. `notifyAvailableContractors(task)` is called
3. Top 5 contractors receive WebSocket notifications

### Contractor Task Discovery

`GET /tasks` for contractors calls:

```typescript
findAvailableForContractor(
  contractorId: string,
  categories: string[],
  lat: number,
  lng: number,
  radiusKm: number
): Promise<Task[]>
```

Returns tasks within radius matching contractor's categories.

---

## Unit Tests (6.5)

### Test Coverage: 23 Tests

```
TasksService
  calculateDistance
    ✓ should return 0 for same coordinates
    ✓ should calculate distance between Warsaw and Krakow correctly
    ✓ should handle coordinates across the equator
    ✓ should be symmetric (A to B = B to A)
    ✓ should calculate short distances accurately

  calculateContractorScore
    ✓ should return ~1.0 for perfect contractor
    ✓ should return low score for new contractor far away
    ✓ should apply weights correctly
    ✓ should cap completions normalization at 100
    ✓ should handle rating above 5 gracefully
    ✓ should return higher score for closer contractors

  findAndRankContractors
    ✓ should return contractors sorted by score (highest first)
    ✓ should filter out offline contractors
    ✓ should filter by category match
    ✓ should filter by distance radius
    ✓ should return empty array when no matches
    ✓ should skip contractors without location
    ✓ should limit results to specified number
    ✓ should include distance in results

  notifyAvailableContractors
    ✓ should notify ranked contractors via WebSocket
    ✓ should not send notifications when no contractors available

  findAvailableForContractor
    ✓ should return tasks within radius matching categories
    ✓ should filter out tasks beyond radius
```

### Running Tests

```bash
cd backend

# Run matching algorithm tests only
npm test src/tasks/tasks.service.spec.ts

# Run with coverage
npm run test:cov

# Run in watch mode
npm run test:watch
```

---

## Configuration

### Default Values

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxRadius` | 20 km | Maximum search radius for contractors |
| `limit` | 5 | Maximum contractors to notify |
| `MAX_COMPLETIONS_FOR_NORMALIZATION` | 100 | Tasks count for max score |

### Adjusting Weights

To change scoring weights, edit `SCORING_WEIGHTS` in [tasks.service.ts](../backend/src/tasks/tasks.service.ts):

```typescript
const SCORING_WEIGHTS = {
  RATING: 0.4,      // Increase for rating-focused matching
  COMPLETIONS: 0.3, // Increase for experience-focused matching
  PROXIMITY: 0.3,   // Increase for location-focused matching
};
```

---

## Future Enhancements

1. **45-second batch queue** - Notify next batch if no acceptance
2. **Dynamic pricing** - Adjust scores based on demand
3. **Historical performance** - Factor in acceptance rate
4. **Category expertise** - Weight by category-specific ratings
5. **Availability windows** - Match scheduled tasks with available contractors

---

## Real-Life Testing Guide

### Prerequisites

1. **Running Services**
   ```bash
   # Terminal 1: Start database
   docker-compose up -d postgres redis

   # Terminal 2: Start backend with logs
   cd backend && npm run start:dev
   ```

2. **Seed Database**
   ```bash
   cd backend
   npm run seed:fresh
   ```

### Test Accounts

| Role | Name | Phone | Categories | Status |
|------|------|-------|------------|--------|
| Client | Jan Kowalski | +48111111111 | - | Active |
| Client | Anna Nowak | +48111111112 | - | Active |
| Contractor | Marek Szybki | +48222222221 | paczki, zakupy, kolejki | Online, Verified |
| Contractor | Tomasz Złota Rączka | +48222222222 | montaz, przeprowadzki | Online, Verified |
| Contractor | Katarzyna Czyścioch | +48222222223 | sprzatanie | **Offline**, Verified |
| Contractor | Adam Nowy | +48222222224 | paczki, zakupy, kolejki | Online, **Not Verified** |

**OTP Code for all test accounts:** `123456`

### Step-by-Step Test

OTP (One-Time Password)
OTP to jednorazowy kod weryfikacyjny wysyłany SMS-em na telefon użytkownika.

Jak działa:

Użytkownik podaje numer telefonu
System wysyła SMS z 6-cyfrowym kodem (np. 123456)
Użytkownik wpisuje kod w aplikacji
System weryfikuje kod i loguje użytkownika
Po co:

Bezpieczna weryfikacja że użytkownik ma dostęp do tego numeru telefonu
Nie wymaga pamiętania hasła
Popularny sposób logowania w aplikacjach mobilnych (Uber, Bolt, InPost)

JWT (JSON Web Token)
JWT to "przepustka" którą serwer wydaje po zalogowaniu.

Jak działa:

Użytkownik loguje się (OTP, Google, Apple)
Serwer zwraca JWT token (długi zakodowany string)
Aplikacja zapisuje token i dołącza go do każdego żądania
Serwer sprawdza token i wie kto wysyła żądanie
Przykład tokena:


eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U
Po co:

Serwer nie musi przechowywać sesji użytkownika
Token zawiera informacje o użytkowniku (ID, typ)
Każde żądanie API wymaga tokena w nagłówku Authorization: Bearer <token>


#### 1. Get Client JWT Token

```bash
# Request OTP
curl -X POST http://localhost:3000/api/v1/auth/phone/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+48111111111"}'

# Verify OTP
curl -X POST http://localhost:3000/api/v1/auth/phone/verify \
  -H "Content-Type: application/json" \
  -d '{"phone": "+48111111111", "code": "123456"}'
```

Save the `accessToken` from the response.

#### 2. Get Contractor JWT Token

```bash
curl -X POST http://localhost:3000/api/v1/auth/phone/verify \
  -H "Content-Type: application/json" \
  -d '{"phone": "+48222222221", "code": "123456"}'
```

Save this token separately for WebSocket connection.

#### 3. Connect Contractor to WebSocket

Install wscat and connect:

```bash
npm install -g wscat

# Connect with contractor token
wscat -c "ws://localhost:3000?token=<CONTRACTOR_JWT_TOKEN>"

```

Keep this terminal open to receive notifications.

#### 4. Create a Task (as Client)

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <CLIENT_JWT_TOKEN>" \
  -d '{
    "category": "paczki",
    "title": "Test delivery",
    "description": "Pick up package from paczkomat",
    "locationLat": 52.2297,
    "locationLng": 21.0122,
    "address": "ul. Marszałkowska 100, Warsaw",
    "budgetAmount": 50
  }'
```

#### 5. Expected Results

**Backend logs:**
```
[TasksService] Notifying 1 contractors for task <task-id>
[TasksService] Notified contractor 22222222-... (score: 0.82, distance: 2.5km)
```

**WebSocket (contractor terminal):**
```json
{
  "event": "task:new_available",
  "data": {
    "task": {
      "id": "...",
      "category": "paczki",
      "title": "Test delivery",
      "budgetAmount": 50
    },
    "score": 0.82,
    "distance": 2.5
  }
}
```

### Test Scenarios

| Scenario | Task Category | Expected Contractors Notified |
|----------|---------------|-------------------------------|
| Normal match | paczki | Marek Szybki (score ~0.8) |
| No match (offline) | sprzatanie | None (Kasia is offline) |
| No match (unverified) | paczki | Only Marek (Adam not verified) |
| Multiple matches | montaz | Tomasz only |
| Far location (Krakow) | paczki | None (outside 20km radius) |

### Quick Verification Commands

```bash
# Check contractor is online
curl -X GET http://localhost:3000/api/v1/contractor/profile \
  -H "Authorization: Bearer <CONTRACTOR_JWT_TOKEN>"

# Update contractor location
curl -X PUT http://localhost:3000/api/v1/contractor/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <CONTRACTOR_JWT_TOKEN>" \
  -d '{"lat": 52.2300, "lng": 21.0130}'

# Toggle contractor online status
curl -X PUT http://localhost:3000/api/v1/contractor/availability \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <CONTRACTOR_JWT_TOKEN>" \
  -d '{"isOnline": true}'
```

---

## Postman Collection

A complete Postman collection is available for API testing:

**File:** [postman/Contractor_Matching_Tests.postman_collection.json](./postman/Contractor_Matching_Tests.postman_collection.json)

### Import & Run

1. Open Postman
2. Click **Import** → Select the JSON file
3. The collection includes 6 folders with 20+ requests:
   - **1. Authentication** - Get JWT tokens for client and contractor
   - **2. Contractor Setup** - Configure contractor profile, location, availability
   - **3. Task Creation & Matching** - Test matching scenarios (match, no match, far location)
   - **4. Contractor View** - View available tasks as contractor
   - **5. Task Lifecycle** - Full flow: accept → start → complete → confirm → rate
   - **6. Edge Cases** - Invalid category, missing fields, unauthorized requests

### Run All Tests

1. Click the collection name → **Run**
2. Click **Run Szybka Fucha - Contractor Matching Tests**
3. All tests have built-in assertions that validate responses

### Collection Variables

| Variable | Description |
|----------|-------------|
| `baseUrl` | API base URL (default: `http://localhost:3000/api/v1`) |
| `clientToken` | Auto-saved after client login |
| `contractorToken` | Auto-saved after contractor login |
| `taskId` | Auto-saved after task creation |

---

## Related Documentation

- [Authentication Testing Guide](./AUTHENTICATION_TESTING.md)
- [Database Migrations](./DATABASE_MIGRATIONS.md)
- [PRD - Section 5.5 Matching](./prd-szybka-fucha.md)
