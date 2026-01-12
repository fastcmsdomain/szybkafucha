# Authentication Testing Guide

> **Task Reference:** 3.0 Authentication Module from `tasks-prd-szybka-fucha.md`
> **Status:** Completed
> **Date:** January 2026

---

## Overview

This guide covers how to test all authentication methods in the Szybka Fucha backend:
- Phone OTP authentication
- Google Sign-In
- Apple Sign-In
- Logout

---

## Prerequisites

1. Backend server running: `cd backend && npm run start:dev`
2. PostgreSQL and Redis running: `docker-compose up -d`
3. Base URL: `http://localhost:3000/api/v1`

---

## 1. Phone OTP Authentication

### Step 1: Request OTP

```bash
curl -X POST http://localhost:3000/api/v1/auth/phone/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+48123456789"}'
```

**Expected Response:**
```json
{
  "message": "OTP sent successfully",
  "expiresIn": 300
}
```

**In Development Mode:**
- OTP is NOT sent via SMS
- Check backend console logs for the OTP code:
  ```
  [AuthService] [DEV] OTP for +48123456789: 123456
  ```

### Step 2: Verify OTP

```bash
curl -X POST http://localhost:3000/api/v1/auth/phone/verify \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+48123456789",
    "code": "123456",
    "userType": "client"
  }'
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-here",
    "type": "client",
    "name": null,
    "email": null,
    "phone": "+48123456789",
    "avatarUrl": null,
    "status": "active"
  },
  "isNewUser": true
}
```

**Parameters:**
| Field | Required | Description |
|-------|----------|-------------|
| phone | Yes | Phone number (with or without +48 prefix) |
| code | Yes | 6-digit OTP from console/SMS |
| userType | No | `client` (default) or `contractor` |

---

## 2. Google Sign-In

In development, the endpoint accepts Google credentials directly without token validation.

```bash
curl -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "googleId": "google-user-123456",
    "email": "user@gmail.com",
    "name": "Jan Kowalski",
    "avatarUrl": "https://lh3.googleusercontent.com/...",
    "userType": "client"
  }'
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-here",
    "type": "client",
    "name": "Jan Kowalski",
    "email": "user@gmail.com",
    "phone": null,
    "avatarUrl": "https://lh3.googleusercontent.com/...",
    "status": "active"
  },
  "isNewUser": true
}
```

**Parameters:**
| Field | Required | Description |
|-------|----------|-------------|
| googleId | Yes | Google user ID (from Google Sign-In SDK) |
| email | Yes | User's email from Google |
| name | No | Display name |
| avatarUrl | No | Profile picture URL |
| userType | No | `client` (default) or `contractor` |

**Behavior:**
- If `googleId` exists: Returns existing user
- If `email` exists but no `googleId`: Links Google account to existing user
- Otherwise: Creates new user

---

## 3. Apple Sign-In

In development, the endpoint accepts Apple credentials directly without token validation.

```bash
curl -X POST http://localhost:3000/api/v1/auth/apple \
  -H "Content-Type: application/json" \
  -d '{
    "appleId": "apple-user-123456",
    "email": "user@icloud.com",
    "name": "Anna Nowak",
    "userType": "contractor"
  }'
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-here",
    "type": "contractor",
    "name": "Anna Nowak",
    "email": "user@icloud.com",
    "phone": null,
    "avatarUrl": null,
    "status": "active"
  },
  "isNewUser": true
}
```

**Parameters:**
| Field | Required | Description |
|-------|----------|-------------|
| appleId | Yes | Apple user ID (from Apple Sign-In SDK) |
| email | No | User's email (Apple may hide this) |
| name | No | Display name (only provided on first sign-in) |
| userType | No | `client` (default) or `contractor` |

**Note:** Apple only provides email and name on the FIRST sign-in. Subsequent sign-ins only provide `appleId`.

---

## 4. Logout

Requires authentication (Bearer token).

```bash
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response:**
```json
{
  "message": "Logged out successfully"
}
```

**Implementation Note:**
This is a simple logout - the client should clear the stored token. The JWT remains valid until expiration (30 days). For MVP, this is acceptable.

---

## 5. Using Protected Routes

After authentication, use the `accessToken` for protected endpoints:

```bash
# Get current user profile
curl http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Update profile
curl -X PUT http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Name"}'
```

---

## Postman Collection

Import these requests into Postman for easier testing:

### Environment Variables
```
base_url: http://localhost:3000/api/v1
access_token: (set after login)
```

### Collection Structure
```
Auth/
├── Phone/
│   ├── Request OTP
│   └── Verify OTP
├── Google Sign-In
├── Apple Sign-In
└── Logout
```

---

## Common Errors

### 400 Bad Request
```json
{"statusCode": 400, "message": ["phone should not be empty"], "error": "Bad Request"}
```
**Cause:** Missing or invalid request body fields.

### 401 Unauthorized
```json
{"statusCode": 401, "message": "Unauthorized"}
```
**Cause:** Missing or invalid Bearer token for protected routes.

### 429 Too Many Requests
```json
{"statusCode": 429, "message": "ThrottlerException: Too Many Requests"}
```
**Cause:** Rate limit exceeded.
- OTP request: 3 requests per 60 seconds
- OTP verify: 5 requests per 60 seconds

### OTP Errors
```json
{"statusCode": 400, "message": "OTP not found or expired. Please request a new one."}
```
**Cause:** OTP expired (5 minutes) or already used.

```json
{"statusCode": 400, "message": "Invalid OTP code."}
```
**Cause:** Wrong OTP code entered.

---

## Production Considerations

### Phone OTP
- Configure Twilio credentials in `.env`:
  ```
  TWILIO_ACCOUNT_SID=your_account_sid
  TWILIO_AUTH_TOKEN=your_auth_token
  TWILIO_PHONE_NUMBER=+1234567890
  ```
- OTP will be sent via SMS in production (`NODE_ENV=production`)

### Google Sign-In
- In production, validate Google ID tokens properly
- Configure `GOOGLE_CLIENT_ID` in `.env`
- Mobile app should use official Google Sign-In SDK

### Apple Sign-In
- In production, validate Apple identity tokens
- Configure Apple Sign-In credentials
- Required for iOS App Store if any other social login is offered

---

## Automated Tests

### Unit Tests
```bash
cd backend
npm test src/auth/auth.service.spec.ts
```
**16 tests covering:** Token generation, OTP flow, Google auth, Apple auth

### E2E Tests
```bash
cd backend
npm run test:e2e test/auth.e2e-spec.ts
```
**20 tests covering:** All endpoints, validation, error cases, protected routes

### Run All Tests
```bash
cd backend
npm test           # Unit tests
npm run test:e2e   # E2E tests
```

---

## JWT Token Structure

The access token contains:
```json
{
  "sub": "user-uuid",    // User ID
  "type": "client",      // User type (client/contractor)
  "iat": 1234567890,     // Issued at
  "exp": 1237246290      // Expires (30 days from issue)
}
```

Decode tokens at [jwt.io](https://jwt.io) for debugging.

---

## Quick Test Script

Save as `test-auth.sh`:

```bash
#!/bin/bash
BASE_URL="http://localhost:3000/api/v1"

echo "=== Testing Phone OTP ==="
echo "1. Request OTP..."
curl -s -X POST "$BASE_URL/auth/phone/request-otp" \
  -H "Content-Type: application/json" \
  -d '{"phone": "+48999888777"}' | jq

echo ""
echo "Check backend console for OTP code, then run:"
echo 'curl -X POST "'$BASE_URL'/auth/phone/verify" -H "Content-Type: application/json" -d '"'"'{"phone": "+48999888777", "code": "YOUR_OTP"}'"'"''

echo ""
echo "=== Testing Google Auth ==="
GOOGLE_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/google" \
  -H "Content-Type: application/json" \
  -d '{"googleId": "test-google-'$RANDOM'", "email": "test'$RANDOM'@gmail.com", "name": "Test User"}')
echo $GOOGLE_RESPONSE | jq

TOKEN=$(echo $GOOGLE_RESPONSE | jq -r '.accessToken')
echo ""
echo "=== Testing Protected Route ==="
curl -s "$BASE_URL/users/me" \
  -H "Authorization: Bearer $TOKEN" | jq

echo ""
echo "=== Testing Logout ==="
curl -s -X POST "$BASE_URL/auth/logout" \
  -H "Authorization: Bearer $TOKEN" | jq
```

Run with: `chmod +x test-auth.sh && ./test-auth.sh`
