# Task 17.0: Real-time Features - Implementation Guide

**Status**: 🚀 IN PROGRESS
**Target**: Socket.io integration + Location tracking + Chat
**Timeline**: Phased implementation over multiple steps

---

## Quick Start: What You Need from the User

Before implementing Task 17.0, you'll need the user to provide:

### 1. **WebSocket URL** ⚠️ CRITICAL
- **Dev Mode**: Is backend running on `localhost:3000`?
- **Staging**: What's the staging WebSocket URL?
- **Production**: What's the production WebSocket URL?

**Expected Format**: `ws://localhost:3000` or `wss://api.szybkafucha.pl`

**Configure In**:
```dart
// lib/core/config/websocket_config.dart
abstract class WebSocketConfig {
  static const String webSocketUrl = 'ws://localhost:3000/realtime';
  // ↑ User provides this
}
```

### 2. **Firebase Setup** (for push notifications)
- Google Play Services? Already set up?
- `google-services.json` ready?
- APNs certificates for iOS?
- FCM credentials available?

### 3. **Backend Event Payload Format**
Ask user to confirm these Socket.io events match what backend is sending:

```typescript
// location:update event
{
  userId: string
  latitude: number
  longitude: number
  timestamp: Date
}

// message:new event
{
  id: string
  taskId: string
  senderId: string
  senderName: string
  content: string
  createdAt: Date
}

// task:status event
{
  taskId: string
  status: string  // "accepted" | "in_progress" | "completed"
  updatedAt: Date
}
```

---

## Implementation Phases

### Phase 1: WebSocket Core (Days 1-2)

**Deliverables**:
- Socket.io client connects to backend with JWT auth
- Automatic reconnection with exponential backoff
- Dev mode mock implementation
- Connection state indicator in UI

**User Steps**:
1. Provide WebSocket URL
2. Confirm Socket.io namespace is `/realtime`
3. Verify JWT token is passed in connection params

**Files to Create**:
- `lib/core/services/websocket_service.dart` - Core service (350 lines)
- `lib/core/providers/websocket_provider.dart` - Riverpod provider (120 lines)
- `lib/core/config/websocket_config.dart` - Configuration (40 lines)

**Testing**:
```bash
# Dev mode with mock WebSocket - no backend needed
flutter run
# Should see "Connected" indicator in UI
```

---

### Phase 2: Location Tracking (Days 3-4)

**Deliverables**:
- Contractor sends GPS location every 15 seconds while task active
- Client receives location updates and shows on map
- Real-time location indicator in UI

**User Steps**:
1. Provide location permission descriptions for iOS/Android
2. Confirm backend is broadcasting `location:update` events
3. Test with actual GPS or simulator

**Files to Create**:
- `lib/core/services/location_service.dart` - GPS polling (200 lines)
- `lib/features/contractor/providers/location_provider.dart` - Broadcasting (180 lines)
- `lib/features/client/providers/contractor_location_provider.dart` - Receiving (150 lines)
- `lib/features/client/widgets/contractor_location_map.dart` - Map display (180 lines)

**Modifications**:
- `active_task_screen.dart` - Add location indicator
- `task_tracking_screen.dart` - Show contractor location on map

**Testing**:
```bash
# Use Android Emulator's location simulation
# Or iPhone Simulator's location features
# Should see location update every 15 seconds
```

---

### Phase 3: Chat Feature (Days 5-7)

**Deliverables**:
- Real-time messaging between contractor and client
- Message persistence (local storage)
- Offline message queue
- Chat UI with proper formatting

**User Steps**:
1. Confirm backend `message:new` event payload
2. Provide test task ID for testing
3. Set up Hive database (local storage)

**Files to Create**:
- `lib/features/chat/models/message.dart` - Message model (120 lines)
- `lib/features/chat/providers/chat_provider.dart` - Chat state (280 lines)
- `lib/features/chat/screens/chat_screen.dart` - Main chat UI (350 lines)
- `lib/features/chat/widgets/message_bubble.dart` - Message display (200 lines)
- `lib/features/chat/widgets/chat_input.dart` - Input widget (180 lines)

**Modifications**:
- `active_task_screen.dart` - Add chat button
- `lib/core/providers/storage_provider.dart` - Add Hive storage

**Dependencies**:
```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
hive_generator: ^2.0.1  # dev_dependencies
```

**Testing**:
```bash
# Test with two devices or two simulator instances
# Send message from contractor, receive on client
# Test offline: disconnect internet, send message
# Turn internet on: message auto-sends
```

---

### Phase 4: Push Notifications (Days 8+)

**Deliverables**:
- Firebase Cloud Messaging integration
- Notification routing based on type
- Deep linking to relevant screens
- Notification history

**User Steps**:
1. Provide Firebase project ID
2. Configure `google-services.json`
3. Provide APNs certificate (iOS)
4. Whitelist notification domains

**Files to Create**:
- `lib/core/services/push_notification_service.dart` - FCM service (250 lines)
- `lib/core/providers/push_notification_provider.dart` - Provider (100 lines)
- `lib/core/services/notification_router.dart` - Deep linking (150 lines)

**Dependencies**:
```yaml
firebase_messaging: ^14.7.0
firebase_core: ^2.24.0
```

**Testing**:
```bash
# Send test notification from Firebase Console
# Should see notification on device
# Tap notification should deep link to correct screen
```

---

## Architecture: How It All Connects

```
┌─────────────────────────────────────────────────────────┐
│  UI Screens (Active Task, Tracking, Chat)               │
├─────────────────────────────────────────────────────────┤
│  ↓ reads/writes                                         │
│  Riverpod Providers (location_provider, chat_provider) │
├─────────────────────────────────────────────────────────┤
│  ↓ calls methods on                                     │
│  Services (WebSocketService, LocationService)          │
├─────────────────────────────────────────────────────────┤
│  ↓ sends events over                                    │
│  WebSocket → Backend Socket.io Gateway                 │
└─────────────────────────────────────────────────────────┘
```

### Data Flow Example: Send Chat Message

```
1. User types message in ChatInput
   ↓
2. ChatNotifier.sendMessage() called
   ↓
3. Service sends POST /tasks/:id/messages (REST for reliability)
   ↓
4. Backend receives, broadcasts message:new via Socket.io
   ↓
5. WebSocketService receives message:new event
   ↓
6. Event triggers chat_provider state update
   ↓
7. UI rebuilds with new message
```

### Data Flow Example: Receive Location Update

```
1. Contractor's location_provider polls GPS every 15s
   ↓
2. Sends location:update via WebSocket
   ↓
3. Backend broadcasts to client in task room
   ↓
4. Client's contractor_location_provider receives event
   ↓
5. Updates map marker on task_tracking_screen
   ↓
6. Calculates ETA and displays to user
```

---

## Key Decisions to Make

### 1. **Location Accuracy vs Battery**
**Options**:
- **Option A**: High accuracy (10m), updates every 5 seconds
  - Pros: Very accurate tracking
  - Cons: Drains battery fast
- **Option B**: Balanced (50m), updates every 15 seconds ✅ RECOMMENDED
  - Pros: Good accuracy, reasonable battery usage
  - Cons: May have slight delay
- **Option C**: Low accuracy (100m), updates every 30 seconds
  - Pros: Battery efficient
  - Cons: Too inaccurate for navigation

**Recommendation**: Use **Option B** (15 second updates)

### 2. **Message Persistence**
**Options**:
- **Option A**: No persistence (message lost if app closes)
  - Pros: Simple, privacy-focused
  - Cons: Terrible UX
- **Option B**: Cache locally with Hive ✅ RECOMMENDED
  - Pros: Good UX, messages available offline
  - Cons: Requires local storage
- **Option C**: Cloud backup (complex)

**Recommendation**: Use **Option B** (Hive local storage)

### 3. **Reconnection Strategy**
**Exponential Backoff**:
```
Connection fails → Wait 1s → Retry
Still fails → Wait 2s → Retry
Still fails → Wait 4s → Retry
...
Max wait: 8 seconds between retries
Max attempts: 10
```

Rationale: Don't overwhelm server, but reconnect quickly when possible

### 4. **Dev Mode Testing**
**Mock WebSocket Events** (when `devModeEnabled = true`):
```dart
// Simulate location updates
Timer.periodic(Duration(seconds: 15), (_) {
  _emit('location:update', {
    'latitude': 52.2 + random(),
    'longitude': 21.0 + random(),
  });
});

// Simulate incoming messages
_scheduleMessage('Hello from client!', delaySeconds: 5);

// Simulate task status changes
_scheduleTaskStatusUpdate(TaskStatus.accepted, delaySeconds: 30);
```

---

## Implementation Checklist

### Prerequisites
- [ ] User provides WebSocket URL
- [ ] User confirms Firebase setup
- [ ] Backend confirms event formats
- [ ] iOS/Android permissions configured

### Phase 1: WebSocket
- [ ] Create `WebSocketService` with connection lifecycle
- [ ] Create `websocket_provider` for state management
- [ ] Implement exponential backoff reconnection
- [ ] Add dev mode mock implementation
- [ ] Test connection with backend
- [ ] Add connection state indicator to UI

### Phase 2: Location
- [ ] Create `LocationService` for GPS polling
- [ ] Create `location_provider` for contractor
- [ ] Create `contractor_location_provider` for client
- [ ] Handle location permissions (iOS/Android)
- [ ] Integrate map widget in tracking screen
- [ ] Calculate distance and ETA
- [ ] Test on real devices with actual GPS

### Phase 3: Chat
- [ ] Create `Message` model with JSON serialization
- [ ] Set up Hive database for message storage
- [ ] Create `chat_provider` with offline queue
- [ ] Build `ChatScreen` UI
- [ ] Implement message sending and receiving
- [ ] Add read receipts
- [ ] Test chat flow on two devices

### Phase 4: Notifications
- [ ] Set up Firebase Cloud Messaging
- [ ] Create `PushNotificationService`
- [ ] Implement notification routing
- [ ] Add deep linking to screens
- [ ] Test notifications from Firebase Console

### Quality Assurance
- [ ] `flutter analyze` passes
- [ ] All tests pass
- [ ] No console warnings/errors
- [ ] Performance is acceptable
- [ ] Offline mode works
- [ ] Reconnection works

---

## Testing Scenarios

### Scenario 1: Chat While Location Tracking
**Steps**:
1. Contractor accepts task
2. Starts location tracking (icon shows "sharing location")
3. Both users send chat messages
4. Verify messages arrive in real-time
5. Verify location updates continue while chatting

**Success**: Messages and location updates both work simultaneously

---

### Scenario 2: Reconnect After Network Loss
**Steps**:
1. Airplane mode ON (internet off)
2. Try to send message (shows "sending...")
3. Airplane mode OFF (internet on)
4. Wait 5 seconds
5. Message auto-sends

**Success**: Message queued offline, sent when reconnected

---

### Scenario 3: App Backgrounded While Tracking
**Steps**:
1. Start location tracking (foreground)
2. Press home button (app backgrounds)
3. Wait 30 seconds
4. Bring app back to foreground
5. Check map - contractor location updated

**Success**: Location continued broadcasting in background

---

### Scenario 4: Multiple Notifications
**Steps**:
1. Receive chat message notification
2. Tap notification
3. Should open ChatScreen for that task
4. Go back, receive another notification (different task)
5. Tap notification
6. Should open ChatScreen for the new task

**Success**: Each notification opens correct screen

---

## Performance Targets

| Metric | Target | Acceptable |
|--------|--------|-----------|
| WebSocket connection time | < 2s | < 5s |
| Chat message round-trip | < 500ms | < 2s |
| Location update latency | < 100ms | < 500ms |
| Memory usage | < 50MB | < 100MB |
| Battery drain (tracking) | < 5%/hour | < 10%/hour |

---

## Error Scenarios & Recovery

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| WebSocket disconnected | Timeout after 30s | Auto-reconnect with backoff |
| Location unavailable | GPS timeout | Show "Location unavailable" |
| Message send failed | HTTP 500 | Queue and retry |
| Chat history corrupted | Hive read error | Clear cache, reload from server |
| FCM token expired | 401 response | Request new token |

---

## User Input Required

**Before You Start Implementing**:

Please provide the following information so I can write the correct integration:

1. **WebSocket Configuration**:
   - [ ] WebSocket URL (e.g., `ws://localhost:3000/realtime`)
   - [ ] Namespace (confirm it's `/realtime`)
   - [ ] Authentication method (confirm JWT in query params)

2. **Event Formats**:
   - [ ] Confirm the exact payload for `location:update` events
   - [ ] Confirm the exact payload for `message:new` events
   - [ ] Confirm the exact payload for `task:status` events
   - [ ] Any additional events we should listen for?

3. **Firebase Setup**:
   - [ ] Is Google Play Services configured?
   - [ ] Is `google-services.json` ready?
   - [ ] Are APNs certificates ready?
   - [ ] Firebase project ID?

4. **Testing Environment**:
   - [ ] Can we test with backend running locally?
   - [ ] Do you have test task IDs we should use?
   - [ ] Can you create two test contractor accounts for chat testing?

---

## Next Steps

1. **Provide the information above** ↑
2. I'll create `WebSocketService` with proper configuration
3. Test connection to your backend
4. Implement location tracking
5. Implement chat feature
6. Add push notifications

---

## Questions?

Common questions I anticipate:

**Q: Can we test without the backend running?**
A: Yes! Dev mode has mock WebSocket that simulates all events.

**Q: Will location tracking drain battery?**
A: 15-second polling uses ~2-3% battery/hour on average devices.

**Q: What if user loses internet?**
A: Chat messages queue locally and send when reconnected. Location is lost (we don't store it).

**Q: How many concurrent WebSocket connections?**
A: One per app session (singleton), with automatic cleanup on logout.

**Q: Can chat messages be encrypted?**
A: Currently no (rely on HTTPS/WSS). Can add end-to-end encryption in future.

---

## Files You'll See Created

As we implement Task 17.0, these files will be created:

```
lib/core/
├── services/
│   ├── websocket_service.dart ........... ~350 lines
│   ├── location_service.dart ............ ~200 lines
│   └── push_notification_service.dart ... ~250 lines
├── config/
│   └── websocket_config.dart ............ ~50 lines
└── providers/
    ├── websocket_provider.dart .......... ~120 lines
    └── push_notification_provider.dart .. ~100 lines

lib/features/
├── chat/
│   ├── models/message.dart ............. ~120 lines
│   ├── providers/chat_provider.dart ..... ~280 lines
│   ├── screens/chat_screen.dart ........ ~350 lines
│   └── widgets/
│       ├── message_bubble.dart ......... ~200 lines
│       └── chat_input.dart ............. ~180 lines
├── contractor/
│   └── providers/location_provider.dart . ~180 lines
└── client/
    ├── providers/contractor_location_provider.dart . ~150 lines
    └── widgets/contractor_location_map.dart ..... ~180 lines
```

**Total**: ~2,500 lines of new code across 15+ files

---

## Ready to Begin?

Once you provide the information above, I can start implementing Phase 1 (WebSocket Core) immediately.

Just tell me:
1. WebSocket URL
2. Event payload formats
3. Firebase setup status

Then I'll create fully functional real-time features! 🚀

