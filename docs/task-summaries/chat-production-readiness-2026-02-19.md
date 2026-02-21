# Chat — Production Readiness Audit

**Date**: 2026-02-19
**Status**: Implementation complete, production deployment requires fixes below

---

## Architektura czatu

```
[Flutter App]
    │
    ├── WebSocket (Socket.io)  ──────────────────► [NestJS realtime.gateway.ts]
    │   └── message:send                               └── saveMessage() → broadcast message:new
    │
    └── REST API (Dio)         ──────────────────► [NestJS messages.controller.ts]
        ├── GET  /tasks/:id/messages (historia)        └── MessagesService
        └── POST /tasks/:id/messages (fallback)
```

**Przepływ wiadomości:**
1. Użytkownik wpisuje tekst → `ChatInput` sprawdza numer telefonu
2. `ChatNotifier.sendMessage()` wysyła przez WebSocket (`message:send`)
3. Backend zapisuje do DB i rozgłasza (`message:new`) do pokoju zadania
4. Drugi użytkownik odbiera wiadomość w czasie rzeczywistym
5. Przy wejściu do czatu: REST API pobiera ostatnie 50 wiadomości z historii

---

## KRYTYCZNE — blokują produkcję

### 1. Hardcoded adresy IP dewelopera
**Pliki:**
- `mobile/lib/core/api/api_config.dart`
- `mobile/lib/core/config/websocket_config.dart`

**Problem:**
```dart
// api_config.dart
static const String devServerUrl = 'http://192.168.1.131:3000';
static const String serverUrl = devServerUrl; // ← używane wszędzie

// websocket_config.dart
static const String webSocketUrl = 'ws://192.168.1.131:3000';
```
Aplikacja łączy się tylko z komputerem dewelopera. Żaden inny użytkownik nie połączy się z backendem.

**Fix:**
```dart
// api_config.dart
static const String productionUrl = 'https://api.szybkafucha.pl';
static const String devServerUrl = 'http://192.168.1.131:3000';
static const String serverUrl = bool.fromEnvironment('dart.vm.product')
    ? productionUrl
    : devServerUrl;
```

---

### 2. Dev Mode włączony w produkcji
**Plik:** `mobile/lib/core/api/api_config.dart`

```dart
static const bool devModeEnabled = true; // ← mock data zamiast backend
```
Aplikacja używa fikcyjnych danych — żadne API nie jest wywoływane.

**Fix:** Ustawić `false` lub uzależnić od `dart.vm.product`.

---

### 3. Sender Name zawsze "Unknown User"
**Plik:** `mobile/lib/features/chat/providers/chat_provider.dart:146`

```dart
final message = Message(
  senderName: 'Unknown User', // ← hardcoded
  ...
);
```
Backend nie wysyła nazwy nadawcy w evencie WebSocket `message:new`.

**Fix w `realtime.gateway.ts`** — dodać dane nadawcy do broadcast:
```typescript
// Przed emit, pobierz dane nadawcy
const sender = await this.realtimeService.getUserById(userId);

this.server.to(`task:${data.taskId}`).emit(ServerEvent.MESSAGE_NEW, {
  id: savedMessage.id,
  taskId: data.taskId,
  senderId: userId,
  senderName: sender?.name ?? 'Użytkownik',      // ← DODAĆ
  senderAvatarUrl: sender?.avatarUrl ?? null,      // ← DODAĆ
  content: data.content,
  createdAt: savedMessage.createdAt,
});
```

---

### 4. CORS WebSocket — brak ograniczeń
**Plik:** `backend/src/realtime/realtime.gateway.ts`

```typescript
@WebSocketGateway({
  cors: {
    origin: '*', // ← dowolna domena może się połączyć
    credentials: true,
  },
})
```

**Fix:**
```typescript
cors: {
  origin: [
    'http://localhost:3001',
    'https://szybkafucha.pl',
    'https://app.szybkafucha.pl',
  ],
  credentials: true,
},
```

---

### 5. JWT Token w query params WebSocket
**Plik:** `mobile/lib/core/services/websocket_service.dart`

Token JWT jest wysyłany jako parametr URL — widoczny w logach serwera, proxy, CDN.

**Fix:** Wysyłać token w nagłówku `auth` (Socket.io obsługuje):
```dart
// W websocket_service.dart
.setExtraHeaders({'Authorization': 'Bearer $jwtToken'})
```

---

### 6. Brak rate limiting na wiadomości
**Pliki:** `realtime.gateway.ts`, `messages.controller.ts`

Użytkownik może wysyłać tysiące wiadomości na sekundę.

**Fix w `messages.controller.ts`:**
```typescript
import { Throttle } from '@nestjs/throttler';

@Throttle({ default: { limit: 30, ttl: 60000 } }) // 30 wiadomości/minutę
@Post(':taskId/messages')
async sendMessage(...) {}
```

---

## WAŻNE — degradują doświadczenie

### 7. Kolejność wiadomości — niespójność REST vs UI
**Backend** zwraca wiadomości `DESC` (najnowsze pierwsze):
```typescript
queryBuilder.orderBy('message.createdAt', 'DESC').take(50);
```
**Frontend** sortuje `ASC`:
```dart
all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
```
Wynik: poprawna kolejność wyświetlania, ale przy paginacji (load more) może być chaotycznie.

**Fix:** Zmienić backend na `ASC` lub zachować `DESC` i odwrócić po stronie frontendu bez sortowania.

---

### 8. Brak paginacji — tylko 50 wiadomości
Backend ma parametr `before` w `getTaskMessages()`, ale frontend nigdy go nie używa.
Użytkownicy nie mogą zobaczyć wiadomości starszych niż ostatnie 50.

**Fix:** Dodać w `ChatScreen` listener na scroll — gdy użytkownik scrolluje do góry, wywołać `loadMoreMessages(before: firstMessageId)`.

---

### 9. Brak przycisku "Wyślij ponownie" dla nieudanych wiadomości
Nieudane wiadomości trafiają do `pendingMessages` i są tam — bez UI do ponownego wysłania.

---

### 10. Push notifications nie otwierają czatu
Backend wysyła powiadomienie `NEW_MESSAGE`, ale tap na powiadomienie nie nawiguje do ekranu czatu.

**Fix:** W `NotificationService` dodać handler:
```dart
if (notification.type == 'NEW_MESSAGE') {
  context.push(Routes.chat(taskId: notification.taskId, ...));
}
```

---

### 11. Brak limitu znaków w polu tekstowym
**Backend:** `@MaxLength(2000)` w DTO
**Frontend:** brak `maxLength` w `TextField`

Użytkownik może wpisać 10 000 znaków i dostać błąd serwera.

**Fix w `chat_input.dart`:**
```dart
TextField(
  maxLength: 2000,
  // ...
)
```

---

### 12. Wiadomości pending nie są persystowane
Nieudane wiadomości istnieją tylko w pamięci. Po zamknięciu aplikacji — znikają.

**Fix (długoterminowy):** Użyć Hive lub SQLite do lokalnego przechowywania pending messages.

---

## MNIEJSZE — nice to have

| # | Issue | Plik |
|---|-------|------|
| 13 | Brak badge z liczbą nieprzeczytanych wiadomości | `task_tracking_screen.dart`, `active_task_screen.dart` |
| 14 | Avatar bez placeholder/fallback przy błędzie ładowania | `message_bubble.dart` |
| 15 | Brak wskaźnika "pisze..." (typing indicator) | `realtime.gateway.ts`, `chat_provider.dart` |
| 16 | Komunikaty błędów WebSocket po angielsku | `websocket_service.dart` |
| 17 | Brak licznika znaków w polu wiadomości | `chat_input.dart` |
| 18 | Scroll physics nie dopasowane do platformy (iOS/Android) | `chat_screen.dart` |

---

## Co już działa poprawnie

- Blokowanie numerów telefonów na 3 poziomach (Flutter UI, REST, WebSocket)
- Poprawne `autoDispose` na `chatProvider` — brak problemu ze starym stanem
- `isConnected` odzwierciedla realny stan WebSocketa (`stateStream`)
- Auto-retry pending messages po reconnect
- Historia wiadomości pobierana z REST API przy wejściu do czatu
- PopScope cleanup — wypisanie z pokoju przy wyjściu

---

## Priorytetyzacja dla produkcji

### Przed deploymentem (MUST):
1. Zmień URL API i WebSocket na produkcyjny
2. Wyłącz `devModeEnabled`
3. Napraw "Unknown User" (dodać senderName do WebSocket broadcast)
4. Ogranicz CORS WebSocket

### Krótko po deploymencie (SHOULD):
5. Dodaj rate limiting
6. Napraw JWT w query params → nagłówek
7. Obsłuż tap na push notification → czat
8. Dodaj limit znaków w TextField

### Iteracja 2 (COULD):
9. Paginacja historii wiadomości
10. Persist pending messages
11. Typing indicator
12. Unread badge
