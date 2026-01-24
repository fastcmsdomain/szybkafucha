# Szybka Fucha API - Running on http://localhost:3000

## ✅ Server Status

**Base URL**: `http://localhost:3000/api/v1`  
**Status**: ✅ Running and healthy  
**Database**: ✅ Connected (PostgreSQL)

---

## 🔍 Quick Check

### Health Check
```bash
curl http://localhost:3000/api/v1/health
```
**Response:**
```json
{
  "status": "ok",
  "info": {
    "database": {
      "status": "up"
    }
  },
  "error": {},
  "details": {
    "database": {
      "status": "up"
    }
  }
}
```

### Root Endpoint
```bash
curl http://localhost:3000/api/v1
```
**Response:** `Hello World!`

---

## 📡 Available API Endpoints

### 🔐 Authentication (`/api/v1/auth`)

#### Request OTP (SMS)
```bash
POST /api/v1/auth/phone/request-otp
Content-Type: application/json

{
  "phone": "+48123456789"
}
```

#### Verify OTP & Login
```bash
POST /api/v1/auth/phone/verify
Content-Type: application/json

{
  "phone": "+48123456789",
  "code": "123456"
}
```

#### Google OAuth
```bash
POST /api/v1/auth/google
Content-Type: application/json

{
  "idToken": "google_id_token_here"
}
```

#### Apple Sign In
```bash
POST /api/v1/auth/apple
Content-Type: application/json

{
  "idToken": "apple_id_token_here"
}
```

---

### 👤 Users (`/api/v1/users`)

**All endpoints require JWT authentication**

#### Get Current User Profile
```bash
GET /api/v1/users/me
Authorization: Bearer <jwt_token>
```

#### Update Profile
```bash
PUT /api/v1/users/me
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "name": "Jan Kowalski",
  "avatarUrl": "https://..."
}
```

---

### 📦 Tasks (`/api/v1/tasks`)

**All endpoints require JWT authentication**

#### Create New Task (Client only)
```bash
POST /api/v1/tasks
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "category": "paczki",
  "title": "Delivery in Krakow",
  "description": "Need to deliver package",
  "locationLat": 50.0647,
  "locationLng": 19.9450,
  "address": "Krakow, Poland",
  "budgetAmount": 50.00,
  "scheduledAt": "2026-01-25T10:00:00Z" // optional
}
```

#### List Tasks
```bash
# For clients - returns their own tasks
GET /api/v1/tasks
Authorization: Bearer <jwt_token>

# For contractors - returns available nearby tasks
GET /api/v1/tasks?lat=50.0647&lng=19.9450&categories=paczki,zakupy&radiusKm=10
Authorization: Bearer <jwt_token>
```

#### Get Task Details
```bash
GET /api/v1/tasks/:id
Authorization: Bearer <jwt_token>
```

#### Accept Task (Contractor)
```bash
PUT /api/v1/tasks/:id/accept
Authorization: Bearer <jwt_token>
```

#### Start Task (Contractor)
```bash
PUT /api/v1/tasks/:id/start
Authorization: Bearer <jwt_token>
```

#### Complete Task (Contractor)
```bash
PUT /api/v1/tasks/:id/complete
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "completionPhotos": ["url1", "url2"] // optional
}
```

#### Confirm Task (Client)
```bash
PUT /api/v1/tasks/:id/confirm
Authorization: Bearer <jwt_token>
```

#### Cancel Task
```bash
PUT /api/v1/tasks/:id/cancel
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "reason": "Changed my mind" // optional
}
```

#### Rate Task
```bash
POST /api/v1/tasks/:id/rate
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "rating": 5,
  "comment": "Great service!"
}
```

#### Add Tip
```bash
POST /api/v1/tasks/:id/tip
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "amount": 10.00
}
```

---

### 🔧 Contractor (`/api/v1/contractor`)

**All endpoints require JWT authentication (contractor only)**

#### Get Contractor Profile
```bash
GET /api/v1/contractor/profile
Authorization: Bearer <jwt_token>
```

#### Update Profile
```bash
PUT /api/v1/contractor/profile
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "bio": "Experienced delivery person",
  "categories": ["paczki", "zakupy"],
  "serviceRadiusKm": 15
}
```

#### Update Availability
```bash
PUT /api/v1/contractor/availability
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "isOnline": true
}
```

#### Update Location
```bash
PUT /api/v1/contractor/location
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "lat": 50.0647,
  "lng": 19.9450
}
```

---

### 💬 Messages (`/api/v1/tasks/:taskId/messages`)

**All endpoints require JWT authentication**

#### Get Chat History
```bash
GET /api/v1/tasks/:taskId/messages
Authorization: Bearer <jwt_token>
```

#### Send Message
```bash
POST /api/v1/tasks/:taskId/messages
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "content": "Hello, when can you arrive?"
}
```

#### Mark Messages as Read
```bash
POST /api/v1/tasks/:taskId/messages/read
Authorization: Bearer <jwt_token>
```

#### Get Unread Count
```bash
GET /api/v1/tasks/:taskId/messages/unread-count
Authorization: Bearer <jwt_token>
```

---

### 💳 Payments (`/api/v1/payments`)

**All endpoints require JWT authentication**

#### Create Payment Intent
```bash
POST /api/v1/payments/intent
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "taskId": "uuid-here",
  "amount": 50.00
}
```

#### Confirm Payment
```bash
POST /api/v1/payments/confirm
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "paymentIntentId": "pi_xxx"
}
```

---

### 🔐 KYC (`/api/v1/kyc`)

**All endpoints require JWT authentication (contractor only)**

#### Upload ID Document
```bash
POST /api/v1/kyc/id
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data

file: <image_file>
```

#### Upload Selfie
```bash
POST /api/v1/kyc/selfie
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data

file: <image_file>
```

#### Add Bank Account
```bash
POST /api/v1/kyc/bank
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "accountNumber": "PL1234567890",
  "bankName": "PKO BP"
}
```

---

### 📧 Newsletter (`/api/v1/newsletter`)

#### Subscribe (Public)
```bash
POST /api/v1/newsletter/subscribe
Content-Type: application/json

{
  "email": "user@example.com",
  "name": "Jan Kowalski",
  "userType": "client",
  "consent": true
}
```

#### Get All Subscribers (Admin only)
```bash
GET /api/v1/newsletter/subscribers
Authorization: Bearer <admin_jwt_token>
```

---

### 👨‍💼 Admin (`/api/v1/admin`)

**All endpoints require JWT authentication (admin only)**

#### Dashboard Stats
```bash
GET /api/v1/admin/stats
Authorization: Bearer <admin_jwt_token>
```

#### List All Users
```bash
GET /api/v1/admin/users?page=1&limit=20&type=client
Authorization: Bearer <admin_jwt_token>
```

#### List All Tasks
```bash
GET /api/v1/admin/tasks?status=created&category=paczki
Authorization: Bearer <admin_jwt_token>
```

#### List Disputes
```bash
GET /api/v1/admin/disputes
Authorization: Bearer <admin_jwt_token>
```

---

## 🔒 Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Getting a JWT Token

1. **Request OTP:**
   ```bash
   POST /api/v1/auth/phone/request-otp
   {
     "phone": "+48123456789"
   }
   ```

2. **Verify OTP:**
   ```bash
   POST /api/v1/auth/phone/verify
   {
     "phone": "+48123456789",
     "code": "123456"
   }
   ```
   
   **Response:**
   ```json
   {
     "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "user": {
       "id": "uuid",
       "phone": "+48123456789",
       "type": "client"
     }
   }
   ```

3. **Use the token:**
   Include `Authorization: Bearer <accessToken>` in all subsequent requests.

---

## 🧪 Testing Endpoints

### Using cURL

```bash
# Health check
curl http://localhost:3000/api/v1/health

# Request OTP
curl -X POST http://localhost:3000/api/v1/auth/phone/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"+48123456789"}'

# Get tasks (requires auth)
curl http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Using Postman

Import the collection from: `tasks/postman/Szybka-Fucha-API.postman_collection.json`

---

## 📊 Server Information

- **Framework**: NestJS
- **Database**: PostgreSQL 15 (with PostGIS)
- **Cache**: Redis
- **Port**: 3000
- **API Prefix**: `/api/v1`
- **CORS**: Enabled for mobile app, admin panel, and landing page
- **Security**: Helmet.js, rate limiting, JWT authentication

---

## 🐛 Troubleshooting

### Server not responding
```bash
# Check if server is running
curl http://localhost:3000/api/v1/health

# Check Docker containers
docker-compose ps

# Check backend logs
cd backend && npm run start:dev
```

### CORS errors
- Make sure your origin is in the allowed list
- Check `backend/.env` for `FRONTEND_URL`, `ADMIN_URL`, `LANDING_PAGE_URL`

### Authentication errors
- Make sure JWT token is valid and not expired
- Check token format: `Authorization: Bearer <token>`

---

## 📚 More Information

- **API Documentation**: See `tasks/postman/api-summary.md`
- **Postman Collection**: `tasks/postman/Szybka-Fucha-API.postman_collection.json`
- **Backend Setup**: `backend/SETUP.md`
- **Architecture**: `ARCHITECTURE.md`
