# Szybka Fucha API - Implementation Summary

> **Date:** January 2, 2026  
> **Status:** ✅ Backend API Running & Database Connected  
> **Base URL:** `http://localhost:3000/api/v1`

---

## 📋 What Was Accomplished

### ✅ Infrastructure Setup
- **Docker Compose** configured with PostgreSQL (PostGIS), Redis, and pgAdmin
- **Database tables** created automatically via TypeORM:
  - `users` - User accounts (clients & contractors)
  - `contractor_profiles` - Extended contractor data
  - `tasks` - Task/job postings
  - `ratings` - Reviews and ratings
  - `messages` - Chat messages
  - `payments` - Payment tracking

### ✅ Backend Modules Implemented
1. **Authentication Module** - JWT-based auth with phone OTP, Google, Apple
2. **Users Module** - Profile management
3. **Tasks Module** - Full task lifecycle (create, accept, start, complete, rate)
4. **Contractor Module** - Contractor profile, availability, location, KYC

### ✅ Admin Dashboard
- React + TypeScript + Chakra UI
- Routing configured
- Pages: Dashboard, Users, Tasks, Disputes

---

## 🚀 Running Services

| Service | URL | Status |
|---------|-----|--------|
| **Backend API** | http://localhost:3000/api/v1 | ✅ Running |
| **PostgreSQL** | localhost:5432 | ✅ Running |
| **Redis** | localhost:6379 | ✅ Running |
| **pgAdmin** | http://localhost:5050 | ✅ Running |
| **Admin Dashboard** | http://localhost:3002 | ✅ Running |

---

## 🔐 Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

### Authentication Flow

1. **Request OTP** → Get SMS code (mock in dev)
2. **Verify OTP** → Receive JWT token
3. **Use JWT** → Include in all subsequent requests

---

## 📡 API Endpoints

### Base URL
```
http://localhost:3000/api/v1
```

---

## 1. Authentication Endpoints

### 1.1 Request OTP
**POST** `/auth/phone/request-otp`

Send OTP code to phone number (mock implementation for development).

**Request Body:**
```json
{
  "phone": "+48123456789"
}
```

**Response:**
```json
{
  "message": "OTP sent successfully",
  "code": "123456"
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/auth/phone/request-otp`
- Headers: `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "phone": "+48123456789"
}
```

---

### 1.2 Verify OTP
**POST** `/auth/phone/verify`

Verify OTP and receive JWT token.

**Request Body:**
```json
{
  "phone": "+48123456789",
  "code": "123456",
  "userType": "client"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "type": "client",
    "phone": "+48123456789",
    "status": "active"
  }
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/auth/phone/verify`
- Headers: `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "phone": "+48123456789",
  "code": "123456",
  "userType": "client"
}
```

**💡 Save the `access_token` from response - you'll need it for protected endpoints!**

---

### 1.3 Google Sign-In
**POST** `/auth/google`

Authenticate with Google ID token.

**Request Body:**
```json
{
  "googleId": "google_user_id",
  "email": "user@example.com",
  "name": "John Doe",
  "avatarUrl": "https://...",
  "userType": "client"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/auth/google`
- Headers: `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "googleId": "123456789",
  "email": "john@example.com",
  "name": "John Doe",
  "avatarUrl": "https://example.com/avatar.jpg",
  "userType": "client"
}
```

---

### 1.4 Apple Sign-In
**POST** `/auth/apple`

Authenticate with Apple ID token.

**Request Body:**
```json
{
  "appleId": "apple_user_id",
  "email": "user@example.com",
  "name": "John Doe",
  "userType": "client"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/auth/apple`
- Headers: `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "appleId": "001234.567890abcdef",
  "email": "john@example.com",
  "name": "John Doe",
  "userType": "contractor"
}
```

---

## 2. User Endpoints

### 2.1 Get My Profile
**GET** `/users/me`

Get current authenticated user's profile.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:**
```json
{
  "id": "uuid",
  "type": "client",
  "phone": "+48123456789",
  "email": "user@example.com",
  "name": "John Doe",
  "avatarUrl": null,
  "status": "active",
  "createdAt": "2026-01-02T06:00:00.000Z",
  "updatedAt": "2026-01-02T06:00:00.000Z"
}
```

**Postman Setup:**
- Method: `GET`
- URL: `http://localhost:3000/api/v1/users/me`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`

---

### 2.2 Update My Profile
**PUT** `/users/me`

Update current user's profile (name, avatar).

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "name": "John Updated",
  "avatarUrl": "https://example.com/new-avatar.jpg"
}
```

**Response:**
```json
{
  "id": "uuid",
  "name": "John Updated",
  "avatarUrl": "https://example.com/new-avatar.jpg",
  ...
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/users/me`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "name": "John Updated",
  "avatarUrl": "https://example.com/new-avatar.jpg"
}
```

---

## 3. Task Endpoints

### 3.1 Create Task
**POST** `/tasks`

Create a new task (client only).

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "category": "paczki",
  "title": "Odbierz paczkę z paczkomatu",
  "description": "Paczka w paczkomacie przy ul. Marszałkowskiej 1",
  "locationLat": 52.2297,
  "locationLng": 21.0122,
  "address": "ul. Marszałkowska 1, Warszawa",
  "budgetAmount": 50,
  "scheduledAt": "2026-01-02T10:00:00Z"
}
```

**Available Categories:**
- `paczki` - Package pickup/delivery
- `zakupy` - Shopping
- `kolejki` - Queue standing
- `montaz` - Assembly
- `przeprowadzki` - Moving
- `sprzatanie` - Cleaning

**Response:**
```json
{
  "id": "task-uuid",
  "clientId": "user-uuid",
  "category": "paczki",
  "title": "Odbierz paczkę z paczkomatu",
  "status": "created",
  "budgetAmount": 50,
  "createdAt": "2026-01-02T06:00:00.000Z"
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/tasks`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "category": "zakupy",
  "title": "Kup produkty spożywcze",
  "description": "Lista zakupów: mleko, chleb, jajka",
  "locationLat": 52.2297,
  "locationLng": 21.0122,
  "address": "ul. Nowy Świat 15, Warszawa",
  "budgetAmount": 100
}
```

---

### 3.2 List Tasks
**GET** `/tasks`

List tasks filtered by user role:
- **Clients**: See their own tasks
- **Contractors**: See available nearby tasks (requires location)

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Query Parameters (for contractors):**
- `lat` - Latitude (required for contractors)
- `lng` - Longitude (required for contractors)
- `categories` - Comma-separated categories (optional)
- `radiusKm` - Search radius in km (default: 10)

**Example for Contractor:**
```
GET /tasks?lat=52.2297&lng=21.0122&categories=paczki,zakupy&radiusKm=15
```

**Response:**
```json
[
  {
    "id": "task-uuid",
    "category": "paczki",
    "title": "Odbierz paczkę",
    "budgetAmount": 50,
    "status": "created",
    "address": "ul. Marszałkowska 1, Warszawa",
    "distanceKm": 2.5
  }
]
```

**Postman Setup:**
- Method: `GET`
- URL: `http://localhost:3000/api/v1/tasks?lat=52.2297&lng=21.0122&categories=paczki&radiusKm=10`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`

---

### 3.3 Get Task Details
**GET** `/tasks/:id`

Get full task details.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:**
```json
{
  "id": "task-uuid",
  "clientId": "user-uuid",
  "contractorId": null,
  "category": "paczki",
  "title": "Odbierz paczkę z paczkomatu",
  "description": "...",
  "locationLat": 52.2297,
  "locationLng": 21.0122,
  "address": "ul. Marszałkowska 1, Warszawa",
  "budgetAmount": 50,
  "status": "created",
  "createdAt": "2026-01-02T06:00:00.000Z"
}
```

**Postman Setup:**
- Method: `GET`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`

---

### 3.4 Accept Task
**PUT** `/tasks/:id/accept`

Contractor accepts a task.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:**
```json
{
  "id": "task-uuid",
  "status": "accepted",
  "contractorId": "contractor-uuid",
  "acceptedAt": "2026-01-02T06:30:00.000Z"
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}/accept`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`

---

### 3.5 Start Task
**PUT** `/tasks/:id/start`

Contractor starts working on the task.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:**
```json
{
  "id": "task-uuid",
  "status": "in_progress",
  "startedAt": "2026-01-02T07:00:00.000Z"
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}/start`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`

---

### 3.6 Complete Task
**PUT** `/tasks/:id/complete`

Contractor marks task as complete (with photo proof).

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "completionPhotos": [
    "https://example.com/photo1.jpg",
    "https://example.com/photo2.jpg"
  ]
}
```

**Response:**
```json
{
  "id": "task-uuid",
  "status": "completed",
  "completedAt": "2026-01-02T08:00:00.000Z",
  "completionPhotos": ["https://example.com/photo1.jpg"]
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}/complete`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "completionPhotos": [
    "https://example.com/photo1.jpg"
  ]
}
```

---

### 3.7 Confirm Task
**PUT** `/tasks/:id/confirm`

Client confirms task completion (triggers payment).

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:**
```json
{
  "id": "task-uuid",
  "status": "completed",
  "finalAmount": 50,
  "commissionAmount": 5
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}/confirm`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`

---

### 3.8 Cancel Task
**PUT** `/tasks/:id/cancel`

Cancel a task (only before acceptance, or with admin approval).

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "reason": "Changed my mind"
}
```

**Response:**
```json
{
  "id": "task-uuid",
  "status": "cancelled",
  "cancelledAt": "2026-01-02T06:15:00.000Z",
  "cancellationReason": "Changed my mind"
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}/cancel`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "reason": "Changed my mind"
}
```

---

### 3.9 Rate Task
**POST** `/tasks/:id/rate`

Submit rating and review for completed task.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "rating": 5,
  "comment": "Świetna praca, bardzo polecam!"
}
```

**Response:**
```json
{
  "id": "rating-uuid",
  "taskId": "task-uuid",
  "rating": 5,
  "comment": "Świetna praca, bardzo polecam!",
  "createdAt": "2026-01-02T08:30:00.000Z"
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}/rate`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "rating": 5,
  "comment": "Świetna praca, bardzo polecam!"
}
```

---

### 3.10 Add Tip
**POST** `/tasks/:id/tip`

Add tip to a completed task.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "amount": 10
}
```

**Response:**
```json
{
  "id": "task-uuid",
  "tipAmount": 10,
  "finalAmount": 60
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/tasks/{task-id}/tip`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "amount": 10
}
```

---

## 4. Contractor Endpoints

### 4.1 Get Contractor Profile
**GET** `/contractor/profile`

Get current contractor's profile (creates if doesn't exist).

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Response:**
```json
{
  "userId": "user-uuid",
  "bio": "Doświadczony kurier",
  "categories": ["paczki", "zakupy"],
  "serviceRadiusKm": 10,
  "kycStatus": "pending",
  "ratingAvg": 4.5,
  "ratingCount": 10,
  "completedTasksCount": 25,
  "isOnline": false
}
```

**Postman Setup:**
- Method: `GET`
- URL: `http://localhost:3000/api/v1/contractor/profile`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`

---

### 4.2 Update Contractor Profile
**PUT** `/contractor/profile`

Update contractor profile (bio, categories, radius).

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "bio": "Profesjonalny kurier z 5-letnim doświadczeniem",
  "categories": ["paczki", "zakupy", "kolejki"],
  "serviceRadiusKm": 15
}
```

**Response:**
```json
{
  "userId": "user-uuid",
  "bio": "Profesjonalny kurier z 5-letnim doświadczeniem",
  "categories": ["paczki", "zakupy", "kolejki"],
  "serviceRadiusKm": 15
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/contractor/profile`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "bio": "Profesjonalny kurier z 5-letnim doświadczeniem",
  "categories": ["paczki", "zakupy", "kolejki"],
  "serviceRadiusKm": 15
}
```

---

### 4.3 Set Availability
**PUT** `/contractor/availability`

Toggle online/offline status.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "isOnline": true
}
```

**Response:**
```json
{
  "userId": "user-uuid",
  "isOnline": true
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/contractor/availability`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "isOnline": true
}
```

---

### 4.4 Update Location
**PUT** `/contractor/location`

Update GPS coordinates.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "lat": 52.2297,
  "lng": 21.0122
}
```

**Response:**
```json
{
  "userId": "user-uuid",
  "lastLocationLat": 52.2297,
  "lastLocationLng": 21.0122,
  "lastLocationAt": "2026-01-02T06:00:00.000Z"
}
```

**Postman Setup:**
- Method: `PUT`
- URL: `http://localhost:3000/api/v1/contractor/location`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "lat": 52.2297,
  "lng": 21.0122
}
```

---

### 4.5 Submit KYC ID
**POST** `/contractor/kyc/id`

Submit ID document for verification.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "documentUrl": "https://example.com/id-document.jpg"
}
```

**Response:**
```json
{
  "userId": "user-uuid",
  "kycIdVerified": true,
  "kycStatus": "pending"
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/contractor/kyc/id`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "documentUrl": "https://example.com/id-document.jpg"
}
```

---

### 4.6 Submit KYC Selfie
**POST** `/contractor/kyc/selfie`

Submit selfie for face verification.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "selfieUrl": "https://example.com/selfie.jpg"
}
```

**Response:**
```json
{
  "userId": "user-uuid",
  "kycSelfieVerified": true,
  "kycStatus": "pending"
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/contractor/kyc/selfie`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "selfieUrl": "https://example.com/selfie.jpg"
}
```

---

### 4.7 Submit KYC Bank
**POST** `/contractor/kyc/bank`

Submit bank account for payouts.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Request Body:**
```json
{
  "iban": "PL61109010140000071219812874",
  "accountHolder": "Jan Kowalski"
}
```

**Response:**
```json
{
  "userId": "user-uuid",
  "kycBankVerified": true,
  "kycStatus": "pending"
}
```

**Postman Setup:**
- Method: `POST`
- URL: `http://localhost:3000/api/v1/contractor/kyc/bank`
- Headers:
  - `Authorization: Bearer <your_jwt_token>`
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "iban": "PL61109010140000071219812874",
  "accountHolder": "Jan Kowalski"
}
```

---

## 📦 Postman Collection Setup

### Step 1: Create Environment Variables

1. Open Postman
2. Click **Environments** → **+** (Create)
3. Name: `Szybka Fucha Local`
4. Add variables:
   - `base_url`: `http://localhost:3000/api/v1`
   - `jwt_token`: (leave empty, will be set after login)

### Step 2: Create Collection

1. Click **Collections** → **+** (New Collection)
2. Name: `Szybka Fucha API`
3. Add folders:
   - `Auth`
   - `Users`
   - `Tasks`
   - `Contractor`

### Step 3: Configure Collection Variables

1. Click on collection → **Variables** tab
2. Add:
   - `base_url`: `http://localhost:3000/api/v1`
   - `jwt_token`: (empty)

### Step 4: Set Up Authorization

For protected endpoints:

1. Go to collection → **Authorization** tab
2. Type: `Bearer Token`
3. Token: `{{jwt_token}}`

Or set per request:
- **Authorization** tab → Type: `Bearer Token`
- Token: `{{jwt_token}}`

### Step 5: Save JWT Token Automatically

After **Verify OTP** request:

1. Go to **Tests** tab
2. Add script:
```javascript
if (pm.response.code === 200) {
    const jsonData = pm.response.json();
    if (jsonData.access_token) {
        pm.environment.set("jwt_token", jsonData.access_token);
        console.log("JWT token saved!");
    }
}
```

### Step 6: Example Request Flow

1. **Request OTP**
   - POST `{{base_url}}/auth/phone/request-otp`
   - Body: `{ "phone": "+48123456789" }`

2. **Verify OTP** (with Tests script to save token)
   - POST `{{base_url}}/auth/phone/verify`
   - Body: `{ "phone": "+48123456789", "code": "123456", "userType": "client" }`

3. **Get Profile** (uses saved token)
   - GET `{{base_url}}/users/me`
   - Authorization: Bearer `{{jwt_token}}`

---

## 🧪 Testing Workflow

### Complete Task Flow Example

1. **Create Client Account**
   ```
   POST /auth/phone/request-otp
   POST /auth/phone/verify (userType: "client")
   → Save JWT as `client_token`
   ```

2. **Create Task**
   ```
   POST /tasks
   Authorization: Bearer {{client_token}}
   → Save task ID
   ```

3. **Create Contractor Account**
   ```
   POST /auth/phone/request-otp
   POST /auth/phone/verify (userType: "contractor")
   → Save JWT as `contractor_token`
   ```

4. **Setup Contractor Profile**
   ```
   PUT /contractor/profile
   PUT /contractor/availability (isOnline: true)
   PUT /contractor/location
   Authorization: Bearer {{contractor_token}}
   ```

5. **Contractor Views Available Tasks**
   ```
   GET /tasks?lat=52.2297&lng=21.0122&categories=paczki
   Authorization: Bearer {{contractor_token}}
   ```

6. **Contractor Accepts Task**
   ```
   PUT /tasks/{task-id}/accept
   Authorization: Bearer {{contractor_token}}
   ```

7. **Contractor Starts Task**
   ```
   PUT /tasks/{task-id}/start
   Authorization: Bearer {{contractor_token}}
   ```

8. **Contractor Completes Task**
   ```
   PUT /tasks/{task-id}/complete
   Body: { "completionPhotos": ["https://..."] }
   Authorization: Bearer {{contractor_token}}
   ```

9. **Client Confirms Task**
   ```
   PUT /tasks/{task-id}/confirm
   Authorization: Bearer {{client_token}}
   ```

10. **Client Rates Task**
    ```
    POST /tasks/{task-id}/rate
    Body: { "rating": 5, "comment": "Świetna praca!" }
    Authorization: Bearer {{client_token}}
    ```

---

## 🔍 Error Responses

All endpoints return standard error format:

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request"
}
```

**Common Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid JWT)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

---

## 📝 Notes

- **JWT Expiration**: Tokens expire after 24 hours (configurable in `.env`)
- **Phone OTP**: Currently mocked in development (returns code `123456`)
- **Database**: TypeORM auto-syncs schema (use migrations in production)
- **Validation**: All DTOs use `class-validator` for request validation

---

## 🚀 Next Steps

1. ✅ Database connected
2. ✅ API endpoints working
3. ⏳ Payments Module (Stripe integration)
4. ⏳ Real-time Module (WebSocket)
5. ⏳ Chat Module
6. ⏳ Push Notifications
7. ⏳ Admin Dashboard Backend API

---

**Last Updated:** January 2, 2026  
**API Version:** v1  
**Base URL:** `http://localhost:3000/api/v1`
