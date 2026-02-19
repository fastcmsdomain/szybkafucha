# App Icon Badge — Liczba nieprzeczytanych wiadomości

**Priorytet**: Średni
**Szacowany czas**: 2–3h
**Zależności**: Działający czat (✅), push notyfikacje (FCM setup)

---

## Cel

Pokazywać liczbę nieprzeczytanych wiadomości na ikonie aplikacji — tak jak WhatsApp / Messenger.
Działa na iOS (wszystkie launchers) i Android (Samsung, MIUI, Huawei, OnePlus — nie działa natively na stock Android Pixel bez notyfikacji).

---

## Podejście: Hybryda (zalecane)

- **Backend** ustawia `badge` w FCM payload → iOS automatycznie aktualizuje ikonę przy push notyfikacji
- **Flutter** (`flutter_app_badger`) czyści badge przy otwarciu aplikacji i aktualizuje przy nowych wiadomościach WS (gdy app jest na pierwszym planie)

---

## Co już istnieje

- `messages.service.ts` → `getAllUnreadCounts(userId)` — zlicza nieprzeczytane per task
- `NotificationsService` → wysyła FCM `NEW_MESSAGE` do odbiorcy
- `unreadMessagesProvider` → trzyma licznik per task w pamięci aplikacji
- `markAsRead` endpoint — czyści nieprzeczytane po wejściu do czatu

---

## Plan implementacji

### 1. Backend — dodaj `badge` do FCM payload

**Plik:** `backend/src/notifications/notifications.service.ts`

Przed wysłaniem notyfikacji `NEW_MESSAGE`, pobierz sumę nieprzeczytanych wiadomości dla odbiorcy i dodaj do FCM payloadu:

```typescript
// W sendToUser() dla NEW_MESSAGE
const totalUnread = await this.messagesService.getAllUnreadCounts(recipientId);
const badgeCount = totalUnread.reduce((sum, t) => sum + t.count, 0);

// Do FCM payload dodać:
{
  notification: { title, body },
  apns: {
    payload: {
      aps: { badge: badgeCount }  // iOS badge
    }
  },
  android: {
    notification: {
      notificationCount: badgeCount  // Android badge (Samsung etc.)
    }
  }
}
```

### 2. Flutter — dodaj pakiet `flutter_app_badger`

**Plik:** `mobile/pubspec.yaml`

```yaml
dependencies:
  flutter_app_badger: ^1.5.0
```

**iOS** (`mobile/ios/Runner/Info.plist`) — nie wymaga dodatkowych uprawnień dla badge.

### 3. Flutter — aktualizuj badge przy nowych wiadomościach (foreground)

**Plik:** `mobile/lib/core/widgets/websocket_initializer.dart`

W `build()`, po inicjalizacji, dodaj listener na `unreadMessagesProvider`:

```dart
ref.listen<Map<String, int>>(unreadMessagesProvider, (_, counts) {
  final total = counts.values.fold(0, (sum, c) => sum + c);
  if (total > 0) {
    FlutterAppBadger.updateBadgeCount(total);
  } else {
    FlutterAppBadger.removeBadge();
  }
});
```

### 4. Flutter — wyczyść badge przy wejściu do czatu

**Plik:** `mobile/lib/features/chat/screens/chat_screen.dart`

W `Future.microtask()` w `initState`, po `clearUnread()`:

```dart
final remaining = ref.read(unreadMessagesProvider);
final total = remaining.values.fold(0, (sum, c) => sum + c);
total > 0
    ? FlutterAppBadger.updateBadgeCount(total)
    : FlutterAppBadger.removeBadge();
```

### 5. Flutter — wyczyść badge przy starcie (cold start)

**Plik:** `mobile/lib/main.dart` lub `WebSocketInitializer.initState()`

```dart
FlutterAppBadger.removeBadge(); // Czyść przy otwarciu app
```

---

## Pliki do modyfikacji

| Plik | Zmiana |
|------|--------|
| `backend/src/notifications/notifications.service.ts` | Dodaj `badge` / `notificationCount` do FCM payload |
| `mobile/pubspec.yaml` | Dodaj `flutter_app_badger` |
| `mobile/lib/core/widgets/websocket_initializer.dart` | Listener na `unreadMessagesProvider` → update badge |
| `mobile/lib/features/chat/screens/chat_screen.dart` | Aktualizuj badge po `clearUnread()` |
| `mobile/lib/main.dart` | `removeBadge()` przy cold start |

---

## Ograniczenia

- **Android stock (Pixel/AOSP)**: Badge na ikonie wymaga aktywnej notyfikacji w szufladzie — bez niej nie działa. Po wyświetleniu push notyfikacji badge pojawi się automatycznie dzięki FCM `notificationCount`.
- **iOS**: Działa niezawodnie na wszystkich urządzeniach.
- Licznik jest resetowany do 0 przy otwarciu aplikacji, nie tylko konkretnego czatu — można to udoskonalić w przyszłości (reset per-task).
