# Push Notifications - Szybka Fucha

## Overview

Push notifications are handled via Firebase Cloud Messaging (FCM). The system supports both Android and iOS platforms and operates in mock mode during development when Firebase credentials are not configured.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Backend       │────▶│   Firebase      │────▶│   Mobile App    │
│   Service       │     │   FCM           │     │   (iOS/Android) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │
        ▼
┌─────────────────┐
│   User DB       │
│   (FCM Tokens)  │
└─────────────────┘
```

## Configuration

### Environment Variables

Add to `.env`:

```bash
# Firebase Cloud Messaging
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### Mock Mode

When `FIREBASE_PROJECT_ID` is `placeholder` or not set, the service runs in mock mode:
- Notifications are logged to console
- All API calls return success
- No actual push notifications are sent

## API Endpoints

### Register FCM Token

```http
PUT /users/me/fcm-token
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "fcmToken": "fcm-device-token-from-firebase-sdk"
}
```

**Response:**
```json
{
  "id": "user-123",
  "fcmToken": "fcm-device-token-from-firebase-sdk",
  ...
}
```

## Notification Types

| Type | Trigger | Recipients |
|------|---------|------------|
| `new_task_nearby` | Task created | Nearby contractors |
| `task_accepted` | Contractor accepts | Client |
| `task_started` | Contractor starts work | Client |
| `task_completed` | Contractor completes | Client |
| `task_confirmed` | Client confirms | Contractor |
| `task_cancelled` | Task cancelled | Other party |
| `task_rated` | User rated | Rated user |
| `tip_received` | Client tips | Contractor |
| `new_message` | Message sent | Recipient |
| `payment_received` | Payment captured | Contractor |
| `payment_refunded` | Payment refunded | Client |
| `kyc_document_verified` | ID verified | Contractor |
| `kyc_selfie_verified` | Selfie verified | Contractor |
| `kyc_bank_verified` | Bank verified | Contractor |
| `kyc_complete` | Full KYC done | Contractor |

## Service API

### NotificationsService

```typescript
// Send to single user by ID
await notificationsService.sendToUser(
  userId,
  NotificationType.TASK_ACCEPTED,
  { taskTitle: 'Task Name', contractorName: 'John' }
);

// Send to multiple users
await notificationsService.sendToUsers(
  userIds,
  NotificationType.TASK_CANCELLED,
  { taskTitle: 'Task Name', reason: 'Client request' }
);

// Send directly to FCM token
await notificationsService.sendToToken(
  fcmToken,
  NotificationType.NEW_MESSAGE,
  { senderName: 'John', messagePreview: 'Hello!' }
);

// Check if in mock mode
const isMock = notificationsService.isMockMode();
```

## Template Placeholders

Templates use `{placeholder}` syntax:

```typescript
const templates = {
  new_task_nearby: {
    title: 'Nowe zlecenie w pobliżu!',
    body: '{category} - {budget} PLN ({distance}km od Ciebie)',
  },
  task_accepted: {
    title: 'Zlecenie zaakceptowane!',
    body: '{contractorName} przyjął Twoje zlecenie "{taskTitle}"',
  },
  // ...
};
```

## Mobile Integration

### Android (Flutter)

```dart
// Get FCM token
final token = await FirebaseMessaging.instance.getToken();

// Send to backend
await dio.put('/users/me/fcm-token', data: {'fcmToken': token});

// Listen for token refresh
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  dio.put('/users/me/fcm-token', data: {'fcmToken': newToken});
});
```

### iOS (Flutter)

```dart
// Request permission
await FirebaseMessaging.instance.requestPermission();

// Get APNS token (handled automatically by Flutter)
final token = await FirebaseMessaging.instance.getToken();
```

## Testing

### Unit Tests

```bash
cd backend && npm test -- --testPathPattern=notifications
```

### E2E Tests

```bash
cd backend && npm run test:e2e -- --testPathPattern=notifications
```

## Troubleshooting

### Notifications not received

1. Check FCM token is registered: `GET /users/me`
2. Check backend logs for mock mode warning
3. Verify Firebase credentials in `.env`
4. Check Firebase Console for delivery issues

### Mock mode active

```
⚠️ Firebase not configured - running in MOCK MODE. Notifications will be logged but not sent.
```

To fix: Add valid Firebase credentials to `.env`

## Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create or select project
3. Go to Project Settings > Service Accounts
4. Generate new private key
5. Copy values to `.env`:
   - `FIREBASE_PROJECT_ID`: from service account JSON
   - `FIREBASE_CLIENT_EMAIL`: from service account JSON
   - `FIREBASE_PRIVATE_KEY`: from service account JSON (keep newlines as `\n`)

## Security

- FCM tokens are stored in user records
- Tokens should be refreshed on app launch
- Old tokens are overwritten on update
- No sensitive data in notification payloads
