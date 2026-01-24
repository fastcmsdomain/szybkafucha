# Task Completion: Real-Time Task Acceptance Flow

**Data**: 2026-01-23
**Zadanie**: 17.7 - Naprawa flow akceptacji zlecenia z real-time WebSocket updates
**Status**: ✅ COMPLETE

---

## Przegląd

Naprawiono flow akceptacji zlecenia, gdzie zleceniodawca (klient) nie otrzymywał aktualizacji w czasie rzeczywistym po tym, jak wykonawca zaakceptował zlecenie. Poprzednio ekran śledzenia zlecenia używał symulacji zamiast prawdziwych danych z backendu.

### Problem
1. Backend wysyłał tylko push notification, brak WebSocket broadcast
2. Ekran TaskTrackingScreen używał hardcoded symulacji (6 stanów UI)
3. Zleceniodawca musiał ręcznie odświeżać, żeby zobaczyć zmiany statusu
4. Brak danych wykonawcy (imię, ocena, avatar) po akceptacji

### Rozwiązanie
1. Dodano WebSocket broadcasts w TasksService przy zmianie statusu
2. Dodano nową metodę `broadcastTaskStatusWithContractor()` z danymi wykonawcy
3. Usunięto symulację z TaskTrackingScreen, zastąpiono real-time WebSocket
4. Uproszczono UI do 4 podstawowych stanów (mapujących 1:1 na backend)

---

## Zmienione Pliki

### Backend

#### `backend/src/tasks/tasks.service.ts`
- Dodano WebSocket broadcasts w metodach: `acceptTask()`, `startTask()`, `completeTask()`, `cancelTask()`
- Przy akceptacji wysyłane są pełne dane wykonawcy

#### `backend/src/realtime/realtime.gateway.ts`
- Dodano nową metodę `broadcastTaskStatusWithContractor()`
- Zmodyfikowano `broadcastTaskStatus()` aby opcjonalnie wysyłać bezpośrednio do klienta

### Mobile (Flutter)

#### `mobile/lib/core/services/websocket_service.dart`
- Dodano klasę `ContractorInfo`
- Rozszerzono `TaskStatusEvent` o pole `contractor`

#### `mobile/lib/features/client/screens/task_tracking_screen.dart`
- Usunięto symulację (`_simulateStatusUpdates()`, Timer, `_etaMinutes`)
- Zredukowano `TrackingStatus` enum z 6 do 4 stanów
- Dodano WebSocket listener dla real-time updates
- Dodano metodę `_handleStatusUpdate()` do obsługi eventów

#### `mobile/lib/core/providers/task_provider.dart`
- Dodano WebSocket listener w `ClientTasksNotifier`
- Dodano metodę `_handleTaskStatusUpdate()` do aktualizacji stanu

#### `mobile/lib/features/client/models/task.dart`
- Dodano pole `contractor` do modelu Task
- Zaktualizowano `fromJson()` i `copyWith()`

### Dokumentacja

#### `tasks/tasks-prd-szybka-fucha.md`
- Dodano nowe zadanie 17.7 w sekcji Phase 4

#### `It_must_be_done_before_MVP_start.MD`
- Dodano Task 4.3 (Real-Time Task Acceptance Flow) w Phase 4 Testing

---

## Przykłady Kodu

### Backend: WebSocket Broadcast z danymi wykonawcy

```typescript
// backend/src/tasks/tasks.service.ts - acceptTask()
this.realtimeGateway.broadcastTaskStatusWithContractor(
  taskId,
  TaskStatus.ACCEPTED,
  contractorId,
  task.clientId,
  {
    id: contractorId,
    name: contractorProfile?.user?.name || 'Wykonawca',
    avatarUrl: contractorProfile?.user?.avatarUrl || null,
    rating: contractorProfile?.ratingAvg || 0,
    completedTasks: contractorProfile?.completedTasksCount || 0,
  },
);
```

### Backend: Nowa metoda gateway

```typescript
// backend/src/realtime/realtime.gateway.ts
broadcastTaskStatusWithContractor(
  taskId: string,
  status: TaskStatus,
  updatedBy: string,
  clientId: string,
  contractor: {
    id: string;
    name: string;
    avatarUrl: string | null;
    rating: number;
    completedTasks: number;
  },
): void {
  const update = {
    taskId,
    status,
    updatedAt: new Date(),
    updatedBy,
    contractor,
  };

  // Wyślij do task room (dla użytkowników w pokoju)
  this.server.to(`task:${taskId}`).emit(ServerEvent.TASK_STATUS, update);

  // Wyślij bezpośrednio do klienta (backup)
  this.sendToUser(clientId, ServerEvent.TASK_STATUS, update);

  this.logger.debug(
    `Task ${taskId} status broadcast with contractor: ${status} -> ${contractor.name}`,
  );
}
```

### Mobile: ContractorInfo i rozszerzony TaskStatusEvent

```dart
// mobile/lib/core/services/websocket_service.dart
class ContractorInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final double rating;
  final int completedTasks;

  ContractorInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.completedTasks,
  });

  factory ContractorInfo.fromJson(Map<String, dynamic> json) {
    return ContractorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedTasks: json['completedTasks'] as int? ?? 0,
    );
  }
}

class TaskStatusEvent {
  final String taskId;
  final String status;
  final DateTime updatedAt;
  final String updatedBy;
  final ContractorInfo? contractor;  // NOWE POLE

  // ... constructor i fromJson z parsowaniem contractor
}
```

### Mobile: WebSocket listener w TaskTrackingScreen

```dart
// mobile/lib/features/client/screens/task_tracking_screen.dart
@override
Widget build(BuildContext context) {
  // Nasłuchuj na WebSocket updates
  ref.listen<AsyncValue<TaskStatusEvent>>(
    taskStatusUpdatesProvider,
    (previous, next) {
      next.whenData((event) {
        if (event.taskId == widget.taskId) {
          _handleStatusUpdate(event);
        }
      });
    },
  );

  return Scaffold(/* ... */);
}

void _handleStatusUpdate(TaskStatusEvent event) {
  if (event.taskId != widget.taskId) return;

  setState(() {
    _status = _mapStringStatus(event.status);

    if (event.contractor != null) {
      _contractor = Contractor(
        id: event.contractor!.id,
        name: event.contractor!.name,
        avatarUrl: event.contractor!.avatarUrl,
        rating: event.contractor!.rating,
        completedTasks: event.contractor!.completedTasks,
        isVerified: true,
        isOnline: true,
      );
    }
  });
}
```

---

## Stany UI (4 podstawowe stany)

| Stan | Backend Status | UI Display |
|------|----------------|------------|
| `searching` | `CREATED` | "Szukamy pomocnika..." |
| `accepted` | `ACCEPTED` | "Pomocnik znaleziony" + dane wykonawcy |
| `inProgress` | `IN_PROGRESS` | "Praca w toku" |
| `completed` | `COMPLETED` | "Zakończone" |

---

## Testowanie

### Test Flow (Manual)

1. **Uruchom backend**: `cd backend && npm run start:dev`
2. **Uruchom app na dwóch urządzeniach/symulatorach**
3. **Urządzenie A**: Zaloguj jako klient, utwórz zlecenie
4. **Urządzenie B**: Zaloguj jako wykonawca
5. **Wykonawca widzi zlecenie** na liście
6. **Wykonawca klika "Przyjmij"**
7. **WERYFIKUJ**: Klient natychmiast widzi:
   - Status zmienia się z "Szukamy pomocnika" na "Pomocnik znaleziony"
   - Pojawia się karta wykonawcy z imieniem i oceną
8. **Wykonawca klika "Wyruszyłem" (start)**
9. **WERYFIKUJ**: Klient widzi status "Praca w toku"
10. **Wykonawca klika "Zakończ"**
11. **WERYFIKUJ**: Klient widzi status "Zakończone"

### Flutter Analyze

```bash
cd mobile && flutter analyze
# Wynik: Tylko minor info-level warnings (unused fields), brak błędów
```

---

## Decyzje Architektoniczne

1. **4 stany zamiast 6**: Uproszczono UI do mapowania 1:1 z backend statusami. Usunięto `onTheWay` i `arrived` które były sztuczne.

2. **Dual broadcast**: WebSocket wysyła zarówno do task room JAK I bezpośrednio do klienta (backup jeśli nie jest w pokoju).

3. **Push notification zachowane**: FCM push notification nadal wysyłane jako backup gdy app zamknięta.

4. **Contractor data w evencie**: Dane wykonawcy wysyłane tylko przy statusie `ACCEPTED`, nie przy każdej zmianie statusu.

---

## Następne Kroki

1. **Testy E2E**: Przeprowadzić pełne testy na fizycznych urządzeniach
2. **WebSocket reconnection**: Zweryfikować zachowanie przy utracie połączenia
3. **Offline support**: Rozważyć cache'owanie statusu lokalnie

---

## Powiązane Dokumenty

- PRD: `tasks/tasks-prd-szybka-fucha.md` - Task 17.7
- MVP Checklist: `It_must_be_done_before_MVP_start.MD` - Task 4.3
- Plan: `.claude/plans/immutable-beaming-hollerith.md`
